# UNDERLOD Spawn Tuning Guide

How enemies get onto the field on campaign levels, and which knobs shape it.
Source files: `spawns/spawnmanager.lua`, `spawns/levelmanager.lua`,
`game_constants.lua`.

---

## 1. Architecture: two lanes + one events layer

Campaign levels are driven by the **spawn director** (`spawn_director` config
in `LEVEL_SPAWN_POOLS`). It runs two independent lanes plus an authored layer:

1. **Swarmer lane** (`SpawnManager:tick_swarmer_lane`) — chaff. Fires clumps
   on its own adaptive cooldown (see §2). Runs from the first second of the
   level.
2. **Specials queue** (`SpawnManager:tick_spawn_director`) — tanks, small
   archers, and the `special` pool. Deficit-weighted pick: each fire spawns
   whichever slot is furthest below its setpoint. These setpoints are **hard
   caps**: a slot at setpoint never spawns, so `tank = 2` means at most 2
   tanks alive. Paced by **whole-field** power fill (swarmers included), so a
   packed swarm delays the next special. Held closed for the first
   `SPAWN_DIRECTOR_OPENING_GRACE` (7) seconds of the level.
3. **Authored events** (`specials = {{type=..., at=...}}` in a level config) —
   one-shot spawns at a kill-quota progress fraction. They bypass caps AND the
   opening grace, so `at = 0` is the deliberate "nasty thing from second one"
   override.

Both lanes share per-slot setpoints, pending (in-flight) tracking, and
weighted offscreen placement. The ramp (setpoint scales `ramp.from ->
ramp.to` across kill-quota progress, default 0.8 -> 1.2) and the ceiling
(`ramped setpoint * SPAWN_DIRECTOR_CEILING_MULT`) apply to the **swarmer lane
only** — fractional specials make no sense, so their setpoints stay fixed
integers. Between setpoint and ceiling the swarmer interval stretches by up
to `(1 + SWARMER_LANE_OVERFILL_SLOWDOWN)`x, so overshoot is a slow drift,
not full-rate spawning.

## 2. Swarmer lane: fill-time-based cooldown

The lane's base interval is **derived, not authored**. The design goal:
starting from an empty field, reach `SWARMER_LANE_TARGET_FILL` (80%) of the
swarmer setpoint in `SWARMER_LANE_FILL_TIME` (8) seconds — on every level,
regardless of setpoint. Levels with bigger swarms spawn proportionally
faster; sustained throughput scales linearly with the setpoint.

Mechanics per fire:

- Average clump size `G` is computed from `SWARMER_GROUP_MIX` (currently 5:
  1/3 chance of a 4-6 scatter group, 2/3 chance of a clustered 4-6).
- The catch-up curve scales the interval by
  `m(fill) = c + (1-c) * min(fill / frac, 1)` with
  `c = SWARMER_LANE_CATCHUP_MULT` (0.5), `frac = SWARMER_LANE_CATCHUP_FRACTION`
  (0.5): half-length intervals on an empty field, full length from half-
  setpoint up.
- The base interval solves the fill-time goal, integrating that slowdown:

```
M      = TARGET_FILL - frac*(1-c)/2          (= 0.675 with defaults)
I_base = FILL_TIME * G / (setpoint_ramped * M)
```

clamped to `[SWARMER_LANE_INTERVAL_MIN, SWARMER_LANE_INTERVAL_MAX]`
(1.2s-6.5s). Because `setpoint_ramped` includes the within-level ramp, the
cadence tightens ~20% over a level automatically.

- At or above the ceiling the fire is skipped (recheck in
  `SWARMER_LANE_RETRY` = 0.5s); it also respects quota-met and the global cap.

Resulting steady-state intervals with defaults (FILL_TIME 8, G 5):

| level | swarmer setpoint | ramped (x0.8 open) | I_base open | I_base level end (x1.2) |
|---|---|---|---|---|
| L1-2 | 15 | 12.0 | 4.9s | 3.3s |
| L3 | 20 | 16.0 | 3.7s | 2.5s |
| L4-5 | 22 | 17.6 | 3.4s | 2.2s |
| L7-10 | 48 | 38.4 | 1.5s | 1.2s (clamped) |

Caveat: at low setpoints (L1-2) a single clump is roughly a third of the
field, so "80% in 8s" quantizes coarsely; the fill-time promise really
governs bigger setpoints where multiple fires matter. If early levels should
open lazier, shrink clump sizes at low setpoints (group mix), don't raise
FILL_TIME.

## 3. Knobs

### Per-level (`LEVEL_SPAWN_POOLS[n].spawn_director`)

| you want | knob | effect |
|---|---|---|
| denser/thinner swarm | `setpoints.swarmer` | standing density AND refill rate (throughput scales linearly with it) — the main difficulty dial |
| more/other specials | `setpoints.tank/small_archer/special`, `special_pool` | deficit queue handles composition |
| front-load the level | `ramp = {from = 1.3, to = 0.9}` | swarmer lane only: opens heavy, eases off; also speeds the opening cadence since I_base uses the ramped setpoint |
| scripted opening punch | `specials = {{type='brute', at=0}}` | fires immediately, ignores caps and grace |
| this level fills faster/slower | `fill_time = 4` | per-level override of SWARMER_LANE_FILL_TIME |
| more swarmer overshoot room | `ceilings`, `ceiling_mult` | swarmer ceiling override (specials cap at setpoint) |

### Global (`game_constants.lua`)

| knob | default | meaning |
|---|---|---|
| `SWARMER_LANE_FILL_TIME` | 8 | seconds to reach TARGET_FILL from empty — the game-wide opening pace |
| `SWARMER_LANE_TARGET_FILL` | 0.8 | definition of "filled"; rarely touch |
| `SWARMER_LANE_CATCHUP_MULT/FRACTION` | 0.5 / 0.5 | recovery speed after the player wipes the field; lower mult = punishes big clears faster |
| `SWARMER_LANE_INTERVAL_MIN/MAX` | 1.2 / 6.5 | safety clamp on the derived interval |
| `SWARMER_GROUP_MIX` | 4-6 scatter / 8-12 clump | **burstiness, rate-neutral**: avg size G is in the interval formula, so bigger clumps = longer gaps at identical throughput |
| `SPAWN_DIRECTOR_OPENING_GRACE` | 7 | seconds before the specials queue opens |
| `SPAWN_DIRECTOR_TANK_SWARM_GATE` | 0.5 | tanks wait until the swarm is at this fraction of setpoint |
| `SPAWN_DIRECTOR_INTERVAL_MIN/MAX`, `RATE_EXP` | 0.2 / 6 / 2 | specials-queue pacing curve (whole-field power fill) |
| `SPAWN_DIRECTOR_RAMP_FROM/TO` | 0.8 / 1.2 | within-level escalation of the swarmer setpoint (per-level `ramp` overrides) |
| `SWARMER_LANE_OVERFILL_SLOWDOWN` | 2 | interval stretch above the swarmer setpoint, up to (1+this)x at the ceiling |

Mental model: **setpoint = how hard, fill time = how fast it gets there,
ramp = the shape within a level, group mix = the texture, catch-up = the
slack for clearing well.**

# UNDERLOD Spawn Tuning Guide

How enemies get onto the field on campaign levels, and which knobs shape it.
Source files: `spawns/spawnmanager.lua`, `spawns/levelmanager.lua`,
`game_constants.lua`.

Every campaign level is a **roster released over a clock**. The level config
says how many of each enemy exist and how long the release takes; what the
player kills only changes *when* things arrive, never *how many*. Victory
requires an empty enemy group and zero pending spawns once the roster is
spent. Kill score alone never clears the level, and survivors are never
automatically killed. Offspring and summons are extra enemies that must also
be defeated. Bosses keep their all-enemies-dead rule; the debug arena finishes
after its manual queue is exhausted and the field is cleared.

---

## 1. Level config

```lua
[3] = {
  spawn_director = {
    length = 30,                              -- seconds
    swarmer = { cap = 10, total = 30 },       -- alive ceiling, roster
    timeline = { small_archer = 6 },          -- specials: totals only
    clustered_only = true,                    -- optional
  },
  specials = { {type = 'pulsar', at = 0.5} }, -- optional scripted beats
},
```

- `length` — seconds over which the roster is released. The level usually
  runs longer than this: leftover swarmers spill afterward, and the player
  still has to clear the field.
- `swarmer.cap` / `swarmer.total` — at most `cap` swarmers alive (ramped, see
  §2); `total` spawn over the level.
- `timeline` — `{type = total}` or `{type = {total = n, group = g}}` for
  enemies that spawn in groups (linker pairs). Specials have **no alive cap**.
- `clustered_only` — every swarmer clump uses the clustered roll from
  `SWARMER_GROUP_MIX`; no scatter groups.
- `specials` events — one-shot spawns at a fraction of `length`. They bypass
  caps and the opening grace, so `at = 0` is the deliberate "nasty thing from
  second one" override.

The spawn budget (`kill_quota`) is **derived**: every swarmer, timeline
special and scripted event priced by `enemy_to_round_power`
(`Director_Spawn_Quota`). It is exact, so there is no overshoot, and it is
the progress bar's total. `LEVEL_PACING` only carries `round_power` (the
gold-per-kill denominator) now.

## 2. Swarmer lane

`SpawnManager:tick_swarmer_lane`. The roster is metered through a **bank**:

- The bank opens at `cap`, so the field fills to cap immediately (clumps
  fire `SWARMER_LANE_MIN_GAP` apart).
- It then accrues at `(total - cap) / length` per second — the even release
  rate. A clump fires only when the bank holds a whole clump's worth and the
  cap has room; a full cap just delays it, the bank keeps growing.
- When the clock passes `length`, the whole remainder is banked and spills
  as fast as the cap frees up.
- The cap ramps `SPAWN_DIRECTOR_RAMP_FROM -> _TO` (0.8 -> 1.2) across the
  clock, so the standing swarm grows about 50% over a level. Per-level
  `ramp = {from=, to=}` overrides.

Rates with current rosters (opening burst excluded):

| level | cap | total | length | drip after opening |
|---|---|---|---|---|
| L1 | 15 | 45 | 20s | 1.5/s — a 5-clump every 3.3s |
| L2 | 15 | 55 | 25s | 1.6/s — every 3s |
| L3 | 10 | 40 | 30s | 1.0/s — every 5s |
| L4 | 22 | 70 | 35s | 1.4/s — every 3.6s |
| L5 | 22 | 80 | 40s | 1.45/s — every 3.4s |
| L7-10 | 26 | 100-145 | 45-60s | 1.6-2.0/s — every 2.5-3s |

A player who clears fast sees a thinner field between clumps; a slow player
sits at cap and the bank spills at the end. Either way the count is fixed.

## 3. Specials timeline

`SpawnManager:tick_special_timeline`. At level start each timeline type is
spread evenly over `length`: `n` entries at `length * (i - 0.5) / n`, each
shifted by up to `SPAWN_TIMELINE_JITTER` (20%) of that spacing, clamped to
`[SPAWN_DIRECTOR_OPENING_GRACE, length]`. All types merge into one sorted
schedule. An entry fires when the spawn clock reaches it, **regardless of
how many specials are alive** — only `SPAWN_DIRECTOR_GLOBAL_CAP` (200, a
performance backstop) can delay it. Killing a special never summons another;
ignoring one never prevents the next.

## 4. Knobs

### Per-level (`LEVEL_SPAWN_POOLS[n].spawn_director`)

| you want | knob | effect |
|---|---|---|
| a longer/shorter level | `length` | stretches both the swarmer drip and the special schedule |
| denser/thinner standing swarm | `swarmer.cap` | alive ceiling; also the size of the opening burst |
| more/fewer swarmers overall | `swarmer.total` | roster; with `length` sets the drip rate |
| more/other specials | `timeline` | totals per type; evenly interleaved |
| front-load the swarm | `ramp = {from = 1.2, to = 0.8}` | cap opens high and eases off |
| scripted opening punch | `specials = {{type='brute', at=0}}` | fires immediately, ignores caps and grace |
| clumps only, never scatter | `clustered_only = true` | every swarmer fire uses the clustered roll |

### Global (`game_constants.lua`)

| knob | default | meaning |
|---|---|---|
| `SPAWN_DIRECTOR_DEFAULT_LENGTH` | 60 | length for configs that omit one |
| `SPAWN_DIRECTOR_RAMP_FROM/TO` | 0.8 / 1.2 | swarmer cap scaling across the clock |
| `SPAWN_DIRECTOR_OPENING_GRACE` | 2 | earliest second a timeline special can be scheduled |
| `SPAWN_TIMELINE_JITTER` | 0.2 | per-special schedule shift, as a fraction of its spacing |
| `SWARMER_GROUP_MIX` | 4-6 scatter (2) / 4-6 clustered (4) | clump size and texture, weighted |
| `SWARMER_LANE_MIN_GAP` | 0.75 | shortest gap between clumps (opening burst cadence) |
| `SWARMER_LANE_RETRY` | 0.5 | recheck delay when a fire is skipped |
| `SPAWN_DIRECTOR_JITTER` | 0.25 | jitter on the swarmer gap |
| `SPAWN_DIRECTOR_GLOBAL_CAP` | 200 | hard total-alive backstop |

Mental model: **total = how much, cap = how thick, length = how fast, ramp
= the shape within a level, group mix = the texture.**

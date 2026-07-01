# UNDERLOD Combat Model (DPS-requirement package)

Self-contained reference for computing **how much player DPS a level demands**.
Everything here is extracted from the live code (file:line cited). No game
engine needed — plug the formulas into any calculator/model.

Source files: `combat_stats/combat_stats.lua`, `objects.lua`,
`helper/helper_damage.lua`, `main.lua`, `spawns/levelmanager.lua`,
`spawns/spawnmanager.lua`, `game_constants.lua`.

---

## 1. Player (troop) offense

### 1.1 Base stats (`combat_stats.lua`)
- `TROOP_HP = 100`, `TROOP_DAMAGE = 11`, `TROOP_MS = 60`.

### 1.2 Per-character multipliers (`unit_stat_multipliers`)
| character | hp× | dmg× | def× | mvspd× | notes |
|---|---|---|---|---|---|
| archer   | 1.25 | 1.5  | 1   | 1.0  | single-target ranged |
| swordsman| 1.5  | 1.25 | 1.25| 1.0  | melee |
| sword    | 1.4  | 1.3  | 1.2 | 1.05 | melee AoE cone (hits 2+) |
| shotgun  | 1.2  | 0.3  | 1   | 1.05 | **5 pellets/shot**, dmg× is per pellet |
| laser    | 1.0  | 1.0  | 1   | 1.0  | piercing beam (hits all in line) |

Effective per-hit damage (no items):
`dmg = TROOP_DAMAGE * character.dmg` → archer 16.5, swordsman 13.75, sword 14.3,
shotgun 3.3/pellet (×5 = 16.5 point-blank), laser 11.

Items/perks/set-bonuses add on top (additive `+a` then multiplicative `*m`; see
`objects.lua:calculate_stats`). Treat those as external modifiers to `dmg`.

### 1.3 Attack cadence
Attack period = `troop_attack_cooldowns[character]` (seconds), plus a small cast
time (`troop_cast_times`, ≤0.05–0.15s, usually negligible).

| character | cooldown (s) | cast (s) | shots/s (base) |
|---|---|---|---|
| archer    | 0.45 | 0.05 | ~2.0 |
| swordsman | 0.8  | 0.15 | ~1.05 |
| sword     | 1.65 (`fast`×1.5) | 0.15 | ~0.56 |
| shotgun   | 1.5 (`medium`) | 0.15 | ~0.61 (×5 pellets) |
| laser     | 2.5 (`slow`) | 0    | 0.4 (pierces line) |

`attack_cooldowns = { very-fast 0.8, fast 1.1, medium 1.5, slow 2.5, very-slow 4.0 }`.
Item `aspd` multiplies the cooldown: `cooldown = base_cooldown * aspd_m` (`objects.lua:1007`).

### 1.4 Crit (`helper_damage.lua:281`, `BASE_CRIT_MULT = 2`)
`expected_dmg = dmg * (1 + crit_chance * (crit_mult - 1))`. Base crit_chance = 0
(only from items). Default crit_mult = 2.

### 1.5 Single-target DPS
```
DPS_single = dmg_per_hit * hits_per_second * (1 + crit_chance*(crit_mult-1))
hits_per_second = 1 / (attack_cooldown * aspd_m + cast_time)
```
Multi-hit weapons (shotgun ×5 pellets, sword cone, laser pierce, multishot procs)
multiply effective DPS by the number of enemies/pellets that land.

---

## 2. Enemy defense & effective HP

### 2.1 Damage vs defense (`objects.lua:532`)
```
if def >= 0:  taken = dmg * 100/(100+def)
else:         taken = dmg * (2 - 100/(100+def))
```
**Almost all enemies have def = 0** (no reduction). Only a few set `flat_def`/
`percent_def` via `enemy_type_to_stats`. Default: `taken = dmg` (full).

### 2.2 Class base stats (`combat_stats.lua`)
| class | base HP | base dmg | base ms |
|---|---|---|---|
| regular_enemy | 45  | 15 | 18 |
| special_enemy | 280 | 20 | 20 |
| miniboss      | 400 | 20 | 50 |
| boss          | 1400| 20 | 70 |

(swarmer = regular_enemy; tank / small_archer / most specials = special_enemy.)

### 2.3 Level scaling
`ENEMY_SCALE_BY_LEVEL` (index = level):
```
L1-3:0  L4-6:1  L7-9:2  L10-12:3  L13-15:4  L16-18:5  L19:6  L20-22:7  L23-25:8
```
`POST_BOSS_HP_MULT`: L1-6 = 1.0, L7-11 = 1.4, L12+ = 1.7.

```
SCALED_ENEMY_HP(L, base)     = base * (1 + 0.2*scale) * POST_BOSS_HP_MULT(L)
SCALED_ENEMY_DAMAGE(L, base) = base * (1 + 0.1*scale)
SCALED_ENEMY_MS(L, base)     = base * (1 + 0.03*scale)
```
Bosses use `BOSS_SCALE_BY_LEVEL` (1 at L12, 2 at L20, 4 at L28; else 0) with
coefficients 0.8/0.2/0.05, and per-boss `BOSS_HP_MULT_BY_TYPE` (stompy 3.36,
dragon 2.5) applied on top of `SCALED_BOSS_HP`.

### 2.4 Per-type multipliers (`enemy_type_to_stats`) — applied AFTER scaling
`effective_HP = SCALED_ENEMY_HP(L, class_base) * type.hp   (type.hp defaults 1)`
`effective_dmg = SCALED_ENEMY_DAMAGE(L, class_base) * type.dmg`

| type | class | hp× | dmg× | mvspd× |
|---|---|---|---|---|
| swarmer      | regular | 0.6 | 0.5 | 1.3 |
| tank         | special | 0.8 | 1.0 | 0.6 |
| small_archer | special | 0.4 | 0.5 | 0.9 |
| brute        | special | 1.6 | 1.0 | 1.5 |
| slime        | special | 1.4 | 1.0 | 0.7 |
| orb          | special | 1.8 | 1.0 | 0.8 |
| sniper       | special | 1.0 | 1.0 | 1.0 |
| roach        | special | 1.0 | 1.0 | 1.6 |
(others default hp/dmg/mvspd = 1 unless listed; full table at `combat_stats.lua:668`.)

### 2.5 Effective HP examples (computed from §2.3–2.4)
Swarmer `= 45*(1+0.2*scale)*postboss*0.6`:
| L | scale | postboss | swarmer HP | tank HP `=280*(…)*0.8` | small_archer HP `*0.4` |
|---|---|---|---|---|---|
| 1 | 0 | 1.0 | 27.0 | 224.0 | 112.0 |
| 2 | 0 | 1.0 | 27.0 | 224.0 | 112.0 |
| 3 | 0 | 1.0 | 27.0 | 224.0 | 112.0 |
| 4 | 1 | 1.0 | 32.4 | 268.8 | 134.4 |
| 5 | 1 | 1.0 | 32.4 | 268.8 | 134.4 |
| 7 | 2 | 1.4 | 52.9 | 439.0 | 219.5 |
| 10| 3 | 1.4 | 60.5 | 501.8 | 250.9 |
| 12| 3 | 1.7 | 73.4 | 609.3 | 304.6 |

---

## 3. Level economy (what must die)

### 3.1 Round power per enemy (`main.lua enemy_to_round_power`)
swarmer 25, tank 100, small_archer 75, slime 100, goblin_archer 150, brute 200,
sniper 200, orb 200, cleaver 200, snakearrow 200, mortar 200, boomerang 200,
plasma 200, splitter 200, pulse_walker 200, drone_carrier 200 (all T2-pool = 200),
bosses `BOSS_ROUND_POWER = 1000`. Killing an enemy adds its round_power to the
level's kill tally.

### 3.2 kill_quota — the level-completion gate (`levelmanager.lua:204`)
A non-boss level clears when cumulative killed round_power ≥ `kill_quota`:
```
quota_level = (L <= 3) ? 1 : L
qrp   = ROUND_POWER_BY_LEVEL[quota_level] + 500
mult  = 1.5 + 0.10*(quota_level-1);   if quota_level>=4: mult *= 1.15
scale = (quota_level>=4) ? 0.65 : 1.0
kill_quota = ceil(qrp * mult * 1.5 * scale)
```
`ROUND_POWER_BY_LEVEL`: L1 400, L2 600, L3 800, L4 1100, L5 1300, L7 1700,
L8 1900, L9 2100, L10 2300, L11 2500 (L6/L11 are bosses).

Computed kill_quota (non-boss, shipping range):
| L | kill_quota |
|---|---|
| 1 | 2025 |
| 2 | 2025 |
| 3 | 2025 |
| 4 | 3230 |
| 5 | 3835 |
| 7 | 5181 |
| 8 | 5921 |
| 9 | 6706 |
| 10| 7535 |
| L6, L11 | boss levels — no kill_quota; clear = kill the boss (see §2.3) |

### 3.3 HP that must be dealt to clear
Killing `kill_quota` worth of round_power means dealing the **sum of effective HP**
of the enemies killed. Per-type "HP per power" ratio (level-dependent):
```
hp_per_power(type, L) = effective_HP(type, L) / round_power(type)
```
- swarmer L1: 27 / 25 = **1.08 HP/power**
- tank L1:   224 / 100 = **2.24 HP/power**
- small_archer L1: 112 / 75 = **1.49 HP/power**

Total HP to clear a level ≈ `kill_quota * weighted_avg(hp_per_power)`, weighted by
the composition the director actually spawns (§4). Swarmer-dominated early levels
sit near ~1.1 HP/power.

**Clear-time DPS requirement:**
```
required_DPS_to_clear(L, T_target) = (kill_quota(L) * avg_hp_per_power) / T_target
```
Example — L1, all-swarmer approximation, clear in 60 s:
`(2025 * 1.08) / 60 ≈ 36.5 damage/sec`. (Archer base ≈ 16.5 * 2.0 ≈ 33 DPS →
just under; that's the intended "need a couple items / crits" pressure.)

---

## 4. Spawn director (what's alive & arriving)

The director maintains a per-slot **setpoint** (ideal alive count) per level and
paces spawns by total-power fill. Relevant for the *sustain* DPS requirement
(kill rate must ≥ arrival rate or the field grows to the cap and overwhelms you).

### 4.1 Setpoints (`levelmanager.lua`)
| L | swarmer | tank | special | small_archer | special_pool |
|---|---|---|---|---|---|
| 1 | 22 | 1 | – | – | – |
| 2 | 30 | 2 | – | 1 | – |
| 3 | 40 | 2 | 1 | – | sniper, slime |
| 4 | 48 | 1 | 1 | 2 | sniper, slime |
| 5 | 48 | 2 | 1 | 2 | sniper, slime |
| 7–10 | 48 | 2 | 4 | 3 | T2 pool (11 types, all power 200) |

- `special` is a category slot: draws a random type from `special_pool` each spawn.
- Setpoints scale over the level by `lerp(0.8, 1.2, kill_quota_progress)`
  (`SPAWN_DIRECTOR_RAMP_FROM/TO`).
- Per-slot ceiling = `ceil(setpoint * 1.75)` (`SPAWN_DIRECTOR_CEILING_MULT`);
  global hard cap `SPAWN_DIRECTOR_GLOBAL_CAP = 200`.
- Tanks gated: no tank spawns unless swarmers alive ≥ 0.5 × swarmer setpoint
  (`SPAWN_DIRECTOR_TANK_SWARM_GATE`).

### 4.2 Setpoint power (the pacing denominator)
```
setpoint_power = Σ_slots  max(1, setpoint*ramp) * slot_power
slot_power = round_power[type]; for 'special' = average round_power of its pool
```

### 4.3 Spawn cadence (`spawnmanager.lua tick_spawn_director`)
```
fill = (alive_power + in_flight_power) / setpoint_power    (clamped to 1)
cooldown = lerp(INTERVAL_MIN, INTERVAL_MAX, fill ^ RATE_EXP)
```
`INTERVAL_MIN = 0.2`, `INTERVAL_MAX = 6`, `RATE_EXP = 2`, ±25% jitter.
Empty field → spawns every ~0.2s; at setpoint → every 6s. Each spawn is the
most-deficient slot (weighted by fractional deficit below setpoint). Swarmers
roll a group size (4–6 scattered, or 8–12 clustered wave); other slots spawn 1.

### 4.4 Sustain DPS requirement (steady state)
At steady state the director replaces what you kill, holding ~setpoint_power on
the field. To *not* fall behind (fill rising toward the global cap):
```
required_kill_power_rate ≈ setpoint_power / mean_cooldown_at_target
required_sustain_DPS ≈ required_kill_power_rate * avg_hp_per_power
```
In practice the clear-time requirement (§3.3) dominates because the level ends on
kill_quota; the sustain number tells you whether a *weak* build gets buried before
reaching the quota (fill pins at cap) vs. a *strong* build outpaces it (fill
oscillates low, cooldown stays short, level clears fast).

---

## 5. How to compute a level's DPS requirement (recipe)

1. **Composition:** from §4.1 setpoints, estimate the kill mix (swarmer-heavy
   early; add specials/tanks/small_archer per level).
2. **avg_hp_per_power:** weight each type's `hp_per_power(type, L)` (§3.3) by its
   share of killed round_power.
3. **Clear requirement:** `kill_quota(L) * avg_hp_per_power / T_target`.
   Pick `T_target` (e.g. 45–75 s intended per level).
4. **Sustain check:** `setpoint_power(L)` / `INTERVAL_MAX` × avg_hp_per_power
   gives the minimum kill-DPS to keep fill from climbing; below it the field
   drifts toward the 200-enemy cap.
5. **Compare to player DPS** (§1.5) with expected items at that level (item
   count = `UNIT_LEVEL_TO_NUMBER_OF_ITEMS` = 6 slots; gold income per level from
   `GOLD_PER_ROUND + GOLD_GAINED_BY_LEVEL`).

---

## 6. Constant appendix (quick reference)
- `TROOP_HP 100`, `TROOP_DAMAGE 11`, `TROOP_MS 60`, `BASE_CRIT_MULT 2`.
- Enemy class bases: regular 45/15/18, special 280/20/20, miniboss 400/20/50, boss 1400/20/70.
- `POST_BOSS_HP_MULT` 1 / 1.4 (L7+) / 1.7 (L12+).
- `WAVE_KILL_QUOTA_MULTIPLIER 1.5` (legacy waves), director quota via §3.2.
- Director: `INTERVAL_MIN 0.2`, `INTERVAL_MAX 6`, `RATE_EXP 2`, `CEILING_MULT 1.75`,
  `GLOBAL_UNIT_CAP 200`, ramp 0.8→1.2, tank gate 0.5.
- Item slots per unit: 6. Max units: `MAX_UNITS` (currently 1).

*Regenerate this doc if the cited constants change — it's a snapshot, not live.*

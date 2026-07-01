#!/usr/bin/env lua
-- ==========================================================================
-- dps_model.lua — UNDERLOD per-level DPS-requirement calculator
--
-- Pure Lua 5.1+ / LuaJIT, zero dependencies.  Run from repo root or from
-- documentation/:  lua documentation/dps_model.lua
--
-- Reads the REAL game constants by loading game_constants.lua,
-- combat_stats/combat_stats.lua and spawns/levelmanager.lua into a sandbox
-- (plus a text-extract of enemy_to_round_power from main.lua), so numbers
-- cannot drift from the game. The few values that live inline in unit/spell
-- files (sword arc, shotgun pellets, laser charge/beam) are mirrored here
-- with SYNC tags pointing at their source line.
--
-- Implements the three-regime model:
--   Regime 1  "ceiling-camp threshold": min sustained kill-DPS below which
--             the field sits at slot ceilings (CEILING_MULT x setpoint).
--             NOT a death spiral — director weights go to 0 at the ceiling,
--             so spawning self-limits — but you fight at max density all level.
--   Regime 2  DPS-bound clear: clear_time = quota_HP / effective_DPS.
--   Regime 3  spawn-bound floor: fastest possible clear given director
--             throughput + warning + travel; strong builds plateau here.
--
-- Effective player DPS chain:
--   eff = hit * crit_f * E[dmg-weighted targets] * (1 - overkill_waste)
--         / period * uptime * troop_count
--
-- TERMINOLOGY (verified against the code, see NOTES at bottom):
--   waste    = OVERKILL damage: the killing hit's excess over remaining HP.
--              Damage applies to exactly one unit per hit with no carryover
--              (Helper.Damage:primary_hit), so this loss is real. It is NOT
--              missed hits and NOT time.
--   uptime   = fraction of the level the troop is actually attacking. Split
--              into a DERIVED part (spawn warning + enemy travel to the
--              weapon's engage range — troops hold position, enemies walk to
--              them; Troop:move_towards_target is unused) and a MEASURED
--              placeholder part (retarget gaps, kiting, clump gaps).
-- ==========================================================================

-- ----------------------------------------------------------------------
-- LOAD REAL GAME CONSTANTS
-- ----------------------------------------------------------------------
local script_dir = (arg and arg[0] or ''):match('^(.*[/\\])') or ''
local ROOT = script_dir .. '../'

local function make_env()
  local env = {}
  env._G = env
  -- game_constants.lua calls system.load_stats() at load time
  env.system = { load_stats = function() end }
  -- levelmanager's Build_Level_List touches engine color tables and the
  -- engine's table extensions; stub just enough.
  local any_color = setmetatable({}, { __index = function() return true end })
  env.grey, env.black, env.orange = any_color, any_color, any_color
  env.table = setmetatable({
    shuffle = function(t) return t end,
    copy = function(t)
      local r = {}
      for k, v in pairs(t) do r[k] = v end
      return r
    end,
  }, { __index = table })
  return setmetatable(env, { __index = _G })
end

local function run_file(path, env)
  local fn, err
  if setfenv then                      -- Lua 5.1 / LuaJIT
    fn, err = loadfile(path)
    assert(fn, err)
    setfenv(fn, env)
  else                                 -- Lua 5.2+
    local f = assert(io.open(path, 'rb'), 'cannot open ' .. path)
    local src = f:read('*a'); f:close()
    fn, err = load(src, '@' .. path, 't', env)
    assert(fn, err)
  end
  fn()
end

-- enemy_to_round_power lives inside main.lua (which needs the full engine),
-- so brace-match the table literal out of the source text and evaluate it.
local function extract_enemy_round_power(env)
  local path = ROOT .. 'main.lua'
  local f = assert(io.open(path, 'rb'), 'cannot open ' .. path)
  local src = f:read('*a'); f:close()
  local s = src:find('enemy_to_round_power%s*=%s*{')
  assert(s, 'enemy_to_round_power not found in main.lua')
  local open = src:find('{', s)
  local depth, i = 0, open
  while i <= #src do
    local c = src:sub(i, i)
    if c == '{' then depth = depth + 1
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 then break end
    end
    i = i + 1
  end
  assert(depth == 0, 'unbalanced braces extracting enemy_to_round_power')
  local chunk = 'return ' .. src:sub(open, i)
  local fn
  if setfenv then
    fn = assert(loadstring(chunk, 'enemy_to_round_power'))
    setfenv(fn, env)
  else
    fn = assert(load(chunk, 'enemy_to_round_power', 't', env))
  end
  return fn()
end

local G = make_env()
run_file(ROOT .. 'game_constants.lua', G)
run_file(ROOT .. 'combat_stats/combat_stats.lua', G)
G.enemy_to_round_power = extract_enemy_round_power(G)
run_file(ROOT .. 'spawns/levelmanager.lua', G)

local LEVEL_LIST = G.Build_Level_List(G.NUMBER_OF_ROUNDS or 11)

-- ----------------------------------------------------------------------
-- CONFIG pulled from the game
-- ----------------------------------------------------------------------
local GW, GH            = 480, 270    -- engine viewport (engine/init: gw, gh)
local ARENA_AREA        = GW * GH
local OFFSCREEN_OFFSET  = 15          -- SpawnGlobals offscreen spawn offset
local WARNING_TIME      = G.WAVE_SPAWN_WARNING_TIME

local INTERVAL_MIN      = G.SPAWN_DIRECTOR_INTERVAL_MIN
local INTERVAL_MAX      = G.SPAWN_DIRECTOR_INTERVAL_MAX
local RATE_EXP          = G.SPAWN_DIRECTOR_RATE_EXP
local CEILING_MULT      = G.SPAWN_DIRECTOR_CEILING_MULT
local SWARMER_GROUP_MIX = G.SWARMER_GROUP_MIX

local POWER   = G.enemy_to_round_power
local ESTATS  = G.enemy_type_to_stats

-- Non-boss campaign levels that have director configs.
local LEVEL_ORDER = {}
for L = 1, (G.NUMBER_OF_ROUNDS or 11) do
  if not G.Is_Boss_Level(L) and G.LEVEL_SPAWN_POOLS[L] then
    LEVEL_ORDER[#LEVEL_ORDER + 1] = L
  end
end

-- Target clear time: design intent, not a game constant. 45s at L1 -> 75s L10.
local function t_target(L) return 45 + (L - 1) * (75 - 45) / 9 end

-- ----------------------------------------------------------------------
-- CONFIG: weapons, derived from combat_stats + unit/spell files
-- ----------------------------------------------------------------------
-- The four real selectable characters (ui/character_select_overlay.lua:14).
-- 'swordsman' exists in code but is legacy and not in the pool.
--
-- engagement: MEASURED placeholder — residual uptime once enemies are on the
--   field (retarget gaps, kiting, clump gaps). Replace with a debug counter
--   of time_with_valid_target / (level_time - initial_lag).
-- engage_range: enemies must close to this before the weapon works; feeds the
--   derived travel-lag part of uptime. nil = can hit anything on the field
--   (laser: infinite_range = true, range 400 covers the arena).
local TD = G.TROOP_DAMAGE
local SM = G.unit_stat_multipliers
local CD = G.troop_attack_cooldowns
local CT = G.troop_cast_times

local WEAPONS = {
  archer = {
    dmg = TD * SM.archer.dmg, cd = CD.archer, cast = CT.archer,
    splash = 'none',
    engage_range = G.TROOP_ARCHER_RANGE,
    engagement = 0.95,
  },
  sword = {
    dmg = TD * SM.sword.dmg, cd = CD.sword, cast = CT.sword,
    splash = 'cone',
    -- SYNC: swing_half_angle = pi/3 (sword_weapon_troop.lua:12) -> 120° arc,
    -- radius = TROOP_SWORD_WEAPON_RANGE. Full damage to every enemy in arc
    -- (sword_swing_spell.lua:apply_damage).
    splash_area = (math.pi / 3) * G.TROOP_SWORD_WEAPON_RANGE ^ 2,
    engage_range = G.TROOP_SWORD_WEAPON_RANGE,
    engagement = 0.80,
  },
  shotgun = {
    dmg = TD * SM.shotgun.dmg, cd = CD.shotgun, cast = CT.shotgun,
    splash = 'pellets',
    -- SYNC: SHOTGUN_PELLET_COUNT = 5, SHOTGUN_HALF_SPREAD = pi/16, pellets
    -- die at range * 1.3 (shotgun_troop.lua:7-9,34). All pellets scatter
    -- randomly in the cone — none are aimed — so pellets_primary is the
    -- expected number crossing the target's body at typical engage distance
    -- (~0.57 of the cone at 40px for a ~4.5px body; near 1.0 point-blank).
    pellets = 5, pellets_primary = 3.5,
    stray_area = (math.pi / 16) * (G.TROOP_SHOTGUN_RANGE * 1.3) ^ 2, -- cone sector
    engage_range = G.TROOP_SHOTGUN_RANGE,
    engagement = 0.88,
  },
  laser = {
    dmg = TD * SM.laser.dmg, cd = CD.laser, cast = CT.laser,
    -- SYNC: charge_duration = 0.5 inside Laser_Spell spelldata
    -- (laser_troop.lua:69); happens in 'channeling', cooldown starts after,
    -- and it is NOT scaled by attack speed.
    charge = 0.5,
    splash = 'line',
    -- SYNC: beam = 500-length line through the target, width 8
    -- (laser_troop.lua laser_width, laser_spell.lua length default). Arena
    -- clips it; ~GW/2 of it crosses populated field on average.
    splash_area = (GW / 2) * 8,
    -- SYNC: reduce_pierce_damage_amount = 0.2 (laser_spell.lua:84): each
    -- pierced enemy past the first takes 0.8x the previous one's damage.
    pierce_falloff = 0.8,
    engage_range = nil,
    engagement = 0.97,
  },
}
local WEAPON_ORDER = { 'archer', 'sword', 'shotgun', 'laser' }

-- ----------------------------------------------------------------------
-- CONFIG: model knobs (not game constants)
-- ----------------------------------------------------------------------
-- Swarmers arrive in clumps, so density at the point of engagement is much
-- higher than the arena average. Multiplies avg density for splash targeting.
local CLUSTERING = 3.0

-- Overkill on the primary target of an AoE partially carries into the splash,
-- so AoE weapons only eat this fraction of the computed waste.
local SPLASH_WASTE_DISCOUNT = 0.5

-- Expected item power by level. PLACEHOLDERS — replace with the gold-economy
-- curve (GOLD_GAINED_BY_LEVEL + interest -> items bought -> avg stat density
-- per rarity via TIER_TO_ITEM_RARITY_WEIGHTS).
local ITEMS = {
  dmg_m       = function(L) return 1.0 + 0.08 * math.max(L - 1, 0) end,
  aspd_m      = function(L) return math.max(0.60, 1.0 - 0.03 * math.max(L - 1, 0)) end,
  crit_chance = function(L) return 0.0 end,
  crit_mult   = G.BASE_CRIT_MULT,
}
local SHOW_NAKED = true   -- also print item-free DPS for reference

-- Troops on the field: MAX_UNITS squads x troops per unit level. Troop count
-- is flat 3 at every unit level right now, so only expected_unit_level's
-- existence matters, not its curve.
local function expected_unit_level(L) return math.min(5, 1 + math.floor(L / 3)) end
local function TROOP_COUNT(L)
  return (G.MAX_UNITS or 1) * (G.UNIT_LEVEL_TO_NUMBER_OF_TROOPS[expected_unit_level(L)] or 3)
end

-- ==========================================================================
-- MODEL
-- ==========================================================================

local function avg_group_size(mix)
  local w, s = 0, 0
  for _, e in ipairs(mix) do
    w = w + e.weight
    s = s + e.weight * (e.min + e.max) / 2
  end
  return s / w
end
local SWARMER_GROUP_AVG = avg_group_size(SWARMER_GROUP_MIX)

-- hp / power / base-class for a slot's representative enemy at level L.
-- 'special' averages the level's draw pool using real per-type stats.
local function slot_stats(L, slot, pool_list)
  if slot == 'special' then
    assert(pool_list and #pool_list > 0, 'special slot with no special_pool')
    local hp_sum, pw_sum = 0, 0
    for _, t in ipairs(pool_list) do
      local mult = (ESTATS[t] and ESTATS[t].hp) or 1
      hp_sum = hp_sum + G.SCALED_ENEMY_HP(L, G.SPECIAL_ENEMY_HP) * mult
      pw_sum = pw_sum + (POWER[t] or 200)
    end
    return hp_sum / #pool_list, pw_sum / #pool_list
  end
  local base = (slot == 'swarmer') and G.REGULAR_ENEMY_HP or G.SPECIAL_ENEMY_HP
  local mult = (ESTATS[slot] and ESTATS[slot].hp) or 1
  return G.SCALED_ENEMY_HP(L, base) * mult, POWER[slot]
end

local function swarmer_speed(L)
  return G.SCALED_ENEMY_MS(L, G.REGULAR_ENEMY_MS) * (ESTATS.swarmer.mvspd or 1)
end

-- Mean spawn-edge -> engage-range travel time for swarmers (max_v = mvspd,
-- objects.lua:1026, so this is real px/s modulo steering losses).
local function travel_to_range(L, range)
  local mean_half = (GW / 2 + GH / 2) / 2
  return (mean_half + OFFSCREEN_OFFSET - (range or 0)) / swarmer_speed(L)
end

-- Power spawned per director fire for a slot (swarmers fire as a group).
local function slot_group_power(slot, power)
  if slot == 'swarmer' then return power * SWARMER_GROUP_AVG end
  return power
end

-- Per-hit overkill waste fraction for a single enemy HP value.
local function overkill_waste(hp, hit)
  if hit <= 0 then return 0 end
  local hits = math.ceil(hp / hit)
  local spent = hits * hit
  return (spent - hp) / spent
end

-- Build everything the level demands.
local function analyze_level(L)
  local director = G.LEVEL_SPAWN_POOLS[L].spawn_director
  local quota = LEVEL_LIST[L].kill_quota
  local out = { L = L, quota = quota, setpoints = director.setpoints }

  -- --- composition: killed-power shares ~= setpoint power shares -----------
  -- (steady-state assumption: the director replaces what dies, so over a
  --  level the killed mix converges to the maintained mix)
  local slots, total_sp = {}, 0
  for slot, sp in pairs(director.setpoints) do
    local hp, power = slot_stats(L, slot, director.special_pool)
    slots[slot] = { setpoint = sp, hp = hp, power = power, sp_power = sp * power }
    total_sp = total_sp + slots[slot].sp_power
  end
  out.setpoint_power = total_sp

  local avg_hpp = 0        -- avg HP per round_power, weighted by power share
  local inv_gp_sum = 0     -- for avg power per director fire (harmonic)
  for slot, s in pairs(slots) do
    s.share = s.sp_power / total_sp
    s.hp_per_power = s.hp / s.power
    avg_hpp = avg_hpp + s.share * s.hp_per_power
    inv_gp_sum = inv_gp_sum + s.share / slot_group_power(slot, s.power)
  end
  out.slots = slots
  out.avg_hp_per_power = avg_hpp
  out.quota_hp = quota * avg_hpp

  -- --- director throughput ------------------------------------------------
  local avg_power_per_fire = 1 / inv_gp_sum
  out.avg_power_per_fire = avg_power_per_fire

  -- Regime 1: kill-DPS needed to hold the field near setpoint. Below this the
  -- field drifts to slot ceilings (spawning then stops per-slot), i.e. you
  -- fight at CEILING_MULT x density for the whole level.
  out.ceiling_camp_dps = (avg_power_per_fire / INTERVAL_MAX) * avg_hpp

  -- Regime 3: spawn-bound clear floor. Strong-build equilibrium modeled at
  -- fill ~= 0.5 (killing fast keeps fill low; cooldown from the fill curve).
  local cd_half = INTERVAL_MIN + (INTERVAL_MAX - INTERVAL_MIN) * (0.5 ^ RATE_EXP)
  local max_power_rate = avg_power_per_fire / cd_half

  out.swarmer_travel = travel_to_range(L, G.TROOP_ARCHER_RANGE)
  out.min_clear_time = quota / max_power_rate + WARNING_TIME + out.swarmer_travel

  -- Regime 2: required on-target DPS for the target clear time.
  out.t_target = t_target(L)
  out.required_dps = out.quota_hp / out.t_target

  return out
end

-- Uptime: derived initial lag (spawn warning + enemy walk to engage range,
-- amortized over the level) x measured residual engagement.
local function weapon_uptime(L, w, lvl)
  local lag = WARNING_TIME
  if w.engage_range then lag = lag + travel_to_range(L, w.engage_range) end
  return math.max(0, 1 - lag / lvl.t_target) * w.engagement
end

-- Effective field DPS for one weapon at one level.
local function weapon_dps(L, wname, lvl, use_items)
  local w = WEAPONS[wname]
  local dmg_m  = use_items and ITEMS.dmg_m(L)  or 1.0
  local aspd_m = use_items and ITEMS.aspd_m(L) or 1.0
  local cc     = use_items and ITEMS.crit_chance(L) or 0.0
  local cm     = ITEMS.crit_mult

  local hit = w.dmg * dmg_m
  -- aspd scales BOTH cooldown and cast time (objects.lua:1007-1010); the
  -- laser's in-spell charge is not aspd-scaled.
  local period = (w.cd + w.cast) * aspd_m + (w.charge or 0)
  local crit_f = 1 + cc * (cm - 1)

  -- E[targets]: local swarm density at point of engagement
  local alive_sw = lvl.setpoints.swarmer or 0    -- ramp avg ~1.0
  local density  = CLUSTERING * alive_sw / ARENA_AREA
  local dmg_weighted_targets = 1
  local pellets_landing = nil
  if w.splash == 'cone' then
    -- full damage to every enemy in the arc
    dmg_weighted_targets = 1 + density * w.splash_area
  elseif w.splash == 'line' then
    -- pierced enemies take falloff^k of the hit (k = pierce order)
    local extra = density * w.splash_area
    local f = w.pierce_falloff
    -- continuous geometric sum over 1 primary + `extra` pierced targets
    dmg_weighted_targets = (1 - f ^ (1 + extra)) / (1 - f)
  elseif w.splash == 'pellets' then
    local stray = math.min(1, density * w.stray_area)
    pellets_landing = w.pellets_primary + (w.pellets - w.pellets_primary) * stray
    dmg_weighted_targets = pellets_landing
  end

  -- Overkill waste, weighted by killed-power share per slot.
  local waste = 0
  for _, s in pairs(lvl.slots) do
    waste = waste + s.share * overkill_waste(s.hp, hit)
  end
  if w.splash ~= 'none' then waste = waste * SPLASH_WASTE_DISCOUNT end

  local per_shot = hit * dmg_weighted_targets
  local on_target = per_shot * crit_f * (1 - waste) / period
  local uptime = weapon_uptime(L, w, lvl)
  return on_target * uptime * TROOP_COUNT(L), dmg_weighted_targets, waste, uptime
end

-- ==========================================================================
-- REPORT
-- ==========================================================================
local function feel(ratio)
  if ratio < 1.0 then return 'CEILING-CAMPED'
  elseif ratio < 1.5 then return 'white-knuckle'
  elseif ratio < 2.5 then return 'comfortable'
  else return 'stomping' end
end

local function line(ch) print(string.rep(ch, 104)) end

print('UNDERLOD DPS-requirement model (constants loaded from game files)')
print(string.format(
  'arena %dx%d | director %.1f-%.1fs (exp %.1f) | swarmer group avg %.1f | clustering x%.1f | troops %d',
  GW, GH, INTERVAL_MIN, INTERVAL_MAX, RATE_EXP, SWARMER_GROUP_AVG, CLUSTERING, TROOP_COUNT(1)))
line('=')

for _, L in ipairs(LEVEL_ORDER) do
  local lvl = analyze_level(L)
  print(string.format(
    'L%-2d  quota %d pw (= %.0f HP, avg %.2f HP/pw) | target %.0fs -> need %.1f DPS on-field',
    L, lvl.quota, lvl.quota_hp, lvl.avg_hp_per_power, lvl.t_target, lvl.required_dps))
  print(string.format(
    '     ceiling-camp threshold %.1f DPS | spawn-bound clear floor %.0fs | swarmer travel %.1fs',
    lvl.ceiling_camp_dps, lvl.min_clear_time, lvl.swarmer_travel))

  print(string.format('     %-8s %10s %10s %8s %8s %8s %7s  %s',
    'weapon', 'DPS(items)', 'DPS(base)', 'E[tgt]', 'waste%', 'uptime%', 'clear', 'feel'))
  for _, wname in ipairs(WEAPON_ORDER) do
    local dps_i, tgt, waste, up = weapon_dps(L, wname, lvl, true)
    local dps_0 = SHOW_NAKED and weapon_dps(L, wname, lvl, false) or dps_i
    local clear = math.max(lvl.quota_hp / dps_i, lvl.min_clear_time)
    local ratio = dps_i / lvl.ceiling_camp_dps
    print(string.format('     %-8s %10.1f %10.1f %8.2f %7.1f%% %7.1f%% %6.0fs  %s (%.1fx)',
      wname, dps_i, dps_0, tgt, waste * 100, up * 100, clear, feel(ratio), ratio))
  end
  line('-')
end

print([[
NOTES / SEMANTICS (verified against code)
 * waste = overkill: a hit lands on exactly one enemy (or one enemy per AoE
   member) and the killing hit's excess is lost — no carryover. It is not
   missed hits and not downtime.
 * True misses barely exist: arrows home while the target lives; if it dies
   mid-flight the arrow flies straight and still hits the first enemy it
   touches (instants.lua:160,175). Only shotgun pellets genuinely miss —
   every pellet scatters randomly in a ±11.25° cone — and that is modeled
   via pellets_landing, not waste.
 * Un-modeled loss channel: several troops firing at one dying target
   (targeting is get_random_close_object; no least-targeted claim). Small in
   dense fields because of arrow redirect; measure if squads > 3.
 * uptime = time-not-attacking. Troops never chase (move_towards_target is
   unused) — enemies walk to them — so idle time is spawn warning + swarmer
   travel to the weapon's engage range (derived, per weapon: laser skips it,
   melee waits longest) x `engagement`, a residual PLACEHOLDER for retarget
   gaps / kiting / inter-clump gaps. Measure engagement with a debug counter:
   time_with_valid_target / (level_time - initial_lag).
 * Composition assumption: killed-power mix == setpoint power shares (steady
   state). If telemetry disagrees, override lvl.slots[*].share.
 * ITEMS.* are placeholder curves; wire in the gold economy for real ones.
 * Ceiling-camp threshold is a comfort line, not survival: director weights
   zero out at ceilings, so under-DPS means fighting at CEILING_MULT x
   density, not an unbounded flood.
 * Spawn-bound floor assumes strong builds hold fill ~0.5; an estimate of
   the plateau, not an exact bound.
 * SYNC-tagged values (sword arc, shotgun pellets/spread, laser charge/beam/
   falloff) live inline in unit/spell files and are mirrored by hand.]])

-- Run from the repository root: luajit documentation/level_pressure.lua
-- Enemy hp inflow per level vs. the dps a generic build has by then.
-- Loads the real constants so the numbers can't drift from the game.
local function noop() end
Object = {}
function Object:extend() local c = {implement = noop}; c.__index = c; return c end
GameObject = {}
system = {load_stats = noop}
Helper = {Time = {time = 0}}
math.clamp = function(v, lo, hi) return math.max(lo, math.min(v, hi)) end
random = {}
function random:float(lo, hi) return lo + (hi - lo) * math.random() end
function random:int(lo, hi) return math.random(lo, hi) end
function random:table(t) return t[self:int(1, #t)] end
dofile('game_constants.lua')
dofile('combat_stats/combat_stats.lua')
dofile('spawns/levelmanager.lua')

-- ---------------------------------------------------------------- enemies
local function class_of(t)
  return (t == 'swarmer' or t == 'hunter_swarmer') and 'regular_enemy' or 'special_enemy'
end
local function enemy_hp(t, level)
  local st = enemy_type_to_stats[t] or {}
  local base = class_of(t) == 'regular_enemy' and REGULAR_ENEMY_HP or SPECIAL_ENEMY_HP
  return SCALED_ENEMY_HP(level, base, st.hp_scale or 1) * (st.hp or 1)
end
local function roster(level)
  local cfg = LEVEL_SPAWN_POOLS[level] and LEVEL_SPAWN_POOLS[level].spawn_director
  if not cfg then return nil end
  local r = {length = cfg.length or SPAWN_DIRECTOR_DEFAULT_LENGTH, cap = cfg.swarmer and cfg.swarmer.cap or 0, types = {}}
  if cfg.swarmer then r.types.swarmer = cfg.swarmer.total end
  for t, v in pairs(cfg.timeline or {}) do r.types[t] = type(v) == 'table' and v.total or v end
  -- one_of: count each option at its expected share.
  for _, frag in ipairs(cfg.one_of or {}) do
    for t, v in pairs(frag) do
      local n = type(v) == 'table' and v.total or v
      r.types[t] = (r.types[t] or 0) + n / #cfg.one_of
    end
  end
  return r
end

-- ---------------------------------------------------------------- player
-- One unit = UNIT_LEVEL_TO_NUMBER_OF_TROOPS[1] troops sharing its items.
-- Period = cooldown + cast + backswing (archer_troop.lua: backswing 0.1).
local TROOPS = UNIT_LEVEL_TO_NUMBER_OF_TROOPS[1]
local function unit_dps(char, power_pieces)
  local m = unit_stat_multipliers[char]
  local dmg = TROOP_DAMAGE * m.dmg * (1 + 0.2 * power_pieces)   -- Power: +20% per piece
  local period = troop_attack_cooldowns[char] + troop_cast_times[char] + 0.1
  local hits = char == 'shotgun' and 5 or 1   -- SYNC: SHOTGUN_PELLET_COUNT in shotgun_troop.lua; all pellets on target
  return TROOPS * dmg * hits / period
end

-- Generic path: start with one archer, +3 gold a round (+10% interest, max
-- 3), items cost 2. 'items' buys Power onto the newest unit up to 3 pieces
-- before saving for the next unit (6 gold); 'units' buys units first.
local function simulate(path, char)
  local gold = STARTING_GOLD - 6
  local units = {{power = 0}}
  local out = {}
  for level = 1, NUMBER_OF_ROUNDS do
    if level > 1 then
      gold = gold + math.min(math.floor(gold * INTEREST_AMOUNT), MAX_INTEREST)
      gold = gold + (Is_Boss_Level(level - 1) and GOLD_FOR_BOSS_ROUND[1] or GOLD_PER_ROUND(level - 1))
      local spent = true
      while spent do
        spent = false
        local u = units[#units]
        local want_unit = #units < 3 and (path == 'units' or u.power >= 3)
        if want_unit and gold >= 6 then
          table.insert(units, {power = 0}); gold = gold - 6; spent = true
        elseif not want_unit and u.power < 3 and gold >= 2 then
          u.power = u.power + 1; gold = gold - 2; spent = true
        elseif want_unit and gold < 6 and u.power < 3 and path == 'items' then
          -- nothing affordable
        end
      end
    end
    local dps = 0
    for _, u in ipairs(units) do dps = dps + unit_dps(char, u.power) end
    local desc = {}
    for _, u in ipairs(units) do table.insert(desc, u.power .. 'p') end
    out[level] = {dps = dps, units = #units, desc = table.concat(desc, '/'), gold = gold}
  end
  return out
end

-- ---------------------------------------------------------------- report
local function fmt(n, d) return string.format('%.' .. (d or 0) .. 'f', n) end
print('Base dps per unit (' .. TROOPS .. ' troops, no items): archer ' .. fmt(unit_dps('archer', 0), 1)
  .. ', shotgun (all pellets hit) ' .. fmt(unit_dps('shotgun', 0), 1) .. ', laser (one target) ' .. fmt(unit_dps('laser', 0), 1))
print('Enemy hp: swarmer L1 ' .. fmt(enemy_hp('swarmer', 1), 1) .. ', L4 ' .. fmt(enemy_hp('swarmer', 4), 1) .. ', L7 ' .. fmt(enemy_hp('swarmer', 7), 1)
  .. '; tank/archer L1 ' .. fmt(enemy_hp('tank', 1)) .. ', L4 ' .. fmt(enemy_hp('tank', 4)) .. '; dart L4 ' .. fmt(enemy_hp('dart', 4)))
print()

local items = simulate('items', 'archer')
local unitsfirst = simulate('units', 'archer')
print(string.format('%-3s %-5s %-6s %-6s %-6s %-6s %-5s | %-10s %-6s %-5s | %-10s %-6s %-5s',
  'L', 'len', 'swarmH', 'specH', 'totalH', 'hp/s', 'peakS', 'items-path', 'dps', 'x', 'units-path', 'dps', 'x'))
for level = 1, NUMBER_OF_ROUNDS do
  local r = roster(level)
  if r then
    local swarm_hp, spec_hp, spec_list = 0, 0, {}
    for t, n in pairs(r.types) do
      local hp = enemy_hp(t, level) * n
      if class_of(t) == 'regular_enemy' then swarm_hp = swarm_hp + hp else spec_hp = spec_hp + hp; table.insert(spec_list, (n == math.floor(n) and n or string.format('%.1f', n)) .. ' ' .. t) end
    end
    table.sort(spec_list)
    local total = swarm_hp + spec_hp
    local rate = total / r.length
    local peak = r.cap * enemy_hp('swarmer', level)
    local a, b = items[level], unitsfirst[level]
    print(string.format('%-3d %-5d %-6d %-6d %-6d %-6.1f %-5d | %-10s %-6.0f %-5.1f | %-10s %-6.0f %-5.1f   %s',
      level, r.length, swarm_hp, spec_hp, total, rate, peak, a.desc, a.dps, a.dps / rate, b.desc, b.dps, b.dps / rate, table.concat(spec_list, ', ')))
  elseif Is_Boss_Level(level) then
    print(string.format('%-3d boss (%s)', level, Is_Boss_Level(level)))
  end
end
print()
print('hp/s = total roster hp spread over the spawn length. x = dps / hp/s: how many')
print('times faster the team deletes hp than it arrives (uptime and misses ignored).')
print('peakS = hp of a full swarmer cap on screen at once.')

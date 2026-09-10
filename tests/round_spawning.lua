-- Run from the repository root: lua tests/round_spawning.lua
-- Exercise the real spawn manager with a deterministic timer and enemy factory.
local function noop() end
Object = {}
function Object:extend()
  local class = {implement = noop}
  class.__index = class
  return class
end
GameObject = {}
system = {load_stats = noop}
Helper = {Time = {time = 0}}
math.clamp = function(v, lo, hi) return math.max(lo, math.min(v, hi)) end
random = {}
function random:float(lo, hi) return lo + (hi - lo) * math.random() end
function random:int(lo, hi) return math.random(lo, hi) end
function random:table(t) return t[self:int(1, #t)] end
math.randomseed(314159)
dofile('game_constants.lua')
dofile('spawns/levelmanager.lua')
dofile('spawns/spawnmanager.lua')
-- Read the shipped power table without loading the game or its assets.
local f = assert(io.open('main.lua')); local source = f:read('*a'); f:close()
local power_table = assert(source:match('enemy_to_round_power = (%b{})'))
assert(loadstring('enemy_to_round_power = ' .. power_table))()
Get_Offscreen_Spawn_Point = function() return {x = -20, y = 100} end
Get_Random_Offscreen_Point = Get_Offscreen_Spawn_Point
local spawned_types
Spawn_Enemy = function(arena, enemy_type, location)
  local e = {type = enemy_type, x = location.x, y = location.y,
    class = enemy_type == 'swarmer' and 'regular_enemy' or 'special_enemy'}
  table.insert(arena.enemies, e)
  spawned_types[enemy_type] = (spawned_types[enemy_type] or 0) + 1
end
local function timer()
  local t = {now = 0, events = {}}
  function t:after(delay, fn) table.insert(self.events, {at = self.now + delay, fn = fn}) end
  function t:update(dt)
    self.now = self.now + dt
    local due = {}
    for i = #self.events, 1, -1 do
      if self.events[i].at <= self.now then table.insert(due, table.remove(self.events, i)) end
    end
    for _, event in ipairs(due) do event.fn() end
  end
  return t
end
local function arena_for(budget, config, debug_queue)
  -- Director levels derive their budget from the roster, like Build_Level_List.
  if budget == nil and config and config.spawn_director then
    budget = Director_Spawn_Quota(config)
  end
  local arena = {level = 1, t = timer(), enemies = {}, wins = 0, level_list = {
    [1] = {kill_quota = budget, spawn_config = config or {}, debug_spawn_queue = debug_queue}}}
  arena.main = {get_objects_by_classes = function() return arena.enemies end}
  arena.level_clear = function(self) self.wins = self.wins + 1 end
  main = {current = {enemies = {}, current_arena = arena, main = arena.main}}
  spawned_types = {}
  arena.spawn_manager = setmetatable({}, SpawnManager)
  arena.spawn_manager:init(arena)
  arena.spawn_manager:change_state('spawning')
  return arena, arena.spawn_manager
end
local function kill(arena, index)
  local e = table.remove(arena.enemies, index or #arena.enemies)
  arena.spawn_manager:on_enemy_removed(e)
end
local function queue(arena, enemy_type, count)
  arena.spawn_manager.wave_spawn_delay = 0
  return Spawn_Group_With_Location(arena, {enemy_type, count}, {x = 0, y = 0})
end
local function eq(a, b) assert(a == b, tostring(a) .. ' ~= ' .. tostring(b)) end

-- Booking pending spawns spends the budget; kills neither spend nor refill it.
local a, sm = arena_for(1020)
eq(queue(a, 'swarmer', 100), 41)
eq(sm.wave_spawn_power, 1025); eq(sm.pending_spawns, 41)
eq(queue(a, 'tank', 10), 0)
sm:update(.01); eq(a.wins, 0)
a.t:update(10); eq(sm.pending_spawns, 0)
sm:update(.01); eq(sm.state, 'waiting_for_clear'); eq(a.wins, 0)
sm.wave_kill_power = 100000
sm:update(.01); eq(a.wins, 0); eq(#a.enemies, 41)
while #a.enemies > 0 do kill(a) end
sm:update(.01); eq(a.wins, 1)
sm:update(.01); eq(a.wins, 1)

-- An empty field between groups is not a win if budget remains.
a, sm = arena_for(100)
queue(a, 'swarmer', 1); a.t:update(2); kill(a)
sm:update(.01); eq(a.wins, 0); eq(sm.state, 'spawning')
eq(queue(a, 'swarmer', 5), 3)

-- Reserve late scripted events even if ordinary enemies consume their share.
a, sm = arena_for(1020, {specials = {{type = 'pulsar', at = .95}}})
eq(sm.reserved_event_power, 400)
eq(queue(a, 'swarmer', 100), 25)
eq(sm.wave_spawn_power, 625); assert(not sm:quota_met())
sm:tick_special_events({specials = 0, by_type = {}})
eq(sm.wave_spawn_power, 1025); eq(sm.reserved_event_power, 0)
assert(sm:quota_met()); assert(sm.special_events[1].fired)
sm:tick_special_events({specials = 0, by_type = {}}); eq(sm.wave_spawn_power, 1025)
a.t:update(10); eq(spawned_types.pulsar, 1)

-- All-event encounters also finish, even if the authored events exceed budget.
a, sm = arena_for(100, {specials = {{type = 'linker', at = .9, group_size = 2}}})
eq(queue(a, 'swarmer', 3), 0)
sm:tick_special_events({specials = 0, by_type = {}})
eq(sm.wave_spawn_power, 400); eq(sm.pending_spawns, 2); assert(sm:quota_met())

-- Scatter pending counts reflect only enemies actually admitted by the budget.
a, sm = arena_for(75, {spawn_director = {swarmer = {cap = 10, total = 10}}})
sm:director_spawn('swarmer', 10, true)
eq(sm.wave_spawn_power, 75); eq(sm.pending_spawns, 3); eq(sm.spawn_director.pending.swarmer, 3)
a.t:update(10); eq(sm.pending_spawns, 0); eq(sm.spawn_director.pending.swarmer, 0)

-- Dead runs never clear, even with the budget spent and no enemies left.
a, sm = arena_for(25)
queue(a, 'swarmer', 1); a.t:update(2); kill(a); a.died = true
sm:update(.01); eq(a.wins, 0); eq(sm.state, 'finished')

-- Debug queue is bounded by entries, not scores or offspring kills.
a, sm = arena_for(9999, {}, {{type = 'swarmer', count = 1}})
sm:update(.01); eq(a.wins, 0)
sm:debug_spawn_next(); assert(sm:quota_met())
a.t:update(2); sm:update(.01); eq(a.wins, 0)
kill(a); sm:update(.01); eq(a.wins, 1)

-- Bosses keep the existing all-enemies-dead clear condition.
a, sm = arena_for(nil)
sm:change_state('waiting_for_clear')
a.enemies = {{type = 'hunter_swarmer'}}
sm:update(.01); eq(a.wins, 0)
a.enemies = {}; sm:update(.01); eq(a.wins, 1)

-- Run the actual director for every current ordinary campaign level: the
-- roster is spent exactly (no budget overshoot) and every timeline special
-- spawns the authored number of times.
local function roster_totals(config)
  local d = config.spawn_director
  local totals = {}
  if d.swarmer then totals.swarmer = d.swarmer.total end
  for etype, spec in pairs(d.timeline or {}) do
    totals[etype] = (type(spec) == 'table') and spec.total or spec
  end
  return totals
end
for _, level in ipairs({1, 2, 3, 4, 5, 7, 8, 9, 10}) do
  local config = LEVEL_SPAWN_POOLS[level]
  a, sm = arena_for(nil, config)
  local budget = sm.level_data.kill_quota
  assert(budget > 0)
  local exhausted_power
  for frame = 1, 20000 do
    a.t:update(.05)
    if frame % 4 == 0 and #a.enemies > 1 then kill(a, 1) end
    sm:update(.05)
    assert(sm.pending_spawns >= 0)
    if sm.state == 'waiting_for_clear' then
      eq(a.wins, 0)
      exhausted_power = sm.wave_spawn_power
      for i = 1, 20 do a.t:update(.05); sm:update(.05) end
      eq(sm.wave_spawn_power, exhausted_power)
      while #a.enemies > 0 do kill(a) end
      sm:update(.05); eq(a.wins, 1)
      break
    end
  end
  assert(exhausted_power, 'level did not exhaust budget: ' .. level)
  eq(exhausted_power, budget)
  for etype, total in pairs(roster_totals(config)) do
    assert(spawned_types[etype] == total,
      ('level %d spawned %s x%s, roster says %d'):format(level, etype, tostring(spawned_types[etype]), total))
  end
end

-- Composition does not depend on kills: with nothing killed, every timeline
-- special still arrives on schedule while the swarm sits at its cap; the
-- swarmer remainder spills only once room frees up.
a, sm = arena_for(nil, LEVEL_SPAWN_POOLS[3])
local L3 = LEVEL_SPAWN_POOLS[3].spawn_director
for frame = 1, (L3.length + 5) * 20 do a.t:update(.05); sm:update(.05) end
eq(spawned_types.small_archer, L3.timeline.small_archer)
assert(spawned_types.swarmer <= math.ceil(L3.swarmer.cap * SPAWN_DIRECTOR_RAMP_TO))
assert(spawned_types.swarmer < L3.swarmer.total)
eq(sm.state, 'spawning')
for frame = 1, 4000 do
  a.t:update(.05)
  if frame % 4 == 0 and #a.enemies > 0 then kill(a, 1) end
  sm:update(.05)
  if sm.state == 'waiting_for_clear' then break end
end
eq(sm.state, 'waiting_for_clear'); eq(spawned_types.swarmer, L3.swarmer.total)

-- Killing only swarmers never summons extra specials.
a, sm = arena_for(nil, LEVEL_SPAWN_POOLS[3])
for frame = 1, (L3.length + 5) * 20 do
  a.t:update(.05)
  if frame % 4 == 0 then
    for idx = #a.enemies, 1, -1 do
      if a.enemies[idx].type == 'swarmer' then kill(a, idx); break end
    end
  end
  sm:update(.05)
end
eq(spawned_types.small_archer, L3.timeline.small_archer)

-- A specials-only level: the timeline alone spends the budget and the same
-- clear rules apply.
a, sm = arena_for(nil, {spawn_director = {length = 10, timeline = {sniper = 3}}})
for frame = 1, 2000 do
  a.t:update(.05)
  if frame % 20 == 0 and #a.enemies > 1 then kill(a) end
  sm:update(.05)
  if sm.state == 'waiting_for_clear' then break end
end
eq(sm.state, 'waiting_for_clear'); eq(sm.wave_spawn_power, 600)
eq(spawned_types.sniper, 3); eq(spawned_types.swarmer, nil); eq(a.wins, 0)

-- Scripted events on director levels key off the spawn clock, not kills.
a, sm = arena_for(nil, {spawn_director = {length = 20, swarmer = {cap = 5, total = 5}},
  specials = {{type = 'pulsar', at = 0.5}}})
eq(sm.level_data.kill_quota, 525)
for frame = 1, 9 * 20 do a.t:update(.05); sm:update(.05) end
eq(spawned_types.pulsar, nil)
for frame = 1, 2 * 20 do a.t:update(.05); sm:update(.05) end
eq(spawned_types.pulsar, 1)

-- The progress bar cannot announce completion while enemies still remain.
dofile('ui/progress_bar.lua')
alert1 = {play = noop}
a, sm = arena_for(100)
local segment = setmetatable({progress = 0, max_progress = 100, create_particles = noop}, ProgressBarSegment)
segment:increase_progress(200); eq(segment.progress, 99)
segment:complete_wave(); eq(segment.progress, 100)

-- Path-across enemies must return to a finite arena rather than escape.
Unit = {update = noop, extend = Object.extend}
Physics = {}
dofile('enemies/enemy.lua')
local EnemyClass = Enemy
EnemyClass.super = Unit
Helper.Target = {is_in_camera_bounds = function() return false end,
  is_fully_in_camera_bounds = noop, way_inside_camera_bounds = noop}
gw, gh = 480, 270
local function crossing_enemy()
  local e = setmetatable({x = 600, y = 135, currentMovementAction = MOVEMENT_TYPE_PATH_ACROSS,
    transition_active = false, random_dest_timer = 0}, {__index = EnemyClass})
  for _, name in ipairs({'update_cast_cooldown', 'onTickCallbacks', 'update_buffs',
    'update_status_particles', 'update_animation', 'calculate_stats'}) do e[name] = noop end
  return e
end
local crossing = crossing_enemy(); crossing:update(.01)
assert(not crossing.dead); assert(math.cos(crossing.path_heading) < 0)
a, sm = arena_for(100, {}, {{type = 'slime'}})
crossing = crossing_enemy(); crossing:update(.01); assert(crossing.dead)

-- A splitter's death timer survives its removal and blocks victory until
-- its offspring have spawned and been defeated.
dofile('enemies/regular/splitter.lua')
a, sm = arena_for(25)
sm.wave_spawn_power = 25
local tint = {clone = function(self) return self end}
green = {[0] = tint}
Set_Enemy_Shape = noop
Circle = function() return {} end
local splitter = {x = 0, y = 0, level = 1, size = 1, state_change_functions = {}}
enemy_to_class.splitter.init_enemy(splitter)
Enemy = function(args)
  local child = {type = args.type, class = 'regular_enemy'}
  table.insert(a.enemies, child)
  return child
end
splitter.state_change_functions.death(splitter)
eq(sm.pending_spawns, 3)
sm:update(.01); eq(a.wins, 0)
a.t:update(.1); eq(sm.pending_spawns, 0); eq(#a.enemies, 3)
sm:update(.01); eq(a.wins, 0)
while #a.enemies > 0 do kill(a) end
sm:update(.01); eq(a.wins, 1)

-- Compile all changed gameplay files with the project's Lua version.
for _, path in ipairs({'spawns/spawnmanager.lua', 'spawns/levelmanager.lua',
  'enemies/enemy.lua', 'enemies/regular/splitter.lua', 'enemies/regular/dart.lua', 'ui/progress_bar.lua',
  'level_classes/arena.lua', 'level_classes/combat_level.lua'}) do assert(loadfile(path)) end
print('PASS: finite budget, delayed spawns, no score-based wins, scripted events, scatter accounting, loss priority, debug, bosses, all campaign rosters, kill-independent composition, swarmer-free levels, clock-based events, progress display, returning enemies, and splitter offspring.')

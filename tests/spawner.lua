-- Run from the repository root: luajit tests/spawner.lua
dofile('engine/game/object.lua')
GameObject = {init_game_object = function(self, args)
  for k, v in pairs(args) do self[k] = v end
end}
unit_states = {idle = 'idle', casting = 'casting', channeling = 'channeling', stunned = 'stunned'}
Helper = {Time = {time = 0}, Unit = {set_state = function(_, unit, state) unit.state = state end}}
main = {current = {main = {}}}
purple = {[0] = {clone = function(self) return self end}}
Circle = function(x, y, r) return {x = x, y = y, rs = r} end
Set_Enemy_Shape = function(self) self.shape = {w = 18, h = 18} end
pop2 = {play = function() end}
random = {float = function(_, lo, hi) return (lo + hi) / 2 end}
Has_Static_Proc = function() return false end
Can_Spawn = function() return true end
local children = {}
EnemyCritter = function(args)
  children[#children + 1] = args
  return args
end
enemy_to_class = {}
dofile('helper/spells/v2/spell.lua')
dofile('enemies/regular/spawner.lua')
local function spawner()
  local unit = {x = 100, y = 100, level = 7, size = 'special', state = 'idle',
    hfx = {use = function() end},
    end_cast = function(self) self.state = 'idle' end,
    cancel_cast = function(self) self.state = 'idle' end}
  for k, v in pairs(enemy_to_class.spawner) do unit[k] = v end
  unit:init_enemy()
  return unit
end
local function start_cast(unit)
  local attack = unit.attack_options[1]
  assert(attack.viable(), 'hatch should be viable')
  local args = {unit = unit}
  for k, v in pairs(attack) do args[k] = v end
  local cast = Cast(args)
  unit.castObject = cast
  return cast
end
local function hatch(unit)
  local cast = start_cast(unit)
  local before = #children
  Helper.Time.time = Helper.Time.time + 0.5
  cast:update(0.5)
  assert(#children == before, 'must respect hatch windup')
  Helper.Time.time = Helper.Time.time + 0.6
  cast:update(0.6)
  assert(cast.dead and unit.state == 'idle', 'cast must finish cleanly')
end
local unit = spawner()
hatch(unit)
assert(unit:count_brood() == 4)
for _, child in ipairs(children) do
  assert(child.brood_model and child.parent == unit and child.level == 7)
  assert(math.abs((child.x - unit.x)^2 + (child.y - unit.y)^2 - 18^2) < 0.01)
end
hatch(unit)
hatch(unit)
assert(unit:count_brood() == 10, 'last batch must respect living cap')
assert(not unit.attack_options[1].viable())
unit.brood[1].dead = true
unit.brood[2].dead = true
unit.brood[3].dead = true
hatch(unit)
assert(unit:count_brood() == 10, 'dead offspring must free slots')
local other = spawner()
hatch(other)
assert(other:count_brood() == 4 and unit:count_brood() == 10, 'caps are per spawner')
Can_Spawn = function() return false end
local blocked = spawner()
hatch(blocked)
assert(blocked:count_brood() == 0, 'blocked spawns must not consume slots')
Can_Spawn = function() return true end
for _, cancelled_state in ipairs({'dead', 'stunned'}) do
  local interrupted = spawner()
  local cast = start_cast(interrupted)
  if cancelled_state == 'dead' then interrupted.dead = true
  else interrupted.state = 'stunned'; cast:cancel() end
  local before = #children
  Helper.Time.time = Helper.Time.time + 2
  cast:update(2)
  assert(#children == before, 'interrupted hatch must not spawn offspring')
end
print('Spawner checks passed: windup, batches, living cap, refill, placement failure, independent broods, cancellation.')

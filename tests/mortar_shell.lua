-- Run from the repository root: luajit tests/mortar_shell.lua
love = love or {timer = {getTime = function() return 0 end}}
dofile('engine/game/object.lua')
dofile('engine/math/math.lua')
dofile('engine/graphics/color.lua')
local serial = 0
random = {
  uid = function() serial = serial + 1; return serial end,
  float = function(_, lo, hi) return (lo + hi) / 2 end,
}
dofile('engine/game/trigger.lua')
local spawned = {}
GameObject = {
  init_game_object = function(self, args)
    for k, v in pairs(args) do self[k] = v end
    self.x, self.y, self.r = self.x or 0, self.y or 0, self.r or 0
    self.t = Trigger()
    self.spring = {x = 1, pull = function() end}
    spawned[#spawned + 1] = self
  end,
  update_game_object = function(self, dt) self.t:update(dt) end,
}
Physics = {}
Circle = function(x, y, rs)
  return {x = x, y = y, rs = rs, move_to = function(self, nx, ny) self.x, self.y = nx, ny end}
end
orange, red, fg, yellow, black = {[0]=Color('#f07021')}, {[0]=Color('#e91d39')},
  {[0]=Color('#dadada')}, {[0]=Color('#facf00')}, {[0]=Color('#000000')}
local sound = {play = function() end}
orb1, earth2, turret_hit_wall2, cannoneer1 = sound, sound, sound, sound
get_dmg_value = function(value) return value end
HitCircle, HitParticle = function() end, function() end
Helper = {Time = {time = 0}, Target = {get_random_enemy = function() return nil end}}
unit_states = {channeling = 'channeling'}
dofile('helper/spells/v2/spell.lua')
-- Match startup order: spells are loaded before miscellaneous_objects.
dofile('helper/spells/v2/mortar.lua')
local f = assert(io.open('miscellaneous_objects.lua'))
local source = f:read('*a'); f:close()
local effects = source:sub(assert(source:find('Stomp = Object:extend()', 1, true)),
  assert(source:find('GroundFlash = Object:extend()', 1, true)) - 1)
assert(loadstring(effects))()
local hits = 0
local victim = {x = 200, y = 160, color = fg[0],
  slow = function() end, hit = function(_, damage) assert(damage == 20); hits = hits + 1 end}
main = {current = {effects = {}, friendlies = {}, main = {get_objects_in_shape = function(_, shape)
  assert(shape.x == 200 and shape.y == 160 and shape.rs == 25)
  return {victim}
end}}}
local caster = {x = 40, y = 160, r = 0}
local target = {x = 200, y = 160}
local volley = Mortar_Spell{unit = caster, target = target, damage = 20, target_offset = 0}
volley:fire()
local shell = spawned[#spawned]
assert(shell:is(MortarShell) and shell.chargeTime == 1.5)
local x, y, height = shell:flight_position()
assert(x == 52 and y == 160 and height == 0, 'must launch from current muzzle')
target.x, target.y = 350, 250
caster.x, caster.y = 80, 200
assert(shell.x == 200 and shell.y == 160, 'landing must not follow the target')
for i = 1, 75 do shell:update(0.01) end
x, y, height = shell:flight_position()
assert(math.abs(x - 126) < 0.001 and height > 40 and hits == 0, 'midflight arc without damage')
caster.dead = true
local count = #spawned
volley:update(1)
assert(volley.dead and #spawned == count, 'dead mortar cannot launch more shells')
for i = 1, 76 do shell:update(0.01) end
x, y, height = shell:flight_position()
assert(x == 200 and y == 160 and height == 0)
assert(shell.visual_phase == 'impact' and hits == 1, 'airborne shell lands after caster death')
for i = 1, 30 do shell:update(0.01) end
assert(shell.dead and hits == 1, 'one explosion and cleanup')
caster.dead = false
local next_volley = Mortar_Spell{unit = caster, target = target, damage = 20, target_offset = 0}
next_volley:fire()
local next_shell = spawned[#spawned]
assert(next_shell.x == 350 and next_shell.y == 250 and next_shell.source_x == 92)
print('Mortar checks passed: startup order, fixed target, muzzle position, arc, impact timing, caster death, single damage, cleanup.')

-- Boss rock barrages and line patterns share the same flight/impact code.
grey = {[0] = Color('#808080')}
unit_states.idle, unit_states.casting, unit_states.frozen = 'idle', 'casting', 'frozen'
Helper.Unit = {set_state = function(_, unit, state) unit.state = state end, get_list = function() return {} end}
get_dmg_value = function(value) return type(value) == 'function' and value() or value end
main.current.main.world = {}
main.current.main.get_objects_in_shape = function() return {} end
local line_caster = {x = 100, y = 100}
local line = LineMortar_Spell{unit = line_caster, target = {x = 200, y = 100},
  damage = 20, num_shots = 3, line_length = 120, shell_style = 'rock'}
line:fire()
local first_rock = spawned[#spawned]
assert(first_rock:is(MortarShell) and first_rock.shell_style == 'rock')
assert(first_rock.x == 140 and first_rock.y == 100 and first_rock.chargeTime == 1)
line_caster.x, line_caster.y = 300, 200
line:fire()
local second_rock = spawned[#spawned]
assert(second_rock.x == 180 and second_rock.y == 100, 'line must remain anchored')
assert(second_rock.source_x == 300, 'rocks launch from current caster position')
line_caster.dead = true
local before = #spawned
line:update(1)
assert(line.dead and #spawned == before)
for i = 1, 101 do first_rock:update(0.01) end
assert(first_rock.visual_phase == 'impact', 'launched line rocks must still land')

local function source_between(path, first, last)
  local file = assert(io.open(path)); local text = file:read('*a'); file:close()
  return text:sub(assert(text:find(first, 1, true)), assert(text:find(last, 1, true)) - 1)
end
assert(loadstring(source_between('helper/spells/v2/instants.lua',
  'Avalanche = Object:extend()', 'Boomerang = Object:extend()')))()
Unit = {}
assert(loadstring(source_between('objects.lua', 'function Unit:pick_action()', 'function Unit:update_cast_cooldown(dt)')))()
assert(loadstring(source_between('objects.lua', 'function Unit:end_cast()', 'function Unit:end_channel()')))()
enemy_to_class = {}
dofile('enemies/bosses/stompy.lua')
Set_Enemy_Shape = function(unit) unit.shape = {w = 56, rs = 28} end
get_movement_type_by_enemy_type = function() return 'seek' end
Has_Static_Proc = function() return false end
GOLEM_CAST_TIME, HITS_BEFORE_RETARGETING = 0.5, 5
enemy_attack_cooldowns = {stompy_avalanche = 12}
usurer1 = sound
local boss = {x = 240, y = 135, dmg = 20, type = 'stompy', in_arena_radius = true,
  attack_cooldown_timer = 0, get_random_object_in_shape = function() end,
  put_attack_on_cooldown = function() end, clear_my_target = function() end,
  cast = function(self, attack) self.selected_attack = attack end}
for name, fn in pairs(Unit) do boss[name] = fn end
for name, fn in pairs(enemy_to_class.stompy) do boss[name] = fn end
Helper.Time.time = 100
boss:init_enemy()
local avalanche_attack
for _, attack in ipairs(boss.attack_options) do
  if attack.name == 'avalanche' then avalanche_attack = attack end
  if attack.name == 'mortar' then assert(attack.spelldata.shell_style == 'rock') end
end
assert(avalanche_attack and avalanche_attack.priority)
Helper.Time.time = 111
assert(not avalanche_attack.viable())
Helper.Time.time = 112
assert(boss:pick_action() and boss.selected_attack == avalanche_attack, 'avalanche must win the priority selection')
avalanche_attack.oncast()
local args = Deep_Copy_Cast(avalanche_attack)
args.unit = boss
local cast = Cast(args)
boss.castObject = cast
Helper.Time.time = 113
cast:update(1)
local avalanche = spawned[#spawned]
assert(avalanche:is(Avalanche) and boss.state == 'frozen', 'avalanche must survive cast completion')
local start_index = #spawned
for i = 1, 541 do avalanche:update(0.01) end
local rocks = {}
for i = start_index + 1, #spawned do
  local object = spawned[i]
  if object:is(MortarShell) then rocks[#rocks + 1] = object end
end
assert(#rocks == 48, 'six waves of eight rocks')
for _, rock in ipairs(rocks) do
  assert(rock.shell_style == 'rock' and rock.chargeTime == 0.9)
  assert(rock.source_x == 240 and rock.source_y == 123)
end
assert(avalanche.dead and boss.state == 'idle', 'boss must resume after avalanche')
assert(not avalanche_attack.viable(), 'avalanche cadence must reset on cast')

local interrupted = Avalanche{group = main.current.main, unit = boss, team = 'enemy', damage = 20}
interrupted:update(0.01)
local live_rock = spawned[#spawned]
boss.dead = true
before = #spawned
interrupted:update(5)
assert(interrupted.dead and #spawned == before, 'boss death must stop future waves')
for i = 1, 91 do live_rock:update(0.01) end
assert(live_rock.visual_phase == 'impact', 'airborne avalanche rocks must land')
print('Stompy checks passed: rock lines, fixed pattern, avalanche priority, full 48-rock cast, recovery, death handling.')

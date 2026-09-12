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

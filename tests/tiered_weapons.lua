-- Run: luajit tests/tiered_weapons.lua. Uses production weapon/AI/effect code
-- with a small world fixture; no window, audio, or physics runtime required.
dofile('engine/game/object.lua')
dofile('engine/math/math.lua')
dofile('engine/graphics/color.lua')
local serial, spawned, arrows, lasers = 0, {}, {}, {}
random = {uid = function() serial = serial + 1; return serial end,
  float = function(_, lo, hi) return lo end, table = function(_, t) return t[1] end}
table.contains = function(t, value) for _, v in ipairs(t) do if v == value then return true end end return false end
GameObject = {
  init_game_object = function(self, args)
    for key, value in pairs(args) do self[key] = value end
    self.x, self.y, self.r = self.x or 0, self.y or 0, 0
    self.id = random:uid(); spawned[#spawned + 1] = self
  end,
  update_game_object = function() end,
}
Circle = function(x, y, r) return {x = x, y = y, rs = r} end
local colors = {red='#e91d39', blue='#019bd6', green='#8bbf40', orange='#f07021', yellow='#facf00', brown='#735440', fg='#dadada'}
for key, hex in pairs(colors) do _G[key] = {[0] = Color(hex)} end
local sound = {play = function() end}
earth1, spark2, cannoneer1, cannoneer2 = sound, sound, sound, sound
local draw_calls = 0
graphics = setmetatable({}, {__index = function() return function(...) draw_calls = draw_calls + 1 end end})
LightningLine = function() end
ArrowProjectile = function(data) arrows[#arrows + 1] = data end
Laser_Spell = function(data) lasers[#lasers + 1] = data end
MAX_ITEM_STACK, MAX_ITEM_SLOTS = 3, 18
TROOP_ARCHER_RANGE, TROOP_SHOTGUN_RANGE, TROOP_RANGE = 100, 70, 100
unit_states = {normal='normal', idle='idle', stopped='stopped', following='following', stunned='stunned'}
Has_Static_Proc = function() return false end
Helper = {Time = {time = 0}, Unit = {closest_enemy_distance_multiplier = 1}}
Helper.Unit.in_range_of_rally_point = function(_, unit)
  return math.distance(unit.x, unit.y, unit.target_pos.x, unit.target_pos.y) < 5
end
default_to = function(value, fallback) if value == nil then return fallback end return value end
DAMAGE_TYPE_PHYSICAL = 'physical'
ELEMENTAL_HIT_DAMAGE_TYPES, ELEMENTAL_EFFECT_TYPES = {}, {}
BASE_CRIT_MULT = 2
dofile('helper/helper_damage.lua')
-- Keep the real critical-hit dispatch; replace unrelated status/audio hooks.
Helper.Damage.process_pre_hit = function() return true end
Helper.Damage.calculate_final_damage = function(_, _, damage) return damage end
Helper.Damage.deal_damage = function(_, target, damage) target.hp = target.hp - damage; target.hits = target.hits + 1 end
for _, key in ipairs({'process_physical_to_elemental', 'process_post_damage', 'track_team_damage', 'process_callbacks'}) do
  Helper.Damage[key] = function() end
end
Helper.Damage.handle_death = function(_, target) target.dead = true end

local enemies = {}
local world = {}
function world:get_objects_in_shape(shape)
  local matches = {}
  for _, enemy in ipairs(enemies) do
    if not enemy.dead and math.distance(shape.x, shape.y, enemy.x, enemy.y) <= shape.rs then matches[#matches+1] = enemy end
  end
  return matches
end
function world:get_objects_by_classes()
  return enemies
end
main = {current = {main = world, effects = {}, enemies = {}}}
dofile('items/weapons.lua')
dofile('items/weapon_effects.lua')
Unit = Object:extend(); Troop = Unit:extend()
local file = assert(io.open('units/player/player_troop.lua')); local source = file:read('*a'); file:close()
local start = assert(source:find('function Troop:build_weapons()', 1, true))
local finish = assert(source:find('function Troop:set_rally_position', start, true))
assert(loadstring(source:sub(start, finish - 1)))()
function Troop:distance_to_object(other) return math.distance(self.x, self.y, other.x, other.y) end
function Troop:set_target(target) self.target = target end
function Troop:clear_my_target() self.target = nil end
function Troop:clear_assigned_target() self.assigned_target = nil end
function Troop:stretch_on_attack() end
function Troop:onAttackCallbacks() end
function Troop:get_bonus_pierce() return 0 end
local function troop(key)
  local u = setmetatable({x=0,y=0,dmg=10,aspd_m=1,buff_range_a=0,buff_range_m=1,
    area_size_m=1,crit_chance=0,state='normal',items={create_weapon_item(key)},is_troop=true}, Troop)
  u:build_weapons(); return u
end
local function enemy(x, y)
  local e = {x=x,y=y,hp=10000,hits=0,fully_onscreen=true,
    burn=function(self, damage) self.burn_damage = damage end,
    shock=function(self) self.shocked = true end}
  enemies[#enemies+1] = e; return e
end
local function near(a,b) assert(math.abs(a-b) < 1e-6, tostring(a)..' != '..tostring(b)) end

-- Every weapon inherits the same unit damage, attack speed and range stats.
for _, key in ipairs(WEAPON_KEYS) do
  local u = troop(key); local w = u.weapons[1]
  local base_damage, base_cd, base_range = w.damage, w.cooldown, w.range
  u.dmg, u.aspd_m, u.buff_range_m = 20, 0.5, 1.25
  u:update_weapon_stats()
  near(w.damage, base_damage*2); near(w.cooldown, base_cd*0.5); near(w.range, base_range*1.25)
end

-- Marine remains the starter; Crossbow keeps homing until impact and pierces.
enemies = {}; local target = enemy(35,0)
local archer = troop('archer'); archer:update_weapons(0.01,true)
assert(#arrows == 1 and arrows[1].homing)
assert(create_weapon_item('archer').name == 'Marine')
assert(WEAPON_DEFS.archer.cooldown == 0.6)
assert(arrows[1].bullet_size == 1.25 and arrows[1].speed == 500 and arrows[1].projectile_style == 'marine')
local crossbow = troop('crossbow'); crossbow:update_weapons(0.01,true)
assert(arrows[2].pierce == 2 and arrows[2].straight_after_hit and arrows[2].crit_on_pierce)
assert(arrows[2].damage > arrows[1].damage)
local laser = troop('laser'); laser:update_weapons(0.01,true)
assert(#lasers == 1 and lasers[1].reduce_pierce_damage == false)

-- Cannon lands at the captured target position and hits every enemy in radius.
local cannon = troop('cannon'); cannon.crit_chance = 1; cannon.area_size_m = 2
local nearby = enemy(70,0); local distant = enemy(130,0)
cannon:update_weapons(0.01,true)
local shell = spawned[#spawned]; assert(shell.kind == 'cannon' and shell.radius == 44)
assert(target.hits == 0)
target.x = 150 -- impact remains at the original point
shell:update(shell.flight_time + 0.01)
assert(target.hits == 0 and nearby.hits == 1 and distant.hits == 0)
near(10000-nearby.hp, cannon.weapons[1].damage*2)
shell:draw_ground(); shell:draw(); shell:update(0.31); assert(shell.dead)

-- Radiance pulses follow mobile units, use Area, crit, and apply burn.
enemies = {}; local close = enemy(30,0)
local radiance = troop('radiance'); radiance.state = 'following'; radiance.crit_chance = 1
radiance.area_size_m = 1.5; radiance:update_weapon_stats(); radiance:update_weapons(0.01,false)
local pulse = spawned[#spawned]
assert(pulse.kind == 'radiance' and pulse.radius == 63 and close.hits == 1 and close.burn_damage > 0)
near(10000-close.hp, radiance.weapons[1].damage*2)
pulse:draw_ground()
radiance.state = 'stunned'; radiance.weapons[1].elapsed = 99
local count = #spawned; radiance:update_weapons(1,false); assert(#spawned == count)

-- Orbit is persistent and target-free, with contact cooldown and live stats.
enemies = {}; local orbital = troop('orbit'); orbital.state = 'following'; orbital.crit_chance = 1
orbital:update_weapons(0,false)
local orbit = orbital.weapons[1].effect; assert(orbit and orbit.kind == 'orbit')
local touching = enemy(38,0); orbit:update(0)
assert(touching.hits == 1); near(10000-touching.hp, orbital.weapons[1].damage*2)
orbit:update(0); assert(touching.hits == 1, 'contact cannot hit every frame')
orbital.aspd_m = 0.5; orbital.area_size_m = 2; orbital:update_weapon_stats()
orbit:update(0.51); near(orbit.radius, 8)
orbital.x = 20; orbit:draw(); orbit:draw_ground()
orbital.items = {create_weapon_item('archer')}; orbital:build_weapons(); assert(orbit.dead)

-- Lightning runs without an on-hit trigger, caps each zap at three targets.
enemies = {}; for i=1,4 do enemy(10*i,0) end
local lightning = troop('lightning'); lightning.crit_chance = 1
lightning:update_weapons(0,true); local ball = spawned[#spawned]
ball:update(0); assert(enemies[1].hits == 1 and enemies[3].hits == 1 and enemies[4].hits == 0)
near(10000-enemies[1].hp, lightning.weapons[1].damage*2)
assert(enemies[1].shocked); ball:draw(); ball:update(2); assert(ball.dead)

-- Meteor telegraphs before its impact; owner death cancels outstanding effects.
enemies = {}; local victim = enemy(40,0)
local meteor = troop('meteor'); meteor:update_weapons(0,true)
local falling = spawned[#spawned]; falling:update(0.3)
assert(victim.hits == 0); falling:draw_ground(); falling:draw()
falling:update(0.4); assert(victim.hits == 1); falling:draw_ground()
local cancelled = WeaponEffect{unit=meteor, weapon=meteor.weapons[1], kind='meteor', target=victim, damage_multi=1}
meteor.dead = true; cancelled:update(1); assert(cancelled.dead and victim.hits == 1)
assert(draw_calls > 0)
-- Weapon lasers use the real line-damage path, including crits and deduping
-- multiple hitbox points. Enemy lasers retain their deferred damage path.
dofile('helper/helper_geometry.lua')
local laser_file = assert(io.open('helper/spells/v2/laser_spell.lua'))
local laser_source = laser_file:read('*a'); laser_file:close()
local damage_start = assert(laser_source:find('function Laser_Spell:try_damage()', 1, true))
local damage_end = assert(laser_source:find('function Laser_Spell:draw()', damage_start, true))
Laser_Spell = {}; assert(loadstring(laser_source:sub(damage_start, damage_end - 1)))()
enemies = {}; local beam_target = enemy(40,0)
beam_target.points = {{x=0,y=0}, {x=1,y=0}}
local beyond = enemy(140,0); beyond.points = {{x=0,y=0}}
Helper.Unit.get_list = function() return enemies end
laser.crit_chance = 1
local beam = setmetatable({weapon_hit=true, damage_once=true, damage=30, unit=laser,
  lineCoords={0,0,120,0}, laser_width=8, already_damaged={}}, {__index=Laser_Spell})
beam:try_damage(); beam:try_damage()
assert(beam_target.hits == 1 and beyond.hits == 0)
near(10000-beam_target.hp, 60)
assert(lasers[1].weapon_hit and lasers[1].length == laser.weapons[1].range)
print('tiered_weapons: shared stats, crits, scheduling, area damage, persistence, and cleanup passed')

-- Each attack switches to the closest valid enemy, even while the old one lives.
enemies = {}
local far = enemy(60, 0)
local aiming = troop('archer')
aiming:update_weapons(0.01, true)
assert(arrows[#arrows].target == far)
local close = enemy(20, 0)
aiming:update_weapons(aiming.weapons[1].cooldown, true)
assert(arrows[#arrows].target == close and aiming.target == close)
local dead = enemy(1, 0); dead.dead = true
local hidden = enemy(2, 0); hidden.fully_onscreen = false
local immune = enemy(3, 0); immune.untargetable = true
aiming:update_weapons(aiming.weapons[1].cooldown, true)
assert(arrows[#arrows].target == close)
aiming.assigned_target = far
aiming:update_weapons(aiming.weapons[1].cooldown, true)
assert(arrows[#arrows].target == far, 'manual target retains priority')
far.x = 200
aiming:update_weapons(aiming.weapons[1].cooldown, true)
assert(arrows[#arrows].target == close, 'out-of-range command falls back to nearest')
close.dead = true
local before = #arrows
aiming:update_weapons(aiming.weapons[1].cooldown, true)
assert(#arrows == before, 'no shot when every enemy is invalid or out of range')
print('weapon targeting: nearest per attack, eligibility, range, and manual priority passed')
-- Rally travel blocks every weapon, even in otherwise fire-ready states.
for _, key in ipairs(WEAPON_KEYS) do
  if not WEAPON_DEFS[key].persistent then
    for _, state in ipairs({'normal', 'idle', 'stopped', 'following'}) do
      enemies = {}; local victim = enemy(5, 0)
      local u = troop(key); u.state = state; u.rallying = true; u.target_pos = {x=200,y=0}
      local shots = 0
      u.fire_weapon = function() shots = shots + 1 end
      u:update_weapons(1, true); assert(shots == 0 and not u.weapons[1].can_fire, key)
      u.x = 200; victim.x = 205
      u:update_weapons(0, true); assert(shots == 1, key .. ' must fire on arrival')
      u.target_pos.x = 400
      u:update_weapons(10, true); assert(shots == 1, key .. ' must stop on a new rally')
      u.rallying = false; u.target_pos = nil
      u:update_weapons(0, true); assert(shots == 2, key .. ' must resume after rally cancellation')
    end
  end
end
-- Orbit can start and keep dealing contact damage while travelling to a rally.
enemies = {}; local u = troop('orbit')
u.rallying = true; u.target_pos = {x=200,y=0}
u:update_weapons(0, true)
local effect = u.weapons[1].effect; assert(effect and u.weapons[1].can_fire)
local victim = enemy(u.weapons[1].range, 0)
effect:update(0); assert(victim.hits == 1)
u:update_weapons(0, true); effect:update(0)
assert(victim.hits == 1, 'Orbit must still respect contact cooldown')
u.x = 200; local next_victim = enemy(200 + u.weapons[1].range, 0)
u:update_weapons(0, true); effect:update(0); assert(next_victim.hits == 1)
-- A repeat queued before movement starts still fires automatically in transit.
enemies = {}; victim = enemy(5, 0); u = troop('archer')
u.repeat_attack_chance = 1
local pending
u.t = {after = function(_, delay, callback) pending = callback end}
u:update_weapons(0, true)
local before = #arrows
u.rallying = true; u.target_pos = {x=200,y=0}
assert(pending); pending(); assert(#arrows == before + 1)
u:instant_attack(victim, 1); assert(#arrows == before + 1)
-- A player laser already winding up is cancelled by rally travel.
local update_start = assert(laser_source:find('function Laser_Spell:update(dt)', 1, true))
local update_end = assert(laser_source:find('function Laser_Spell:update_target_coords()', update_start, true))
assert(loadstring(laser_source:sub(update_start, update_end - 1)))()
local charging = setmetatable({unit=u, weapon_hit=true, total_time=0,
  die=function(self) self.dead=true end}, {__index=Laser_Spell})
charging:update(0.01); assert(charging.dead)
-- A queued repeat laser continues its windup during travel.
Laser_Spell.super = {update = function() end}
local repeated = setmetatable({unit=u, weapon_hit=true, is_repeat=true,
  total_time=0, total_duration=10, lasermode='fixed', charge_time=0, charge_duration=1, laser_aim_width=1,
  update_target_coords=function() end, update_coords=function() end,
  update_charge=function(self) self.charge_advanced=true end,
  die=function(self) self.dead=true end}, {__index=Laser_Spell})
repeated:update(0.01); assert(not repeated.dead and repeated.charge_advanced)
print('rally attacks: new attacks wait for arrival; Orbit and queued repeats continue')
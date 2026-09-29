-- Run: luajit tests/swarmer_contact.lua
-- Also runs against real Box2D when invoked by a LÖVE harness.
dofile('engine/game/object.lua')
dofile('engine/math/math.lua')
dofile('engine/datastructures/table.lua')
system = {load_stats = function() end}
dofile('game_constants.lua')
dofile('combat_stats/combat_stats.lua')
GameObject, Parent, State = {}, {}, {}
dofile('engine/game/physics.lua')
dofile('objects.lua')
dofile('units/player/player_troop.lua')
dofile('enemies/enemy.lua')
Helper = {Time = {time = 0}}
dofile('helper/helper_unit.lua')
Helper.Unit.get_survivor_damage_boost = function() return 1 end
random = {float = function(_, lo, hi) return (lo + hi)/2 end, table = function(_, t) return t[1] end}
Wall = Object:extend()
main = {current = {enemies = {Enemy}, friendlies = {Troop}}}

local function near(actual, expected)
  assert(math.abs(actual - expected) < 0.0001, tostring(actual) .. ' ~= ' .. tostring(expected))
end
local function timer()
  return {pending = {}, delayed = {}, after = function(self, delay, fn)
    local queue = delay == 0 and self.pending or self.delayed
    queue[#queue + 1] = fn
  end, flush = function(self)
    local pending = self.pending; self.pending = {}
    for _, fn in ipairs(pending) do fn() end
  end}
end
local function empty() return {} end
local function troop(hp_bonus)
  local t = setmetatable({class='troop', character='unit', is_troop=true,
    base_hp=TROOP_HP, base_dmg=TROOP_DAMAGE, base_mvspd=TROOP_MS, hp=math.huge,
    x=0, y=0, t=timer(), pushes=0, hits=0,
    process_buffs_to_stats=empty, process_items_to_stats=empty,
    process_set_bonuses_to_stats=function() return {hp=hp_bonus or 0} end,
    preprocess_perks_to_stats=empty, process_team_meta_to_stats=empty,
    count_elemental_afflictions=function() return 0 end,
    update_weapon_stats=function() end,
    push=function(self,force,angle,invulnerable,duration)
      self.pushes=self.pushes+1; self.push_angle=angle; self.push_strength=force
    end,
    hit=function(self, damage)
      self.hits=self.hits+1; self.hp=self.hp-self:calculate_damage(damage)
    end,
    angle_to_object=function(self, other) return math.atan2(other.y-self.y, other.x-self.x) end,
  }, Troop)
  t:calculate_stats()
  return t
end
local function enemy(kind, level, fraction)
  local class = (kind=='swarmer' or kind=='hunter_swarmer') and 'regular_enemy' or 'special_enemy'
  local base = class=='regular_enemy' and REGULAR_ENEMY_DAMAGE or SPECIAL_ENEMY_DAMAGE
  local stats = enemy_type_to_stats[kind]
  local body = {vx=0, vy=0, getLinearVelocity=function(self) return self.vx,self.vy end,
    setLinearDamping=function() end, applyAngularImpulse=function() end,
    applyLinearImpulse=function(self,x,y) self.vx=self.vx+x*32; self.vy=self.vy+y*32 end}
  return setmetatable({type=kind, class=class, x=8, y=0, max_hp=100,
    hp=100*(fraction or 1), dmg=SCALED_ENEMY_DAMAGE(level or 1,base)*(stats.dmg or 1),
    t=timer(), body=body, die=function(self) self.dead=true end,
    angle_to_object=function(self, other) return math.atan2(other.y-self.y,other.x-self.x) end,
  },Enemy)
end
-- Mini swarmers keep normal speed but halve the scaled health and damage bases.
local mini = enemy('swarmer', 7); mini.level = 7
_set_unit_base_stats(mini)
local full_hp, full_damage, full_speed = mini.base_hp, mini.base_dmg, mini.base_mvspd
mini.mini_swarmer = true
_set_unit_base_stats(mini)
near(mini.base_hp, full_hp * 0.5); near(mini.baseline_hp, mini.base_hp)
near(mini.base_dmg, full_damage * 0.5); near(mini.base_mvspd, full_speed)
local contact = {getPositions=function() return 0,0 end, setEnabled=function(self,b) self.enabled=b end}
local function collide(t,e,enemy_first)
  if enemy_first then e:on_collision_enter(t,contact); t:on_collision_enter(e,contact)
  else t:on_collision_enter(e,contact); e:on_collision_enter(t,contact) end
  t:on_collision_pre_solve(e,contact)
end

-- Either Box2D callback order must push the troop away and preserve swarmer recoil.
for _, kind in ipairs({'swarmer','hunter_swarmer'}) do
  for _, enemy_first in ipairs({false,true}) do
    Helper.Time.time=0
    local t,e=troop(),enemy(kind)
    collide(t,e,enemy_first)
    near(t.hp,125); assert(not e.being_knocked_back, 'never mutate physics inside contact')
    t.t:flush(); e.t:flush()
    assert(not e.dead and e.being_knocked_back and e.contact_recoil)
    assert(e:get_velocity()>0, 'swarmer should recoil away from the troop')
    assert(t.pushes==1 and contact.enabled==false)
    near(t.push_angle,math.pi); near(t.push_strength,LAUNCH_PUSH_FORCE_ENEMY)
    near(t.hp,kind=='swarmer' and 120 or 119)
  end
end
-- Colored swarmer variants still recoil; their death abilities are unaffected.
local t,e=troop(),enemy('swarmer'); e.special_swarmer_type='exploder'
assert(not Dies_On_Contact(e)); collide(t,e); t.t:flush(); e.t:flush(); assert(not e.dead)

-- A crowd can chip health, but cannot stack all its bites on one frame.
Helper.Time.time=0; t=troop()
local swarm={}
for i=1,10 do swarm[i]=enemy('swarmer'); collide(t,swarm[i]) end
t.t:flush()
near(t.hp,120); assert(t.hits==1 and t.pushes==1)
for _,s in ipairs(swarm) do s.t:flush(); assert(s.contact_recoil) end
-- A rebounding swarmer also cannot bite the next troop immediately.
local second=troop(); collide(second,swarm[1]); second.t:flush(); near(second.hp,125)
Helper.Time.time=SWARMER_HIT_GRACE+0.01
collide(t,enemy('swarmer')); t.t:flush(); near(t.hp,115)
Helper.Time.time=SWARMER_CONTACT_COOLDOWN+0.01
collide(second,swarm[1]); second.t:flush(); near(second.hp,120)

-- Grace applies only to swarmer contact: a special still hits and shoves.
Helper.Time.time=0; t=troop(); collide(t,enemy('swarmer')); t.t:flush()
local tank=enemy('tank'); contact.enabled=true; collide(t,tank); t.t:flush(); tank.t:flush()
near(t.hp,92); assert(t.pushes==2 and tank.dead and contact.enabled)
local boss=enemy('tank'); boss.class='boss'; boss.pinball_charging=true
local hits=t.hits; collide(t,boss); t.t:flush(); assert(t.hits==hits and not boss.dead)
boss.pinball_charging=false; collide(t,boss); t.t:flush(); near(t.hp,68); assert(not boss.dead)

-- Recoil cannot bowl through a crowd for free collision-chain damage.
local bounced=swarm[1]; bounced.t:flush()
bounced:on_collision_enter(enemy('swarmer'),contact)
assert(#bounced.t.pending==0, 'contact recoil must not deal chain damage')
-- If a projectile kills the swarmer before deferred recoil, leave it alone.
Helper.Time.time=0; t=troop(); e=enemy('swarmer'); collide(t,e); e.dead=true
e.t:flush(); assert(not e.being_knocked_back)

-- Audit using production stat calculation and armor, not a second HP formula.
print('level | troop HP | swarm hit | special shot | tank contact | hits to die (swarm/special/tank)')
for _,level in ipairs({1,4,7,10}) do
  t=troop(); near(t.max_hp,125); near(t.def,25)
  local sw=t:calculate_damage(Contact_Damage(enemy('swarmer',level)))
  local sp=t:calculate_damage(enemy('sniper',level).dmg)
  local ta=t:calculate_damage(Contact_Damage(enemy('tank',level)))
  near(sw,({[1]=5,[4]=6,[7]=7,[10]=8})[level])
  assert(sp > sw*4 and ta > sp)
  assert(math.ceil(t.max_hp/sp)>=4 and math.ceil(t.max_hp/sp)<=6)
  near(t:calculate_damage(Contact_Damage(enemy('swarmer',level,0.5))),sw/2)
  print(string.format('%2d    | %.0f      | %.2f      | %.2f        | %.2f        | %d/%d/%d',
    level,t.max_hp,sw,sp,ta,math.ceil(t.max_hp/sw),math.ceil(t.max_hp/sp),math.ceil(t.max_hp/ta)))
end
near(troop(0.2).max_hp,150); near(troop(0.35).max_hp,168.75); near(troop(0.5).max_hp,187.5)

-- Optional real physics check: catch accidental solver shoves as well as push() calls.
if love and love.physics then
  Trigger=timer
  dofile('engine/game/group.lua')
  for _, enemy_first in ipairs({false,true}) do
    Helper.Time.time=0
    local g=Group():set_as_physics_world(32,0,0,{'troop','enemy'})
    t=troop(); e=enemy('swarmer'); e.x=6
    t.id,t.tag=1,'troop'; e.id,e.tag=2,'enemy'
    g.objects.by_id[1],g.objects.by_id[2]=t,e
    local function body(o,r)
      o.body=love.physics.newBody(g.world,o.x,o.y,'dynamic')
      o.fixture=love.physics.newFixture(o.body,love.physics.newCircleShape(r),1)
      o.fixture:setUserData(o.id); o.body:setMass(1); o.body:setFixedRotation(true)
    end
    if enemy_first then body(e,5); body(t,2.5) else body(t,2.5); body(e,5) end
    t.push=Troop.push -- Exercise the production knockback helper against Box2D.
    e.body:setLinearVelocity(-20,0)
    g.world:update(1/60)
    assert(t.body:getLinearVelocity()<0 and t.body:getX()<0, 'player should move away from the swarmer')
    t.t:flush(); e.t:flush()
    near(t.hp,120); assert(not e.dead and e.body:getLinearVelocity()>0)
    for _=1,10 do g.world:update(1/60); t.t:flush(); e.t:flush() end
    assert(t.body:getLinearVelocity()<0); near(t.hp,120)
    g.world:destroy()
  end
  print('swarmer_contact: real Box2D player knockback and swarmer recoil passed')
end
print('swarmer_contact: callback order, recoil, cooldowns, special threats, and HP audit passed')
-- Run: luajit tests/level_orb.lua. A LÖVE harness also checks actual sensors.
dofile('engine/game/object.lua')
dofile('engine/math/math.lua')
dofile('engine/datastructures/table.lua')
dofile('engine/graphics/color.lua')
system={load_stats=function() end,save_run=function() end}
dofile('game_constants.lua')
dofile('combat_stats/combat_stats.lua')
dofile('spawns/levelmanager.lua')
local serial=0
local function noop() end
local function timer() return {update=noop,cancel=noop,after=noop,tween=noop} end
GameObject={init_game_object=function(self,args)
  for k,v in pairs(args) do self[k]=v end
  serial=serial+1; self.id=serial; self.t=timer()
  if self.group.add then self.group:add(self) end
end,update_game_object=noop}
dofile('engine/game/physics.lua')
local real_circle=Physics.set_as_circle
do -- Constructor-only fixtures first; the optional physics check restores this method.
  Physics.set_as_circle=function(self,r,kind,tag)
    self.shape={rs=r,w=r*2,h=r*2}; self.tag=tag
    self.fixture={setSensor=function(_,value) self.sensor_enabled=value end}
  end
end
Unit=Object:extend()
dofile('enemies/enemy.lua')
dofile('ui/level_orb.lua')
dofile('level_classes/arena.lua')
Helper={Time={time=0}}
dofile('spawns/spawnmanager.lua')
orange={[0]=Color('#efa17e')}; red={[3]=Color('#e91d39')}
Set_Enemy_Shape=noop
dofile('enemies/regular/tank.lua')
hit1={play=noop}; camera={shake=noop}; Text2=function(args) return args end
Helper={Unit={all_troops_are_dead=function() return false end},Target={}}
Helper.Target.get_closest_enemy=function() return {is_troop=true} end
Helper.Target.get_random_enemy=Helper.Target.get_closest_enemy
random={float=function(_,lo,hi) return hi end}
star_group={update=noop}
local effects=0
HitCircle=function(args)
  assert(not args.group.world or not args.group.world:isLocked())
  effects=effects+1
end
HitParticle=noop
local function arena(level)
  local a=setmetatable({level=level or 1,offset_x=0,offset_y=0,t=timer(),damage_taken=0,wins=0},Arena)
  a.main={enemies={},update=noop}
  a.main.get_objects_by_classes=function(self)
    local alive={}; for _,e in ipairs(self.enemies) do if not e.dead then alive[#alive+1]=e end end
    return alive
  end
  a.floor,a.post_main,a.effects,a.ui={update=noop},{update=noop},{update=noop},{update=noop}
  a.spawn_manager=setmetatable({arena=a,state='waiting_for_clear',pending_spawns=0},SpawnManager)
  a.level_clear=function(self) assert(not self.died); self.wins=self.wins+1 end
  main={current={enemies={Enemy},current_arena=a,main=a.main}}
  return a
end
local function swarmer(a,kind,fraction)
  local e=setmetatable({type=kind or 'swarmer',class='regular_enemy',group=a.main,
    x=gw/2+5,y=gh/2,hp=100*(fraction or 1),max_hp=100,dmg=10,death_count=0,
    die=function(self)
      assert(not self.group.world or not self.group.world:isLocked())
      self.dead=true; self.death_count=self.death_count+1
    end},Enemy)
  if a.main.enemies then table.insert(a.main.enemies,e) end
  return e
end
local function near(a,b) assert(math.abs(a-b)<0.0001,tostring(a)..' ~= '..tostring(b)) end
gw,gh=480,270
-- Creation is centered in the owning arena; all configured bosses omit it.
for _,level in ipairs({0,6,11,16}) do
  local a=arena(level); a:create_level_orb(); assert(not a.level_orb and not a.main.level_orb)
end
local a=arena(); a.offset_x=480; a:create_level_orb()
local orb=a.level_orb
assert(orb.x==720 and orb.y==135 and orb.hp==100 and a.main.level_orb==orb)
local e=swarmer(a)
assert(e:acquire_target_seek() and e.target==orb)
e.type='hunter_swarmer'; assert(e:acquire_target_seek() and e.target==orb)
e.type='tank'
for k,v in pairs(enemy_to_class.tank) do e[k]=v end
e:init_enemy()
assert(e:acquire_target_seek() and e.target==orb and e.knockback_immune)
e.type='swarmer'; orb.dead=true; assert(not e:acquire_target_seek() and not e.target)
orb.dead=false; a.main.level_orb=nil; assert(e:acquire_target_seek() and e.target.is_troop)
a.main.level_orb=orb

-- Duplicate sensor contacts deal one hit, outside the physics callback.
e=swarmer(a); orb:on_trigger_enter(e); orb:on_trigger_enter(e)
assert(orb.hp==100 and not e.dead and #orb.pending_contacts==1)
orb:resolve_contacts(); assert(orb.hp==90 and e.dead and e.death_count==1 and effects==1)
orb:on_trigger_enter(e); orb:resolve_contacts(); assert(orb.hp==90 and effects==1)
-- Dead sacrifices cannot act or draw while awaiting the group's cleanup.
e:update(0.01); e:draw()
e=swarmer(a,'hunter_swarmer',0.5); orb:on_trigger_enter(e); orb:resolve_contacts(); near(orb.hp,85)
-- A swarmer shot before the queued impact cannot hurt the orb.
e=swarmer(a); orb:on_trigger_enter(e); e.dead=true; orb:resolve_contacts(); near(orb.hp,85)
-- Specials, bosses, and projectiles do not damage the objective.
for _,kind in ipairs({'dart','stompy','projectile'}) do
  e=swarmer(a,kind); orb:on_trigger_enter(e); orb:resolve_contacts(); assert(not e.dead)
end
near(orb.hp,85)
for _,state in ipairs({'arena_start','suction_to_targets','finished'}) do
  a.spawn_manager.state=state; e=swarmer(a); orb:on_trigger_enter(e); orb:resolve_contacts()
  assert(not e.dead and orb.hp==85)
end

-- Tanks also sacrifice themselves at the orb, using their heavier damage.
local tank_arena=arena(); tank_arena:create_level_orb()
local tank=swarmer(tank_arena,'tank',0.5); tank.dmg=SPECIAL_ENEMY_DAMAGE
local tank_orb=tank_arena.level_orb
tank_orb:on_trigger_enter(tank); tank_orb:resolve_contacts()
near(tank_orb.hp,86); assert(tank.dead and tank.death_count==1)

-- Arena update resolves a fatal last-enemy impact before the clear check.
a=arena(); a:create_level_orb(); orb=a.level_orb; orb.hp=5
e=swarmer(a)
a.main.update=function() orb:on_trigger_enter(e) end
Arena.update(a,0.01)
assert(orb.dead and orb.hp==0 and a.died and a.loss_reason=='orb' and e.dead)
assert(a.wins==0 and a.spawn_manager.state=='finished')
assert(a.died_text.lines[1].text:find('orb destroyed',1,true))
near(a.damage_taken,5)
orb:hit(100); assert(a.damage_taken==5)
-- Surviving the final sacrifice allows normal progression.
a=arena(); a:create_level_orb(); orb=a.level_orb; e=swarmer(a)
a.main.update=function() orb:on_trigger_enter(e) end
Arena.update(a,0.01)
assert(orb.hp==90 and a.wins==1 and not a.died)
-- A cleared level cannot be killed by lingering contacts.
a.level_cleared=true; e=swarmer(a); orb:on_trigger_enter(e); orb:resolve_contacts()
assert(orb.hp==90 and not e.dead)
-- Loss in the spawning phase also stops the director immediately.
a=arena(); a.died=true; a.spawn_manager.state='spawning'
a.spawn_manager:update(0.1); assert(a.spawn_manager.state=='finished')

if love and love.physics then
  -- Use the actual arena collision masks and both enemy fixtures.
  Trigger=timer; State={}; main_after_characters={}; full_res_draws={}
  dofile('engine/game/group.lua')
  Circle=function(x,y,r) return {x=x,y=y,rs=r,w=2*r,h=2*r} end
  -- Constructor tests above did not need a world; use real fixtures here.
  Physics.set_as_circle=real_circle; LevelOrb.set_as_circle=real_circle
  a=arena(); a:init_physics(); a:create_level_orb(); orb=a.level_orb
  e=swarmer(a); serial=serial+1; e.id=serial; a.main:add(e)
  e.body=love.physics.newBody(a.main.world,orb.x+5,orb.y,'dynamic')
  e.fixture=love.physics.newFixture(e.body,love.physics.newCircleShape(3))
  e.fixture:setUserData(e.id); e.fixture:setCategory(a.main.collision_tags.enemy.category)
  e.sensor=love.physics.newFixture(e.body,love.physics.newCircleShape(3))
  e.sensor:setUserData(e.id); e.sensor:setSensor(true)
  a.main.world:update(1/60)
  assert(orb.hp==100 and #orb.pending_contacts==1 and not e.dead)
  orb:resolve_contacts(); assert(orb.hp==90 and e.dead and e.death_count==1)
  near(e.body:getX(),orb.x+5)
  a.main.world:destroy()
  print('level_orb: real sensor filtering, duplicate contacts, and deferred impact passed')
end
print('level_orb: normal/boss creation, target priority, damage, cleanup, and loss-before-clear passed')
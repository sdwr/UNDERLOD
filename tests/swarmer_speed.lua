-- Run: luajit tests/swarmer_speed.lua
local function noop() end
dofile('engine/game/object.lua')
dofile('engine/math/math.lua')
system = {load_stats = noop}
dofile('game_constants.lua')
dofile('combat_stats/combat_stats.lua')
Unit = Object:extend(); Unit.update = noop
GameObject, Physics = {}, {}
dofile('enemies/enemy.lua')
dofile('enemies/regular/swarmer.lua')
dofile('enemies/regular/hunter_swarmer.lua')
gw, gh = 480, 270
Helper = {Target = {is_in_camera_bounds = function() return false end,
  is_fully_in_camera_bounds = noop, way_inside_camera_bounds = noop},
  Unit = {teams = {{troops = {{x=0,y=0}}}}}}
local function near(a,b) assert(math.abs(a-b)<0.0001, tostring(a)..' ~= '..tostring(b)) end
local orb = {x=720,y=405}
for _, kind in ipairs({'swarmer','hunter_swarmer'}) do
  for _, variant in ipairs({'normal','poison','exploder','mini'}) do
    local e = {type=kind, group={level_orb=orb}, y=orb.y,
      mini_swarmer=variant=='mini', special_swarmer_type=variant}
    local ratio = enemy_to_class[kind].get_proximity_speed_ratio
    for _, sample in ipairs({{0,0.5},{20,0.5},{50,0.75},{80,1},{100,1},
      {135,1},{202.5,1.5},{270,2},{400,2}}) do
      e.x = orb.x + sample[1]; near(ratio(e),sample[2])
      -- Troop proximity must not affect the result.
      Helper.Unit.teams[1].troops[1].x = e.x
      Helper.Unit.teams[1].troops[1].y = e.y
      near(ratio(e),sample[2])
    end
    e.x,e.y=orb.x,orb.y+202.5; near(ratio(e),1.5)
    orb.dead=true; near(ratio(e),1); orb.dead=false
    e.group.level_orb=nil; near(ratio(e),1)
  end
end
-- Exercise the actual Enemy update: offscreen entry must not stack with
-- the orb multiplier, while enemies in orb-free arenas retain entry speed.
local e=setmetatable({type='swarmer', class='regular_enemy', x=-30,y=135,
  group={level_orb={x=240,y=135}}, random_dest_timer=0, transition_active=false,
  get_proximity_speed_ratio=Get_Swarmer_Orb_Speed_Ratio,
  calculate_stats=function(self) self.max_v=10 end}, Enemy)
for _, key in ipairs({'update_cast_cooldown','onTickCallbacks','update_buffs',
  'update_status_particles','update_animation'}) do e[key]=noop end
e:update(0.01); near(e.max_v,20)
e.x=220; e:update(0.01); near(e.max_v,5)
e.x=-30; e.entered_screen=nil; e.group.level_orb=nil
e:update(0.01); near(e.max_v,10*ENEMY_ENTRY_SPEED_MULT)
print('swarmer speed: orb distance curve, all variants, troop independence, boss fallback, and no stacked entry boost passed')
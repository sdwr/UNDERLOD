-- Run from the repository root: luajit tests/dart_target.lua
-- Exercise the real enemy movement dispatch and dart-specific target lock.
dofile('engine/game/object.lua')
dofile('engine/math/math.lua')
dofile('engine/graphics/color.lua')
Unit = Object:extend(); GameObject, Physics = {}, {}
dofile('enemies/enemy.lua')
orange = {[5] = Color('#efa17e')}; red = {[0] = Color('#e91d39')}
MOVEMENT_TYPE_SEEK, SEEK_DECELERATION = 'seek', 1
get_seek_weight_by_enemy_type = function() return 1 end
Set_Enemy_Shape = function() end
Circle = function(x,y,r) return {x=x,y=y,r=r} end
main = {current = {friendlies = {}}}
Helper = {Unit = {teams = {}}}
local rings = {}
graphics = {circle = function(x,y,r,color,width)
  rings[#rings+1] = {x=x,y=y,r=r,color=color,width=width}
end}
dofile('enemies/regular/dart.lua')
local dart = setmetatable({x=0,y=0,size=10,state_always_run_functions={},
  get_objects_in_shape=function() return {} end,
  seek_point=function(self,x,y) self.seek_x,self.seek_y=x,y end,
  rotate_towards_velocity=function() end,
},Enemy)
for k,v in pairs(enemy_to_class.dart) do dart[k]=v end
dart:init_enemy()
dart.currentMovementAction=MOVEMENT_TYPE_SEEK

-- An empty arena is safe; target acquisition begins when troops are present.
assert(not dart:choose_movement_target()); dart:draw_ground(); assert(#rings==0)
local first={x=40,y=10,display_size=14}
local second={x=100,y=10,display_size=14}
Helper.Unit.teams={{troops={first}},{troops={second}}}
dart.state_always_run_functions.always_run(dart)
assert(dart.target==first and dart.dart_target==first)
dart:draw_ground()
assert(#rings==1 and rings[1].x==40 and rings[1].y==10)
assert(math.abs(rings[1].r-6.6)<0.0001 and rings[1].width==1)
assert(rings[1].color.r>rings[1].color.g and rings[1].color.a==0.8)

-- A closer troop must not steal the lock when the action timer restarts.
second.x=1; first.x,first.y=70,20
assert(dart:choose_movement_target() and dart.target==first)
-- Generic target cleanup also must not discard the dart's lock.
dart.target=nil
assert(dart:update_move_seek() and dart.target==first)
assert(dart.seek_x==70 and dart.seek_y==20)
dart:draw_ground(); assert(rings[2].x==70 and rings[2].y==20)

-- Reticles vanish immediately on death; only then may another troop be chosen.
first.dead=true
dart:draw_ground(); assert(#rings==2)
assert(dart:choose_movement_target() and dart.target==second)
dart:draw_ground(); assert(#rings==3 and rings[3].x==1)
dart.exploded=true; dart:draw_ground(); assert(#rings==3)
dart.exploded=false; dart.dead=true; dart:draw_ground(); assert(#rings==3)
dart.dead=false; second.dead=true
assert(not dart:choose_movement_target() and not dart.target and not dart.dart_target)
assert(not dart:update_move_seek())
dart:draw_ground(); assert(#rings==3)
print('dart_target: acquisition, stable lock, movement restarts, marker tracking, death, and cleanup passed')
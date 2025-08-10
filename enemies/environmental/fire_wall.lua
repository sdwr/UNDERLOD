
--put these in the floor group
--so they are drawn under the player
--and get cleaned up when the floor is cleared
Fire_Wall = Object:extend()
Fire_Wall.__class_name = 'Fire_Wall'
Fire_Wall:implement(GameObject)
Fire_Wall:implement(Physics)
function Fire_Wall:init(args)
  self:init_game_object(args)
  self:init_physics(args)

  self:set_as_rectangle(60, 60, 'static', 'enemy')
  self:set_restitution(0.1)
  self:set_as_steerable(self.v, 1000, 2*math.pi, 2)

  self.color = red[0]:clone()
  
  --passed in args
  --should be set in init_game_object, but just want to make them explicit

  self.cooldown = args.cooldown or 1
  self.damage = args.damage or 20
  self.nextTick = 0
end

function Fire_Wall:update(dt)
  self:update_game_object(dt)
  self:update_physics(dt)
end

function Fire_Wall:draw()
  self:draw_game_object()
  self:draw_physics()
end
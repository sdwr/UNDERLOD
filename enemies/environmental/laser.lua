
--put these in the floor group
--so they are drawn under the player
--and get cleaned up when the floor is cleared
Laser_Hazard = Object:extend()
Laser_Hazard:implement(GameObject)
Laser_Hazard:implement(Physics)
function Laser_Hazard:init(args)
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

function Laser_Hazard:update(dt)
  self:update_game_object(dt)
  self:update_physics(dt)
end

function Laser_Hazard:draw()
  self:draw_game_object()
  self:draw_physics()
end
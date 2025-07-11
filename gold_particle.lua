GoldParticle = Object:extend()
GoldParticle:implement(GameObject)
GoldParticle:implement(Physics)
function GoldParticle:init(args)
  self:init_game_object(args)
  
  -- Particle properties
  self.target_x = args.target_x
  self.target_y = args.target_y
  self.amount = args.amount or 1
  self.parent = args.parent
  
  -- Physics setup
  self:set_as_circle(3, 'dynamic', 'effect')
  self:set_as_steerable(200, 1000, 4*math.pi, 4)
  
  -- Visual properties
  self.color = yellow[0]
  self.duration = 2.0
  self.elapsed = 0
  
  -- Calculate direction to target
  local dx = self.target_x - self.x
  local dy = self.target_y - self.y
  local distance = math.sqrt(dx*dx + dy*dy)
  
  if distance > 0 then
    -- Set initial velocity towards target
    local speed = 150
    self:set_velocity(dx/distance * speed, dy/distance * speed)
  end
end

function GoldParticle:update(dt)
  self:update_game_object(dt)
  self.elapsed = self.elapsed + dt
  
  -- Seek towards target
  self:seek_point(self.target_x, self.target_y, 2.0, 3.0)
  
  -- Check if we've reached the target
  local distance_to_target = math.distance(self.x, self.y, self.target_x, self.target_y)
  if distance_to_target < 10 or self.elapsed > self.duration then
    -- Arrived at target, give gold to parent
    if self.parent then
      self.parent:receive_gold(self.amount)
    end
    self:die()
  end
end

function GoldParticle:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, 3, self.color)
  graphics.pop()
end 

function GoldParticle:die()
  self.dead = true
end
GoldCounter = Object:extend()
GoldCounter:implement(GameObject)
function GoldCounter:init(args)
  self:init_game_object(args)
  
  -- Gold counter properties
  self.x = args.x or 60
  self.y = args.y or 30
  self.color = yellow[0]
  self.text = nil
  
  self.offset_x = args.offset_x or 0
  self.offset_y = args.offset_y or 0
  
  -- Update the display
  self:update_display()
end

function GoldCounter:update(dt)
  self:update_game_object(dt)
  
  -- Check if arena offset has changed and update display if needed
  local current_offset_x = 0
  local current_offset_y = 0
  if self.parent and self.parent.offset_x and self.parent.offset_x ~= self.offset_x then
    self.offset_x = self.parent.offset_x
    self:update_display()
  end
  if self.parent and self.parent.offset_y and self.parent.offset_y ~= self.offset_y then
    self.offset_y = self.parent.offset_y
    self:update_display()
  end
  
end

function GoldCounter:update_display()
  -- Create text showing current gold
  if self.text then
    self.text.dead = true
  end

  -- self.text = Text2{
  --   group = main.current.world_ui, 
  --   x = self.x + self.offset_x, 
  --   y = self.y + self.offset_y, 
  --   lines = {{text = '[wavy_mid, fg]gold: [yellow]' .. tostring(gold), font = pixul_font, alignment = 'left'}}
  -- }
end

function GoldCounter:add_gold(amount, source_x, source_y)
  -- Create gold particle that flies to the counter
  GoldParticle{
    group = main.current.main,
    x = source_x,
    y = source_y,
    target_x = self.x,
    target_y = self.y,
    amount = amount,
    parent = self
  }
end

function GoldCounter:receive_gold(amount)
  -- Update global gold
  gold = gold + amount
  
  -- Update display
  self:update_display()
  
  -- Play sound
  gold2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  
  -- Create particles at the counter
  for i = 1, 5 do
    HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
  end
end

function GoldCounter:draw()
  -- The text is drawn by the UI group, so we don't need to draw anything here
end 


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
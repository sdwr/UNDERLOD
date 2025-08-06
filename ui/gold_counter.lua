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

  self.previous_gold = gold

  self.sound_cooldown = 0.5
  self.sound_cooldown_timer = 0
  
  -- Update the display
  self:update_display()
end

function GoldCounter:update(dt)
  self:update_game_object(dt)

  if self.sound_cooldown_timer > 0 then
    self.sound_cooldown_timer = self.sound_cooldown_timer - dt
  end
  
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

  if self.previous_gold ~= gold then
    self.previous_gold = gold
    self:update_display()
  end
end

function GoldCounter:update_display()
  -- Create text showing current gold
  self:hide_display()

  self.text = Text2{
    group = self.group, 
    x = self.x + self.offset_x, 
    y = self.y + self.offset_y, 
    lines = {{text = '[wavy_mid, fg]gold: [yellow]' .. tostring(math.floor(gold)), font = pixul_font, alignment = 'left'}}
  }
end

function GoldCounter:hide_display()
  if self.text then
    self.text.dead = true
    self.text = nil
  end
end

function GoldCounter:add_round_power(round_power, source_x, source_y)
  local level = self.parent.level
  local level_list = self.parent.level_list

  if not level then return end
  if not level_list then return end

  local total_round_gold = GOLD_GAINED_BY_LEVEL[level] or 10
  local total_round_power = level_list[level].round_power or 500
  
  local percent_of_round_power = (round_power * 1.0) / total_round_power
  local gold_to_add = percent_of_round_power * total_round_gold

  if math.floor(gold) < math.floor(gold + gold_to_add + .0001) then
    self:create_gold_particle(gold_to_add, source_x, source_y)
  else
    self:add_gold(gold_to_add)
  end
end

function GoldCounter:create_gold_particle(amount, source_x, source_y)
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

function GoldCounter:receive_gold_particle(amount)

  self:add_gold(amount)
  
  -- Play sound
  if self.sound_cooldown_timer <= 0 then
    gold2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.sound_cooldown_timer = self.sound_cooldown
  end
  
  -- Create particles at the counter
  for i = 1, 5 do
    HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
  end
end

function GoldCounter:add_gold(amount)
  -- Update global gold
  gold = gold + amount

  if math.floor(gold + .0001) ~= math.floor(gold) then
    gold = math.floor(gold + .0001)
  end
  
  -- Update display
  self:update_display()
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
      self.parent:receive_gold_particle(self.amount)
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
GoldCounter = Object:extend()
GoldCounter:implement(GameObject)
function GoldCounter:init(args)
  self:init_game_object(args)
  
  -- Gold counter properties
  self.x = args.x or 60
  self.y = args.y or 30
  self.color = yellow[0]
  self.text = nil
  
  -- Update the display
  self:update_display()
end

function GoldCounter:update(dt)
  self:update_game_object(dt)
  
  -- Check if arena offset has changed and update display if needed
  local current_offset_x = 0
  local current_offset_y = 0
  if main.current and main.current.offset_x then
    current_offset_x = main.current.offset_x
    current_offset_y = main.current.offset_y
  end
  
  if self.last_offset_x ~= current_offset_x or self.last_offset_y ~= current_offset_y then
    self.last_offset_x = current_offset_x
    self.last_offset_y = current_offset_y
    self:update_display()
  end
end

function GoldCounter:update_display()
  -- Create text showing current gold
  if self.text then
    self.text.dead = true
  end
  
  -- Get arena offset if available
  local offset_x = 0
  local offset_y = 0
  if main.current and main.current.offset_x then
    offset_x = main.current.offset_x
    offset_y = main.current.offset_y
  end
  
  self.text = Text2{
    group = main.current.world_ui, 
    x = self.x + offset_x, 
    y = self.y + offset_y, 
    lines = {{text = '[wavy_mid, fg]gold: [yellow]' .. tostring(gold), font = pixul_font, alignment = 'left'}}
  }
end

function GoldCounter:add_gold(amount, source_x, source_y)
  -- Get arena offset if available
  local offset_x = 0
  local offset_y = 0
  if main.current and main.current.offset_x then
    offset_x = main.current.offset_x
    offset_y = main.current.offset_y
  end
  
  -- Create gold particle that flies to the counter
  GoldParticle{
    group = main.current.main,
    x = source_x,
    y = source_y,
    target_x = self.x + offset_x,
    target_y = self.y + offset_y,
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
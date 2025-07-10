Door = Object:extend()
Door:implement(GameObject)
Door:implement(Physics)
function Door:init(args)
  self:init_game_object(args)

  
  -- Door properties
  self.x = args.x or gw - 50
  self.y = args.y or gh/2
  self.width = args.width or 40
  self.height = args.height or 80
  self.color = args.color or green[0]
  
  self:set_as_rectangle(self.width, self.height, 'static', 'door', true) -- true makes it a sensor/trigger
  
  -- Door state
  self.is_open = false
  self.animation_progress = 0
  self.animation_duration = 2.0  -- Changed to 2 seconds
    
  -- Door appearance
  self.door_color = green[0]:clone()
  self.glow_color = green[5]:clone()
  
  -- Pulse effect properties
  self.pulse_timer = 0
  self.pulse_duration = 5.0  -- 1 second per pulse cycle
  self.pulse_intensity = 0.2  -- Base pulse intensity
  
  -- Sound effect
  self.open_sound_played = false
end

function Door:update(dt)
  self:update_game_object(dt)
  
  -- Update animation
  if self.is_open then
    self.animation_progress = math.min(self.animation_progress + dt / self.animation_duration, 1)
  end
  
  -- Update pulse effect
  if self.is_open then
    self.pulse_timer = self.pulse_timer + dt
    if self.pulse_timer >= self.pulse_duration then
      self.pulse_timer = 0
    end
  end
end

function Door:open()
  self.is_open = true
  
  -- Play open sound
  if not self.open_sound_played then
    door_open:play{pitch = random:float(0.9, 1.1), volume = 3.5}
    self.open_sound_played = true
  end
  
  -- Create opening effect
  for i = 1, 10 do
    local angle = random:float(0, math.pi * 2)
    local distance = random:float(20, 40)
    local px = self.x + math.cos(angle) * distance
    local py = self.y + math.sin(angle) * distance
    HitParticle{group = main.current.effects, x = px, y = py, color = self.glow_color}
  end
end

function Door:draw()
  if self.is_open then
    -- Calculate fade-in alpha over 2 seconds
    local alpha = self.animation_progress
    local door_color = self.door_color:clone()
    door_color.a = alpha
    
    -- Calculate rhythmic pulse effect
    local pulse_progress = self.pulse_timer / self.pulse_duration
    local pulse_alpha = 0.3 + (self.pulse_intensity * math.sin(pulse_progress * math.pi * 2))
    local glow_color = self.glow_color:clone()
    glow_color.a = alpha * pulse_alpha
    
    graphics.push(self.x, self.y, 0, 1, 1)
    graphics.rectangle(self.x, self.y, self.width, self.height, 3, 3, door_color)
    
    -- Draw pulsing glow effect
    graphics.rectangle(self.x, self.y, self.width + 8, self.height + 8, 3, 3, glow_color)
    graphics.pop()
  else
    -- -- Draw closed door
    -- graphics.push(self.x, self.y, 0, 1, 1)
    -- -- Draw door frame
    -- graphics.rectangle(self.x, self.y, self.width + 4, self.height + 4, 3, 3, bg[-1])
    -- graphics.rectangle(self.x, self.y, self.width, self.height, 3, 3, self.door_color)
    
    -- graphics.pop()
  end
end

function Door:on_trigger_enter(other, contact)
  -- Check if a player unit is touching the door
  if self.is_open and other:is(Troop) then
    -- Advance to next level
    if main.current then
      main.current:advance_to_next_level()
    end
  end
end 
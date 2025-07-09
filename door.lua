Door = Object:extend()
Door:implement(GameObject)
Door:implement(Physics)
function Door:init(args)
  self:init_game_object(args)

  self:set_as_rectangle(self.width, self.height, 'static', 'door')
  
  -- Door properties
  self.x = args.x or gw - 50
  self.y = args.y or gh/2
  self.width = args.width or 40
  self.height = args.height or 80
  self.color = args.color or green[0]
  
  -- Door state
  self.is_open = false
  self.animation_progress = 0
  self.animation_duration = 1.0
    
  -- Door appearance
  self.door_color = green[0]:clone()
  self.glow_color = green[5]:clone()
  
  -- Sound effect
  self.open_sound_played = false
end

function Door:update(dt)
  self:update_game_object(dt)
  
  -- Update animation
  if self.is_open then
    self.animation_progress = math.min(self.animation_progress + dt / self.animation_duration, 1)
  end
end

function Door:open()
  print('open door')
  self.is_open = true
  
  -- Play open sound
  if not self.open_sound_played then
    magic_hit1:play{pitch = random:float(0.9, 1.1), volume = 0.8}
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
    -- Draw open door (transparent)
    local alpha = self.animation_progress
    local door_color = self.door_color:clone()
    door_color.a = alpha
    
    graphics.push(self.x, self.y, 0, 1, 1)
    graphics.rectangle(self.x, self.y, self.width, self.height, 3, 3, door_color)
    
    -- Draw glow effect
    local glow_alpha = alpha * 0.5
    local glow_color = self.glow_color:clone()
    glow_color.a = glow_alpha
    
    graphics.rectangle(self.x, self.y, self.width + 10, self.height + 10, 3, 3, glow_color)
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

function Door:on_collision_enter(other, contact)
  -- Check if a player unit is touching the door
  if self.is_open and Troop:is(other) then
    -- Advance to next level
    if main.current then
      main.current:advance_to_next_level()
    end
  end
end 
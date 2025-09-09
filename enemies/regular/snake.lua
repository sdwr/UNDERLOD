local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  
  -- Create shape
  self.color = purple[-2]:clone()
  Set_Enemy_Shape(self, self.size)
  
  self.class = 'special_enemy'
  self.icon = 'snake'
    
  -- Movement behavior
  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true
  
  -- Snake-specific variables
  self.snake_segments = 8  -- Number of segments for visual trail
  self.segment_history = {}  -- Store past positions for segments
  self.segment_spacing = 4  -- Distance between segments
  self.wave_amplitude = 10  -- How much the snake wiggles
  self.wave_frequency = 3  -- How fast it wiggles
  self.wave_phase = random:float(0, math.pi * 2)  -- Random starting phase
  
  -- Initialize segment history
  for i = 1, self.snake_segments do
    table.insert(self.segment_history, {x = self.x, y = self.y})
  end
end

fns['update'] = function(self, dt)
  -- Store current position for trail
  table.insert(self.segment_history, 1, {x = self.x, y = self.y})
  
  -- Keep only the positions we need
  while #self.segment_history > self.snake_segments * self.segment_spacing do
    table.remove(self.segment_history)
  end
  
  -- Update wave phase for wiggling motion
  self.wave_phase = self.wave_phase + dt * self.wave_frequency
end

fns['attack'] = function(self)
  -- Snake doesn't attack, it just moves towards the orb
end

fns['draw_enemy'] = function(self)
  -- Draw the snake body segments
  local segments_to_draw = {}
  
  -- Add head position
  table.insert(segments_to_draw, self.x)
  table.insert(segments_to_draw, self.y)
  
  -- Add body segments from history
  for i = 1, self.snake_segments - 1 do
    local index = i * self.segment_spacing
    if self.segment_history[index] then
      local segment = self.segment_history[index]
      
      -- Add perpendicular wiggle offset
      local dx = self.x - segment.x
      local dy = self.y - segment.y
      local length = math.sqrt(dx * dx + dy * dy)
      
      if length > 0.1 then
        local perp_x = -dy / length
        local perp_y = dx / length
        
        -- Calculate wiggle offset based on segment position
        local t = i / self.snake_segments
        local offset = math.sin(self.wave_phase - t * math.pi * 2) * self.wave_amplitude * (1 - t * 0.5)
        
        local wiggled_x = segment.x + perp_x * offset
        local wiggled_y = segment.y + perp_y * offset
        
        table.insert(segments_to_draw, wiggled_x)
        table.insert(segments_to_draw, wiggled_y)
      else
        table.insert(segments_to_draw, segment.x)
        table.insert(segments_to_draw, segment.y)
      end
    end
  end
  
  -- Draw the snake as a continuous line if we have enough points
  if #segments_to_draw >= 4 then
    -- Draw main body line
    graphics.polyline(self.color, 4, unpack(segments_to_draw))
    
    -- Draw secondary inner line for depth
    local inner_color = self.color:clone()
    inner_color.a = 0.6
    graphics.polyline(inner_color, 2, unpack(segments_to_draw))
  end
  
  -- Draw head as a circle
  graphics.circle(self.x, self.y, self.shape.w / 2, self.color)
  
  -- Draw eyes
  local eye_color = white[0]:clone()
  eye_color.a = 0.8
  local eye_size = 2
  local eye_offset = self.shape.w / 3
  
  -- Calculate eye positions based on movement direction
  local vx, vy = self:get_velocity()
  local speed = math.sqrt(vx * vx + vy * vy)
  if speed > 0.1 then
    local dir_x = vx / speed
    local dir_y = vy / speed
    local perp_x = -dir_y
    local perp_y = dir_x
    
    graphics.circle(self.x + dir_x * 2 + perp_x * eye_offset, 
                   self.y + dir_y * 2 + perp_y * eye_offset, 
                   eye_size, eye_color)
    graphics.circle(self.x + dir_x * 2 - perp_x * eye_offset, 
                   self.y + dir_y * 2 - perp_y * eye_offset, 
                   eye_size, eye_color)
  end
  
  -- Apply status effect overlays if needed
  self:draw_fallback_status_effects()
end

enemy_to_class['snake'] = fns
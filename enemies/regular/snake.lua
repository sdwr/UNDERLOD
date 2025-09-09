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

fns['update_enemy'] = function(self, dt)
  -- Only store position if we've moved enough
  local last_pos = self.segment_history[1]
  if not last_pos or math.distance(self.x, self.y, last_pos.x, last_pos.y) > 2 then
    -- Store current position for trail
    table.insert(self.segment_history, 1, {x = self.x, y = self.y})
    
    -- Keep only the positions we need for all segments
    while #self.segment_history > self.snake_segments * self.segment_spacing do
      table.remove(self.segment_history)
    end
  end
  
  -- Update wave phase for wiggling motion
  self.wave_phase = self.wave_phase + dt * self.wave_frequency
end

fns['draw_enemy'] = function(self)
  -- Build segments from history
  local segments = {}
  
  -- Start with head
  table.insert(segments, {x = self.x, y = self.y})
  
  -- Add body segments from history 
  for i = 1, math.min(#self.segment_history, self.snake_segments - 1) do
    local index = i * self.segment_spacing
    if index <= #self.segment_history and self.segment_history[index] then
      table.insert(segments, self.segment_history[index])
    end
  end
  
  -- Only draw if we have enough segments
  if #segments >= 2 then
    -- Draw body segments as circles that get smaller
    for i = #segments, 2, -1 do
      local segment = segments[i]
      local size_ratio = 1 - ((i - 1) / #segments) * 0.4  -- Size decreases toward tail
      local radius = (self.shape.w / 2) * size_ratio
      
      -- Add wiggle offset
      local wiggle_x = 0
      local wiggle_y = 0
      if i > 1 and i < #segments then
        -- Get direction between this segment and next
        local next_seg = segments[i - 1]
        local dx = next_seg.x - segment.x
        local dy = next_seg.y - segment.y
        local length = math.sqrt(dx * dx + dy * dy)
        
        if length > 0.1 then
          -- Perpendicular to movement direction
          local perp_x = -dy / length
          local perp_y = dx / length
          
          local t = (i - 1) / (#segments - 1)
          local offset = math.sin(self.wave_phase - t * math.pi * 2) * self.wave_amplitude * (1 - t * 0.3)
          wiggle_x = perp_x * offset
          wiggle_y = perp_y * offset
        end
      end
      
      -- Draw segment circle
      local segment_color = self.color:clone()
      segment_color.a = 0.8 * (1 - (i - 1) / #segments * 0.3)  -- Fade toward tail
      graphics.circle(segment.x + wiggle_x, segment.y + wiggle_y, radius, segment_color)
    end
  end
  
  -- Draw head last (on top)
  graphics.circle(self.x, self.y, self.shape.w / 2, self.color)
  
  -- Draw eyes
  local eye_color = white[0]:clone()
  eye_color.a = 0.9
  local eye_size = 2
  local eye_offset = self.shape.w / 4
  
  -- Calculate eye positions based on movement direction
  local vx, vy = self:get_velocity()
  local speed = math.sqrt(vx * vx + vy * vy)
  if speed > 0.1 then
    local dir_x = vx / speed
    local dir_y = vy / speed
    local perp_x = -dir_y
    local perp_y = dir_x
    
    graphics.circle(self.x + dir_x * 3 + perp_x * eye_offset, 
                   self.y + dir_y * 3 + perp_y * eye_offset, 
                   eye_size, eye_color)
    graphics.circle(self.x + dir_x * 3 - perp_x * eye_offset, 
                   self.y + dir_y * 3 - perp_y * eye_offset, 
                   eye_size, eye_color)
  end
  
  -- Apply status effect overlays if needed
  self:draw_fallback_status_effects()
end

enemy_to_class['snake'] = fns
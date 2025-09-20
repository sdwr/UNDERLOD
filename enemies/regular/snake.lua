local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Set class before shape so Set_Enemy_Shape knows it's a special enemy
  self.class = 'special_enemy'

  -- Create shape
  self.color = purple[-2]:clone()
  Set_Enemy_Shape(self, self.size)
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
  -- Build path points from history
  local path_points = {}
  
  -- Start with head
  table.insert(path_points, {x = self.x, y = self.y})
  
  -- Add body segments from history 
  for i = 1, math.min(#self.segment_history, self.snake_segments - 1) do
    local index = i * self.segment_spacing
    if index <= #self.segment_history and self.segment_history[index] then
      local segment = self.segment_history[index]
      
      -- Add smooth curve offset using sine wave
      local wiggle_x = 0
      local wiggle_y = 0
      
      -- Only wiggle middle segments, not head or tail
      if i > 1 and i < self.snake_segments - 2 then
        -- Get direction for perpendicular offset
        local prev_index = math.max(1, index - self.segment_spacing)
        local next_index = math.min(#self.segment_history, index + self.segment_spacing)
        
        if self.segment_history[prev_index] and self.segment_history[next_index] then
          local dx = self.segment_history[next_index].x - self.segment_history[prev_index].x
          local dy = self.segment_history[next_index].y - self.segment_history[prev_index].y
          local length = math.sqrt(dx * dx + dy * dy)
          
          if length > 0.1 then
            -- Perpendicular to movement direction
            local perp_x = -dy / length
            local perp_y = dx / length
            
            -- Smooth sine wave for curves
            local t = i / self.snake_segments
            local offset = math.sin(self.wave_phase + t * math.pi * 3) * self.wave_amplitude * (1 - t * 0.5)
            wiggle_x = perp_x * offset
            wiggle_y = perp_y * offset
          end
        end
      end
      
      table.insert(path_points, {x = segment.x + wiggle_x, y = segment.y + wiggle_y})
    end
  end
  
  -- Only draw if we have enough points
  if #path_points >= 2 then
    -- Convert points to flat array for polyline
    local line_points = {}
    for i, point in ipairs(path_points) do
      table.insert(line_points, point.x)
      table.insert(line_points, point.y)
    end
    
    -- Draw main body line with varying thickness
    if #line_points >= 4 then
      -- Draw outer line (thicker)
      local outer_color = self.color:clone()
      outer_color.a = 0.7
      graphics.polyline(outer_color, 6, unpack(line_points))
      
      -- Draw inner line (thinner) for depth
      local inner_color = self.color:clone()
      inner_color.a = 0.9
      graphics.polyline(inner_color, 3, unpack(line_points))
    end
  end
  
  -- Draw head as a circle
  graphics.circle(self.x, self.y, self.shape.w / 2.5, self.color)
  
  -- Draw eyes
  local eye_color = white[0]:clone()
  eye_color.a = 0.9
  local eye_size = 2
  local eye_offset = self.shape.w / 5
  
  -- Calculate eye positions based on movement direction or next segment
  local dir_x, dir_y = 0, 0
  local vx, vy = self:get_velocity()
  local speed = math.sqrt(vx * vx + vy * vy)
  
  if speed > 0.1 then
    dir_x = vx / speed
    dir_y = vy / speed
  elseif #self.segment_history > 1 then
    -- Use direction to first segment if not moving
    dir_x = self.x - self.segment_history[1].x
    dir_y = self.y - self.segment_history[1].y
    local length = math.sqrt(dir_x * dir_x + dir_y * dir_y)
    if length > 0.1 then
      dir_x = dir_x / length
      dir_y = dir_y / length
    end
  end
  
  if dir_x ~= 0 or dir_y ~= 0 then
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
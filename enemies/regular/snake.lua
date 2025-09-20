local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Set class before shape so it uses the right collision tag
  self.class = 'special_enemy'
  self.icon = 'snake'

  -- Create shape
  self.color = purple[-2]:clone()
  Set_Enemy_Shape(self, self.size)
    
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

  -- Store spawn point for extending back to origin
  self.spawn_point = {x = self.x, y = self.y}
  self.extend_to_origin = true  -- Snake extends back to spawn point

  -- Initialize segment history
  for i = 1, self.snake_segments do
    table.insert(self.segment_history, {x = self.x, y = self.y})
  end

  -- Segment enemies for targeting
  self.segments = {}
  self.segment_spawn_distance = 30  -- Distance between targetable segments
  self.next_segment_distance = 0
  self.total_distance_traveled = 0
end

fns['update_enemy'] = function(self, dt)
  -- Track distance moved
  local last_pos = self.segment_history[1]
  local distance_moved = 0

  if last_pos then
    distance_moved = math.distance(self.x, self.y, last_pos.x, last_pos.y)
  end

  -- Only store position if we've moved enough
  if not last_pos or distance_moved > 2 then
    -- Store current position for trail
    table.insert(self.segment_history, 1, {x = self.x, y = self.y})

    -- Update total distance for segment spawning
    self.total_distance_traveled = self.total_distance_traveled + distance_moved
    self.next_segment_distance = self.next_segment_distance + distance_moved

    -- Keep history extending back to spawn if enabled
    if self.extend_to_origin then
      -- Don't remove history, let it grow to spawn point
    else
      -- Keep only the positions we need for all segments
      while #self.segment_history > self.snake_segments * self.segment_spacing do
        table.remove(self.segment_history)
      end
    end
  end

  -- Spawn segment enemies at intervals
  if self.next_segment_distance >= self.segment_spawn_distance then
    self.next_segment_distance = 0
    self:spawn_segment()
  end

  -- Update existing segments to follow the path
  self:update_segments()

  -- Update wave phase for wiggling motion
  self.wave_phase = self.wave_phase + dt * self.wave_frequency
end

fns['spawn_segment'] = function(self)
  -- Don't spawn too many segments
  if #self.segments >= 20 then return end

  -- Get position from history for this segment
  local segment_index = #self.segments + 1
  local history_index = segment_index * 10  -- Space them out in history

  if history_index <= #self.segment_history then
    local pos = self.segment_history[history_index]

    -- Create a segment enemy at this position
    local segment = Enemy{
      type = 'snake_segment',
      group = main.current.main,
      x = pos.x,
      y = pos.y,
      level = self.level,
      data = {
        parent_snake = self,
        segment_index = segment_index,
        spawn_point = self.spawn_point
      }
    }

    table.insert(self.segments, segment)
  end
end

fns['update_segments'] = function(self)
  -- Update each segment to follow the snake's path
  for i, segment in ipairs(self.segments) do
    if segment and not segment.dead then
      local history_index = (i + 1) * 10  -- Space them out

      if history_index <= #self.segment_history then
        local target_pos = self.segment_history[history_index]
        -- Directly set position since special enemies don't collide
        if segment.set_position then
          segment:set_position(target_pos.x, target_pos.y)
        end
      end
    end
  end
end

fns['on_death'] = function(self)
  -- Clean up all segments when snake dies
  if self.segments then
    for _, segment in ipairs(self.segments) do
      if segment and not segment.dead then
        segment.dead = true
      end
    end
  end
end

fns['draw_enemy'] = function(self)
  -- Build path points from history
  local path_points = {}

  -- Start with head
  table.insert(path_points, {x = self.x, y = self.y})

  -- Determine how many segments to draw
  local segments_to_draw = self.extend_to_origin and #self.segment_history or math.min(#self.segment_history, self.snake_segments - 1)

  -- Add body segments from history
  for i = 1, segments_to_draw do
    local index = i * self.segment_spacing
    if index <= #self.segment_history and self.segment_history[index] then
      local segment = self.segment_history[index]
      
      -- Add smooth curve offset using sine wave
      local wiggle_x = 0
      local wiggle_y = 0
      
      -- Only wiggle middle segments, not head or tail
      local total_segments = self.extend_to_origin and #self.segment_history / self.segment_spacing or self.snake_segments
      if i > 1 and i < total_segments - 2 then
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
            local total_segments = self.extend_to_origin and #self.segment_history / self.segment_spacing or self.snake_segments
            local t = i / total_segments
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
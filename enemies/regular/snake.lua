local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Snake is a regular enemy with collision
  self.class = 'special_enemy'

  -- Create shape - snake is now a long rectangle
  self.color = purple[-2]:clone()
  self.snake_length = 80  -- Length of the snake body
  self.snake_width = 12   -- Width of the snake body
  
  self:set_as_rectangle(self.snake_length, self.snake_width, 'dynamic', 'ghost_enemy')
  self.icon = 'snake'

  -- Movement behavior
  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true

  -- Snake segment spawning variables
  self.spawned_segments = {}  -- References to spawned segment enemies
  self.segment_spawn_distance = 3  -- Distance to travel before spawning new segment (smaller for continuous trail)
  self.last_head_position = nil  -- Track last head position for spawning

  self.segment_count = 0
  self.max_segments = 10  -- Maximum number of segments to spawn

  -- Zig-zag pattern variables
  self.zigzag_amplitude = 15  -- How far to zig-zag
  self.zigzag_phase = 0  -- Current phase in the zig-zag
  self.zigzag_segments_per_cycle = 6  -- Segments per full zig-zag

  -- Visual trail (kept for head decoration)
end

fns['update_enemy'] = function(self, dt)
  -- Calculate head position (front of the snake rectangle)
  local vx, vy = self:get_velocity()
  local speed = math.sqrt(vx * vx + vy * vy)
  local head_x, head_y = self.x, self.y

  if speed > 0.1 then
    local dir_x = vx / speed
    local dir_y = vy / speed
    -- Head is at the front of the rectangle
    head_x = self.x + dir_x * (self.snake_length / 2)
    head_y = self.y + dir_y * (self.snake_length / 2)
  end

  if not self.last_head_position then
    self.last_head_position = {x = head_x, y = head_y}
  end

  -- Track distance traveled by the head
  local distance = math.distance(head_x, head_y, self.last_head_position.x, self.last_head_position.y)

  -- Spawn new segment if head has traveled far enough
  if distance >= self.segment_spawn_distance and self.segment_count < self.max_segments then
    -- self:spawn_segment()
    self.last_head_position = {x = head_x, y = head_y}
    -- self.segment_count = self.segment_count + 1
  end

  -- Clean up dead segments
  -- for i = #self.spawned_segments, 1, -1 do
  --   if self.spawned_segments[i] and self.spawned_segments[i].dead then
  --     table.remove(self.spawned_segments, i)
  --   end
  -- end
end

fns['spawn_segment'] = function(self)
  -- Calculate where to place segment along the snake body
  local vx, vy = self:get_velocity()
  local speed = math.sqrt(vx * vx + vy * vy)
  
  if speed > 0.1 then
    local dir_x = vx / speed
    local dir_y = vy / speed
    
    -- Place segment behind the head, distributed along the body
    local segment_offset = (self.segment_count / self.max_segments) * self.snake_length
    local segment_x = self.x + dir_x * (self.snake_length / 2 - segment_offset)
    local segment_y = self.y + dir_y * (self.snake_length / 2 - segment_offset)
    
    -- Spawn segment enemy
    print('spawn_segment', self.icon, Helper.Time.time, self.x, self.y)
    print('segment_x', segment_x, segment_y)
    local segment = Enemy{
      type = 'snake_segment',
      group = self.group,
      x = segment_x,
      y = segment_y,
      level = self.level,
      data = {
        parent_snake = self
      }
    }
    
    -- Set rotation after creation
    if segment then
      segment.r = math.atan2(dir_y, dir_x)
      segment:set_fixed_rotation(true)
      table.insert(self.spawned_segments, segment)
    end
  end
end

fns['draw_enemy'] = function(self)
  -- Draw snake as a long rectangle
  graphics.push(self.x, self.y, self.r, 1, 1)

  -- Draw main body rectangle
  local body_color = self.color:clone()
  graphics.rectangle(self.x, self.y, self.snake_length, self.snake_width, 3, 3, body_color)

  -- Draw darker inner stripe for depth
  local stripe_color = self.color:clone()
  stripe_color = stripe_color:darken(0.3)
  graphics.rectangle(self.x, self.y, self.snake_length * 0.8, self.snake_width * 0.4, 2, 2, stripe_color)

  graphics.rotate(0)
  graphics.pop()

  -- Draw head indicator (front of the rectangle)
  local vx, vy = self:get_velocity()
  local speed = math.sqrt(vx * vx + vy * vy)
  local head_x, head_y = self.x, self.y

  if speed > 0.1 then
    -- Calculate head position at front of rectangle based on movement direction
    local dir_x = vx / speed
    local dir_y = vy / speed
    head_x = self.x + dir_x * (self.snake_length / 2 - 5)
    head_y = self.y + dir_y * (self.snake_length / 2 - 5)
  end

  -- Draw head as a small circle
  graphics.circle(head_x, head_y, 6, self.color)

  -- Draw eyes on the head
  local eye_color = white[0]:clone()
  eye_color.a = 0.9
  local eye_size = 2
  local eye_offset = 3

  if speed > 0.1 then
    local dir_x = vx / speed
    local dir_y = vy / speed
    local perp_x = -dir_y
    local perp_y = dir_x

    graphics.circle(head_x + perp_x * eye_offset,
                   head_y + perp_y * eye_offset,
                   eye_size, eye_color)
    graphics.circle(head_x - perp_x * eye_offset,
                   head_y - perp_y * eye_offset,
                   eye_size, eye_color)
  end

  -- Apply status effect overlays if needed
  self:draw_fallback_status_effects()
end

enemy_to_class['snake'] = fns
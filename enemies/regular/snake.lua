local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Snake is a regular enemy with collision
  self.class = 'special_enemy'

  -- Create shape - snake head is smaller now
  self.color = purple[-2]:clone()
  self.snake_length = 20  -- Length of the snake head
  self.snake_width = 12   -- Width of the snake body

  self:set_as_rectangle(self.snake_length, self.snake_width, 'dynamic', 'ghost_enemy')
  self.icon = 'snake'

  -- Movement behavior
  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true

  -- Snake segment spawning variables
  self.spawned_segments = {}  -- References to spawned segment enemies
  self.segment_spawn_distance = 20  -- Distance to travel before spawning new segment
  self.distance_traveled = 19  -- Start at 10 to spawn first segment sooner
  self.last_position = nil  -- Track last position for distance calculation

  self.segment_count = 0
  self.max_segments = 30  -- Maximum number of segments to spawn

  -- Zig-zag pattern variables
  self.zigzag_amplitude = 15  -- How far to zig-zag
  self.zigzag_phase = 0  -- Current phase in the zig-zag
  self.zigzag_segments_per_cycle = 6  -- Segments per full zig-zag

  -- Visual trail (kept for head decoration)
end

fns['update_enemy'] = function(self, dt)
  if not self.last_position then
    self.last_position = {x = self.x, y = self.y}
  end

  -- Track distance traveled
  local dist = math.distance(self.x, self.y, self.last_position.x, self.last_position.y)
  self.distance_traveled = self.distance_traveled + dist
  self.last_position = {x = self.x, y = self.y}

  -- Spawn new segment every 20 units traveled
  if self.distance_traveled >= self.segment_spawn_distance and self.segment_count < self.max_segments then
    self:spawn_segment()
    self.distance_traveled = 0  -- Reset distance counter
    self.segment_count = self.segment_count + 1
  end

  -- Clean up dead segments
  for i = #self.spawned_segments, 1, -1 do
    if self.spawned_segments[i] and self.spawned_segments[i].dead then
      table.remove(self.spawned_segments, i)
    end
  end
end

fns['spawn_segment'] = function(self)
  -- Get movement direction
  local vx, vy = self:get_velocity()
  local speed = math.sqrt(vx * vx + vy * vy)

  if speed > 0.1 then
    local dir_x = vx / speed
    local dir_y = vy / speed

    -- Place segment 10 units behind the center (half of snake_length)
    local segment_x = self.x - dir_x * 10
    local segment_y = self.y - dir_y * 10

    -- Spawn segment enemy
    local segment = Enemy{
      type = 'snake_segment',
      group = self.group,
      x = segment_x,
      y = segment_y,
      level = self.level,
      parent_snake = self
    }

    -- Set rotation after creation
    if segment then
      segment.r = self.r
      segment.freezerotation = true
      table.insert(self.spawned_segments, segment)
    end
  end
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end

-- Custom fallback drawing for snake head
fns['draw_fallback_custom'] = function(self)
  -- Determine base color (hit flash, silenced, or normal color)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color

  graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)

  -- Draw main body rectangle
  graphics.rectangle(self.x, self.y, self.snake_length, self.snake_width, 3, 3, base_color)

  -- Draw darker inner stripe for depth
  local stripe_color = base_color:clone()
  stripe_color = stripe_color:darken(0.3)
  graphics.rectangle(self.x, self.y, self.snake_length * 0.8, self.snake_width * 0.4, 2, 2, stripe_color)


  local head_x = self.x + (self.snake_length / 2)
  local head_y = self.y 

  -- Draw head as a small circle at the front
  graphics.circle(head_x, head_y, 6, base_color)

  -- Draw eyes on the head
  local eye_color = white[0]:clone()
  eye_color.a = 0.9
  local eye_size = 2
  local eye_offset = 3

  local perp_x = 0
  local perp_y = 1

  graphics.circle(head_x + perp_x * eye_offset,
                  head_y + perp_y * eye_offset,
                  eye_size, eye_color)
  graphics.circle(head_x - perp_x * eye_offset,
                  head_y - perp_y * eye_offset,
                  eye_size, eye_color)

  graphics.pop()
end

enemy_to_class['snake'] = fns
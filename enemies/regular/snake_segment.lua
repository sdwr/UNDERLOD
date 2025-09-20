local fns = {}

fns['init_enemy'] = function(self)
  -- Snake segments are targetable points along the snake's body
  self.color = purple[-2]:clone()
  self.color.a = 0.6  -- Slightly transparent

  -- Set class before shape
  self.class = 'special_enemy'  -- No collision with other units
  self.is_snake_segment = true

  -- Use smaller collision shape
  self.size = 'small'
  Set_Enemy_Shape(self, self.size)

  -- Segment properties
  self.parent_snake = self.data.parent_snake  -- Reference to main snake
  self.segment_index = self.data.segment_index or 1
  self.spawn_point = self.data.spawn_point  -- Store original spawn point

  -- Make segments invulnerable but still targetable
  self.invulnerable = true
  self.ignoreKnockback = true
  self.hide_hp_bar = true  -- Don't show health bar

  -- Override the reject damage callback to forward damage to parent
  self.rejectDamageCallback = function(self, damage, from, damageType)
    if self.parent_snake and not self.parent_snake.dead then
      -- Forward damage to parent snake
      Helper.Damage:apply_hit(self.parent_snake, damage, from, damageType, true)

      -- Show hit effect at segment location
      self.hfx:use('hit', 0.05, 200, 10, 0.1)

      -- Create visual feedback at segment
      for i = 1, 3 do
        HitParticle{
          group = main.current.effects,
          color = self.color,
          x = self.x + random:float(-5, 5),
          y = self.y + random:float(-5, 5),
          type = 'effect',
          size = 0.5,
          speed = random:float(20, 40),
          direction = random:float(0, 2 * math.pi),
          duration = 0.3,
          fade_out = true,
          fade_out_duration = 0.5,
        }
      end
    end
  end

  -- Don't attack or move
  self.attack_options = {}
  self.baseIdleTimer = 999
  self.baseActionTimer = 999

  -- Override movement to do nothing
  self.currentMovementAction = MOVEMENT_TYPE_STATIONARY
end

fns['update_enemy'] = function(self, dt)
  -- Check if parent snake is dead
  if not self.parent_snake or self.parent_snake.dead then
    self.dead = true
    return
  end

  -- Update collision sensor position
  if self.attack_sensor then
    self.attack_sensor:move_to(self.x, self.y)
  end
end

fns['draw_enemy'] = function(self)
  -- Draw as a small circle at intersection points
  local radius = self.shape.w / 2

  -- Outer ring
  graphics.circle(self.x, self.y, radius * 1.2, self.color, 2)

  -- Inner filled circle
  local inner_color = self.color:clone()
  inner_color.a = 0.3
  graphics.circle(self.x, self.y, radius * 0.8, inner_color)

  -- Pulse effect when recently hit
  if self.hfx.hit.f then
    graphics.circle(self.x, self.y, radius * 1.5, white[0], 1)
  end
end

fns['on_death'] = function(self)
  -- Clean up reference from parent if needed
  if self.parent_snake and self.parent_snake.segments then
    for i, segment in ipairs(self.parent_snake.segments) do
      if segment == self then
        table.remove(self.parent_snake.segments, i)
        break
      end
    end
  end
end

-- Set position directly without physics since special enemies don't collide
fns['set_position'] = function(self, x, y)
  self.x = x
  self.y = y
  if self.body then
    self.body:setPosition(x, y)
  end
  if self.attack_sensor then
    self.attack_sensor:move_to(x, y)
  end
end

enemy_to_class['snake_segment'] = fns
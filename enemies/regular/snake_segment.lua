local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Set as special enemy for no collision
  self.class = 'special_enemy'
  self.icon = 'snake_segment'
  self.size = 'segment'  -- Use tiny size for segments (1x1)

  -- Visual properties
  self.color = purple[-3]:clone()

  -- Use Set_Enemy_Shape which handles special_enemy collision properly
  Set_Enemy_Shape(self, self.size)

  -- Make it a sensor so it doesn't collide physically but can still be targeted
  if self.fixture then
    self.fixture:setSensor(true)
  end

  -- Reference to parent snake
  self.parent_snake = self.data.parent_snake

  -- Segment is invulnerable but forwards damage to parent
  self.invulnerable = true

  -- Don't move after creation
  self.haltOnPlayerContact = true
  self.stopChasingInRange = true
  self.ignoreKnockback = true
  self.can_damage_orb = false  -- Segments don't damage the orb
  self:set_damping(10)  -- High damping to stop movement quickly

  -- Hide HP bar for segments
  self.hide_hp_bar = true
end

fns['update_enemy'] = function(self, dt)
  if not self.parent_snake or self.parent_snake.dead then
    self:die()
    return
  end

  -- Stop any movement
  self:set_velocity(0, 0)
end

fns['draw_enemy'] = function(self)
  -- Draw segment as a simple rectangle matching snake color
  graphics.push(self.x, self.y, self.r, 1, 1)

  local segment_color = self.color:clone()
  segment_color.a = 0.9
  graphics.rectangle(self.x, self.y, 20, 12, 3, 3, segment_color)

  -- Draw darker inner stripe for depth
  local inner_color = self.color:clone()
  inner_color = inner_color:darken(0.3)
  graphics.rectangle(self.x, self.y, 16, 5, 2, 2, inner_color)

  graphics.pop()
end

-- Forward damage to parent snake
fns['take_damage'] = function(self, damage)
  if self.parent_snake and not self.parent_snake.dead then
    self.parent_snake:take_damage(damage)
  end
end

enemy_to_class['snake_segment'] = fns
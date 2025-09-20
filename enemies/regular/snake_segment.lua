local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Set as special enemy for no collision
  self.class = 'special_enemy'
  self.icon = 'snake_segment'
  self.size = 'tiny'  -- Use tiny size for segments (1x1)

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

  -- Small wiggle animation
  self.wiggle_timer = random:float(0, math.pi * 2)
  self.wiggle_amplitude = 1
  self.wiggle_frequency = 2

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

  -- Small wiggle animation
  self.wiggle_timer = self.wiggle_timer + dt * self.wiggle_frequency

  -- Stop any movement
  self:set_velocity(0, 0)
end

fns['draw_enemy'] = function(self)
  -- Empty draw function - segments are invisible hit points
  -- Only used for targeting and damage forwarding
end

-- Forward damage to parent snake
fns['rejectDamageCallback'] = function(self, damage, from, damageType)
  print('rejectDamageCallback snake segment', damage, from, damageType)
  if self.parent_snake and not self.parent_snake.dead then
    -- Forward damage to parent without the invulnerable flag
    Helper.Damage:apply_hit(self.parent_snake, damage, from, damageType, true)
  end
end

enemy_to_class['snake_segment'] = fns
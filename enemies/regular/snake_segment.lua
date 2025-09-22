local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Set as special enemy for no collision
  self.class = 'special_enemy'
  self.icon = 'snake_segment'
  self.size = 'segment'  -- Use tiny size for segments (1x1)

  self.invulnerable = true
  self.not_damage_orb = true

  -- Visual properties
  self.color = purple[-3]:clone()

  -- Use Set_Enemy_Shape which handles special_enemy collision properly
  Set_Enemy_Shape(self, self.size)

  -- Make it a sensor so it doesn't collide physically but can still be targeted
  if self.fixture then
    self.fixture:setSensor(true)
  end

  -- Don't move after creation
  self.haltOnPlayerContact = true
  self.stopChasingInRange = true
  self.ignoreKnockback = true
  self.can_damage_orb = false  -- Segments don't damage the orb

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

-- Custom fallback drawing for snake segments
fns['draw_fallback_custom'] = function(self)
  -- Determine base color (hit flash, silenced, or normal color)
  local hit_flash = self.hfx.hit.f
  local silenced = self.silenced
  local hit_x = self.hfx.hit.x
  if self.parent_snake then
    hit_flash = self.parent_snake.hfx.hit.f
    silenced = self.parent_snake.silenced
    hit_x = self.parent_snake.hfx.hit.x
  end

  local base_color = hit_flash and fg[0] or (silenced and bg[10]) or self.color

  graphics.push(self.x, self.y, self.r or 0, hit_x, hit_x)

  -- Draw segment rectangle
  base_color.a = 0.9
  graphics.rectangle(self.x, self.y, 20, 12, 3, 3, base_color)

  -- Draw darker inner stripe for depth
  local inner_color = base_color:clone()
  inner_color = inner_color:darken(0.3)
  graphics.rectangle(self.x, self.y, 16, 5, 2, 2, inner_color)

  graphics.pop()
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end

-- Forward damage to parent snake
fns['rejectDamageCallback'] = function(self, damage, from, damageType, playHitEffects)
  if self.parent_snake and not self.parent_snake.dead then
    Helper.Damage:apply_hit(self.parent_snake, damage, from, damageType, playHitEffects)
  end
end

enemy_to_class['snake_segment'] = fns
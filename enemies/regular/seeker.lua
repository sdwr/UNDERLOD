local fns = {}
fns['init_enemy'] = function(self)

  --set extra data from variables
  self.data = self.data or {}
  self.icon = 'seeker'

  -- Set to same size as swarmer
  self.size = 'swarmer'

  -- Red triangle special enemy
  self.color = red[0]:clone()

  self.class = 'regular_enemy'
  self.group_tag = 'ghost_enemy'

  Set_Enemy_Shape(self, self.size)

  -- Never stop chasing, keep going until contact
  self.stopChasingInRange = false
  self.haltOnPlayerContact = false
  self.not_damage_orb = true

  -- No idle time, constantly seeking
  self.baseIdleTimer = 0

  -- No attacks - just seeks the player cursor
  self.attack_options = {}
  self.can_attack = false
end

fns['draw_enemy'] = function(self)
  -- Try to draw animation first
  local animation_success = self:draw_animation()

  if not animation_success then
    -- Custom fallback for triangle shape
    self:draw_fallback_custom()
  end
end

fns['draw_fallback_custom'] = function(self)
  -- Determine base color (hit flash, silenced, or normal color)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color

  graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)

  -- Draw triangle polygon (same as dragon but tiny size)
  local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70, self:get_angle())
  graphics.polygon(points, base_color)

  graphics.pop()

  -- Apply status effect overlays if present
  self:draw_fallback_status_effects()
end

enemy_to_class['seeker'] = fns
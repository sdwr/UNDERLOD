local fns = {}
fns['init_enemy'] = function(self)

  self.data = self.data or {}
  self.icon = 'swarmer'

  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.movementStyle = MOVEMENT_TYPE_SEEK

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'regular_enemy'
  self.baseIdleTimer = 0

  self.movement_options = {
    MOVEMENT_TYPE_SEEK,
  }

  self.attack_options = {}
end

fns['draw_enemy'] = function(self)

  local animation_success = self:draw_animation()

  if not animation_success then
    graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end

end

enemy_to_class['swarmer'] = fns
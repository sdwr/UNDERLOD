local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'swarmer'

  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'regular_enemy'
  self.stopChasingInRange = false
  self.haltOnPlayerContact = true
  self.baseIdleTimer = 0

  self.attack_options = {}
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end
  self:draw_steering_debug()
end

enemy_to_class['hunter_swarmer'] = fns

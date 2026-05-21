local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'rat1'

  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'special_enemy'
  self.baseIdleTimer = 0

  self.attack_sensor = Circle(self.x, self.y, 500)
  self.move_option_weight = 0.4

  self.attack_options = {}
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['brute'] = fns

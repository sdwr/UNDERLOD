local fns = {}

fns['init_enemy'] = function(self)
  
  --set extra data from variables
  self.data = self.data or {}
  self.icon = 'rat1'

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)



  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'regular_enemy'
  self.baseIdleTimer = 0

  --set sensors
  self.attack_sensor = Circle(self.x, self.y, 500)

  self.move_option_weight = 0.4


  --set attacks
  self.attack_options = {}

end

fns['draw_enemy'] = function(self)

  
  local animation_success = self:draw_animation()
  
  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end


end

enemy_to_class['chaser'] = fns 
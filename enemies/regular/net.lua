local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  self.class = 'special_enemy'

  Set_Enemy_Shape(self, self.size)
  self.icon = 'net'
  self.color = blue[2]:clone()

  self.baseIdleTimer = 0

  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true

  self.is_net_enemy = true

  NetBehavior.register_net(self)
end

fns['update_enemy'] = function(self, dt)
end

fns['on_death'] = function(self)
  NetBehavior.unregister_net(self)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_custom()
  end
end

fns['draw_fallback_custom'] = function(self)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color

  graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)

  graphics.circle(self.x, self.y, self.shape.w / 2, base_color)

  local inner_color = base_color:clone()
  inner_color = inner_color:lighten(0.3)
  graphics.circle(self.x, self.y, self.shape.w / 3, inner_color)

  graphics.pop()
  self:draw_fallback_status_effects()
end

enemy_to_class['net'] = fns

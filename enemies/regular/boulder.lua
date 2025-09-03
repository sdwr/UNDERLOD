local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = grey[2]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'boulder'
  
  self.baseIdleTimer = 0

  --movement behavior
  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true
end

fns['attack'] = function(self)
  -- Boulder doesn't attack, it just moves
end

fns['draw_enemy'] = function(self)
  -- Draw as a simple circle
  graphics.circle(self.x, self.y, self.shape.w / 2, self.color)
  
  -- Apply status effect overlays if needed
  self:draw_fallback_status_effects()
end

enemy_to_class['boulder'] = fns
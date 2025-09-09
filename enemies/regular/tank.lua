local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = green[-2]:clone()  -- Darker green color for tank
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'tank'
  
  self.baseIdleTimer = 0

  -- Movement behavior - like boulder but slower
  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true
  
end

fns['attack'] = function(self)
  -- Tank doesn't attack, it just moves toward the orb
end

fns['draw_enemy'] = function(self)
  -- Draw as a hexagon to differentiate from boulder
  local points = self:make_regular_polygon(6, self.shape.w / 2, self.r or 0)
  graphics.polygon(points, self.color)
  
  -- Draw a smaller inner hexagon for visual depth
  local inner_color = self.color:clone()
  inner_color = inner_color:lighten(0.2)
  local inner_points = self:make_regular_polygon(6, self.shape.w / 3, self.r or 0)
  graphics.polygon(inner_points, inner_color)
  
  -- Apply status effect overlays if needed
  self:draw_fallback_status_effects()
end

enemy_to_class['tank'] = fns
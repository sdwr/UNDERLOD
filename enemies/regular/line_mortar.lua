local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'plant1'
  self.movementStyle = MOVEMENT_TYPE_RANDOM  -- Stationary enemy

  self.baseCast = attack_speeds['medium']
  self:reset_castcooldown(self.baseCast)

  --set attacks
  self.attack_options = {}

  local line_mortar = {
    name = 'line_mortar',
    viable = function() return self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies) end,
    castcooldown = self.castcooldown,
    oncast = function() 
      self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
    end,
    cast_length = 1,
    spellclass = LineMortar_Spell,
    spelldata = {
      group = main.current.main,
      spell_duration = 8,
      num_shots = 8,
      knockback = true,
      shot_interval = 0.6,
      line_length = 240,
      damage = function() return self.dmg end,
      rs = 18,
      parent = self
    }
  }

  table.insert(self.attack_options, line_mortar)

end

fns['draw_enemy'] = function(self)
  
  local animation_success = self:draw_animation()
  
  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end

end

enemy_to_class['line_mortar'] = fns 
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = blue2[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.cast_time = 0
  
  self.stopChasingInRange = true
  --set attacks
  self.attack_options = {}

  local spread_laser = {
    name = 'spread_laser',
    viable = function() return self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies) end,
    oncast = function() self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies) end,
    castcooldown = 1,
    cast_length = 0.1,
    spellclass = Spread_Laser,
    spelldata = {
      group = main.current.main,
      unit = self,
      target = self.target,
      freeze_rotation = true,
      spell_duration = 10,
      color = blue[0],
      damage = function() return self.dmg end,
      laser_aim_width = 6,
      damage_troops = true,
      damage_once = true,
      lock_last_duration = 1,

      spread_type = 'target',
      num_shots = 3,
      spread_width = math.pi / 16,
    }
  }

  table.insert(self.attack_options, spread_laser)
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['spread'] = fns
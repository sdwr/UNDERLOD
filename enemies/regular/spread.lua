
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = blue2[0]:clone()
  Set_Enemy_Shape(self, self.size)

  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'
  
  self.cast_time = 0

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
      damage = self.dmg,
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
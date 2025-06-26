local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  --set attacks
  self.attack_options = {}

  local mortar = {
    name = 'mortar',
    viable = function() return self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies) end,
    castcooldown = 1,
    oncast = function() end,
    cast_length = 1,
    spellclass = Mortar_Spell,
    spelldata = {
      group = main.current.main,
      spell_duration = 10,
      num_shots = 3,
      shot_interval = 0.7,
      damage = function() return self.dmg end,
      rs = 25,
      parent = self
    }
  }

  table.insert(self.attack_options, mortar)

  end


fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['mortar'] = fns
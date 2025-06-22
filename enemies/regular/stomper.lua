

local fns = {}

fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  --set attacks
  self.attack_options = {}

  local stomp = {
    name = 'stomp',
    viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end,
    oncast = function() end,
    cast_length = 0.1,
    spellclass = Stomp_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      cancel_on_death = true,
      rs = 45,
      color = red[0],
      dmg = self.dmg or 30,
      spell_duration = 1,
      level = self.level,
      parent = self
    },
    rotation_lock = true,
  }
  table.insert(self.attack_options, stomp)
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['stomper'] = fns

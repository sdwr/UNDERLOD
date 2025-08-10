local fns = {}

fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'golem3'

  --set attacks
  self.attack_options = {}

  local stomp = {
    name = 'stomp',
    viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end,

    oncast = function() end,

    spellclass = Stomp_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      cancel_on_death = true,
      rs = 45,
      color = red[0],
      damage = function() return self.dmg end,
      spell_duration = GOLEM3_CAST_TIME,
      level = self.level,
      parent = self
    },
    rotation_lock = true,
  }
  table.insert(self.attack_options, stomp)
end

fns['draw_enemy'] = function(self)
  
  local animation_success = self:draw_animation()
  
  if not animation_success then
    self:draw_fallback_animation()
  end

end

enemy_to_class['stomper'] = fns

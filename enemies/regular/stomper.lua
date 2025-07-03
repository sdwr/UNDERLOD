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
    castcooldown = 1,
    oncast = function() end,
    cast_length = 0.1,
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
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end

end

enemy_to_class['stomper'] = fns

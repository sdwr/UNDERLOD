local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = green[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'goblin2'
  self.movementStyle = MOVEMENT_TYPE_SEEK_TO_RANGE

  --set stats and cooldowns
  self.baseCast = attack_speeds['medium-fast']
  self.cooldownTime = attack_speeds['medium-fast']
  self:reset_castcooldown(self.cooldownTime)

  self.stopChasingInRange = true

  -- Set attack range and sensor
  self.attack_range = attack_ranges['ranged']
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  --set attacks
  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end,
    oncast = function() self.target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
    cast_length = GOBLIN2_CAST_TIME,
    castcooldown = self.cooldownTime,
    cancel_on_range = false,
    instantspell = true,
    cast_sound = scout1,
    spellclass = ArrowProjectile,
    spelldata = {
      group = main.current.effects,
      spell_duration = 1,
      color = blue[0],
      damage = function() return self.dmg end,
      bullet_size = 6, -- Slightly larger arrow for big goblin
      is_troop = false,
      speed = 120,
    },
  }

  table.insert(self.attack_options, shoot)
end

fns['draw_enemy'] = function(self)
  graphics.push(self.x, self.y, 0, 0, 0)
  graphics.circle(self.x, self.y, self.attack_sensor.rs, self.color, 2)
  graphics.pop()
  local animation_success = self:draw_animation()
  
  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end
end
 
enemy_to_class['big_goblin_archer'] = fns 
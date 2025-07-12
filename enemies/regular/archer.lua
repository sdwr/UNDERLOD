local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'archer'  -- Using goblin2 icon for now
  self.movementStyle = MOVEMENT_TYPE_RANDOM  -- Moves randomly

  --set stats and cooldowns - fast attack speed for short action timer
  self.baseCast = attack_speeds['fast']
  self.cooldownTime = attack_speeds['fast']
  self:reset_castcooldown(self.cooldownTime)

  self.baseActionTimer = 1.5  -- Short action timer

  self.move_option_weight = 0

  -- Set attack range and sensor
  self.attack_range = attack_ranges['big-archer']
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  --set attacks
  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end,
    oncast = function() self.target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
    cast_length = 0.2,  -- Very short cast time
    castcooldown = self.cooldownTime,
    cancel_on_range = false,
    instantspell = true,
    cast_sound = scout1,
    spellclass = ArrowProjectile,
    spelldata = {
      group = main.current.effects,
      spell_duration = 1,
      color = red[0],
      damage = function() return self.dmg end,
      bullet_size = 4,
      speed = 150,  -- Slightly faster than goblin archer
      is_troop = false,
    },
  }

  table.insert(self.attack_options, shoot)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  
  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end
end
 
enemy_to_class['archer'] = fns 
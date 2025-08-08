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
  -- Attack speed now handled by base class

  self.baseActionTimer = 2

  self.move_option_weight = 0


  self.stopChasingInRange = true

  self.attack_range = attack_ranges['ranged']
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  --set attacks
  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end,
    oncast = function() 
      self.target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies)
    end,


    cancel_on_range = false,
    instantspell = true,
    cast_sound = scout1,
    spellclass = SingleProjectile,
    spelldata = {
      group = main.current.main,
      color = blue[0],
      damage = function() return self.dmg end,
      v = 120,  -- Speed for physics-based movement
      unit = self,
      source = 'goblin_archer',
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
 
enemy_to_class['goblin_archer'] = fns 
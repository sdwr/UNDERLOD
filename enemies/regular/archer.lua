local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'archer'  -- Using goblin2 icon for now


  --set stats and cooldowns - fast attack speed for short action timer
  -- Attack speed and cast time now handled by base class

  self.baseActionTimer = 2  -- Short action timer

  self.move_option_weight = 0

  -- Set attack range and sensor
  self.attack_range = attack_ranges['big-archer']
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
      color = red[0],
      width = 20,
      height = 4,
      damage = function() return self.dmg end,
      v = 80,  -- Speed for physics-based movement
      unit = self,
      source = 'archer',
    },
  }

  table.insert(self.attack_options, shoot)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  
  if not animation_success then
    self:draw_fallback_animation()
  end
end
 
enemy_to_class['archer'] = fns 
local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  self.class = 'special_enemy'
  
  --create shape
  self.color = green[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.icon = 'goblin2'


  --set stats and cooldowns
  -- Attack speed now handled by base class

  self.stopChasingInRange = true

  -- Set attack range and sensor
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
      source = 'big_goblin_archer',
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
    self:draw_fallback_animation()
  end
end
 
enemy_to_class['big_goblin_archer'] = fns 
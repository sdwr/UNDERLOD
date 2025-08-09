local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = green[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'goblin2'


  --set stats and cooldowns
  -- Attack speed now handled by base class

  self.baseActionTimer = 1.25

  self.move_option_weight = 0


  self.stopChasingInRange = true

  self.attack_range = attack_ranges['ranged']
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  self.last_action = 'attack'
  self.attacks_left = 0

  self.custom_action_selector = function(self, viable_attacks, viable_movements)
    if self.attack_cooldown_timer > 0 then 
      return 'retry', nil
    end
    
    if #viable_attacks == 0 or self.attacks_left <= 0 then
      self.last_action = 'movement'
      self.attacks_left = 3
      return 'movement', MOVEMENT_TYPE_RANDOM
    else
      self.last_action = 'attack'
      self.attacks_left = self.attacks_left - 1
      return 'attack', random:table(viable_attacks)
    end
  end

  --set attacks
  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() local target = Helper.Target:get_closest_enemy(self); return target end,
    oncast = function() 
      self.target = Helper.Target:get_closest_enemy(self)
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
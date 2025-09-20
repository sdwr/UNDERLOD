local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  -- Set class before shape so Set_Enemy_Shape knows it's a special enemy
  self.class = 'special_enemy'

  --create shape
  self.color = green[0]:clone()
  Set_Enemy_Shape(self, self.size)
  self.icon = 'goblin2'


  --set stats and cooldowns
  -- Attack speed now handled by base class

  self.move_option_weight = 0


  self.stopChasingInRange = true

  self.attack_range = attack_ranges['ranged']
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  self.NUM_ATTACKS = 3
  self.NUM_MOVES = 3

  self.attacks_left = 0
  self.moves_left = self.NUM_MOVES

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
    self:draw_fallback_animation()
  end
end
 
enemy_to_class['goblin_archer'] = fns 
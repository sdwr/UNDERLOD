local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = blue[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'plant1'


  -- Attack speed now handled by base class

  --set attacks
  self.attack_options = {}

  local aim_spread = {
    name = 'aim_spread',
    viable = function() return Helper.Target:get_random_enemy(self) end,

    oncast = function() 
      self.target = Helper.Target:get_random_enemy(self)
    end,

    spellclass = AimProjectile_Spell,
    spelldata = {
      group = main.current.main,
      spell_duration = 8,
      num_shots = 3,
      spread = math.pi / 6,  -- 30 degree spread
      damage = function() return self.dmg end,
      speed = 250,
      radius = 5,
      aim_color = red[0],
      color = self.color,
      parent = self
    }
  }

  table.insert(self.attack_options, aim_spread)

end

fns['draw_enemy'] = function(self)
  
  local animation_success = self:draw_animation()
  
  if not animation_success then
    self:draw_fallback_animation()
  end

end

enemy_to_class['aim_spread'] = fns 
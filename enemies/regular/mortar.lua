local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'plant1'


  --set attacks
  self.attack_options = {}

  local mortar = {
    name = 'mortar',
    viable = function() return Helper.Target:get_random_enemy(self) end,

    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,

    spellclass = Mortar_Spell,
    spelldata = {
      group = main.current.main,
      spell_duration = 10,
      num_shots = 3,
      shot_interval = 0.7,
      damage = function() return self.dmg end,
      rs = 25,
      parent = self
    }
  }

  table.insert(self.attack_options, mortar)

  end


fns['draw_enemy'] = function(self)
  
  local animation_success = self:draw_animation()
  
  if not animation_success then
    self:draw_fallback_animation()
  end

end

enemy_to_class['mortar'] = fns
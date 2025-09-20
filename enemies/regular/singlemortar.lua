local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  -- Set class before shape so Set_Enemy_Shape knows it's a special enemy
  self.class = 'special_enemy'

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)
  self.icon = 'plant2'


  -- Attack speed now handled by base class

  --set attacks
  self.attack_options = {}

  local singlemortar = {
    name = 'singlemortar',
    viable = function() return true end,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,

    instantspell = true,
    cancel_on_death = false,

    cast_sound = usurer1,
    cast_volume = 2,
    spellclass = Stomp,
    spelldata = {
      group = main.current.main,
      unit = self,
      team = "enemy",
      damage = function() return self.dmg end,
      cancel_on_death = false,
      knockback = true,
      chargeTime = 2.5,
      rs = 70,
      target_offset = 20,
      parent = self
    }
  }

  table.insert(self.attack_options, singlemortar)

  end


fns['draw_enemy'] = function(self)
  
  local animation_success = self:draw_animation()
  
  if not animation_success then
    self:draw_fallback_animation()
  end

end

enemy_to_class['singlemortar'] = fns 
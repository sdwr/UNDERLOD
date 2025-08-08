local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'plant2'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  self.baseCast = attack_speeds['medium-slow']
  self:reset_castcooldown(self.baseCast)

  --set attacks
  self.attack_options = {}

  local singlemortar = {
    name = 'singlemortar',
    viable = function() return true end,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,
    castcooldown = self.castcooldown,
    instantspell = true,
    cancel_on_death = false,
    cast_length = PLANT2_CAST_TIME,
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
      rs = 40,
      target_offset = 25,
      parent = self
    }
  }

  table.insert(self.attack_options, singlemortar)

  end


fns['draw_enemy'] = function(self)
  
  local animation_success = self:draw_animation()
  
  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end

end

enemy_to_class['singlemortar'] = fns 
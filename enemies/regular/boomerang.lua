local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = yellow[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'ent'

  self.baseCast = attack_speeds['medium-slow']
  self:reset_castcooldown(self.baseCast)

  self.stopChasingInRange = true

  --set attacks

  self.attack_options = {}

  local boomerang = {
    name = 'boomerang',
    viable = function () return true end,
    oncast = function() end,
    castcooldown = self.castcooldown,
    instantspell = true,
    cast_length = ENT_CAST_TIME,
    spellclass = Boomerang,
    spelldata = {
      group = main.current.main,
      unit = self,
      team = "enemy",
      target = self.target,
      x = self.x,
      y = self.y,
      spelltype = "targeted",
      color = yellow[0],
      damage = function() return self.dmg end,
      speed = 75,
      distance = 300,
      parent = self
    }
  }

  table.insert(self.attack_options, boomerang)

end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  
  if not animation_success then
  graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)


    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end

end
 
enemy_to_class['boomerang'] = fns
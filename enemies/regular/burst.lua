local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'lich'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  self.baseCast = attack_speeds['medium-slow']
  self:reset_castcooldown(self.baseCast)

  --set attacks

  self.attack_options = {}

  local burst = {
    name = 'burst',
    viable = function () return true end,
    oncast = function() end,
    castcooldown = self.castcooldown,
    instantspell = true,
    cast_length = LICH_CAST_TIME,
    spellclass = Burst,
    spelldata = {
      group = main.current.main,
      unit = self,
      spelltype = "targeted",
      x = self.x,
      y = self.y,
      color = purple[0],
      damage = function() return self.dmg end,
      speed = 70,
      num_pieces = 8,
      primary_explosion = true,
      parent = self
    }
  }

  table.insert(self.attack_options, burst)

end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end
end
 
enemy_to_class['burst'] = fns
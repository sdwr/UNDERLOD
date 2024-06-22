
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = green[0]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'

  --set attacks

  self.attack_options = {}

  local plasma_barrage = {
    name = 'plasma_barrage',
    viable = function () return true end,
    castcooldown = 0.8,
    cast = function()
      cannoneer1:play{volume=0.7}

      local r = 0
      --need to channel the attack and cast 10 in a row, changing the angle slightly each time
      --need to make sure stuns interrupt the cast, that cooldown doesnt decrease while casting
  }

  table.insert(self.attack_options, plasma_barrage)

end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['plasma'] = fns
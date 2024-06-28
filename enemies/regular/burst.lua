
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'

  --set attacks

  self.attack_options = {}

  local burst = {
    name = 'burst',
    viable = function () return true end,
    oncast = function() end,
    castcooldown = 1,
    instantspell = true,
    cast_length = 1,
    spellclass = Burst,
    spelldata = {
      group = main.current.main,
      unit = self,
      spelltype = "targeted",
      x = self.x,
      y = self.y,
      color = orange[0],
      damage = self.dmg,
      speed = 100,
      num_pieces = 8,
      parent = self
    }
  }

  table.insert(self.attack_options, burst)

end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['burst'] = fns

local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = yellow[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  --set attacks

  self.attack_options = {}

  local boomerang = {
    name = 'boomerang',
    viable = function () return true end,
    oncast = function() end,
    castcooldown = 1,
    instantspell = true,
    cast_length = 1,
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
      damage = self.dmg,
      speed = 100,
      distance = 300,
      parent = self
    }
  }

  table.insert(self.attack_options, boomerang)

end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['boomerang'] = fns

local fns = {}
fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = blue2[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  --set attacks
  self.attack_options = {}

  local arcspread = {
    name = 'arcspread',
    viable = function () return true end,
    oncast = function() end,
    castcooldown = 2,
    instantspell = true,
    cast_length = 1.5,
    spellclass = Arcspread,
    spelldata = {
      group = main.current.main,
      unit = self,
      target = self.target,
      color = blue2[5],
      damage = self.dmg,
      pierce = 1,
      thickness = 2,
      numArcs = 4,

      speed = 100,
    }
  }

  table.insert(self.attack_options, arcspread)
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['arcspread'] = fns

local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'small'

  --create shape
  self.color = brown[5]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

  self.maxSummons = 10
  self.summons = 0

  self.castTime = 3

  --set attacks
    self.t:after(attack_speeds['medium-fast'], function ()
        Summon{group = main.current.main, team = "enemy", type = "enemy_critter", amount = 6, suicide = true,
                x = self.x, y = self.y, rs = 15, castTime = 3, color = brown[5], level = self.level, parent = self}
    end, 'spawn')
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['dragonegg'] = fns
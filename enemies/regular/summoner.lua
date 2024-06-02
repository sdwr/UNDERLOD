

local fns = {}

fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = purple[5]:clone()
  Set_Enemy_Shape(self, self.size)

  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'

  --set special attrs
    self.maxSummons = 2
    self.summons = 0
    self.aggro_sensor = Circle(self.x, self.y, 1)

  --set attacks
    self.t:cooldown(attack_speeds['slow'], function() return self.state == 'normal' and self.summons < self.maxSummons end, function()
        Summon{group = main.current.main, team = "enemy", type = 'rager', amount = 1, castTime = 1.5,
        x = self.x, y = self.y, rs = 15, color = purple[3], level = self.level, parent = self}
    end, nil, nil, 'cast')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['summoner'] = fns

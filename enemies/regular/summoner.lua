

local fns = {}

fns['init_enemy'] = function(self)

  --create shape
  self.color = purple[5]:clone()
  self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

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

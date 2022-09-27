

local fns = {}

fns['init_enemy'] = function(self)

  --create shape
  self.color = purple[0]:clone()
  self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

  --set attacks
    self.summons = 0
    self.t:cooldown(attack_speeds['slow'], function() return self.state == 'normal' and self.summons < 3 end, function()
        Summon{group = main.current.main, team = "enemy", x = self.x, y = self.y, rs = 25, color = purple[0], level = self.level, parent = self}
    end, nil, nil, 'cast')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['summoner'] = fns

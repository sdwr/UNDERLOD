

local fns = {}

fns['safety_dance'] = function(self)
    --implement!
end

fns['init_enemy'] = function(self)

  --create shape
    self.color = orange[-2]:clone()
    self:set_as_rectangle(40, 60, 'dynamic', 'enemy')
  
  --set physics 
    self:set_restitution(0.1)
    self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
    self.class = 'boss'

  --set attacks
    self.cycle_index = 0
    self.t:cooldown(attack_speeds['slow'], function() return true end, function()
      fns['safety_dance'](self)
    end, nil, nil, 'cast')
end

fns['draw_enemy'] = function(self)
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 10, 10, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
end

enemy_to_class['heigan'] = fns
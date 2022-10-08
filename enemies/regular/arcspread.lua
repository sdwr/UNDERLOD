
local fns = {}
fns['init_enemy'] = function(self)
  --create shape
  self.color = blue2[5]:clone()
  self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

  --set attacks
    self.t:cooldown(attack_speeds['slow'], function() return true end, function ()
        sniper_load:play{volume=0.9}
        Helper.Spell.DamageArc.create_spread(self, Helper.Color.blue, true, false, 10, 30, 3, 4, 70, self.x, self.y)
    end, nil, nil, 'shoot')
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['arcspread'] = fns
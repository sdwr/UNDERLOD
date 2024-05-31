
local fns = {}
fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'regular'

  --create shape
  self.color = blue2[5]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

  --set attacks
    self.t:cooldown(attack_speeds['slow'], function() return true end, function ()
        sniper_load:play{volume=0.9}
        Helper.Spell.DamageArc:create_spread(self, Helper.Color.blue, true, false, self.dmg, 30, 3, 4, 50, self.x, self.y)
    end, nil, nil, 'shoot')
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['arcspread'] = fns
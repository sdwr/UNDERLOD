

local fns = {}
--very buggy:
-- will not rotate towards target if unit is in the way
-- does no damage
-- will disappear and reappear somewhere else if blocked mid-charge
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'

  --set attacks
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_target(self.attack_sensor, main.current.friendlies); return target end, function()
      local random_enemy = self:get_random_target(self.attack_sensor, main.current.friendlies)
      if random_enemy then
        Charge{group = main.current.main, unit = self, team = "enemy", x = self.x, y = self.y, color = red[0], damage = self.dmg, parent = self}
      end
    end, nil, nil, 'attack')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['charger'] = fns
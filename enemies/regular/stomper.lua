

local fns = {}

fns['init_enemy'] = function(self)

  --create shape
  self.color = red[0]:clone()
  self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

  --set attacks
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_closest_target(self.attack_sensor, main.current.friendlies); return target end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        Stomp{group = main.current.main, unit = self, team = "enemy", x = self.x, y = self.y, rs = 30, color = red[0], dmg = self.dmg, level = self.level, parent = self}
      end
    end, nil, nil, 'attack')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['stomper'] = fns
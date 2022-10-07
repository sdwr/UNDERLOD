local fns = {}

fns['init_enemy'] = function(self)

  --create shape
  self.color = red[4]:clone()
  self:set_as_rectangle(25, 25, 'dynamic', 'enemy')
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'miniboss'

  --overwrite stats
  self.attack_sensor = Circle(self.x, self.y, 75)

  --set attacks
    self.t:cooldown(attack_speeds['ultra-slow'], function() local target = self:get_closest_target(self.attack_sensor, main.current.friendlies); return target end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        Stomp{group = main.current.main, unit = self, team = "enemy", x = self.x, y = self.y, rs = 100, color = red[0], dmg = 50, chargeTime = 2.5, level = self.level, parent = self}
      end
    end, nil, nil, 'attack')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['bigstomper'] = fns
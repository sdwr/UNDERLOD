
local fns = {}
fns['init_enemy'] = function(self)
  --create shape
  self.color = orange[0]:clone()
  self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

  --set attacks
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target end, function ()
      local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
      if target then
        self:rotate_towards_object(target, 1)
        Mortar{group = main.current.main, unit = self, team = "enemy", target = target, rs = 25, color = red[0], dmg = self.dmg, level = self.level, parent = self}
      end
    end, nil, nil, 'shoot')
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['mortar'] = fns
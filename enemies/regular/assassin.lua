
--doesn't do damage yet?
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = black[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  --set attacks
  self.spawn_pos = {x = self.x, y = self.y}
  self.t:cooldown(attack_speeds['ultra-slow'], function() local targets = self:get_objects_in_shape(self.aggro_sensor, main.current.friendlies); return targets and #targets > 0 end, function()
    local furthest_enemy = self:get_furthest_object_to_point(self.aggro_sensor, main.current.friendlies, {x = self.x, y = self.y})
    if furthest_enemy then
      Vanish{group = main.current.main, team = "enemy", x = self.x, y = self.y, target = furthest_enemy, level = self.level, parent = self}
    end
  end, nil, nil, 'vanish')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['assassin'] = fns

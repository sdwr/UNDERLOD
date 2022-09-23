Assassin = Object:extend()
Assassin:implement(GameObject)
Assassin:implement(Physics)
Assassin:implement(Unit)
Assassin:implement(Enemy)
function Assassin:init(args)
    self:init_game_object(args)
    self:init_unit()

    self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
    self:create_regular(black[0])
    self:calculate_stats(true)

    self:set_attacks()
end

function Assassin:set_attacks()
    self.spawn_pos = {x = self.x, y = self.y}
    self.t:cooldown(attack_speeds['ultra-slow'], function() local targets = self:get_objects_in_shape(self.aggro_sensor, main.current.friendlies); return targets and #targets > 0 end, function()
      local furthest_enemy = self:get_furthest_object_to_point(self.aggro_sensor, main.current.friendlies, {x = self.x, y = self.y})
      if furthest_enemy then
        self:vanish(furthest_enemy)
      end
    end, nil, nil, 'vanish')
end

function Assassin:vanish(target)
    Vanish{group = main.current.main, team = "enemy", x = self.x, y = self.y, target = target, level = self.level, parent = self}
  end

  function Assassin:draw()
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

Stomper = Object:extend()
Stomper:implement(GameObject)
Stomper:implement(Physics)
Stomper:implement(Unit)
Stomper:implement(Enemy)
function Stomper:init(args)
    self:init_game_object(args)
    self:init_unit()

    
    self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
    self:create_regular(red[0])
    self:calculate_stats(true)

    self:set_attacks()
end

function Stomper:set_attacks()
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_closest_target(self.attack_sensor, main.current.friendlies); return target end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        self:stomp(30)
      end
    end, nil, nil, 'attack')
end

function Stomper:stomp(area, mods)
    Stomp{group = main.current.main, team = "enemy", x = self.x, y = self.y, rs = area or 25, color = red[0], dmg = 50, level = self.level, parent = self}
  end

function Stomper:draw()
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

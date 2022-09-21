Mortar = Object:extend()
Mortar:implement(GameObject)
Mortar:implement(Physics)
Mortar:implement(Unit)
Mortar:implement(Enemy)
function Mortar:init(args)
    self:init_game_object(args)
    self:init_unit()

    self:create_unit()
    self:calculate_stats(true)

    self:set_attacks()
end

function Mortar:create_unit()
    self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
    self:set_restitution(0.5)
    self.color = orange[0]:clone()
    self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
    self.class = 'mortar'
end

function Mortar:set_attacks()
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target end, function ()
      local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
      if target then
        self:rotate_towards_object(target, 1)
        self:mortar(target)
      end
    end, nil, nil, 'shoot')
end

function Mortar:mortar(target)
    Mortar{group = main.current.main, team = "enemy", target = target, rs = 25, color = red[0], dmg = 30, level = self.level, parent = self}
  end

function Mortar:draw()
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
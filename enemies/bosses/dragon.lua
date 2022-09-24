

local fns = {}

fns['init_enemy'] = function(self)

  --create shape
  self.color = red[0]:clone()
  self:set_as_rectangle(70, 70, 'dynamic', 'self')
  
  --set physics 
    self:set_restitution(0.1)
    self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
    self.class = 'boss'

  --set attacks
    self.attack_sensor.rs = self.attack_sensor.rs + 20
    self.summons = 0
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end, function()
        local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies);
        self.target = target

        if self:in_range()() then 
            local duration = 2
            local rs = self.attack_sensor.rs + 5
            BreatheFire{origin_offset = true, follows_caster = true, area_type = 'triangle',
            group = main.current.main, team = "self", x = self.x, y = self.y, rs = rs, color = red[3], dmg = 20, duration = duration, level = self.level, parent = self}
        end
    end, nil, nil, 'channel')
    self.t:cooldown(attack_speeds["ultra-slow"], function() return true end, function()
        local amount = math.min(10 - self.summons, 4)
        main.current:spawn_critters(self, amount)
    end, nil, nil, 'summon')
end

fns['draw_enemy'] = function(self)
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    local points = self:make_regular_polygon(3, self.shape.w / 2, self:get_angle())
    graphics.polygon(points, self.color)
end

enemy_to_class['dragon'] = fns
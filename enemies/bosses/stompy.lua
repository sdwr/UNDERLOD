Stompy = Object:extend()
Stompy:implement(GameObject)
Stompy:implement(Physics)
Stompy:implement(Unit)
Stompy:implement(Enemy)
function Stompy:init(args)
    self:init_game_object(args)
    self:init_unit()

    self:create_unit()
    self:calculate_stats(true)

    self:set_attacks()
end

function Stompy:create_unit()
    self:set_as_rectangle(60, 60, 'dynamic', 'enemy')
    self.color = grey[0]
    self:set_restitution(0.1)
    self.class = 'boss'
    self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
end

function Stompy:set_attacks()
    self.t:cooldown(attack_speeds['ultra-slow'], function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target and self.state == unit_states['normal'] end, function ()
        local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
        if target then
        self:rotate_towards_object(target, 1)
        self:mortar(target)
        end
    end, nil, nil, 'shoot')
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target and self.state == unit_states['normal'] end, function()
        self:stomp(self.attack_sensor.rs)
    end, nil, nil, 'stomp')
    self.t:cooldown(attack_speeds['fast'], function() local targets = self:get_objects_in_shape(self.aggro_sensor, main.current.friendlies); return targets and #targets > 0 and self.state == unit_states['normal'] end, function()
        local closest_enemy = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
        self.target = closest_enemy

        if self:in_range()() then
        self:rotate_towards_object(closest_enemy, 1)
        self:attack(20, {x = closest_enemy.x, y = closest_enemy.y})
        end
    end, nil, nil, 'attack')
end

function Stompy:update(dt)
    Enemy_Update(self, dt)
end


function Stompy:draw()
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 10, 10, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
end
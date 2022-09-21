Dragon = Object:extend()
Dragon:implement(GameObject)
Dragon:implement(Physics)
Dragon:implement(Unit)
Dragon:implement(Enemy)
function Dragon:init(args)
    self:init_game_object(args)
    self:init_unit()

    self:create_unit()
    self:calculate_stats(true)

    self:set_attacks()
end

function Dragon:create_unit()
    enemy:set_as_rectangle(70, 70, 'dynamic', 'enemy')
    enemy.color = red[-2]
    enemy:set_restitution(0.1)
    enemy.class = 'boss'
    enemy:calculate_stats(true)
    enemy:set_as_steerable(enemy.v, 1000, 2*math.pi, 2)
end

function Dragon:set_attacks()
    self.attack_sensor.rs = self.attack_sensor.rs + 20
    self.summons = 0
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end, function()
        local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies);
        self.target = target

        if self:in_range()() then
        self:breathe_fire(2, self.attack_sensor.rs + 5)
        end
    end, nil, nil, 'channel')
    self.t:cooldown(attack_speeds["ultra-slow"], function() return true end, function()
        self:spawn_whelps(self, math.min(10 - self.summons, 4))
    end, nil, nil, 'summon')
end

function Dragon:update(dt)
    Enemy_Update(self, dt)
end


function Dragon:draw()
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    local points = self:make_regular_polygon(3, self.shape.w / 2, self:get_angle())
    graphics.polygon(points, self.color)
end

function Dragon:breathe_fire(duration, rs)
    BreatheFire{origin_offset = true, follows_caster = true, area_type = 'triangle',
      group = main.current.main, team = "enemy", x = self.x, y = self.y, rs = rs, color = red[3], dmg = 20, duration = duration, level = self.level, parent = self}
end

function Dragon:spawn_whelps(parent, amount)
    main.current:spawn_critters(parent, amount)
end
Heigan = Object:extend()
Heigan:implement(GameObject)
Heigan:implement(Physics)
Heigan:implement(Unit)
Heigan:implement(Enemy)
function Heigan:init(args)
    self:init_game_object(args)
    self:init_unit()

    self:create_unit()
    self:calculate_stats(true)

    self:set_attacks()
end

function Heigan:create_unit()
    self:set_as_rectangle(40, 60, 'dynamic', 'enemy')
    self.color = orange[-2]
    self:set_restitution(0.1)
    self.class = 'boss'
    self:calculate_stats(true)
    self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
end

function Heigan:set_attacks()
    self.cycle_index = 0
    self.t:cooldown(attack_speeds['slow'], function() return true end, function()
      self:safety_dance()
    end, nil, nil, 'cast')
end

function Heigan:update(dt)
    Enemy_Update(self, dt)
end

function Heigan:draw()
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 10, 10, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
end


function Heigan:safety_dance()
    --implement!
end
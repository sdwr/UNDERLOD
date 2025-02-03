

Launch_Spell = Spell:extend()
function Launch_Spell:init(args)
    Launch_Spell.super.init(self, args)
    
    self.color = self.color or red[0]
    self.aim_color = self.aim_color or red[0]
    self.color_transparent = self.color:clone()
    self.color_transparent.a = 0.3

    self.charge_duration = self.charge_duration or 2
    self.fire_distance = self.fire_distance or 300
    self.already_damaged = {}

    self.damage = self.damage or 40
    self.impulse_magnitude = self.impulse_magnitude or 1000

    self.lineCoords = {0, 0, 0, 0}

    self:set_initial_coords()

    self.aim_width = self.aim_width or 16

    self.charge_sound = laser_charging:play{volume = 0.3}

  --memory 
    self.charge_time = 0
    self.is_charging = true
    self.pctCharged = 0
    self.fire_time = 0
    self.is_firing = false

end

function Launch_Spell:set_initial_coords()
  self.lineCoords = {self.x, self.y, self.x, self.y}
end

function Launch_Spell:update_pct_charged(dt)
    if self.is_charging then
        self.charge_time = self.charge_time + dt
        self.pctCharged = math.min(self.charge_time / self.charge_duration, 1)
    end
end

function Launch_Spell:update_coords()

    self.r = self.unit:get_angle()
    self.length = self.fire_distance * self.pctCharged

    self.lineCoords = {self.x, self.y, Helper.Geometry:move_point_radians(self.x, self.y, self.r, self.length)}
end

function Launch_Spell:update(dt)

    Launch_Spell.super.update(self, dt)
    if self.dead then return end
    
    self.r = self.unit:get_angle()

    self:update_pct_charged(dt)
    self:update_coords()

    if self.pctCharged == 1 then
      self:fire()
    end
end

function Launch_Spell:fire()
    if self.is_firing then return end

    self.is_firing = true
    self.unit:launch_at_facing(self.impulse_magnitude)

    self.charge_sound:stop()
    hit4:play{volume = 0.6}

    self:die()
end

function Launch_Spell:draw()
    Launch_Spell.super.draw(self)

    graphics.push(self.x, self.y, 0)
        graphics.line(self.lineCoords[1], self.lineCoords[2], self.lineCoords[3], self.lineCoords[4], self.color_transparent, self.aim_width)
    graphics.pop()
end

function Launch_Spell:die()
    self.charge_sound:stop()
    Launch_Spell.super.die(self)
end

function Launch_Spell:cancel()
    self.charge_sound:stop()
    Launch_Spell.super.cancel(self)
end

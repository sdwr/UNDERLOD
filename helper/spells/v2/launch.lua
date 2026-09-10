

Launch_Spell = Spell:extend()
function Launch_Spell:init(args)
    Launch_Spell.super.init(self, args)
    
    self.color = self.color or red[0]
    self.aim_color = self.aim_color or red[0]
    self.color_transparent = self.color:clone()
    self.color_transparent.a = 0.3

    self.charge_duration = self.charge_duration or 2
    self.fire_distance = self.fire_distance or 200
    self.already_damaged = {}

    self.damage = get_dmg_value(self.damage)
    self.impulse_magnitude = self.impulse_magnitude or 13000

    self.lineCoords = {0, 0, 0, 0}

    self:set_initial_coords()

    if self.keep_original_angle then
      -- aim_spread: random offset either side of the facing, fixed for the
      -- whole charge (line and launch agree).
      local spread = self.aim_spread or 0
      self.original_angle = self.unit:get_angle() + random:float(-spread, spread)
    end

    self.aim_width = self.aim_width or 16

    if self.play_charge_sound then
      self.charge_sound = laser_charging:play{volume = 0.3}
    end

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

    self.r = self.keep_original_angle and self.original_angle or self.unit:get_angle()
    self.length = self.fire_distance * self.pctCharged
    if self.line_to_wall then
      self.length = math.min(self:distance_to_wall(self.r), self.fire_distance) * self.pctCharged
    end

    self.lineCoords = {self.x, self.y, Helper.Geometry:move_point_radians(self.x, self.y, self.r, self.length)}
end

-- Distance from the unit to the arena's rectangular bounds along angle r,
-- inset by the unit's radius so the line ends where the body will hit.
function Launch_Spell:distance_to_wall(r)
  local arena = main.current and main.current.current_arena
  local x1, y1, x2, y2 = Get_Screen_Bounds(arena)
  local inset = (self.unit.shape and (self.unit.shape.rs or self.unit.shape.w / 2)) or 0
  local cx, cy = math.cos(r), math.sin(r)
  local best = math.huge
  if cx > 1e-6 then best = math.min(best, (x2 - inset - self.x) / cx) end
  if cx < -1e-6 then best = math.min(best, (x1 + inset - self.x) / cx) end
  if cy > 1e-6 then best = math.min(best, (y2 - inset - self.y) / cy) end
  if cy < -1e-6 then best = math.min(best, (y1 + inset - self.y) / cy) end
  return math.max(best, 0)
end

function Launch_Spell:update(dt)

    Launch_Spell.super.update(self, dt)
    if self.dead or (self.unit and self.unit.dead) then return end
    
    self.x = self.unit.x
    self.y = self.unit.y
    self.r = self.keep_original_angle and self.original_angle or self.unit:get_angle()

    self:update_pct_charged(dt)
    self:update_coords()

    if self.pctCharged == 1 then
      self:fire()
    end
end

function Launch_Spell:fire()
    if self.is_firing then return end

    self.is_firing = true
    self.unit:set_angle(self.r)
    self.unit:launch_at_facing(self.impulse_magnitude, self.launch_duration)
    if self.pinball then
      -- Enemy:update_launch holds this heading/speed and stompy's collision
      -- handler mirrors the heading on walls.
      self.unit.pinball_charging = true
      self.unit.pinball_heading = self.r
      self.unit.pinball_speed = self.pinball_speed or LAUNCH_MAX_V
      self.unit.pinball_hits = {}
      if self.unit.set_pinball_collision then self.unit:set_pinball_collision(true) end
    end

    if self.charge_sound then
      self.charge_sound:stop()
    end
    player_hit1:play{volume = 0.9}

    self:die()
end

function Launch_Spell:draw()
    Launch_Spell.super.draw(self)

    if self.show_charge_line then
    graphics.push(self.x, self.y, 0)
        graphics.line(self.lineCoords[1], self.lineCoords[2], self.lineCoords[3], self.lineCoords[4], self.color_transparent, self.aim_width)
        graphics.pop()
    end
end

function Launch_Spell:die()
    if self.charge_sound then
      self.charge_sound:stop()
    end
    Launch_Spell.super.die(self)
end

function Launch_Spell:cancel()
    if self.charge_sound then
      self.charge_sound:stop()
    end
    Launch_Spell.super.cancel(self)
end

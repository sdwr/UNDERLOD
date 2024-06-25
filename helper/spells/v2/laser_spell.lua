--laser use cases:
-- 1. prefire then instant laser (with duration for visual effect)
-- 2. prefire then laser with duration (fixed to place where fired) -- is after spell completes
  -- can hit each target once
  -- or hits each target per tick
  -- or hits each target once per time window, but ticks more often
-- 3. prefire then laser with duration (follows unit, ex laser ball) -- is while spell is active

--movement cases:
-- 1. fixed angle (rotation lock) - follows unit while moving
-- 2. fixed direction (direction lock) - follows unit while moving
-- 3. follow target - follow target while moving
  -- should stop following for the last few ticks to let the target dodge
  -- unless the unit is player troop, that should always hit

-- 4. bonus - sweep laser (rotation lock + rotates in a pattern)
-- 5. slow laser - laser length grows over time (no charge time)


--spell use case: create as instant (without cast, without changing unit state)

Laser_Spell = Spell:extend()
function Laser_Spell:init(args)
  Laser_Spell.super.init(self, args)

  self.color = self.color or blue[0]
  self.aim_color = self.aim_color or red[0]
  self.color_transparent = self.color:clone()
  self.color_transparent.a = 0.6
  self.aim_color_transparent = self.aim_color:clone()
  self.aim_color_transparent.a = 0.4

  self.direction_targetx = -1
  self.direction_targety = -1

  --'target' or 'rotate', whether it follows target or unit rotation
  --can use with direction_lock or rotation_lock to lock the laser in place
  --after its initial facing is set
  self.lasermode = self.lasermode or 'target'
  self.direction_lock = self.direction_lock
  self.rotation_lock = self.rotation_lock
  self.rotation_offset = self.rotation_offset or 0
  self.r = self.r or 0
  self.length = self.length or 1000
  self.damage_troops = self.damage_troops

  self.laser_aim_width = self.laser_aim_width or 4
  self.laser_width = self.laser_width or self.laser_aim_width * 3

  self.charge_duration = self.charge_duration or 1
  self.fire_duration = self.fire_duration or 0.2
  self.damage_once = self.damage_once
  self.fade_fire_draw = self.fade_fire_draw
  self.fade_in_aim_draw = self.fade_in_aim_draw

  --free the unit to move once the spell is cast
  self.end_spell_on_fire = self.end_spell_on_fire
  self.lock_last_duration = self.lock_last_duration or 0
  --does the damage follow the unit
  self.fire_follows_unit = self.fire_follows_unit

  self.tick_interval = self.tick_interval or 0.1

  self.damage = self.damage or 30

  self.lineCoords = {0, 0, 0, 0}

  self:set_initial_coords()

  if self.unit and self.unit.area_size_m then
    self.laser_aim_width = self.laser_aim_width * self.unit.area_size_m
    self.laser_width = self.laser_width * self.unit.area_size_m
  end

  self.charge_sound = laser_charging:play{volume = 0.4}

  -- memory
  self.charge_time = 0
  self.is_charging = true
  self.fire_time = 0
  self.is_firing = false
  --for damage once
  self.has_damaged = false
  --for damage per tick
  self.next_tick = 0
end

--use direction_target if set, otherwise use target
function Laser_Spell:set_distance_to_target()
  if self.direction_targetx == -1 and self.direction_targety == -1 then
    local x, y = Helper.Spell:get_target_nearest_point(self.unit)
    self.direction_targetx = x - self.unit.x
    self.direction_targety = y - self.unit.y
  elseif self.direction_targetx ~= -1 and self.direction_targety ~= -1 then
    self.direction_targetx = self.direction_targetx - self.unit.x
    self.direction_targety = self.direction_targety - self.unit.y
  end
end

function Laser_Spell:set_initial_coords()
  if self.lasermode == 'rotate' then
    self.r = self.unit:get_angle() + self.rotation_offset
    self.lineCoords = {self.x, self.y, Helper.Geometry:move_point(self.x, self.y, self.r, self.length)}
  elseif self.lasermode == 'target' then
    local targetx, targety = 0, 0
    if self.unit:my_target() then
      targetx, targety = self.unit:my_target().x, self.unit:my_target().y
    end
    local x2, y2 = self:get_end_location(self.x, self.y, targetx, targety)
    self.lineCoords = {self.x, self.y, x2, y2}
  end
end

function Laser_Spell:should_freeze_movement()
  if self.lock_last_duration > 0 then
    if self.charge_time > self.charge_duration - self.lock_last_duration then
      return true
    end
  end
end

function Laser_Spell:update(dt)
  if not self.unit or self.unit.dead then
    self:die()
    return
  end
  
  Laser_Spell.super.update(self, dt)
  self.x = self.unit.x
  self.y = self.unit.y

  self:update_target_coords()
  self:update_coords()

  self:update_charge(dt)
  if self.is_firing then
    self.next_tick = self.next_tick - dt
    self:try_damage()
  end

end

function Laser_Spell:update_target_coords()
  if self.unit:my_target() then
    self.target_last_x = self.unit:my_target().x
    self.target_last_y = self.unit:my_target().y
  end
end

function Laser_Spell:update_coords()
  local should_follow_r = self.rotation_lock
  
  local should_stay_fixed = self.is_firing and not self.fire_follows_unit
  local update_r = self.lasermode == 'rotate' and not self.rotation_lock
  local freeze_r = self.lasermode == 'rotate' and self.rotation_lock
  local update_d = self.lasermode == 'target' and not self.direction_lock and not self:should_freeze_movement()
  local freeze_d = self.lasermode == 'target' and (self.direction_lock or self:should_freeze_movement() )
  


  if should_stay_fixed then
    --do nothing
  elseif update_r then
    self.r = self.unit:get_angle() + self.rotation_offset
    self.lineCoords = {self.x, self.y, Helper.Geometry:move_point(self.x, self.y, self.r, 1000)}
  elseif update_d then
    local x2, y2 = self:get_end_location(self.x, self.y, self.target_last_x, self.target_last_y)
    self.lineCoords = {self.x, self.y, x2, y2}
  elseif freeze_r or freeze_d then
    --translate the line to the unit, using the existing x2, y2 coords (works for both rotate and target)
    local xdiff, ydiff = self.lineCoords[1] - self.x, self.lineCoords[2] - self.y
    local oldx, oldy = self.lineCoords[3], self.lineCoords[4]
    self.lineCoords = {self.x, self.y, oldx + xdiff, oldy + ydiff}
  else
    print('error in laser spell update_coords')
  end

end

function Laser_Spell:update_charge(dt)
  if self.is_charging then
    self.charge_time = self.charge_time + dt
    if self.charge_time > self.charge_duration then
      self.is_charging = false
      self.is_firing = true
      --fire here
      shoot1:play{volume=0.35}
      
      if self.end_spell_on_fire then
        self:finish_cast()
      end
      self.charge_sound:stop()
    end
  elseif self.is_firing then
    self.fire_time = self.fire_time + dt
    if self.fire_time > self.fire_duration then
      if not self.end_spell_on_fire then
        self:finish_cast()
      end
    end
  end
end

function Laser_Spell:try_damage()
  if self.damage_once then
    if self.has_damaged then
      return
    else 
      self.has_damaged = true
    end
  else
    if self.next_tick > 0 then
      return
    else
      self.next_tick = self.tick_interval
    end
  end

  --do damage here
  local targets = Helper.Unit:get_list(self.damage_troops)

  for _, unit in ipairs(targets) do
    for _, point in ipairs(unit.points) do
      local x = unit.x + point.x
      local y = unit.y + point.y
      if Helper.Geometry:is_on_line(x, y, self.lineCoords[1], self.lineCoords[2], self.lineCoords[3], self.lineCoords[4], self.laser_width) then
        Helper.Spell:register_damage_point(point, self.unit, self.damage)
      end
    end
  end
end

function Laser_Spell:draw()
  local color = self.color
  local width = self.laser_aim_width
  if self.is_charging then
    color = self.aim_color_transparent
    width = self.laser_aim_width
    if self.fade_in_aim_draw then
      self.aim_color_transparent.a = (self.charge_time / self.charge_duration)
    end
  elseif self.is_firing then
    color = self.color_transparent
    width = self.laser_width
    if self.fade_fire_draw then
      width = width * (1 - self.fire_time / self.fire_duration)
    end
  end
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.line(self.lineCoords[1], self.lineCoords[2], self.lineCoords[3], self.lineCoords[4], color, width)
  graphics.pop()
end

function Laser_Spell:finish_cast()

  Laser_Spell.super.finish_cast(self)

end

--helper

function Laser_Spell:get_end_location(x, y, targetx, targety)
  if not targetx or not targety then
    return 0, 0
  end

  local angle = math.atan2(targety - y, targetx - x)
  return Helper.Geometry:move_point(x, y, angle, self.length)
end

Laser_Damage = Object:extend()
function Laser_Damage:init(args)


end

function Laser_Damage:update(dt)

end

function Laser_Damage:try_damage()

end

function Laser_Damage:draw()

end

function Laser_Damage:die()

end
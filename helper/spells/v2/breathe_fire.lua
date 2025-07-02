

--needs target from oncast
Breathe_Fire = Spell:extend()
function Breathe_Fire:init(args)
  Breathe_Fire.super.init(self, args)


  self.sound = firebreath:play{volume=0.5}

  self.flamewidth = self.flamewidth or 30
  self.flameheight = self.flameheight or 100
  self.tick_interval = self.tick_interval or 0.125
  self.rotate_tick_interval = self.rotate_tick_interval or 1
  
  self.dps = self.dps or 30
  self.damage = self.dps * self.tick_interval
  
  self.color = self.color or red[0]
  self.color_transparent = self.color:clone()
  self.color_transparent.a = 0.2
  
  self.follow_target = self.follow_target
  self.rotation_speed = self.rotation_speed or 5  -- degrees per second

  local target = self.unit:my_target()
  self.directionx = target.x - self.unit.x
  self.directiony = target.y - self.unit.y

  --memory
  self.next_tick = 0
  self.next_rotate_tick = 0
  self.rotation_direction = 1


end

function Breathe_Fire:update(dt)
  if self.dead then return end

  Breathe_Fire.super.update(self, dt)
  self:update_position(dt)
  self.next_tick = self.next_tick - dt
  self.next_rotate_tick = self.next_rotate_tick - dt
  if self.next_tick <= 0 then
    self.next_tick = self.tick_interval
    self:spawn_particles()
    self:deal_damage()
  end
  if self.next_rotate_tick <= 0 then
    self.next_rotate_tick = self.rotate_tick_interval
    self.rotation_direction = self.rotation_direction * -1
  end
end

function Breathe_Fire:update_position(dt)
  -- Mode 1: Follow the unit's target
  if self.follow_target then
    local target = self.unit:my_target()
    if not target then return end

    local max_rotation_this_frame = self.rotation_speed * dt
    local current_angle = math.atan2(self.directiony, self.directionx)
    local target_angle = math.atan2(target.y - self.unit.y, target.x - self.unit.x)
    local angle_diff = target_angle - current_angle

    -- Find the shortest rotation path
    if angle_diff > math.pi then
      angle_diff = angle_diff - 2 * math.pi
    elseif angle_diff < -math.pi then
      angle_diff = angle_diff + 2 * math.pi
    end

    -- Clamp the rotation and apply it
    local rotation_to_apply_degrees = math.max(-max_rotation_this_frame, math.min(max_rotation_this_frame, math.deg(angle_diff)))
    local new_angle_radians = current_angle + math.rad(rotation_to_apply_degrees)
    self.directionx = math.cos(new_angle_radians)
    self.directiony = math.sin(new_angle_radians)

  -- Mode 2: Sweep back and forth at a fixed speed
  else
    -- Note: The logic that reverses self.rotation_direction every
    -- self.rotate_tick_interval is still in your main update() function.
    local rotation_this_frame = self.rotation_speed * self.rotation_direction * dt
    local current_angle = math.atan2(self.directiony, self.directionx)
    local new_angle = current_angle + math.rad(rotation_this_frame)
    
    self.directionx = math.cos(new_angle)
    self.directiony = math.sin(new_angle)
  end
end

function Breathe_Fire:spawn_particles()
  for i = 0, math.random(4, 8) do
    local x = 0
    local y = 0
    while not (Helper.Geometry:is_inside_triangle(x, y, Helper.Geometry:get_triangle_from_height_and_width(self.unit.x, self.unit.y, self.unit.x + self.directionx, self.unit.y + self.directiony, self.flameheight, self.flamewidth))
    and Helper.Geometry:distance(self.unit.x, self.unit.y, x, y) < self.flameheight / 5) do
      x = get_random(self.unit.x - self.flameheight/5, self.unit.x + self.flameheight/5)
      y = get_random(self.unit.y - self.flameheight/5, self.unit.y + self.flameheight/5)
    end
    Helper.Graphics:create_particle(
      self.color, get_random(0.5, 1.5), x, y, get_random(150, 180), 
      get_random(0.4 * self.flameheight / 60, 0.5 * self.flameheight / 60), 
      x - self.unit.x, y - self.unit.y, 20
    )
  end
end

function Breathe_Fire:deal_damage()
  for _, target in ipairs(Helper.Unit:get_list(not self.unit.is_troop)) do
    if Helper.Geometry:is_inside_triangle(target.x, target.y, Helper.Geometry:get_triangle_from_height_and_width(self.unit.x, self.unit.y, self.unit.x + self.directionx, self.unit.y + self.directiony, self.flameheight, self.flamewidth))
      and Helper.Geometry:distance(self.unit.x, self.unit.y, target.x, target.y) < self.flameheight then
      target:hit(self.damage, self.unit, nil, true, false)
      --HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
    end
  end
end

function Breathe_Fire:draw()
  if self.debug_hitbox then
    local x1, y1, x2, y2, x3, y3 = Helper.Geometry:get_triangle_from_height_and_width(self.unit.x, self.unit.y, self.unit.x + self.directionx, self.unit.y + self.directiony, self.flameheight, self.flamewidth)
    graphics.push(self.x, self.y, 0, 0, 0)
      graphics.line(x1, y1, x2, y2, self.color, 4)
      graphics.line(x2, y2, x3, y3, self.color, 4)
      graphics.line(x1, y1, x3, y3, self.color, 4)
    graphics.pop()
  end
  
  function Breathe_Fire:die()
    if self.sound and self.sound.stop then
      self.sound:stop()
    end
    Breathe_Fire.super.die(self)
  end
end
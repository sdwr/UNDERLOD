

--needs target from oncast
Breathe_Fire = Spell:extend()
function Breathe_Fire:init(args)
  Breathe_Fire.super.init(self, args)


  pyro1:play{volume=0.5}

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
  self.follow_speed = self.follow_speed or 60

  local target = self.unit:my_target()
  self.directionx = target.x - self.unit.x
  self.directiony = target.y - self.unit.y

  print(self.follow_target, 'follow target')

  --memory
  self.next_tick = 0
  self.next_rotate_tick = 0
  self.rotation_direction = 1


end

function Breathe_Fire:update(dt)
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
  local x = self.x + self.directionx
  local y = self.y + self.directiony

  if self.follow_target then
    local target = self.unit:my_target()
    if target then
      x, y = Helper.Geometry.rotate_to(self.x, self.y, x, y, target.x, target.y, self.follow_speed)
      self.directionx = x - self.x
      self.directiony = y - self.y
    end
  else
    local rotatedx, rotatedy = Helper.Geometry:rotate_point(x, y, self.x, self.y, 80 * self.rotation_direction)
    x, y = Helper.Geometry.rotate_to(self.x, self.y, x, y, rotatedx, rotatedy, self.follow_speed)
    self.directionx = x - self.x
    self.directiony = y - self.y
  end
end

function Breathe_Fire:spawn_particles()
  for i = 0, get_random(4, 8) do
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
      target:hit(self.damage, self.unit)
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
  
end

function Breathe_Fire:finish_cast()
  Breathe_Fire.super.finish_cast(self)
end
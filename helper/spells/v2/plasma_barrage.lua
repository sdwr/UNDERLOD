
Plasma_Barrage = Spell:extend()
function Plasma_Barrage:init(args)
  Plasma_Barrage.super.init(self, args)

  self.currentTime = 0
  orb1:play({volume = 0.6})

  self.color = red[0] or self.color
  self.color = self.color:clone()
  self.color.a = 0.7

  self.time_between_balls = self.time_between_balls or 0.2
  self.num_balls = self.num_balls or 20
  self.balls = {}

  self.initial_r = self.r or 0
  self.r_offset = self.r_offset or math.pi / 6

  self.explosion_radius = self.explosion_radius or 12
  self.damage = get_dmg_value(self.damage)

  self.speed = self.speed or 100
  self.rotation_speed = self.rotation_speed or 1
  self.movement_type = self.movement_type or 'spiral'
  self.ball_duration = self.ball_duration or 6
  self.target = self.target

  self.ball_i = 0
  self.trigger = self.t:every(self.time_between_balls, function()
    self.ball_i = self.ball_i + 1
    if self.cone_count then
      self:fire_cone_volley()
      return
    end
    local ballData = {
      group = self.group,
      unit = self.unit,
      team = self.team,
      x = self.x,
      y = self.y,
      r = self.r,
      speed = self.speed,
      rotation_speed = self.rotation_speed,
      movement_type = self.movement_type,
      duration = self.ball_duration,
      target = self.target,
      color = self.color,
      explosion_radius = self.explosion_radius,
      damage = self.damage,
    }
    ballData.r = self.initial_r + (self.r_offset * self.ball_i)
    
    dot1:play{pitch = random:float(0.95, 1.05), volume = 0.3}
    PlasmaBall(ballData)

  end, self.num_balls, function() self:die() end)

end
-- Cone mode (cone_count set): each tick fires cone_count straight balls spread
-- over cone_spread radians, re-aimed at the target (a random troop if the
-- target is gone), so only the aimed-at unit has to sidestep.
function Plasma_Barrage:fire_cone_volley()
  if not self.target or self.target.dead then
    self.target = self.unit and Helper.Target:get_random_enemy(self.unit)
  end
  local center = self.initial_r
  if self.target and not self.target.dead then
    center = math.atan2(self.target.y - self.y, self.target.x - self.x)
  end
  local n = self.cone_count
  for i = 1, n do
    local offset = n > 1 and (i - 1) / (n - 1) - 0.5 or 0
    PlasmaBall{
      group = self.group, unit = self.unit, team = self.team,
      x = self.x, y = self.y, r = center + offset * self.cone_spread,
      speed = self.speed, movement_type = 'straight', duration = self.ball_duration,
      color = self.color, explosion_radius = self.explosion_radius, damage = self.damage,
    }
  end
  dot1:play{pitch = random:float(0.95, 1.05), volume = 0.4}
end

function Plasma_Barrage:draw()
  Plasma_Barrage.super.draw(self)
end

function Plasma_Barrage:update(dt)
  Plasma_Barrage.super.update(self, dt)
end

function Plasma_Barrage:die()
  Plasma_Barrage.super.die(self)
  if self.trigger and self.t then self.t:cancel(self.trigger) end
end

-----------------------------------------

--needs container spell that makes a bunch of these with various 
--angles and speeds
--but need to resolve where the unit state /cooldown is handled first
-- in the unit? in the spell? different solutions
PlasmaBall = Object:extend()
PlasmaBall.__class_name = 'PlasmaBall'
PlasmaBall:implement(GameObject)
PlasmaBall:implement(Physics)
function PlasmaBall:init(args)
  self:init_game_object(args)
  self.radius = self.radius or 8
  self.shape = Circle(self.x, self.y, self.radius)

  self.color = red[0] or self.color
  self.color = self.color:clone()
  self.color.a = 0.7

  self.explosion_radius = self.explosion_radius or 12
  self.explosion_damage = self.damage or 30

  self.speed = self.speed or 100
  self.rotation_speed = self.rotation_speed or 1
  self.movement_type = self.movement_type or 'spiral'
  self.target = self.target
  
  self.r = self.r or 0
  self:set_angle(self.r)

  self.duration = self.duration or 12
  self.elapsed = 0
  self.t:after(self.duration, function() self:die() end)
end

function PlasmaBall:update(dt)
  self:update_game_object(dt)
  self:check_hits()
  self.elapsed = self.elapsed + dt

  local x = self.x
  local y = self.y
  if self.movement_type == 'straight' then
    self.x = self.x + self.speed * math.cos(self.r) * dt
    self.y = self.y + self.speed * math.sin(self.r) * dt
  elseif self.movement_type == 'spiral' then
    self.r = self.r + self.rotation_speed * dt
    self.x = self.x + self.speed * math.cos(self.r) * dt
    self.y = self.y + self.speed * math.sin(self.r) * dt
  elseif self.movement_type == 'homing' then
    if self.target and not self.target.dead then
      self.r = math.lerp_angle_dt(0.5, dt, self.r, self:angle_to_object(self.target))
      self.x = self.x + self.speed * math.cos(self.r) * dt
      self.y = self.y + self.speed * math.sin(self.r) * dt
    else
      --just move straight if no target
      self.x = self.x + self.speed * math.cos(self.r) * dt
      self.y = self.y + self.speed * math.sin(self.r) * dt
    end
  end
  self.shape:move_to(self.x, self.y)
end

function PlasmaBall:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  if #friendlies > 0 then
    self:explode()
  end
end

function PlasmaBall:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, self.shape.rs, self.color, 4)
  graphics.pop()
end

function PlasmaBall:explode()
  explosion_new:play{pitch = random:float(0.95, 1.05), volume = 0.3}
  Area{
    group = main.current.effects, 
    unit = self.unit,
    x = self.x, 
    y = self.y, 
    r = self.explosion_radius,
    pick_shape = 'circle',
    duration = 0.15,
    damage = self.explosion_damage,
    is_troop = false,
    color = self.color, 
  }
  self:die()
end

function PlasmaBall:die()
  self.dead = true
end



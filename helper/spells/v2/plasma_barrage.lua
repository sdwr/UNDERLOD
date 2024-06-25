
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
  self.damage = self.damage or 30

  self.speed = self.speed or 100
  self.rotation_speed = self.rotation_speed or 1
  self.movement_type = self.movement_type or 'spiral'
  self.ball_duration = self.ball_duration or 6
  self.target = self.target

  self.ball_i = 0
  self.trigger = self.t:every(self.time_between_balls, function()
    self.ball_i = self.ball_i + 1
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



SnakeArrows = Spell:extend()
function SnakeArrows:init(args)
  SnakeArrows.super.init(self, args)

  self.color = self.color or green[0]
  self.damage = get_dmg_value(self.damage)
  self.speed = self.speed or 100
  self.curve_depth = self.curve_depth or 10  -- How far the S-curve deviates from straight line (reduced from 30)
  self.curve_frequency = self.curve_frequency or 0.4  -- How many S-curves per second (reduced from 2)
  self.duration = self.duration or 8
  self.radius = self.radius or 4

  --fix rotation at start
  if self.target then
    self.r = math.atan2(self.target.y - self.y, self.target.x - self.x)
  else
    self.r = random:float(-math.pi, math.pi)
  end

  self.num_arrows = self.num_arrows or 3
  --memory
  self.next_arrow = 0.2
  self.arrow_interval = self.arrow_interval or 0.8
  self.arrows_left = self.num_arrows
end

function SnakeArrows:update(dt)
  if self.unit.dead then self:die() end
  SnakeArrows.super.update(self, dt)
  self.next_arrow = self.next_arrow - dt
  if self.next_arrow <= 0 then
    self.next_arrow = self.arrow_interval
    self:fire_arrow()
  end
end

function SnakeArrows:fire_arrow()
  self.arrows_left = self.arrows_left - 1
  if self.arrows_left <= 0 then self:die() end


  SnakeArrow{
    group = main.current.main,
    unit = self.unit,
    team = "enemy",
    r = self.r,
    damage = self.damage,
    speed = self.speed,
    curve_depth = self.curve_depth,
    curve_frequency = self.curve_frequency,
    duration = self.duration,
    radius = self.radius,
    color = self.color,
  }
end

function SnakeArrows:draw()
  SnakeArrows.super.draw(self)
end

function SnakeArrows:die()
  SnakeArrows.super.die(self)
  if self.unit then
    self.unit:put_attack_on_cooldown()
  end
end

SnakeArrow = EnemyProjectile:extend()
SnakeArrow.__class_name = 'SnakeArrow'

function SnakeArrow:init(args)
  -- Set up snake arrow specific properties before calling parent
  args.color = args.color or green[0]
  args.speed = args.speed or 100
  args.radius = args.radius or 4
  args.duration = args.duration or 8
  
  -- Call parent init
  SnakeArrow.super.init(self, args)
  
  -- Snake arrow specific properties
  self.curve_depth = args.curve_depth or 15  -- How far the S-curve deviates from straight line
  self.curve_frequency = args.curve_frequency or 1.5  -- How many S-curves per second
  
  -- Movement properties
  self.base_angle = self.r or 0  -- The base direction the arrow travels

  self.distance_traveled = 0
  self.start_x = self.x
  self.start_y = self.y
  
  -- S-curve properties
  self.curve_time = 0
  self.curve_amplitude = self.curve_depth
  self.curve_period = 1 / self.curve_frequency  -- Time for one complete S-curve
  
  -- Visual properties
  self.trail_particles = {}
  self.max_trail_length = 16
  self.trail_interval = 0.05
  self.last_trail_time = 0
  
  -- Sound
  arcane2:play{pitch = random:float(0.9, 1.1), volume = 0.4}
  
  -- Set lifetime
  self.t:after(self.duration, function() self:die() end)
end

function SnakeArrow:update(dt)
  -- Call parent update (handles hit detection, bounds checking, etc)
  SnakeArrow.super.update(self, dt)
  
  -- Update curve time
  self.curve_time = self.curve_time + dt
  
  -- Add trail particle
  if self.last_trail_time + self.trail_interval < Helper.Time.time then
    self:add_trail_particle()
    self.last_trail_time = Helper.Time.time
  end
end

-- Override update_movement for snake pattern
function SnakeArrow:update_movement(dt)
  -- Calculate base movement
  local base_distance = self.speed * dt
  self.distance_traveled = self.distance_traveled + base_distance
  
  -- Calculate S-curve offset
  local curve_offset = self:calculate_curve_offset()
  
  -- Calculate new position
  local base_x = self.start_x + math.cos(self.base_angle) * self.distance_traveled
  local base_y = self.start_y + math.sin(self.base_angle) * self.distance_traveled
  
  -- Apply S-curve perpendicular to base direction
  local perpendicular_angle = self.base_angle + math.pi / 2
  self.x = base_x + math.cos(perpendicular_angle) * curve_offset
  self.y = base_y + math.sin(perpendicular_angle) * curve_offset
end

function SnakeArrow:calculate_curve_offset()
  -- Create a smooth, gentle curve using a simple sine wave
  local t = self.curve_time * self.curve_frequency * 2 * math.pi
  local smooth_curve = math.sin(t)  -- Simple sine wave for smooth curve
  return smooth_curve * self.curve_amplitude
end

function SnakeArrow:add_trail_particle()
  -- Add current position to trail
  table.insert(self.trail_particles, {x = self.x, y = self.y, alpha = 1.0})
  
  -- Limit trail length
  if #self.trail_particles > self.max_trail_length then
    table.remove(self.trail_particles, 1)
  end
  
  -- Fade trail particles
  for i, particle in ipairs(self.trail_particles) do
    particle.alpha = particle.alpha - 0.1
  end
end

-- Collision detection is now handled by parent class check_hits()

function SnakeArrow:draw()
  if self.hidden then return end
  
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
  
  -- Draw trail
  for i, particle in ipairs(self.trail_particles) do
    if particle.alpha > 0 then
      local trail_color = self.color:clone()
      trail_color.a = particle.alpha * 0.6
      graphics.circle(particle.x, particle.y, self.radius * 0.7, trail_color)
    end
  end
  
  -- Draw main arrow
  graphics.circle(self.x, self.y, self.radius, self.color)
  
  graphics.pop()
end

function SnakeArrow:die()
  if not self.dead then
    self.dead = true
    
    -- Death effects
    for i = 1, 5 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
    end
  
  end
end 
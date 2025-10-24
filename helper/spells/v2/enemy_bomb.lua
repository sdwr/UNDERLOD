-- EnemyBomb - A bomb projectile that lands and explodes into projectiles
-- Dropped by bomber enemies
-- Extends EnemyProjectile to use hit detection

EnemyBomb = EnemyProjectile:extend()
EnemyBomb.__class_name = 'EnemyBomb'

function EnemyBomb:init(args)
  -- Call parent init
  EnemyBomb.super.init(self, args)

  -- Override some parent properties
  self.speed = 0  -- Bombs don't move after landing
  self.explosion_delay = args.explosion_delay or 4  -- Will explode after this time
  self.num_beeps = args.num_beeps or 3

  -- Visual properties
  self.color = args.color or orange[0]:clone()
  self.radius = args.radius or 4

  -- Explosion properties
  self.num_projectiles = args.num_projectiles or 8
  self.projectile_speed = args.projectile_speed or 100
  self.projectile_radius = args.projectile_radius or 4
  self.projectile_damage = args.damage  -- Pass through damage to projectiles
  self.projectile_duration = args.projectile_duration or 1

  -- Timer and state
  self.time_elapsed = 0
  self.exploded = false

  -- Beep timing for warning
  self.beep_times = {}
  local beep_interval = self.explosion_delay / (self.num_beeps + 1)
  for i = 1, self.num_beeps do
    table.insert(self.beep_times, beep_interval * i)
  end
  self.next_beep_index = 1


  -- Visual feedback for beep flashes
  self.flash_active = false
  self.flash_duration = 0.1
  self.flash_timer = 0

  -- Override parent timer to explode instead of die
  self.t:after(self.explosion_delay, function()
    if not self.dead then
      self:explode()
    end
  end)
end

function EnemyBomb:update(dt)
  -- Call parent update (handles hit detection)
  EnemyBomb.super.update(self, dt)

  if self.exploded or self.dead then return end

  self.time_elapsed = self.time_elapsed + dt

  -- Update flash timer if flash is active
  if self.flash_active then
    self.flash_timer = self.flash_timer + dt
    if self.flash_timer >= self.flash_duration then
      self.flash_active = false
      self.flash_timer = 0
    end
  end

  -- Check for beeps
  if self.next_beep_index <= #self.beep_times then
    if self.time_elapsed >= self.beep_times[self.next_beep_index] then
      tick_new:play{pitch = random:float(0.95, 1.05), volume = 0.3}
      -- Activate flash
      self.flash_active = true
      self.flash_timer = 0
      self.next_beep_index = self.next_beep_index + 1
    end
  end
end

function EnemyBomb:update_movement(dt)
  -- Override parent movement - bombs don't move
  -- They stay where they land
end

function EnemyBomb:explode()
  if self.exploded then return end
  self.exploded = true

  explosion_new:play{pitch = random:float(0.95, 1.05), volume = 0.1}

  -- Create evenly spaced projectiles
  local angle_step = (2 * math.pi) / self.num_projectiles
  for i = 1, self.num_projectiles do
    local angle = (i - 1) * angle_step

    EnemyProjectile{
      group = main.current.main,
      x = self.x,
      y = self.y,
      r = angle,
      speed = self.projectile_speed,
      radius = self.projectile_radius,
      damage = self.projectile_damage,
      duration = self.projectile_duration,
      color = self.color,
      unit = self.unit,
      source = 'enemy_bomb',
    }
  end

  self:die()
end

function EnemyBomb:draw()
  -- Flash bright only when beeping (0.1 second flash)
  local draw_color = self.flash_active and fg[0] or self.color

  graphics.push(self.x, self.y, 0, 1, 1)
    graphics.circle(self.x, self.y, self.radius + 2, self.color)
    graphics.circle(self.x, self.y, self.radius, draw_color)
  graphics.pop()
end

function EnemyBomb:die()
  self:explode()
  EnemyBomb.super.die(self)
end
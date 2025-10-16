-- Bombardment_Spell
-- A channeled spell that fires multiple waves of projectiles in a circular pattern
-- Each wave can have an offset rotation for alternating patterns
-- Designed to be highly configurable for reuse across different enemies

Bombardment_Spell = Spell:extend()
function Bombardment_Spell:init(args)
  Bombardment_Spell.super.init(self, args)

  -- Projectile appearance
  self.color = self.color or grey[0]
  self.color = self.color:clone()
  self.color.a = 0.7
  self.projectile_radius = self.projectile_radius or 6
  self.projectile_speed = self.projectile_speed or 80

  -- Damage
  self.damage = get_dmg_value(self.damage)

  -- Wave configuration
  self.num_waves = self.num_waves or 3                  -- How many waves to fire
  self.time_between_waves = self.time_between_waves or 0.5  -- Seconds between waves
  self.projectiles_per_wave = self.projectiles_per_wave or 6  -- Projectiles in each wave

  -- Pattern configuration
  self.use_alternating_offset = self.use_alternating_offset or true  -- Whether to offset even waves
  self.offset_angle = self.offset_angle or (math.pi / self.projectiles_per_wave) * 0.5  -- Offset for even waves (half the angle between projectiles by default)
  self.starting_rotation = self.starting_rotation or 0  -- Initial rotation offset

  -- Projectile behavior
  self.projectile_duration = self.projectile_duration or 10

  -- Internal state
  self.current_wave = 0
  self.wave_timer = 0

  -- Play initial sound
  orb1:play{volume = 0.4, pitch = random:float(0.8, 1.0)}

  -- Fire first wave immediately
  self:fire_wave()
end

function Bombardment_Spell:update(dt)
  Bombardment_Spell.super.update(self, dt)

  if self.current_wave >= self.num_waves then
    return  -- All waves fired
  end

  self.wave_timer = self.wave_timer + dt

  if self.wave_timer >= self.time_between_waves then
    self.wave_timer = 0
    self:fire_wave()
  end
end

function Bombardment_Spell:fire_wave()
  self.current_wave = self.current_wave + 1

  -- Determine if this is an even wave (for alternating pattern)
  local is_even_wave = (self.current_wave % 2 == 0)
  local rotation_offset = self.starting_rotation

  -- Apply alternating offset for even waves
  if self.use_alternating_offset and is_even_wave then
    rotation_offset = rotation_offset + self.offset_angle
  end

  -- Calculate angle between projectiles
  local angle_between = (2 * math.pi) / self.projectiles_per_wave

  -- Fire projectiles in a circle
  for i = 1, self.projectiles_per_wave do
    local angle = rotation_offset + (i - 1) * angle_between

    self:fire_projectile(angle)
  end

  -- Play sound
  dot1:play{pitch = random:float(0.95, 1.05), volume = 0.3}

  -- If all waves are fired, end the spell
  if self.current_wave >= self.num_waves then
    self:die()
  end
end

function Bombardment_Spell:fire_projectile(angle)
  EnemyProjectile{
    group = main.current.main,
    unit = self.unit,
    team = self.team or "enemy",
    is_troop = false,
    x = self.x,
    y = self.y,
    r = angle,
    radius = self.projectile_radius,
    speed = self.projectile_speed,
    damage = self.damage,
    color = self.color,
    duration = self.projectile_duration,
  }
end

function Bombardment_Spell:draw()
  Bombardment_Spell.super.draw(self)
end

function Bombardment_Spell:die()
  Bombardment_Spell.super.die(self)
end

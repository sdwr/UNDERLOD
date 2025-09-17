LevelOrb = Object:extend()
LevelOrb.__class_name = 'LevelOrb'
LevelOrb:implement(GameObject)
LevelOrb:implement(Physics)

function LevelOrb:init(args)
  self:init_game_object(args)
  
  -- Position and basic properties
  self.x = args.x or gw/2
  self.y = args.y or gh/2
  self.group = args.group or main.current.main
  
  -- Physical properties
  self.radius = args.radius or 10
  self.boundary_radius = args.boundary_radius or 75
  self.visible_radius = 0

  self:set_as_circle(self.radius, 'static', 'projectile')
  -- Make the orb a sensor so enemies can pass through it
  if self.fixture then
    self.fixture:setSensor(true)
  end
  
  -- Health properties
  self.max_hp = args.max_hp or LEVEL_ORB_HEALTH(main.current.level)
  self.hp = self.max_hp
  
  -- Visual properties
  self.color = args.color or blue[0]:clone()
  self.base_color = self.color:clone()
  self.hurt_color = red[0]:clone()
  self.hurt_flash_color = red[5]:clone()
  
  -- Animation properties
  self.pulse_timer = 0
  self.pulse_speed = 1.5
  self.scale = 1.0
  self.hurt_flash_timer = 0
  self.hurt_flash_duration = 0.2
  
  -- Shimmer effect properties
  self.shimmer_timer = 0
  self.shimmer_speed = 0.8
  
  -- Ripple effects for progress particles
  self.ripples = {}
  self.progress_sound = nil
  self.last_progress_sound_time = 0
  self.progress_sound_pitch = 1
  
  -- Faction - make it targetable by enemies
  self.faction = 'friendly'
  self.is_level_orb = true
    
  -- Damage resistance
  self.damage_reduction = 0 -- Percentage of damage to reduce (0 = no reduction)
  self.invulnerable = false

end

function LevelOrb:spawn()
  self.t:tween(0.5, self, {visible_radius = self.radius}, math.ease_in_out_cubic)
  self.t:after(0.5, function()
    level_up1:play{pitch = random:float(0.9, 1.1), volume = 1}
  end)
end

function LevelOrb:update(dt)
  self:update_game_object(dt)
  
  -- Update pulse animation
  self.pulse_timer = self.pulse_timer + dt * self.pulse_speed
  local pulse_intensity = self.charging and 0.2 or 0.1
  self.scale = 1.0 + pulse_intensity * math.sin(self.pulse_timer)
  
  -- Update shimmer animation
  self.shimmer_timer = self.shimmer_timer + dt * self.shimmer_speed
  
  -- Update ripples
  for i = #self.ripples, 1, -1 do
    local ripple = self.ripples[i]
    ripple.timer = ripple.timer + dt
    ripple.radius = ripple.start_radius + (ripple.max_radius - ripple.start_radius) * (ripple.timer / ripple.duration)
    ripple.alpha = 1 - (ripple.timer / ripple.duration)
    
    if ripple.timer >= ripple.duration then
      table.remove(self.ripples, i)
    end
  end
  
  -- Update charging state
  if self.charging then
    self.charge_timer = self.charge_timer + dt
    
    -- Add charge particles
    if math.random() < 0.8 then
      local angle = random:float(0, 2 * math.pi)
      local distance = random:float(50, 100)
      local particle_x = self.x + math.cos(angle) * distance
      local particle_y = self.y + math.sin(angle) * distance
      
      table.insert(self.charge_particles, {
        x = particle_x,
        y = particle_y,
        target_x = self.x,
        target_y = self.y,
        life = 0.5,
        max_life = 0.5,
        size = random:float(2, 4)
      })
    end
    
    -- Update charge particles
    for i = #self.charge_particles, 1, -1 do
      local particle = self.charge_particles[i]
      particle.life = particle.life - dt
      
      if particle.life <= 0 then
        table.remove(self.charge_particles, i)
      else
        local progress = 1 - (particle.life / particle.max_life)
        particle.x = math.lerp(particle.x, particle.target_x, progress)
        particle.y = math.lerp(particle.y, particle.target_y, progress)
      end
    end
    
    -- End charging when duration is complete
    if self.charge_timer >= self.charge_duration then
      self.charging = false
      self.charge_particles = {}
    end
  end
  
  -- Update hurt flash
  if self.hurt_flash_timer > 0 then
    self.hurt_flash_timer = self.hurt_flash_timer - dt
    if self.hurt_flash_timer <= 0 then
      self.color = self.base_color:clone()
    end
  end
  
  -- Update collision shape position
  if self.shape then
    self.shape:move_to(self.x, self.y)
  end
end

function LevelOrb:on_trigger_enter(other)
  if not other:is(Enemy) then return end
  if other.class == 'boss' then return end
  if other.x ~= other.x then return end
  -- if not other.can_damage_orb then return end

  local enemy_round_power = enemy_to_round_power[other.type] or 100
  local damage_taken = enemy_round_power * 0.1

  self:hit(damage_taken, other, DAMAGE_TYPE_PHYSICAL)
  
  other:die()
end

function LevelOrb:hit(damage, from, damage_type)
  if self.dead then return end
  if self.invulnerable then return end
  if from and from.x ~= from.x then return end
  
  -- Apply damage reduction
  local actual_damage = damage * (1 - self.damage_reduction)
  
  -- Take damage
  self.hp = self.hp - actual_damage
  
  -- Visual feedback
  self:flash_hurt()
  
  -- Play hit sound
  hit1:play{pitch = random:float(0.9, 1.1), volume = 1}
  
  -- Check if destroyed
  if self.hp <= 0 then
    self:die()
  end
end

function LevelOrb:flash_hurt()
  self.hurt_flash_timer = self.hurt_flash_duration
  self.color = self.hurt_color:clone()
end

function LevelOrb:get_hp_percentage()
  if self.max_hp <= 0 then return 1 end
  return math.clamp(self.hp / self.max_hp, 0, 1)
end

function LevelOrb:charge_up(duration)
  self.invulnerable = true
  -- Visual effects
  self.charging = true
  self.charge_timer = 0
  self.charge_duration = duration
  self.original_color = self.color:clone()

  --Sound effects
  self.chargeup_sound = chargeuprising:play{pitch = 1, volume = 1.2}
  self.t:tween(duration, self.chargeup_sound, {volume = 1.5}, math.linear)
  self.t:after(duration, function()
    self.chargeup_sound:stop()
  end)
  
  -- Expand orb
  self.t:tween(duration * 0.8, self, {visible_radius = self.radius * 1.7}, math.ease_in_out_cubic)
  self.t:after(duration * 0.8, function()
    self.t:tween(duration * 0.2, self, {visible_radius = self.radius}, math.ease_in_out_cubic)
  end)
  
  -- Color transition to bright white/yellow
  local charge_color = yellow[5]:clone()
  self.t:tween(duration * 0.7, self.color, {r = charge_color.r, g = charge_color.g, b = charge_color.b}, math.ease_in_cubic)
  
  -- Screen shake that intensifies
  camera:shake(2, duration, 60, 1.5)
  
  -- Pulse effect that speeds up
  self.charge_pulse_speed = self.pulse_speed
  self.t:tween(duration, self, {pulse_speed = self.pulse_speed * 3}, math.ease_in_cubic)
  self.t:after(duration, function()
    self.pulse_speed = self.pulse_speed / 3
  end)

  self.t:after(duration, function()
    self.charging = false
  end)
  
  -- Particle effects
  self.charge_particles = {}
end

function LevelOrb:draw()
  if self.dead then return end
  
  -- Draw debug oval for seek_to_range enemies when enabled
  if DEBUG_ENEMY_SEEK_TO_RANGE then
    -- Use oval shape - stretched horizontally (same as enemy targeting)
    local desired_range = SEEK_TO_RANGE_RADIUS
    local oval_rx = desired_range * SEEK_TO_RANGE_RADIUS_X_MULTIPLIER
    local oval_ry = desired_range * SEEK_TO_RANGE_RADIUS_Y_MULTIPLIER
    
    -- Draw the oval outline
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.setColor(green[0].r, green[0].g, green[0].b, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.ellipse("line", 0, 0, oval_rx, oval_ry)
    love.graphics.pop()
  end

  if self.boundary_radius then
    --make it light grey
    local boundary_color = green[-3]:clone()
    boundary_color.a = 0.07
    graphics.circle(self.x, self.y, self.boundary_radius, boundary_color)
  end
  
  -- Draw charge particles
  if self.charging and self.charge_particles then
    for _, particle in ipairs(self.charge_particles) do
      local alpha = particle.life / particle.max_life
      local particle_color = yellow[3]:clone()
      particle_color.a = alpha
      graphics.circle(particle.x, particle.y, particle.size, particle_color)
    end
  end
  
  graphics.push(self.x, self.y, 0, self.scale, self.scale)
  
  -- Get HP percentage for color interpolation
  local completion_percentage = self.parent:percent_of_round_power_killed()
  local hp_percentage = self:get_hp_percentage()
  
  -- Calculate base color that transitions from grey to vibrant based on health
  local base_orb_color
  if self.hurt_flash_timer > 0 then
    base_orb_color = red[3]:clone()
  elseif self.charging then
    base_orb_color = yellow[3]:clone()
  else
    -- Interpolate from grey-blue to vibrant blue based on health
    local dark_blue = blue[-2]:clone()
    dark_blue.b = dark_blue.b + 0.2  -- Add slight blue tint to grey
    local vibrant_blue = blue[3]:clone()
    
    base_orb_color = Color(
      dark_blue.r + (vibrant_blue.r - dark_blue.r) * completion_percentage,
      dark_blue.g + (vibrant_blue.g - dark_blue.g) * completion_percentage,
      dark_blue.b + (vibrant_blue.b - dark_blue.b) * completion_percentage
    )
  end
  
  -- Draw soft gradient glow (single smooth gradient instead of rings)
  for i = 8, 1, -1 do
    local glow_alpha = 0.015 * (9 - i)  -- Smoother falloff
    local glow_scale = 1 + (0.05 * i)  -- More gradual scale increase
    local outer_glow = base_orb_color:clone()
    outer_glow.a = glow_alpha * completion_percentage * 0.5 + glow_alpha * 0.3  -- Glow intensity based on health
    graphics.circle(self.x, self.y, self.visible_radius * glow_scale, outer_glow)
  end
  
  -- Draw charging glow effect
  if self.charging then
    local glow_intensity = math.sin(self.pulse_timer * 2) * 0.5 + 0.5
    local charge_glow = yellow[0]:clone()
    charge_glow.a = 0.3 * glow_intensity
    graphics.circle(self.x, self.y, self.visible_radius * 1.5, charge_glow)
  end
  
  -- Draw main orb background (empty portion)
  local bg_color = bg[4]:clone()
  graphics.circle(self.x, self.y, self.visible_radius, bg_color)
  
  -- Add subtle inner shadow gradient for depth
  local shimmer_offset = math.sin(self.shimmer_timer) * 0.2 + 0.8
  for i = 1, 4 do
    local gradient_radius = self.visible_radius * (1 - i * 0.08)
    local gradient_color = bg[3]:clone()
    gradient_color.a = 0.08 * (5 - i) / 4 * shimmer_offset
    graphics.circle(self.x, self.y + (i * 1), gradient_radius, gradient_color)
  end
  
  -- Draw health portion (colored from bottom)
  if hp_percentage > 0 then
    local fill_height = self.visible_radius * 2 * hp_percentage
    local fill_y = self.y + self.visible_radius - (fill_height /2) 
    
    -- Create a clipping mask for the health portion
    love.graphics.stencil(function()
      graphics.rectangle(self.x, fill_y, self.visible_radius * 2, fill_height, 0, 0, white[0])
    end, "replace", 1)
    
    love.graphics.setStencilTest("greater", 0)
    
    -- Draw the colored health portion with color that gets more vibrant with more completion
    local health_color
    if self.hurt_flash_timer > 0 then
      health_color = self.hurt_flash_color
    else
      health_color = base_orb_color:clone()
    end
    graphics.circle(self.x, self.y, self.visible_radius, health_color)
    
    -- Add subtle internal highlight
    local health_shimmer = health_color:clone()
    health_shimmer = health_shimmer:lighten(0.2)
    health_shimmer.a = 0.25 * shimmer_offset
    graphics.circle(self.x, self.y - 4, self.visible_radius * 0.8, health_shimmer)
    
    love.graphics.setStencilTest()
  end
  
  -- Draw ripple effects from progress particles
  for _, ripple in ipairs(self.ripples) do
    if ripple and ripple.radius and ripple.radius > 0 then
      local ripple_color = yellow[5]:clone()
      ripple_color.a = ripple.alpha * 0.6
      graphics.circle(self.x, self.y, ripple.radius, ripple_color, 2)
    end
  end
  
  -- Draw soft border with gradient effect
  -- Outer soft edge
  local border_base = base_orb_color:clone()
  border_base = border_base:darken(0.3)
  for i = 1, 3 do
    local border_alpha = 0.1 * (4 - i) / 3
    local border_scale = 1 + (0.005 * i)
    local border_color = border_base:clone()
    border_color.a = border_alpha * (0.5 + completion_percentage * 0.5)  -- Border opacity based on health
    graphics.circle(self.x, self.y, self.visible_radius * border_scale, border_color, 1)
  end
  
  -- Inner edge highlight (very subtle)
  local inner_highlight = base_orb_color:clone()
  inner_highlight = inner_highlight:lighten(0.4)
  inner_highlight.a = 0.15 * completion_percentage
  graphics.circle(self.x, self.y, self.visible_radius * 0.98, inner_highlight, 1)
  
  graphics.pop()

end

function LevelOrb:die()
  if self.dead then return end
  self.dead = true
  
  -- Play glass shatter sound
  glass_shatter:play{pitch = random:float(0.9, 1.1), volume = 1.2}
  
  -- Create shatter animation with glass-like fragments
  self:create_shatter_animation()
  
  -- Camera shake for impact
  camera:shake(4, 0.5)
  
  -- Trigger level failure or other consequences  
  if self.parent and self.parent.on_level_orb_destroyed then
    self.parent:on_level_orb_destroyed()
  end
end

function LevelOrb:create_shatter_animation()
  -- Create glass shard particles flying outward
  local num_shards = 16
  for i = 1, num_shards do
    local angle = (i - 1) * (2 * math.pi / num_shards) + random:float(-0.3, 0.3)
    local speed = random:float(60, 100)
    
    -- Create elongated shards that look like glass fragments
    HitParticle{
      group = main.current.effects,
      x = self.x,
      y = self.y,
      r = angle,
      v = speed,
      w = random:float(9, 15),
      h = random:float(4, 6),
      color = blue[random:int(2, 4)]:clone(),
      duration = random:float(2, 3),
      fade_out = true
    }
    
    -- Create smaller secondary fragments
    if i % 2 == 0 then
      HitParticle{
        group = main.current.effects,
        x = self.x + random:float(-5, 5),
        y = self.y + random:float(-5, 5),
        r = angle + random:float(-0.5, 0.5),
        v = speed,
        w = random:float(4, 6),
        h = random:float(2, 3),
        color = bg[6]:clone(),
        duration = random:float(1.5, 2.5),
        fade_out = true
      }
    end
  end
  
  -- Create a bright flash at the moment of shattering
  HitCircle{
    group = main.current.effects,
    x = self.x, y = self.y,
    rs = self.visible_radius * 0.5,
    color = white[0]:clone(),
    duration = 0.15,
    fade_out = true
  }
  
  -- Create some falling glass dust particles
  for i = 1, 8 do
    main.current.t:after(random:float(0, 0.3), function()
      HitParticle{
        group = main.current.effects,
        x = self.x + random:float(-self.visible_radius, self.visible_radius),
        y = self.y + random:float(-self.visible_radius, self.visible_radius),
        r = math.pi/2 + random:float(-0.3, 0.3), -- Mostly downward
        v = random:float(20, 40),
        w = random:float(2, 3),
        h = random:float(2, 3),
        color = bg[7]:clone(),
        duration = random:float(1, 1.5)
      }
    end)
  end
end

function LevelOrb:heal(amount)
  if self.dead then return end
  
  self.hp = math.min(self.max_hp, self.hp + amount)
  
  -- Visual feedback for healing
  self:flash_heal()
end

function LevelOrb:add_progress_sound()
  if Helper.Time.time - self.last_progress_sound_time > 1 then
    self.progress_sound_pitch = 1
  else
    self.progress_sound_pitch = self.progress_sound_pitch + 0.1
    self.progress_sound_pitch = math.min(self.progress_sound_pitch, 1.5)
  end

  if self.progress_sound then
    self.progress_sound:stop()
  end
  self.progress_sound = spawn_mark2:play{pitch = self.progress_sound_pitch, volume = 0.2}
end

function LevelOrb:add_progress_ripple()
  -- Add a new ripple effect when progress particle hits
  -- Use actual radius if visible_radius is not yet set
  local current_radius = self.visible_radius > 0 and self.visible_radius or self.radius
  table.insert(self.ripples, {
    timer = 0,
    duration = 0.5,
    start_radius = 0,
    max_radius = current_radius * 1.2,
    alpha = 1
  })
end

function LevelOrb:flash_heal()
  -- Flash green briefly
  self.hurt_flash_timer = self.hurt_flash_duration
  self.color = green[0]:clone()
end

function LevelOrb:on_progress_particle_hit()
  -- Called when a progress particle reaches the orb
  -- self:add_progress_sound()
  self:add_progress_ripple()
  self.last_progress_sound_time = Helper.Time.time
end
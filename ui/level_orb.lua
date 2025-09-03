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
  self.radius = args.radius or 25
  self.visible_radius = 0

  self:set_as_circle(self.radius, 'static', 'projectile')
  
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

function LevelOrb:on_collision_enter(other)
  if not other:is(Enemy) then return end
  if not other.can_damage_orb then return end

  local enemy_round_power = enemy_to_round_power[other.type] or 10

  if not self.invulnerable then
    self:hit(enemy_round_power, other, DAMAGE_TYPE_PHYSICAL)
  end
  
  other:die()
end

function LevelOrb:hit(damage, from, damage_type)
  if self.dead then return end
  
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
  
  -- Draw soft outer glow (brighter than before)
  local glow_color = white[5]:clone()  -- Brighter base
  if self.hurt_flash_timer > 0 then
    glow_color = red[3]:clone()
  elseif self.charging then
    glow_color = yellow[3]:clone()
  else
    glow_color = blue[0]:clone()  -- Brighter blue
  end
  
  -- Multiple layers for soft glow
  for i = 3, 1, -1 do
    local glow_alpha = 0.08 * i  -- Increased from 0.05
    local glow_scale = 1 + (0.08 * (4 - i))  -- Tighter glow
    local outer_glow = glow_color:clone()
    outer_glow.a = glow_alpha
    graphics.circle(self.x, self.y, self.visible_radius * glow_scale, outer_glow, 2)
  end
  
  -- Draw charging glow effect
  if self.charging then
    local glow_intensity = math.sin(self.pulse_timer * 2) * 0.5 + 0.5
    local charge_glow = yellow[0]:clone()
    charge_glow.a = 0.3 * glow_intensity
    graphics.circle(self.x, self.y, self.visible_radius * 1.5, charge_glow)
  end
  
  -- Draw main orb background with lighter damaged area
  local bg_color = bg[8]:clone()  -- Lighter grey for empty portion
  graphics.circle(self.x, self.y, self.visible_radius, bg_color)
  
  -- Add inner shimmer gradient for empty portion
  local shimmer_offset = math.sin(self.shimmer_timer) * 0.3 + 0.7
  for i = 1, 3 do
    local gradient_radius = self.visible_radius * (0.9 - i * 0.15)
    local gradient_color = bg[10]:clone()  -- Even lighter shimmer
    gradient_color.a = 0.15 * shimmer_offset * (4 - i) / 3
    graphics.circle(self.x, self.y - (i * 2), gradient_radius, gradient_color)
  end
  
  -- Draw health portion (colored from bottom)
  local hp_percentage = self:get_hp_percentage()
  if hp_percentage > 0 then
    local fill_height = self.visible_radius * 2 * hp_percentage
    local fill_y = self.y + self.visible_radius - (fill_height /2) 
    
    -- Create a clipping mask for the health portion
    love.graphics.stencil(function()
      graphics.rectangle(self.x, fill_y, self.visible_radius * 2, fill_height, 0, 0, white[0])
    end, "replace", 1)
    
    love.graphics.setStencilTest("greater", 0)
    
    -- Draw the colored health portion with subtle internal glow
    local health_color = self.color
    if self.hurt_flash_timer > 0 then
      health_color = self.hurt_flash_color
    end
    graphics.circle(self.x, self.y, self.visible_radius, health_color)
    
    -- Add subtle internal shimmer to health portion
    local health_shimmer = health_color:clone()
    health_shimmer = health_shimmer:lighten(0.15)
    health_shimmer.a = 0.3 * shimmer_offset
    graphics.circle(self.x, self.y - 3, self.visible_radius * 0.85, health_shimmer)
    
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
  
  -- Draw very subtle border (brighter than before)
  local border_color = white[0]:clone()  -- Brighter base
  if self.hurt_flash_timer > 0 then
    border_color = red[5]:clone()
  elseif self.charging then
    border_color = yellow[5]:clone()
  else
    border_color = blue[2]:clone()  -- Brighter blue
  end
  border_color.a = 0.5  -- Increased from 0.4
  graphics.circle(self.x, self.y, self.visible_radius, border_color, 1)
  
  graphics.pop()
end

function LevelOrb:die()
  if self.dead then return end
  self.dead = true
  
  -- Play destruction sound
  explosion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  
  -- Trigger level failure or other consequences
  if self.parent and self.parent.on_level_orb_destroyed then
    self.parent:on_level_orb_destroyed()
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
  self:add_progress_sound()
  self:add_progress_ripple()
  self.last_progress_sound_time = Helper.Time.time
end
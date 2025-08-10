-- Homing Missile Spell
-- A projectile that homes in on its target with limited turn speed
-- Explodes after a set time, distance, or on hitting a target
--
-- Supports both unit targeting and ground targeting
-- Can be launched with custom starting angles or angle offsets

HomingMissile = Object:extend()
HomingMissile.__class_name = 'HomingMissile'
HomingMissile:implement(GameObject)
HomingMissile:implement(Physics)

function HomingMissile:init(args)
  self:init_game_object(args)

  -- Missile properties
  self.damage = get_dmg_value(self.damage)
  self.speed = self.speed or 200
  self.max_turn_speed = self.max_turn_speed or math.pi -- radians per second
  self.color = self.color or orange[0]
  self.radius = self.radius or 3
  
  -- Explosion properties
  self.explosion_radius = self.explosion_radius or 60
  self.explosion_damage = self.explosion_damage or self.damage
  self.explosion_color = self.explosion_color or red[0]
  
  -- Termination conditions
  self.max_lifetime = self.max_lifetime or 5.0 -- seconds
  self.max_distance = self.max_distance or 800 -- pixels
  self.explode_on_impact = args.explode_on_impact ~= false -- default true
  
  -- Position and movement
  self.unit = self.unit
  self.target = self.target
  self.target_x = self.target_x -- For ground targeting
  self.target_y = self.target_y -- For ground targeting
  self.x = self.x or (self.unit and self.unit.x) or 0
  self.y = self.y or (self.unit and self.unit.y) or 0
  self.start_x = self.x
  self.start_y = self.y
  
  -- Angle configuration
  self.starting_angle = self.starting_angle -- Override initial angle
  self.angle_offset = self.angle_offset or 0 -- Offset from target angle
  
  -- Calculate initial angle
  self.angle = self:calculate_initial_angle()
  
  -- Create hitbox
  self.shape = Circle(self.x, self.y, self.radius)
  
  -- Tracking
  self.lifetime = 0
  self.already_hit_targets = {}
  self.has_exploded = false
  
  -- Trail effect properties
  self.trail_positions = {}
  self.trail_max_length = 8
  self.trail_update_timer = 0
  self.trail_update_interval = 0.05
  
  -- Sound effect
  if magic1 then
    magic1:play{pitch = random:float(1.2, 1.4), volume = 0.4}
  end
end

function HomingMissile:update(dt)
  self:update_game_object(dt)
  
  if self.dead or self.has_exploded then
    return
  end
  
  self.lifetime = self.lifetime + dt
  
  -- Check termination conditions
  if self.lifetime >= self.max_lifetime then
    self:explode()
    return
  end
  
  local distance_traveled = math.distance(self.start_x, self.start_y, self.x, self.y)
  if distance_traveled >= self.max_distance then
    self:explode()
    return
  end
  
  -- Update homing behavior
  self:update_homing(dt)
  
  -- Move missile
  self.x = self.x + math.cos(self.angle) * self.speed * dt
  self.y = self.y + math.sin(self.angle) * self.speed * dt
  
  -- Update hitbox
  self.shape:move_to(self.x, self.y)
  
  -- Update trail
  self:update_trail(dt)
  
  -- Check for target collision
  if self.explode_on_impact then
    self:check_collisions()
  end
end

function HomingMissile:calculate_initial_angle()
  -- If starting_angle is explicitly provided, use it
  if self.starting_angle then
    return self.starting_angle
  end
  
  -- Calculate base angle toward target
  local base_angle = 0
  
  if self.target and not self.target.dead then
    -- Unit target
    base_angle = math.atan2(self.target.y - self.y, self.target.x - self.x)
  elseif self.target_x and self.target_y then
    -- Ground target
    base_angle = math.atan2(self.target_y - self.y, self.target_x - self.x)
  else
    -- No target, use current angle or default
    base_angle = self.angle or 0
  end
  
  -- Apply angle offset
  return base_angle + self.angle_offset
end

function HomingMissile:get_target_position()
  if self.target and not self.target.dead then
    return self.target.x, self.target.y
  elseif self.target_x and self.target_y then
    return self.target_x, self.target_y
  else
    return nil, nil
  end
end

function HomingMissile:update_homing(dt)
  local target_x, target_y = self:get_target_position()
  
  if not target_x or not target_y then
    return
  end
  
  -- Calculate desired angle to target
  local target_angle = math.atan2(target_y - self.y, target_x - self.x)
  
  -- Calculate the shortest angular distance
  local angle_diff = target_angle - self.angle
  
  -- Normalize angle difference to [-π, π]
  while angle_diff > math.pi do
    angle_diff = angle_diff - 2 * math.pi
  end
  while angle_diff < -math.pi do
    angle_diff = angle_diff + 2 * math.pi
  end
  
  -- Apply turn speed limit
  local max_turn_this_frame = self.max_turn_speed * dt
  if math.abs(angle_diff) <= max_turn_this_frame then
    self.angle = target_angle
  else
    if angle_diff > 0 then
      self.angle = self.angle + max_turn_this_frame
    else
      self.angle = self.angle - max_turn_this_frame
    end
  end
end

function HomingMissile:update_trail(dt)
  self.trail_update_timer = self.trail_update_timer + dt
  
  if self.trail_update_timer >= self.trail_update_interval then
    self.trail_update_timer = 0
    
    -- Add current position to trail
    table.insert(self.trail_positions, 1, {x = self.x, y = self.y})
    
    -- Limit trail length
    while #self.trail_positions > self.trail_max_length do
      table.remove(self.trail_positions)
    end
  end
end

function HomingMissile:check_collisions()
  -- Check for collisions with appropriate targets
  local target_classes = self.is_troop and main.current.enemies or main.current.friendlies
  local targets = main.current.main:get_objects_in_shape(self.shape, target_classes)
  
  if #targets > 0 then
    for _, target in ipairs(targets) do
      if not table.any(self.already_hit_targets, function(hit_target) return hit_target.id == target.id end) then
        self:explode()
        return
      end
    end
  end
end

function HomingMissile:explode()
  if self.has_exploded then
    return
  end
  
  self.has_exploded = true
  
  -- Create explosion area effect
  Area_Spell{
    group = main.current.effects,
    x = self.x,
    y = self.y,
    radius = self.explosion_radius,
    damage = self.explosion_damage,
    duration = 0.3,
    fade_duration = 0.2,
    color = self.explosion_color,
    opacity = 0.15,
    line_width = 2,
    damage_type = self.damage_type or DAMAGE_TYPE_PHYSICAL,
    hit_only_once = true,
    unit = self.unit,
    is_troop = self.is_troop,
    on_hit_callback = self.on_hit_callback,
  }
  
  -- Explosion sound
  if hit3 then
    hit3:play{pitch = random:float(0.8, 1.2), volume = 0.6}
  end
  
  -- Visual explosion effect (simple expanding circle)
  self:create_explosion_effect()
  
  self:die()
end

function HomingMissile:create_explosion_effect()
  -- Create a simple expanding circle effect
  local effect = Object:extend()
  effect:implement(GameObject)
  
  local explosion_effect = effect{
    group = main.current.effects,
    x = self.x,
    y = self.y,
    radius = 0,
    max_radius = self.explosion_radius * 1.2,
    expansion_speed = self.explosion_radius * 8, -- pixels per second
    duration = 0.4,
    timer = 0,
    color = self.explosion_color:clone(),
  }
  
  function explosion_effect:update(dt)
    self.timer = self.timer + dt
    self.radius = self.radius + self.expansion_speed * dt
    
    -- Fade out over time
    local fade_progress = self.timer / self.duration
    self.color.a = (1 - fade_progress) * 0.4
    
    if self.timer >= self.duration or self.radius >= self.max_radius then
      self:die()
    end
  end
  
  function explosion_effect:draw()
    if self.radius > 0 then
      graphics.circle(self.x, self.y, self.radius, self.color, 2)
    end
  end
  
  function explosion_effect:die()
    self.dead = true
  end
end

function HomingMissile:draw()
  if self.has_exploded then
    return
  end
  
  -- Draw trail
  self:draw_trail()
  
  -- Draw missile body
  graphics.circle(self.x, self.y, self.radius, self.color)
  
  -- Draw directional indicator (small line showing direction)
  local indicator_length = self.radius * 2
  local end_x = self.x + math.cos(self.angle) * indicator_length
  local end_y = self.y + math.sin(self.angle) * indicator_length
  graphics.line(self.x, self.y, end_x, end_y, 1, self.color)
end

function HomingMissile:draw_trail()
  if #self.trail_positions < 2 then
    return
  end
  
  -- Draw trail with fading opacity
  for i = 1, #self.trail_positions - 1 do
    local current_pos = self.trail_positions[i]
    local next_pos = self.trail_positions[i + 1]
    
    -- Calculate opacity based on position in trail (newer = more opaque)
    local opacity_factor = (1 - (i - 1) / #self.trail_positions) * 0.6
    local trail_color = self.color:clone()
    trail_color.a = opacity_factor
    
    -- Draw line segment
    graphics.line(current_pos.x, current_pos.y, next_pos.x, next_pos.y, 1, trail_color)
  end
end

function HomingMissile:die()
  self.dead = true
end

-- Spell wrapper for the missile
HomingMissile_Spell = Spell:extend()

function HomingMissile_Spell:init(args)
  HomingMissile_Spell.super.init(self, args)
  
  -- Create the actual missile projectile
  HomingMissile{
    group = main.current.main,
    unit = self.unit,
    target = self.target,
    target_x = self.target_x,
    target_y = self.target_y,
    x = self.x,
    y = self.y,
    damage = self.damage,
    speed = self.speed,
    max_turn_speed = self.max_turn_speed,
    starting_angle = self.starting_angle,
    angle_offset = self.angle_offset,
    explosion_radius = self.explosion_radius,
    explosion_damage = self.explosion_damage,
    max_lifetime = self.max_lifetime,
    max_distance = self.max_distance,
    explode_on_impact = self.explode_on_impact,
    color = self.color,
    explosion_color = self.explosion_color,
    damage_type = self.damage_type,
    is_troop = self.is_troop,
    on_hit_callback = self.on_hit_callback,
  }
  
  -- The spell completes immediately after creating the missile
  self:die()
end

function HomingMissile_Spell:update(dt)
  -- No update needed, missile handles itself
end

function HomingMissile_Spell:draw()
  -- No drawing needed, missile handles itself
end
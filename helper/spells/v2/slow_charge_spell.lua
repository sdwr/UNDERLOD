SlowChargeSpell = Object:extend()
SlowChargeSpell.__class_name = 'SlowChargeSpell'
SlowChargeSpell:implement(GameObject)

function SlowChargeSpell:init(args)
  self:init_game_object(args)
  
  self.unit = args.unit
  self.damage = args.damage or function() return 10 end
  self.color = args.color or red[0]
  
  -- Charging variables
  self.charge_speed = 0
  self.max_charge_speed = 200
  self.charge_acceleration = 50  -- Speed increase per second
  self.is_charging = false
  self.charge_direction = {x = 0, y = 0}
  
  -- Set unit to channeling state
  Helper.Unit:set_state(self.unit, unit_states['channeling'])
  
  -- Calculate direction to target
  if self.unit.target then
    local dx = self.unit.target.x - self.unit.x
    local dy = self.unit.target.y - self.unit.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance > 0 then
      self.charge_direction.x = dx / distance
      self.charge_direction.y = dy / distance
    end
  end
  
  -- Play charge sound
  if args.cast_sound then
    args.cast_sound:play{pitch = random:float(0.9, 1.1), volume = args.cast_volume or 1.0}
  end
end

function SlowChargeSpell:update(dt)
    self:update_game_object(dt)
    
    if self.unit.target and not self.unit.target.dead then
      -- Rotate unit towards target (this is fine)
      self.unit:rotate_towards_object(self.unit.target, 1)

      -- ✅ ADD NEW LOGIC
      -- Calculate the force needed to achieve the desired acceleration. F = m*a
      -- Assumes the unit has a 'mass' property from the Physics mixin.
      local force_magnitude = self.unit.mass * self.charge_acceleration
  
      -- Calculate the angle of the charge direction
      local angle = math.atan2(self.charge_direction.y, self.charge_direction.x)
  
      -- Apply this as a continuous steering force.
      -- We do not pass the 's' (duration) parameter, so it remains active
      -- as long as this function is called.
      self.unit:apply_steering_force(force_magnitude, angle)
      
      -- The hit-check logic remains the same
      local distance_to_target = self.unit:distance_to_object(self.unit.target)
      if distance_to_target < 30 then
        self:charge_hit(self.unit.target)
        self:end_charge()
      end
    else
      self:end_charge()
    end
  end

function SlowChargeSpell:charge_hit(target)
  if target and not target.dead then
    -- Deal damage
    target:hit(self.damage(), self.unit, nil, true, false)
    
    -- Play hit sound
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
    
    -- Create hit effect
    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 20, color = self.color, duration = 0.2}
    for i = 1, 5 do 
      HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} 
    end
  end
end

function SlowChargeSpell:end_charge()
  -- Reset charging state (optional, as the spell object will be destroyed)
  self.charge_speed = 0
  self.is_charging = false
  
  -- The physics system will no longer receive 'apply_steering_force' from this spell
  self.dead = true

  -- Optional: Immediately stop the unit's movement
  self.unit:set_velocity(0, 0) 
end

function SlowChargeSpell:draw()
  -- Draw charge trail when charging at high speed
  if self.charge_speed > 50 then
    local trail_length = math.min(self.charge_speed / 10, 20)
    local trail_color = self.color:clone()
    trail_color.a = 0.5
    
    graphics.push(self.unit.x, self.unit.y, 0, 0, 0)
    graphics.line(
      self.unit.x - self.charge_direction.x * trail_length, 
      self.unit.y - self.charge_direction.y * trail_length,
      self.unit.x, 
      self.unit.y, 
      trail_color, 
      3
    )
    graphics.pop()
  end
end 
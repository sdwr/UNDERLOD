local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'golem'
  self.movementStyle = MOVEMENT_TYPE_SEEK

  --set stats and cooldowns
  self.baseCast = attack_speeds['medium-slow']
  self.cooldownTime = attack_speeds['medium-slow']
  self:reset_castcooldown(self.cooldownTime)

  self.stopChasingInRange = false
  self.haltOnPlayerContact = false

  -- Set unlimited attack range
  self.attack_range = 9999  -- Unlimited range
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)
  self.aggro_sensor = Circle(self.x, self.y, self.attack_range)

  -- No movement options - only attacks
  self.movement_options = {}
  self.move_option_weight = 0.0  -- Always attack when viable

  --set attacks
  self.attack_options = {}

  local charge_attack = {
    name = 'charge',
    viable = function() 
      local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
      return target 
    end,
    oncast = function() 
      self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
    end,
    cast_length = 0.5,  -- Brief windup
    castcooldown = self.cooldownTime,
    instantspell = false,
    cast_sound = usurer1,
    cast_volume = 1.5,
    spellclass = SlowChargeSpell,
    spelldata = {
      group = main.current.effects,
      unit = self,
      team = "enemy",
      damage = function() return self.dmg * 2 end,  -- Double damage on charge
      color = red[0],
      parent = self
    },
  }

  table.insert(self.attack_options, charge_attack)
end

-- Override the update function to handle charging movement
fns['update'] = function(self, dt)
  Enemy.super.update(self, dt)
  
  -- Charging logic is now handled by the spell
  -- Reset charging state if we're not charging anymore
  if self.is_charging and not self.castObject then
    self.is_charging = false
    self.charge_speed = 0
  end
end

-- Handle charge hit
fns['charge_hit'] = function(self, target)
  if target and not target.dead then
    -- Deal damage
    target:hit(self.dmg * 2, self, nil, true, false)
    
    -- Play hit sound
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
    
    -- Create hit effect
    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 20, color = self.color, duration = 0.2}
    for i = 1, 5 do 
      HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} 
    end
  end
end

-- Override collision to handle wall hits
fns['on_collision_enter'] = function(self, other, contact)
  if other:is(Wall) then
    -- Stop charging when hitting wall
    if self.castObject then
      self:cancel_cast()
    end
    self.hfx:use('hit', 0.15, 200, 10, 0.1)
    self:bounce(contact:getNormal())
  elseif table.any(main.current.friendlies, function(v) return other:is(v) end) then
    -- Stop charging when hitting friendly
    if self.castObject then
      self:cancel_cast()
    end
    self:charge_hit(other)
  end
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  
  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end
  
end

enemy_to_class['slowcharger'] = fns 
enemy_to_class = {}

Enemy = Unit:extend()
Enemy:implement(GameObject)
Enemy:implement(Physics)
function Enemy:init(args)
  self:init_game_object(args)

  self.faction = 'enemy'

  self:setExtraFunctions()
  Helper.Unit:add_custom_variables_to_unit(self)
  Helper.Unit:set_state(self, unit_states['normal'])
  self.init_enemy(self)
  self:init_unit()
  self:init_hitbox_points()

  self.spritesheet = find_enemy_spritesheet(self)

  self:calculate_stats(true)

  self.movementStyle = self.movementStyle or MOVEMENT_TYPE_SEEK
  self.stopChasingInRange = not not self.stopChasingInRange
  self.haltOnPlayerContact = not not self.haltOnPlayerContact

  self.castcooldown = math.random() * (self.base_castcooldown or self.baseCast)
  
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 20 + self.shape.w / 2)
  self.aggro_sensor = self.aggro_sensor or Circle(self.x, self.y, 1000)
  
  self.base_castcooldown = self.base_castcooldown or 3
  self.last_attack_started = 0

  self.random_dest = {x = self.x, y = self.y}
  self.random_dest_timer = 0


end

--load enemy type specific functions from global table
--note: can't be named any of the base enemy functions
-- or they will be overwritten (so init_enemy instead of init)
function Enemy:setExtraFunctions()
  local t = enemy_to_class[self.type]
  for k, v in pairs(t) do
    self[k] = v
  end
end

function Enemy:has_animation(state)
  if self.spritesheet then
    if self.spritesheet[state] then
      return true
    end
  end
  return false
end

function Enemy:update_animation(dt)
  if self.spritesheet and self.spritesheet[self.state] then
    local animation = self.spritesheet[self.state][1]
    local image = self.spritesheet[self.state][2]
    animation:update(dt)
  elseif self.spritesheet and self.spritesheet['normal'] then
    local animation = self.spritesheet['normal'][1]
    local image = self.spritesheet['normal'][2]
    animation:update(dt)
  end
end

function Enemy:draw_animation(state, x, y, r)
  -- Safety checks from Helper.Unit
  if not self.spritesheet then
    return false
  end
  if not self.icon then
    print('no icon for unit ' .. self.type)
    return false
  end

  local direction = self:is_facing_left() and -1 or 1
  local sprite_size = enemy_sprite_sizes[self.icon]
  if not sprite_size then
    print('no sprite size for unit ' .. self.type)
    return false
  end

  local animation = nil
  local image = nil
  local anim_set = self.spritesheet[state] or self.spritesheet['normal']
  if anim_set then
    animation = anim_set[1]
    image = anim_set[2]
  end

  if not animation or not image then
    print('no animation or image for unit ' .. self.type)
    return false
  end

  local sprite_scale = enemy_sprite_scales[self.icon]
  if not sprite_scale then
    print('no sprite scale for unit ' .. self.type)
    return false
  end
  
  -- Calculate scale using global constants
  local scale_x = (self.shape.w / sprite_size[1]) * sprite_scale * direction
  local scale_y = (self.shape.h / sprite_size[2]) * sprite_scale
  
  local frame_width, frame_height = animation:getDimensions()
  local frame_center_x = frame_width / 2
  local frame_center_y = frame_height / 2

  graphics.push(x, y, 0, self.hfx.hit.x, self.hfx.hit.x)
    animation:draw(image.image, x, y, r, scale_x, scale_y, frame_center_x, frame_center_y)
  graphics.pop()
  return true

end


--set castcooldown and self.base_castcooldown in the enemy file (init)
function Enemy:update(dt)
    self:update_game_object(dt)
    self:update_cast_cooldown(dt)

    self:onTickCallbacks(dt)
    self:update_buffs(dt)

    self:update_animation(dt)

    self:calculate_stats()
    
    self.random_dest_timer = self.random_dest_timer - dt

    --get target / rotate to target
    if self.target and self.target.dead then self.target = nil end
    
    if self.state == unit_states['normal'] or (self.can_cast_while_frozen and self.state == unit_states['frozen']) then

      --this needs to work with movement options (some attacks will require target in range, others will not)
      --some will want to chase target (fire breath)
      --when a cast concludes, enemy should return to normal movement, set castcooldown in there from
      --the enemy cooldown
      if self.attack_options and self.castcooldown ~= nil and self.castcooldown <= 0 then
        self:pick_cast()
      end
    end

    --do movement and target selection only if not casting
    if table.any(unit_states_can_target, function(v) return self.state == v end) then
      if self.movementStyle == MOVEMENT_TYPE_SEEK then
        self:update_target_seek()
      elseif self.movementStyle == MOVEMENT_TYPE_RANDOM then
        self:update_target_random()
      else
        --pass, add flee later
        --flee has to not just go for the corners (directly running away)
        --has to look over entire map and pick a random "safe spot" away from troops
      end
    elseif self.state == unit_states['stopped'] or self.state == unit_states['casting'] or self.state == unit_states['channeling'] then
      if self.target and not self.target.dead and not self:should_freeze_rotation() then
        self:rotate_towards_object(self.target, 1)
      end
    end


    --move
    if table.any(unit_states_enemy_can_move, function(v) return self.state == v end) then
      if self.movementStyle == MOVEMENT_TYPE_SEEK then
        self:update_move_seek()
      elseif self.movementStyle == MOVEMENT_TYPE_RANDOM then
        self:update_move_random()
      else
        --pass, add flee later
      end
    elseif table.any(unit_states_enemy_no_velocity, function(v) return self.state == v end) then
      self:set_velocity(0,0)
    end

    self.r = self:get_angle()
  
  
    self.attack_sensor:move_to(self.x, self.y)
    self.aggro_sensor:move_to(self.x, self.y)
  
    if self.area_sensor then self.area_sensor:move_to(self.x, self.y) end
end

function Enemy:update_target_seek()
  if not self:in_range()() then
    -- 30% chance to target critters
    if random:float(0, 1) < ENEMY_CHANCE_TO_TARGET_CRITTER then
      self.target = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
    else
      self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies_without_critters)
    end
  end
  if self.target and self.target.dead then self.target = nil end
  if self.target then
    self:rotate_towards_object(self.target, 0.5)
  end
end

function Enemy:update_move_seek()
  if self:in_range()() and self.stopChasingInRange then
    -- dont need to move
  elseif self.target then
  --can't change speed?
    local decel = SEEK_DECELERATION
    if self.stopChasingInRange then
      decel = 0
    end
    self:seek_point(self.target.x, self.target.y, decel, SEEK_WEIGHT)
    self:wander(50, 200, 5)
    self:rotate_towards_velocity(1)
    self:steering_separate(16, {Enemy}, 8)
    -- self:rotate_towards_velocity(0.5)
  else
    -- dont need to move
  end
end

function Enemy:update_target_random()
  if not self:in_range()() then
    if random:float(0, 1) < ENEMY_CHANCE_TO_TARGET_CRITTER then
      self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
    else
      self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies_without_critters)
    end
  end
  if self.target and self.target.dead then self.target = nil end
  if self.target then
    self:rotate_towards_object(self.target, 0.5)
  end
end

function Enemy:update_move_random()
  if self.random_dest_timer <= 0 then
    self.random_dest = Get_Point_In_Arena()
    self.random_dest_timer = 5
  end

  self:seek_point(self.random_dest.x, self.random_dest.y, SEEK_DECELERATION, SEEK_WEIGHT)
  self:wander(50, 200, 5)
  self:rotate_towards_velocity(1)
  self:steering_separate(16, {Enemy}, 8)
end

function Enemy:draw()
  self:draw_targeted()
  self:draw_buffs()
  self.draw_enemy(self)
  self:draw_launching()
  self:draw_channeling()
  self:draw_frozen()
  self:draw_knockback()
  self:draw_cast_timer()
end

function Enemy:on_collision_enter(other, contact)
    local x, y = contact:getPositions()
    
    if other:is(Wall) then
        self.hfx:use('hit', 0.15, 200, 10, 0.1)
        self:bounce(contact:getNormal())

    elseif table.any(main.current.friendlies, function(v) return other:is(v) end) then
      if self.haltOnPlayerContact then
        self:set_velocity(0,0)
        Helper.Unit:set_state(self, unit_states['frozen'])
        self.t:after(0.8, function()
          if self.state == unit_states['frozen'] then
            Helper.Unit:set_state(self, unit_states['normal'])
          end
        end)
      end
    
    elseif table.any(main.current.enemies, function(v) return other:is(v) end) then
        -- if self.being_pushed and math.length(self:get_velocity()) > 60 then
        --     other:hit(math.floor(self.push_force/4), nil, nil, true)
        --     self:hit(math.floor(self.push_force/2), nil, nil, true)
        --     other:push(math.floor(self.push_force/2), other:angle_to_object(self))
        --     HitCircle{group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1}
        --     for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = self.color} end
        --     hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
        -- end
    end
end

function Enemy:hit(damage, from, damageType, makesSound, cannotProcOnHit)

  if self.invulnerable then return end

  if makesSound == nil then makesSound = true end
  if cannotProcOnHit == nil then cannotProcOnHit = false end
  
  if self.dead then return end
  if self.isBoss then
    if makesSound then
      self.hfx:use('hit', 0.005, 200, 20)
    end
  else
    --scale hit effect to damage
    --no damage won't grow model, up to max effect at 0.5x max hp
    local hitStrength = (damage * 1.0) / self.max_hp
    hitStrength = math.min(hitStrength, 0.5)
    hitStrength = math.remap(hitStrength, 0, 0.5, 0, 1)
    if makesSound then
      self.hfx:use('hit', 0.25 * hitStrength, 200, 10)
    end
  end
  if self.push_invulnerable then return end
  self:show_hp()

  local actual_damage = math.max(self:calculate_damage(damage)*(self.stun_dmg_m or 1), 0)
  self:show_damage_number(actual_damage, damageType)

  if damageType == DAMAGE_TYPE_FIRE then
    self:burn(actual_damage, from)
  end

  if damageType == DAMAGE_TYPE_LIGHTNING then
    ChainLightning{
      group = main.current.main, 
      target = self, range = 50, 
      dmg = actual_damage, color = yellow[0], 
      parent = self,
      is_troop = not self.is_troop}
  end

  if damageType == DAMAGE_TYPE_SHOCK then
    self:shock()
  end

  if damageType == DAMAGE_TYPE_COLD then
    self:chill(actual_damage, from)
  end


  
  self.hp = self.hp - actual_damage
  if self.hp > self.max_hp then self.hp = self.max_hp end
  main.current.damage_dealt = main.current.damage_dealt + actual_damage

  --callbacks
  if from and from.onHitCallbacks and not cannotProcOnHit then
    from:onHitCallbacks(self, actual_damage, damageType)
  end
  self:onGotHitCallbacks(from, actual_damage, damageType)

  if self.hp <= 0 then
    --on death callbacks
    local overkill = - self.hp
    if from and from.onKillCallbacks then
      from:onKillCallbacks(self, overkill)
    end
    self:onDeathCallbacks(from)

    self:die()
    for i = 1, random:int(4, 6) do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 12}:scale_down(0.3):change_color(0.5, self.color)
    magic_hit1:play{pitch = random:float(0.9, 1.1), volume = 0.5}

    if self.isBoss then
      slow(0.25, 1)
      magic_die1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    end
  end
end

function Enemy:onDeath()
  if self.parent and self.parent.summons then
    self.parent.summons = self.parent.summons - 1
  end

  self.state_change_functions['death'](self)
  self.death_function()
end

function Enemy:die()
  if self.dead then return end
  self.super.die(self)
  self.dead = true
  -- update progress bar in arena, based on enemy value
  --progress bar is hidden for bosses
  if main.current.progress_bar then
    local progress_amount = 0
    progress_amount = enemy_to_round_power[self.type] or 0

    main.current.progress_bar:increase_with_particles(progress_amount, self.x, self.y)
  end

  if self.parent and self.parent.summons and self.parent.summons > 0 then
    self.parent.summons = self.parent.summons - 1
  end
end

function Enemy:push(f, r, push_invulnerable, duration)
    local n = 1
    if self.boss then n = 0.2 end

    if self.state == unit_states['knockback'] then
      return
    end

    -- self.state = unit_states['knockback']

    Helper.Unit:set_state(self, unit_states['knockback'])
    self.push_invulnerable = push_invulnerable
    self.push_force = n*f
    self.being_pushed = true
    self.steering_enabled = false
    self:apply_impulse(n*f*math.cos(r), n*f*math.sin(r))
    self:apply_angular_impulse(random:table{random:float(-12*math.pi, -4*math.pi), random:float(4*math.pi, 12*math.pi)})
    self:set_damping(1.5*(1/n))
    self:set_angular_damping(1.5*(1/n))

      -- Cancel any existing during trigger for push
  if self.cancel_trigger_tag then
    self.t:cancel(self.cancel_trigger_tag)
  end

  -- Reset state after the duration
  self.cancel_trigger_tag = self.t:after(duration, function()
    self.steering_enabled = true
    if self.state == unit_states['knockback'] then
      Helper.Unit:set_state(self, unit_states['normal'])
    end
  end)
end

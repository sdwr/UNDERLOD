enemy_to_class = {}

Enemy = Unit:extend()
Enemy:implement(GameObject)
Enemy:implement(Physics)
function Enemy:init(args)
  self:init_game_object(args)

  self.faction = 'enemy'
  self.transition_active = false

  self:setExtraFunctions()
  Helper.Unit:add_custom_variables_to_unit(self)
  Helper.Unit:set_state(self, unit_states['idle'])
  self.size = self.size or enemy_type_to_size[self.type]
  self.init_enemy(self)
  --cast_cooldown and basecast are set custom in init_enemy
  --overwrite again for The longer a troop goes without attacking, the more damage they deal on their next attack
  self.baseCast = 1
  self.castcooldown = 1

  self:init_unit()
  self:init_hitbox_points()

  self.spritesheet = find_enemy_spritesheet(self)

  self:calculate_stats(true)

  self.baseIdleTimer = self.baseIdleTimer or 0.5
  self.idleTimer = self.baseIdleTimer
  self.baseActionTimer = self.baseActionTimer or 1
  self.actionTimer = 0

  self.movementStyle = self.movementStyle or MOVEMENT_TYPE_SEEK
  self.currentMovementAction = nil
  self.stopChasingInRange = not not self.stopChasingInRange
  self.haltOnPlayerContact = not not self.haltOnPlayerContact

  self:reset_castcooldown(self.castcooldown or 1)
  
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 20 + self.shape.w / 2)
  self.aggro_sensor = self.aggro_sensor or Circle(self.x, self.y, 1000)
  
  self.last_attack_started = 0

  self.random_dest = {x = self.x, y = self.y}
  self.random_dest_timer = 0


end

--load enemy type specific functions from global table
--note: can't be named any of the base enemy functions
-- or they will be overwritten (so init_enemy instead of init)
function Enemy:setExtraFunctions()
  local t = enemy_to_class[self.type]
  if not t then
    print('no extra functions for', self.type)
  end
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
  if self.state == unit_states['stunned'] then
    return
  end

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

function Enemy:draw_animation()
  return DrawAnimations.draw_enemy_animation(self, self.state, self.x, self.y, 0)
end


--set castcooldown and in the enemy file (init)
function Enemy:update(dt)
    Enemy.super.update(self, dt)
    self:update_cast_cooldown(dt)

    self:onTickCallbacks(dt)
    self:update_buffs(dt)

    self:update_animation(dt)



    self:calculate_stats()
    
    self.random_dest_timer = self.random_dest_timer - dt

    -- Don't take actions if transition is not complete
    if not self.transition_active then
      return
    end

    --get target / rotate to target
    if self.target and self.target.dead then self.target = nil end
    
    if self.state == unit_states['idle'] then
      self.idleTimer = self.idleTimer - dt
      if self.idleTimer <= 0 then
        self:pick_action()
      end
    end

    if self.state == unit_states['moving'] then
      self.actionTimer = self.actionTimer - dt
      if self.actionTimer <= 0 then
        self:set_idle()
      else
        local movement_success = self:update_movement()
        if not movement_success then
          self:set_idle()
        end
      end
    end


    if self.state == unit_states['stopped'] or self.state == unit_states['casting'] or self.state == unit_states['channeling'] then
      if self.target and not self.target.dead and not self:should_freeze_rotation() then
        self:rotate_towards_object(self.target, 1)
      end
    end

    if table.any(unit_states_enemy_no_velocity, function(v) return self.state == v end) then
      self:set_velocity(0,0)
    end

    self.r = self:get_angle()
  
  
    self.attack_sensor:move_to(self.x, self.y)
    self.aggro_sensor:move_to(self.x, self.y)
  
    if self.area_sensor then self.area_sensor:move_to(self.x, self.y) end
end

function Enemy:set_idle()
  self.idleTimer = self.baseIdleTimer * random:float(0.8, 1.2)
  Helper.Unit:set_state(self, unit_states['idle'])
end

function Enemy:set_movement_action(action)
  self.currentMovementAction = action
  self.actionTimer = self.baseActionTimer * random:float(0.8, 1.2)

  Helper.Unit:set_state(self, unit_states['moving'])
  local chose_target_success = self:choose_movement_target()
  if not chose_target_success then
    self:set_idle()
  end
end

function Enemy:choose_movement_target()
  if self.currentMovementAction == MOVEMENT_TYPE_SEEK then
    return self:acquire_target_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_LOOSE_SEEK then
    return self:acquire_target_loose_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK_TO_RANGE then
    return self:acquire_target_seek_to_range()
  elseif self.currentMovementAction == MOVEMENT_TYPE_RANDOM then
    return self:acquire_target_random()
  end
end

function Enemy:update_movement()
  if self.being_knocked_back then return end
  if not self.transition_active then return end
  
  if self.currentMovementAction == MOVEMENT_TYPE_SEEK then
    return self:update_move_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_LOOSE_SEEK then
    return self:update_move_loose_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK_TO_RANGE then
    return self:update_move_seek_to_range()
  elseif self.currentMovementAction == MOVEMENT_TYPE_RANDOM then
    return self:update_move_random()
  elseif self.currentMovementAction == MOVEMENT_TYPE_WANDER then
    return self:update_move_wander()
  end
  return false
end

function Enemy:acquire_target_seek()
  -- 30% chance to target critters
  if random:float(0, 1) < ENEMY_CHANCE_TO_TARGET_CRITTER then
    self.target = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
  else
    self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies_without_critters)
  end
  return self.target ~= nil
end

function Enemy:acquire_target_loose_seek()
  self.target_location = nil
  self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
  if self.target then
    self.target_location = {x = self.target.x + random:float(-LOOSE_SEEK_OFFSET, LOOSE_SEEK_OFFSET), y = self.target.y + random:float(-LOOSE_SEEK_OFFSET, LOOSE_SEEK_OFFSET)}
  end
  return self.target ~= nil
end

function Enemy:acquire_target_seek_to_range()
  --if we are in range of the target, keep the target
  if self.target and self:in_range_of(self.target) then
    -- Calculate point at enemy's attack range from the target's position, towards the enemy
    local angle_to_enemy = self.target:angle_to_object(self)
    local distance_from_target = self.attack_sensor.rs - 10
    self.target_location = {
      x = self.target.x + distance_from_target * math.cos(angle_to_enemy),
      y = self.target.y + distance_from_target * math.sin(angle_to_enemy)
    }
  else
    --else, target a random enemy
    self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
  end

  if self.target then
    -- Calculate point at enemy's attack range from the target's position, towards the enemy
    local angle_to_enemy = self.target:angle_to_object(self)
    local distance_from_target = self.attack_sensor.rs - 10
    self.target_location = {
      x = self.target.x + distance_from_target * math.cos(angle_to_enemy),
      y = self.target.y + distance_from_target * math.sin(angle_to_enemy)
    }
  else
    self.target_location = nil
  end

  return self.target ~= nil
end

function Enemy:acquire_target_random()
  self.target_location = Get_Point_In_Arena()
  return true
end

function Enemy:update_move_wander()
  self:wander(10, 10, 5)
  return true
end

function Enemy:update_move_seek()
  -- 1. Guard clause: If there's no target, this action can't continue.
  if not self.target then
      return false -- Indicates the movement action failed/is complete.
  end

  -- 2. Check if we are in range.
  if self:in_range_of(self.target) and self.stopChasingInRange then
      -- We are in range and should stop, so just mill about.
      self:wander(10, 10, 5)

  else
      -- We are OUT of range, OR we are not supposed to stop.
      -- In either case, we must seek the target.
      self:seek_point(self.target.x, self.target.y, SEEK_DECELERATION, SEEK_WEIGHT)
      self:wander(10, 10, 5) -- Add a little variation to the seek.
  end

  -- 3. Apply final steering adjustments in all active cases.
  self:rotate_towards_velocity(1)
  self:steering_separate(12, {Enemy}, 4)

  -- 4. Return true because the movement action is successfully ongoing.
  return true
end

function Enemy:update_move_loose_seek()
  
  if self.target_location then
    if self:distance_to_point(self.target_location.x, self.target_location.y) < DISTANCE_TO_TARGET_FOR_IDLE then
      return false
    else
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, SEEK_WEIGHT)
      self:wander(10, 10, 5)
      self:rotate_towards_velocity(1)
      self:steering_separate(12, {Enemy}, 4)
      return true
    end
  end
  return false
end

function Enemy:update_move_seek_to_range()
  if self.target_location then
    if self:distance_to_point(self.target_location.x, self.target_location.y) < DISTANCE_TO_TARGET_FOR_IDLE then
      return false
    else
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, SEEK_WEIGHT)
      self:wander(10, 10, 5)
      self:rotate_towards_velocity(1)
      self:steering_separate(12, {Enemy}, 4)
      return true
    end
  end
  return false
end

function Enemy:update_move_random()
  if self.target_location then
    if self:distance_to_point(self.target_location.x, self.target_location.y) < DISTANCE_TO_TARGET_FOR_IDLE then
      return false
    else
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, SEEK_WEIGHT)
      self:wander(10, 10, 5)
      self:rotate_towards_velocity(1)
      self:steering_separate(12, {Enemy}, 4)
      return true
    end
  end
  return false
end

function Enemy:draw()
  if DEBUG_ENEMY_MOVEMENT then
    self:draw_debug_info()
  end
  self:draw_targeted()
  self:draw_buffs()
  self.draw_enemy(self)
  self:draw_launching()
  self:draw_channeling()
  --the animation will draw the status effects if it exists
  if not self.spritesheet then
    self:draw_status_effects()
    self:draw_knockback()
  end
  self:draw_cast_timer()
end

function Enemy:on_collision_enter(other, contact)
    local x, y = contact:getPositions()
    
    if other:is(Wall) then
        self.hfx:use('hit', 0.15, 200, 10, 0.1)
        self:bounce(contact:getNormal())

    elseif table.any(main.current.friendlies, function(v) return other:is(v) end) then
      if self.class == 'regular_enemy' then
        local duration = KNOCKBACK_DURATION_ENEMY
        local push_force = LAUNCH_PUSH_FORCE_ENEMY
        local dmg = REGULAR_PUSH_DAMAGE
        self:push(push_force, self:angle_to_object(other) + math.pi, nil, duration)
        self:hit(dmg, other, nil, false, true)
      else
        if self.haltOnPlayerContact then
          self:set_velocity(0,0)
          Helper.Unit:set_state(self, unit_states['frozen'])
          self.t:after(0.8, function()
            if self.state == unit_states['frozen'] then
              Helper.Unit:set_state(self, unit_states['idle'])
            end
          end)
        end
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
  -- Mark this unit as an enemy for the damage helper
  self.isEnemy = true
  -- Use the indirect hit function (current behavior)
  Helper.Damage:indirect_hit(self, damage, from, damageType, makesSound)
end

function Enemy:onDeath()
  if self.parent and self.parent.summons then
    self.parent.summons = self.parent.summons - 1
  end
  
  -- Create death animation with reference to the enemy unit
  EnemyDeathAnimation{
    group = main.current.effects, 
    x = self.x, 
    y = self.y,
    enemy = self
  }
  
  self.state_change_functions['death'](self)
  self.death_function()
end

function Enemy:die()
  if self.dead then return end
  self.super.die(self)
  self.dead = true
  _G[random:table{'enemy_die1', 'enemy_die2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.9}
  -- update progress bar in arena, based on enemy value
  --progress bar is hidden for bosses
  if main.current.progress_bar then
    local progress_amount = 0
    progress_amount = enemy_to_round_power[self.type] or 0

    -- Defer particle creation to avoid physics world lock issues
    main.current.t:after(0, function()
      if main.current.progress_bar then
        main.current.progress_bar:increase_with_particles(progress_amount, self.x, self.y)
      end
    end)
  end

  if self.parent and self.parent.summons and self.parent.summons > 0 then
    self.parent.summons = self.parent.summons - 1
  end
end

-- ===================================================================
-- REFACTORED Enemy:push
-- Now also calls the standardized helper function.
-- ===================================================================
function Enemy:push(f, r, push_invulnerable, duration)
  -- Set a default duration if one isn't provided
  duration = duration or KNOCKBACK_DURATION_ENEMY

  -- Apply a multiplier to reduce knockback force on bosses
  local force_multiplier = 1
  if self.class == 'boss' then 
    return
  end

  -- Call the universal knockback function with the modified force
  Helper.Unit:apply_knockback(self, f * force_multiplier, r, duration, push_invulnerable)
end

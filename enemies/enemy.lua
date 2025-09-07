enemy_to_class = {}

Enemy = Unit:extend()
Enemy:implement(GameObject)
Enemy:implement(Physics)
function Enemy:init(args)
  self:init_game_object(args)

  self.faction = 'enemy'
  self.isEnemy = true
  self.transition_active = true

  self:setExtraFunctions()
  Helper.Unit:add_custom_variables_to_unit(self)
  Helper.Unit:set_state(self, unit_states['idle'])
  self.size = self.size or enemy_type_to_size[self.type]
  self.init_enemy(self)

  self:init_unit()
  if self.type == 'swarmer' then
    self:hide_hp()
  end
  self:init_hitbox_points()

  self.spritesheet = find_enemy_spritesheet(self)

  self:calculate_stats(true)

  -- Special enemies get longer idle time
  if self.class == 'special_enemy' then
    self.baseIdleTimer = self.baseIdleTimer or 0.8
  else
    self.baseIdleTimer = self.baseIdleTimer or 0.3
  end
  self.idleTimer = self.baseIdleTimer
  self.baseActionTimer = self.baseActionTimer or 1
  self.actionTimer = 0


  self.currentMovementAction = nil
  self.stopChasingInRange = default_to(self.stopChasingInRange, false)
  self.haltOnPlayerContact = default_to(self.haltOnPlayerContact, true)

  self:set_attack_cooldown_timer(0)
  
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 20 + self.shape.w / 2)
  
  self.last_attack_started = 0

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

-- Draw fallback animation when spritesheet animation fails
-- Uses mask-based approach like sprite animations
function Enemy:draw_fallback_animation()
  -- First draw the base shape with base color
  self:draw_fallback_base_shape()
  
  -- Then apply status effect overlays
  self:draw_fallback_status_effects()
end

-- Draw the base shape (triangle for dragon, rounded rectangle for others)
function Enemy:draw_fallback_base_shape()
  -- Determine base color (hit flash, silenced, or normal color)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color
  
  graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)
  
  if self.type == 'dragon' then
    -- Special case: Dragon uses triangle polygon
    local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70, self:get_angle())
    graphics.polygon(points, base_color)
  else
    -- Default case: Rounded rectangle with size-appropriate corner radius
    local corner_radius = get_enemy_corner_radius(self)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, corner_radius, corner_radius, base_color)
  end
  
  graphics.pop()
end

-- Draw status effect overlays using the same mask-based approach as sprite animations
function Enemy:draw_fallback_status_effects()
  -- Determine status effect mask color (same priority order as in DrawAnimations.draw_enemy_animation)
  local mask_color = nil
  if self.buffs['chill'] then
    mask_color = CHILL_MASK_COLOR
  elseif self.buffs['freeze'] then
    mask_color = FREEZE_MASK_COLOR
  elseif self.buffs['stunned'] then
    mask_color = STUN_MASK_COLOR
  elseif self.buffs['burn'] then
    mask_color = BURN_MASK_COLOR
  end
  
  -- Apply status effect overlay if present
  if mask_color ~= nil then
    graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)
    
    if self.type == 'dragon' then
      -- Dragon triangle with status effect overlay
      local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70, self:get_angle())
      graphics.polygon(points, mask_color)
    else
      -- Rectangle with status effect overlay
      local corner_radius = get_enemy_corner_radius(self)
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, corner_radius, corner_radius, mask_color)
    end
    
    graphics.pop()
  end
end


--set castcooldown and in the enemy file (init)
function Enemy:update(dt)
    Enemy.super.update(self, dt)
    self:update_cast_cooldown(dt)

    self:onTickCallbacks(dt)
    self:update_buffs(dt)

    self:update_animation(dt)

    self.offscreen = not Helper.Target:is_in_camera_bounds(self.x, self.y)
    self.fully_onscreen = Helper.Target:is_fully_in_camera_bounds(self.x, self.y)
    self.way_onscreen = Helper.Target:way_inside_camera_bounds(self.x, self.y)
    self.way_offscreen = Helper.Target:way_outside_camera_bounds(self.x, self.y)
    
    if self.way_offscreen then
      self:despawn()
      return
    end

    if self.offscreen or not self.way_onscreen then
      self.in_arena_radius = false
    else
      self.in_arena_radius = Helper.Unit:in_range_of_player_location(self, ARENA_RADIUS)
    end

    if self.being_knocked_back then
      if math.length(self:get_velocity()) < ENEMY_KNOCKBACK_VELOCITY_REGAIN_CONTROL_THRESHOLD then
        Helper.Unit:reset_knockback_variables(self)
      end
    end



    self:calculate_stats()
    
    -- Don't take actions if transition is not complete
    if not self.transition_active then
      return
    end

    --get target / rotate to target
    if self.target and self.target.dead then self.target = nil end
    
    if self.state == unit_states['idle'] then
      self.idleTimer = self.idleTimer - dt
      self:add_idle_deceleration()
      if self.idleTimer <= 0 then
        local success = self:pick_action()
        if not success then
          self:set_idle_retry()
        end
        
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
        self:rotate_towards_object(self.target, 0.5)
      end
    end

    if table.any(unit_states_enemy_no_velocity, function(v) return self.state == v end) then
      self:set_velocity(0,0)
    end

    if not self:should_freeze_rotation() then
      self.r = self:get_angle()
    end
  
  
    self.attack_sensor:move_to(self.x, self.y)
  
    if self.area_sensor then self.area_sensor:move_to(self.x, self.y) end
end

function Enemy:set_idle()
  self.idleTimer = self.baseIdleTimer * random:float(0.8, 1.2)
  Helper.Unit:set_state(self, unit_states['idle'])
end

function Enemy:set_idle_retry()
  self.idleTimer = 0.1
  Helper.Unit:set_state(self, unit_states['idle'])
end

function Enemy:set_movement_action(action, actionTimer)
  self.currentMovementAction = action
  if actionTimer then
    self.actionTimer = actionTimer
  else
    self.actionTimer = self.baseActionTimer * random:float(0.8, 1.2)
  end

  Helper.Unit:set_state(self, unit_states['moving'])
  local chose_target_success = self:choose_movement_target()
  if not chose_target_success then
    self:set_idle()
  end
end

function Enemy:add_idle_deceleration()
  if self.being_knocked_back then return end
  self:add_deceleration(DECELERATION_WEIGHT)
  local vx, vy = self:get_velocity()
  local speed = math.length(vx, vy)
  if speed < 0.1 then
    self:set_velocity(0,0)
  end
end

function Enemy:choose_movement_target()
  if self.currentMovementAction == MOVEMENT_TYPE_CROSS_SCREEN then
    return self:acquire_target_cross_screen(false)
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK_ORB 
  or self.currentMovementAction == MOVEMENT_TYPE_SEEK_ORB_STALL then
    return self:acquire_target_seek_orb()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK then
    return self:acquire_target_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_LOOSE_SEEK then
    return self:acquire_target_loose_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_APPROACH_ORB then
    return self:acquire_target_approach_orb()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK_ORB_RANGE then
    return self:acquire_target_seek_orb_range()
  elseif self.currentMovementAction == MOVEMENT_TYPE_RANDOM then
    return self:acquire_target_random()
  elseif self.currentMovementAction == MOVEMENT_TYPE_NONE then
    return false -- Stationary enemies don't need movement targets
  end
end

function Enemy:update_movement()
  if self.being_knocked_back then return end
  if not self.transition_active then return end
  
  if self.currentMovementAction == MOVEMENT_TYPE_CROSS_SCREEN then
    return self:update_move_seek_location()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK_ORB then
    return self:update_move_seek_location_no_wander()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK_ORB_STALL then
    return self:update_move_seek_location_no_wander()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK then
    return self:update_move_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_LOOSE_SEEK then
    return self:update_move_seek_location()
  elseif self.currentMovementAction == MOVEMENT_TYPE_APPROACH_ORB then
    return self:update_move_seek_location_no_wander()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK_ORB_RANGE then
    return self:update_move_seek_to_range()
  elseif self.currentMovementAction == MOVEMENT_TYPE_RANDOM then
    return self:update_move_seek_location()
  elseif self.currentMovementAction == MOVEMENT_TYPE_WANDER then
    return self:update_move_wander()
  elseif self.currentMovementAction == MOVEMENT_TYPE_NONE then
    return false -- Stationary enemies don't move
  end
  return false
end

function Enemy:get_orb_stall_speed_multiplier()
  if not main.current.current_arena or not main.current.current_arena.level_orb then
    return 1
  end

  local orb = main.current.current_arena.level_orb

  --slow down as you get closer to the orb
  local distance_to_orb = math.distance(self.x, self.y, main.current.current_arena.level_orb.x, main.current.current_arena.level_orb.y)
  if distance_to_orb > 100 then
    return 1
  end

  local percent_to_orb = 1 - (distance_to_orb / 100)
  local multiplier = math.remap(percent_to_orb, 0, 1, 1, 0.2)

  return multiplier
end

function Enemy:acquire_target_cross_screen(get_new_target)
  if not self.target_location or get_new_target then
    local current_location = {x = self.x, y = self.y}
    self.target_location = Get_Cross_Screen_Destination(current_location)
  end

  return self.target_location ~= nil
end

function Enemy:acquire_target_seek_orb()
  self.target_location = {x = gw/2, y = gh/2}
  return true
end

function Enemy:acquire_target_seek()
  -- 30% chance to target critters
  if random:float(0, 1) < ENEMY_CHANCE_TO_TARGET_CRITTER then
    self.target = Helper.Target:get_closest_enemy(self)
  else
    self.target = Helper.Target:get_random_enemy(self)
  end
  return self.target ~= nil
end

function Enemy:acquire_target_loose_seek()
  self.target_location = nil
  self.target = Helper.Target:get_random_enemy(self)
  if self.target then
    self.target_location = {x = self.target.x + random:float(-LOOSE_SEEK_OFFSET, LOOSE_SEEK_OFFSET), y = self.target.y + random:float(-LOOSE_SEEK_OFFSET, LOOSE_SEEK_OFFSET)}
  end
  return self.target ~= nil
end

function Enemy:acquire_target_approach_orb()
  local target = {x = gw/2, y = gh/2}
  local desired_range = SEEK_TO_RANGE_RADIUS
  local oval_rx = desired_range * SEEK_TO_RANGE_RADIUS_X_MULTIPLIER
  local oval_ry = desired_range * SEEK_TO_RANGE_RADIUS_Y_MULTIPLIER
  
  local oval_x, oval_y = math.closest_point_on_ellipse(target.x, target.y, oval_rx, oval_ry, self.x, self.y)
  self.target_location = {x = oval_x, y = oval_y}
  return true
end

function Enemy:acquire_target_seek_orb_range()
  local target = nil
  if not main.current.current_arena or not main.current.current_arena.level_orb then
    return false
  end
  target = main.current.current_arena.level_orb
  if not target or target.dead then
    return false
  end

  return self:acquire_target_seek_to_range(target)
end

function Enemy:acquire_target_seek_to_range(target)
  if not target or target.dead or not target.x or not target.y then return false end

  self.target_location = nil
  
  -- Use oval shape - stretched horizontally
  local desired_range = SEEK_TO_RANGE_RADIUS
  local oval_rx = desired_range * SEEK_TO_RANGE_RADIUS_X_MULTIPLIER
  local oval_ry = desired_range * SEEK_TO_RANGE_RADIUS_Y_MULTIPLIER
  local enemy_radius = SEEK_TO_RANGE_ENEMY_MOVEMENT_RADIUS
  
  local distance_to_target = math.distance(self.x, self.y, target.x, target.y)
  local angle_to_target = math.atan2(target.y - self.y, target.x - self.x)
  
  -- Draw debug shapes when enabled
  if DEBUG_ENEMY_SEEK_TO_RANGE then
    -- Draw enemy movement circle (possible positions from enemy)
    DebugCircle{
      group = main.current.effects,
      x = self.x,
      y = self.y,
      radius = enemy_radius,
      color = blue[0],
      line_width = 1,
      duration = 0.5
    }
  end
  
  -- Find closest point on oval to enemy position
  local oval_x, oval_y = math.closest_point_on_ellipse(target.x, target.y, oval_rx, oval_ry, self.x, self.y)
  
  -- Calculate distance from enemy to closest point on oval
  local dx = oval_x - self.x
  local dy = oval_y - self.y
  local distance_to_oval = math.sqrt(dx*dx + dy*dy)
  
  -- Check if we're already close to the oval perimeter
  if distance_to_oval < DISTANCE_TO_TARGET_FOR_IDLE * 2 then
    -- We're close to the oval - pick a point along the perimeter to move to
    -- Calculate current angle on the oval
    local current_dx = self.x - target.x
    local current_dy = self.y - target.y
    local current_angle = math.atan2(current_dy / oval_ry, current_dx / oval_rx)
    
    -- Pick movement direction if not set
    if not self.oval_move_direction then
      self.oval_move_direction = random:table({1, -1})
    end
    
    -- Pick a point ahead on the oval to move towards (30-60 degrees)
    local angle_offset = random:float(0.5, 1.0) * self.oval_move_direction
    local new_angle = current_angle + angle_offset
    
    -- Calculate the new target position on the oval
    local new_target_x = target.x + oval_rx * math.cos(new_angle)
    local new_target_y = target.y + oval_ry * math.sin(new_angle)
    
    -- Check if we can reach this new position
    local dist_to_new = math.distance(self.x, self.y, new_target_x, new_target_y)
    if dist_to_new <= enemy_radius then
      self.target_location = {x = new_target_x, y = new_target_y}
    else
      -- Can't reach that far, pick a closer point
      local limited_angle_offset = angle_offset * (enemy_radius / dist_to_new) * 0.8
      new_angle = current_angle + limited_angle_offset
      new_target_x = target.x + oval_rx * math.cos(new_angle)
      new_target_y = target.y + oval_ry * math.sin(new_angle)
      self.target_location = {x = new_target_x, y = new_target_y}
    end
    
    -- Occasionally reverse direction
    if random:float() < 0.3 then -- 10% chance when acquiring new target
      self.oval_move_direction = -self.oval_move_direction
    end
    
    if DEBUG_ENEMY_SEEK_TO_RANGE then
      DebugLine{
        group = main.current.effects,
        x1 = self.x,
        y1 = self.y,
        x2 = self.target_location.x,
        y2 = self.target_location.y,
        color = yellow[0],
        line_width = 2,
      }
    end
    
  elseif distance_to_oval <= enemy_radius then
    -- We can reach the oval but aren't close yet - move to the closest point
    self.target_location = {x = oval_x, y = oval_y}
    
    if DEBUG_ENEMY_SEEK_TO_RANGE then
      DebugLine{
        group = main.current.effects,
        x1 = self.x,
        y1 = self.y,
        x2 = oval_x,
        y2 = oval_y,
        color = white[0],
        line_width = 2,
      }
    end
  else
    -- Can't reach oval - move as close as possible
    local move_ratio = enemy_radius / distance_to_oval
    local target_x = self.x + dx * move_ratio
    local target_y = self.y + dy * move_ratio
    
    self.target_location = {x = target_x, y = target_y}
    
    if DEBUG_ENEMY_SEEK_TO_RANGE then
      DebugLine{
        group = main.current.effects,
        x1 = self.x,
        y1 = self.y,
        x2 = self.target_location.x,
        y2 = self.target_location.y,
        color = red[0],
        line_width = 2,
      }
    end
  end
  
  return self.target_location ~= nil
end

function Enemy:acquire_target_random()
  self.target_location = Get_Point_In_Arena(self, MIN_DISTANCE_FOR_RANDOM_MOVEMENT)
  return true
end

function Enemy:update_move_wander()
  self:wander(ENEMY_WANDER_RADIUS, ENEMY_WANDER_DISTANCE, ENEMY_WANDER_JITTER)
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
      self:wander(ENEMY_WANDER_RADIUS, ENEMY_WANDER_DISTANCE, ENEMY_WANDER_JITTER)

  else
      -- We are OUT of range, OR we are not supposed to stop.
      -- In either case, we must seek the target.
      local seek_weight = get_seek_weight_by_enemy_type(self.type)
      self:seek_point(self.target.x, self.target.y, SEEK_DECELERATION, seek_weight)
      self:wander(ENEMY_WANDER_RADIUS, ENEMY_WANDER_DISTANCE, ENEMY_WANDER_JITTER) -- Add a little variation to the seek.
  end

  -- 3. Apply final steering adjustments in all active cases.
  self:rotate_towards_velocity(0.5)
  self:steering_separate(ENEMY_SEPARATION_RADIUS, {Enemy}, ENEMY_SEPARATION_WEIGHT)

  -- 4. Return true because the movement action is successfully ongoing.
  return true
end

function Enemy:update_move_seek_location() 
  if self.target_location then
    if self:distance_to_point(self.target_location.x, self.target_location.y) < DISTANCE_TO_TARGET_FOR_IDLE then
      return false
    else
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type))
      self:wander(ENEMY_WANDER_RADIUS, ENEMY_WANDER_DISTANCE, ENEMY_WANDER_JITTER)
      self:rotate_towards_velocity(0.5)
      self:steering_separate(ENEMY_SEPARATION_RADIUS, {Enemy}, ENEMY_SEPARATION_WEIGHT)
      return true
    end
  end

  return false
end

function Enemy:update_move_seek_location_no_wander()
  if self.target_location then
    if self:distance_to_point(self.target_location.x, self.target_location.y) < DISTANCE_TO_TARGET_FOR_IDLE then
      return false
    else
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type))
      self:rotate_towards_velocity(0.5)
      return true
    end
  end
  return false
end

function Enemy:update_move_seek_to_range()
  if self.target_location then
    local distance_to_target = self:distance_to_point(self.target_location.x, self.target_location.y)
    
    -- Check if we're close enough to our target position
    if distance_to_target < DISTANCE_TO_TARGET_FOR_IDLE then
      -- We're at the desired range, stop moving
      return false
    else
      -- Continue moving to the target position
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type))
      self:wander(ENEMY_WANDER_RADIUS, ENEMY_WANDER_DISTANCE, ENEMY_WANDER_JITTER)
      self:rotate_towards_velocity(0.5)
      self:steering_separate(ENEMY_SEPARATION_RADIUS, {Enemy}, ENEMY_SEPARATION_WEIGHT)
      return true
    end
  end
  
  return false
end

function Enemy:draw()
  if DEBUG_ENEMY_MOVEMENT then
    self:draw_debug_info()
  end
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
  
  self:draw_steering_debug()
end

function Enemy:on_collision_enter(other, contact)
    local x, y = contact:getPositions()
    
    if other:is(Wall) then
        self:bounce(contact:getNormal())

    elseif table.any(main.current.friendlies, function(v) return other:is(v) end) then
      if self.class == 'regular_enemy' then
        local dmg = REGULAR_PUSH_DAMAGE
        if not self.ignoreKnockback then
          local duration = KNOCKBACK_DURATION_ENEMY
          local push_force = ENEMY_KNOCKBACK_FORCE_TROOP_COLLISION
          self:push(push_force, self:angle_to_object(other) + math.pi, nil, duration)
        end
        --delay the damage to avoid box2d lock
        self.t:after(0, function()
          if self and not self.dead then
            self:hit(dmg, other, nil, false, true)
          end
        end)
      else
        if self.haltOnPlayerContact then
          if not self.ignoreKnockback then
            self:set_velocity(0,0)
            Helper.Unit:set_state(self, unit_states['frozen'])
            self.t:after(0.8, function()
              if self.state == unit_states['frozen'] then
                Helper.Unit:set_state(self, unit_states['idle'])
              end
            end)
          end
        end
      end
    elseif table.any(main.current.enemies, function(v) return other:is(v) end) then
      if self.being_knocked_back and math.length(self:get_velocity()) > ENEMY_KNOCKBACK_CHAIN_VELOCITY_THRESHOLD then
        other:push(math.floor(self.push_force * ENEMY_KNOCKBACK_FORCE_CHAIN_MULTIPLIER), other:angle_to_object(self))
        --delay the damage to avoid box2d lock
        self.t:after(0, function()
          self:hit(ENEMY_KNOCKBACK_CHAIN_DAMAGE, nil, nil, true)
          other:hit(ENEMY_KNOCKBACK_CHAIN_DAMAGE, nil, nil, true)
        end)
      end
    end
end

function Enemy:hit(damage, from, damageType, playHitEffects, cannotProcOnHit)
  -- Use the indirect hit function (current behavior)
  Helper.Damage:indirect_hit(self, damage, from, damageType, playHitEffects)
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

--despawn decrements the onscreen round power
--but doesn't add to the kill count or stats
function Enemy:despawn()
  self.dead = true

  --for safety, should never happen
  if self.class == 'boss' then
    is_boss_dead = true
  end

  current_power_onscreen = current_power_onscreen - enemy_to_round_power[self.type]

  if self.parent and self.parent.summons then
    self.parent.summons = self.parent.summons - 1
  end
end

function Enemy:die()
  if self.dead then return end

  if self.class == 'boss' then
    is_boss_dead = true
  else
    current_power_onscreen = current_power_onscreen - enemy_to_round_power[self.type]
    round_power_killed = round_power_killed + enemy_to_round_power[self.type]
  end

  self.super.die(self)
  self.dead = true
  _G[random:table{'enemy_die1', 'enemy_die2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.5}
  
  -- Drop gold when enemy dies
  -- if main.current and main.current.gold_counter then
  --   local round_power = enemy_to_round_power[self.type] or 100
  --   main.current.gold_counter:add_round_power(round_power, self.x, self.y)
  -- end

  -- Add progress to wave progress bar
  if main.current and main.current.current_arena and main.current.current_arena.progress_bar then
    local round_power = enemy_to_round_power[self.type] or 100
    main.current.current_arena.progress_bar:increase_with_particles(round_power, self.x, self.y)
  end
  if self.parent and self.parent.summons and self.parent.summons > 0 then
    self.parent.summons = self.parent.summons - 1
  end
end

-- ===================================================================
-- REFACTORED Enemy:push
-- Now also calls the standardized helper function.
-- ===================================================================
function Enemy:push(f, r, push_invulnerable)

  
  if self.class == 'boss' then 
    return
  end

  -- Call the universal knockback function with the modified force
  Helper.Unit:apply_knockback_enemy(self, f, r)
end

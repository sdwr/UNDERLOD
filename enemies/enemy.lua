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

  -- Specials (special_enemy/miniboss/boss) draw over normal swarmers and pass through them.
  if self.class == 'special_enemy' or self.class == 'boss' or self.class == 'miniboss' then
    self.z_index = 1
  end
  self._sep_comparator = function(other)
    if self.passes_through or other.passes_through then return false end
    local self_special = self.class == 'special_enemy' or self.class == 'boss' or self.class == 'miniboss'
    local other_special = other.class == 'special_enemy' or other.class == 'boss' or other.class == 'miniboss'
    local self_normal_swarmer = self.type == 'swarmer' and not self.special_swarmer_type
    local other_normal_swarmer = other.type == 'swarmer' and not other.special_swarmer_type
    if self_special and other_normal_swarmer then return false end
    if self_normal_swarmer and other_special then return false end
    return true
  end

  self:init_unit()
  self:init_hitbox_points()

  self.spritesheet = find_enemy_spritesheet(self)

  self:calculate_stats(true)

  self.baseIdleTimer = self.baseIdleTimer or 0.3
  self.idleTimer = self.baseIdleTimer
  self.baseActionTimer = self.baseActionTimer or 1
  self.actionTimer = 0


  self.currentMovementAction = nil
  self.stopChasingInRange = not not self.stopChasingInRange
  self.haltOnPlayerContact = not not self.haltOnPlayerContact

  self:set_attack_cooldown_timer(0)
  
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 20 + self.shape.w / 2)
  
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
  -- Boss intro: hold the current frame while the title card plays.
  if self.intro_frozen then
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

-- Draw the base shape (draw_body hook, triangle for dragon, rounded rectangle for others)
function Enemy:draw_fallback_base_shape()
  -- Determine base color (hit flash, silenced, or normal color)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color
  
  graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)
  
  if self.draw_body then
    -- Custom body (e.g. dart): draws in local space, rotated once by the push.
    self:draw_body(base_color)
  elseif self.type == 'dragon' then
    -- Special case: Dragon uses triangle polygon
    local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70, self:get_angle())
    graphics.polygon(points, base_color)
  elseif self.shape and self.shape.rs then
    -- Circle colliders (rs is circle-only) draw as circles
    graphics.circle(self.x, self.y, self.shape.rs, base_color)
  else
    -- Default case: Rounded rectangle with size-appropriate corner radius
    local corner_radius = get_enemy_corner_radius(self)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, corner_radius, corner_radius, base_color)
  end

  graphics.pop()
end

-- Draw status effect overlays using the same mask-based approach as sprite animations
function Enemy:draw_fallback_status_effects()
  local mask_color = get_status_tint_color(self)

  if mask_color ~= nil then
    graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)

    if self.draw_body then
      self:draw_body(mask_color)
    elseif self.type == 'dragon' then
      local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70, self:get_angle())
      graphics.polygon(points, mask_color)
    elseif self.shape and self.shape.rs then
      graphics.circle(self.x, self.y, self.shape.rs, mask_color)
    else
      local corner_radius = get_enemy_corner_radius(self)
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, corner_radius, corner_radius, mask_color)
    end

    graphics.pop()
  end

  if self.buffs['curse'] then
    graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)

    if self.draw_body then
      self:draw_body(CURSE_OUTLINE_COLOR, 2, 2)
    elseif self.type == 'dragon' then
      local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70 + 2, self:get_angle())
      graphics.polygon(points, CURSE_OUTLINE_COLOR, 2)
    elseif self.shape and self.shape.rs then
      graphics.circle(self.x, self.y, self.shape.rs + 1.5, CURSE_OUTLINE_COLOR, 2)
    else
      local corner_radius = get_enemy_corner_radius(self)
      graphics.rectangle(self.x, self.y, self.shape.w + 3, self.shape.h + 3, corner_radius, corner_radius, CURSE_OUTLINE_COLOR, 2)
    end

    graphics.pop()
  end
end

-- particle accents layer on top of tints so multiple statuses read at once:
-- embers = burn, frost motes = chill/freeze, sparks = shock
function Enemy:update_status_particles(dt)
  if self.offscreen then return end
  if not self.buffs then return end

  self.status_particle_timers = self.status_particle_timers or {burn = 0, chill = 0, shock = 0}
  local timers = self.status_particle_timers
  local w, h = self.shape.w, self.shape.h

  if self.buffs['burn'] then
    timers.burn = timers.burn - dt
    if timers.burn <= 0 then
      timers.burn = random:float(0.1, 0.2)
      HitParticle{group = main.current.effects,
        x = self.x + random:float(-w/3, w/3), y = self.y + random:float(-h/3, h/3),
        r = -math.pi/2 + random:float(-0.4, 0.4), v = random:float(20, 45),
        w = random:float(2.5, 4), duration = random:float(0.3, 0.5),
        color = BURN_PARTICLE_COLORS[random:bool(60) and 1 or 2]}
    end
  end

  if self.buffs['chill'] or self.buffs['freeze'] then
    timers.chill = timers.chill - dt
    if timers.chill <= 0 then
      timers.chill = random:float(0.25, 0.45)
      HitParticle{group = main.current.effects,
        x = self.x + random:float(-w/2, w/2), y = self.y + random:float(-h/2, h/2),
        r = -math.pi/2 + random:float(-0.3, 0.3), v = random:float(8, 18),
        w = random:float(2.5, 3.5), duration = random:float(0.5, 0.8),
        color = CHILL_PARTICLE_COLOR}
    end
  end

  if self.buffs['shock'] then
    timers.shock = timers.shock - dt
    if timers.shock <= 0 then
      timers.shock = random:float(0.15, 0.35)
      for i = 1, random:int(1, 2) do
        HitParticle{group = main.current.effects,
          x = self.x + random:float(-w/2, w/2), y = self.y + random:float(-h/2, h/2),
          r = random:float(0, 2*math.pi), v = random:float(80, 140),
          w = random:float(2.5, 3.5), duration = random:float(0.12, 0.2),
          color = SHOCK_PARTICLE_COLOR}
      end
    end
  end
end

--set castcooldown and in the enemy file (init)
function Enemy:update(dt)
    Enemy.super.update(self, dt)
    self:update_cast_cooldown(dt)

    self:onTickCallbacks(dt)
    self:update_buffs(dt)
    self:update_status_particles(dt)

    self:update_animation(dt)

    self.offscreen = not Helper.Target:is_in_camera_bounds(self.x, self.y)
    self.fully_onscreen = Helper.Target:is_fully_in_camera_bounds(self.x, self.y)
    self.way_onscreen = Helper.Target:way_inside_camera_bounds(self.x, self.y)

    if self.offscreen or not self.way_onscreen then
      self.in_arena_radius = false
    else
      self.in_arena_radius = Helper.Unit:in_range_of_player_location(self, ARENA_RADIUS)
    end

    -- Finite rounds require path-across enemies to return instead of escape.
    if self.currentMovementAction == MOVEMENT_TYPE_PATH_ACROSS
      or self.currentMovementAction == MOVEMENT_TYPE_PATH_ACROSS_VARIED then
      local buffer = 80
      if self.x < -buffer or self.x > gw + buffer
        or self.y < -buffer or self.y > gh + buffer then
        local arena = main.current.current_arena
        local sm = arena and arena.spawn_manager
        if sm and sm:get_spawn_budget() then
          -- Finite rounds require this enemy's defeat; send it back across.
          self.path_heading = math.atan2(gh / 2 - self.y, gw / 2 - self.x)
        else
          self._counted_for_quota = true
          self.dead = true
          return
        end
      end
    end

    if self.being_knocked_back then
      if math.length(self:get_velocity()) < ENEMY_KNOCKBACK_VELOCITY_REGAIN_CONTROL_THRESHOLD then
        Helper.Unit:reset_knockback_variables(self)
      end
    end



    self:calculate_stats()
    if self.get_proximity_speed_ratio and not self.being_knocked_back and not self.is_launching then
      self.max_v = self.max_v * self:get_proximity_speed_ratio()
    end
    
    self.random_dest_timer = self.random_dest_timer - dt

    -- Don't take actions if transition is not complete
    if not self.transition_active then
      return
    end

    --get target / rotate to target
    if self.target and self.target.dead then self.target = nil end
    
    -- A pinball charge that has run its course: stop cleanly and resume AI.
    if self.pinball_charging and not self.is_launching then
      self.pinball_charging = nil
      self.pinball_hits = nil
      self:set_pinball_collision(false)
      self:set_velocity(0, 0)
      self:set_idle()
    end

    if self.is_launching then
      -- No action picks or steering while flying; the launch owns the body.
      self:update_launch(dt)
    elseif self.state == unit_states['idle'] then
      self.idleTimer = self.idleTimer - dt
      self:add_idle_deceleration()
      if self.idleTimer <= 0 then
        local success = self:pick_action()
        if not success then
          self:set_idle_retry()
        end

      end
    elseif self.state == unit_states['moving'] then
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

-- Pinball charge. Runs instead of the AI while launching:
--   * reflects the heading off the arena bounds (not box2d: the walls are
--     chain edges enemies otherwise walk through when entering),
--   * re-asserts heading and speed every frame so nothing bends the path,
--   * hits troops by overlap (physical troop contact is masked off for the
--     charge, see set_pinball_collision) with a per-troop rehit delay.
function Enemy:update_launch(dt)
  if not self.pinball_charging then return end
  local radius = (self.shape and (self.shape.rs or self.shape.w / 2)) or 0
  local arena = main.current and main.current.current_arena
  do
    local x1, y1, x2, y2 = Get_Screen_Bounds(arena)
    local hx, hy = math.cos(self.pinball_heading), math.sin(self.pinball_heading)
    local bounced = false
    if (self.x - radius <= x1 and hx < 0) or (self.x + radius >= x2 and hx > 0) then
      hx = -hx; bounced = true
    end
    if (self.y - radius <= y1 and hy < 0) or (self.y + radius >= y2 and hy > 0) then
      hy = -hy; bounced = true
    end
    if bounced then
      self.pinball_heading = math.atan2(hy, hx)
      if self.on_pinball_bounce then self:on_pinball_bounce() end
    end
  end

  local speed = self.pinball_speed or LAUNCH_MAX_V
  self:set_velocity(math.cos(self.pinball_heading) * speed, math.sin(self.pinball_heading) * speed)
  self.r = self.pinball_heading

  self.pinball_hits = self.pinball_hits or {}
  local now = Helper.Time.time
  local hit_zone = Circle(self.x, self.y, radius + 6)
  for _, troop in ipairs(self:get_objects_in_shape(hit_zone, main.current.friendlies)) do
    if not troop.dead and (self.pinball_hits[troop.id] or -math.huge) + (PINBALL_REHIT_DELAY or 0.6) <= now then
      self.pinball_hits[troop.id] = now
      if self.on_pinball_hit then self:on_pinball_hit(troop) end
    end
  end
end

-- During a pinball charge the body must not trade impulses with troops (the
-- contact solver would shove it off course), so mask the troop category off
-- the fixture; overlap detection in update_launch handles the hits.
function Enemy:set_pinball_collision(on)
  if not self.fixture or not self.group or not self.group.collision_tags or not self.tag then return end
  local masks = table.copy(self.group.collision_tags[self.tag].masks)
  if on then
    for _, tag in ipairs({'troop', 'ghost'}) do
      local t = self.group.collision_tags[tag]
      if t then table.insert(masks, t.category) end
    end
  end
  self.fixture:setMask(unpack(masks))
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
  if self.currentMovementAction == MOVEMENT_TYPE_SEEK then
    return self:acquire_target_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_LOOSE_SEEK then
    return self:acquire_target_loose_seek()
  elseif self.currentMovementAction == MOVEMENT_TYPE_SEEK_TO_RANGE then
    return self:acquire_target_seek_to_range()
  elseif self.currentMovementAction == MOVEMENT_TYPE_RANDOM then
    return self:acquire_target_random()
  elseif self.currentMovementAction == MOVEMENT_TYPE_PATH_ACROSS then
    return self:acquire_target_path_across()
  elseif self.currentMovementAction == MOVEMENT_TYPE_PATH_ACROSS_VARIED then
    return self:acquire_target_path_across_varied()
  elseif self.currentMovementAction == MOVEMENT_TYPE_NONE then
    return false -- Stationary enemies don't need movement targets
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
  elseif self.currentMovementAction == MOVEMENT_TYPE_PATH_ACROSS then
    return self:update_move_path_across()
  elseif self.currentMovementAction == MOVEMENT_TYPE_PATH_ACROSS_VARIED then
    return self:update_move_path_across()
  elseif self.currentMovementAction == MOVEMENT_TYPE_NONE then
    return false -- Stationary enemies don't move
  end
  return false
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

function Enemy:acquire_target_seek_to_range()
  self.target_location = nil
  
  local player_location = Helper.Unit:get_player_location()
  if not player_location then
    return false
  end
  
  -- Calculate distance between enemy and player
  local distance_to_player = math.distance(self.x, self.y, player_location.x, player_location.y)
  local desired_range = self.seek_to_range_radius or SEEK_TO_RANGE_PLAYER_RADIUS
  
  -- Create circle around enemy with radius = distance to player
  local enemy_radius = SEEK_TO_RANGE_ENEMY_MOVEMENT_RADIUS
  -- Create circle around player with desired range
  local player_radius = desired_range
  
  -- Find intersection points between the two circles
  local dx = player_location.x - self.x
  local dy = player_location.y - self.y
  local d = math.distance(self.x, self.y, player_location.x, player_location.y)
  
  -- Check if circles intersect
  if d > enemy_radius + player_radius or d < math.abs(enemy_radius - player_radius) or d == 0 then
    -- No intersection, pick a point on the line between enemy and player
    local angle_to_player = math.atan2(dy, dx)
    local target_x, target_y
    
    if distance_to_player > desired_range then
      -- Move closer to player
      target_x = self.x + (desired_range * 0.8) * math.cos(angle_to_player)
      target_y = self.y + (desired_range * 0.8) * math.sin(angle_to_player)
    else
      -- Move away from player
      target_x = self.x - (desired_range * 0.2) * math.cos(angle_to_player)
      target_y = self.y - (desired_range * 0.2) * math.sin(angle_to_player)
    end
    
    self.target_location = {x = target_x, y = target_y}
  else
    -- Calculate intersection points
    local a = (enemy_radius^2 - player_radius^2 + d^2) / (2*d)
    local h = math.sqrt(enemy_radius^2 - a^2)
    
    local px = self.x + a * dx/d
    local py = self.y + a * dy/d
    
    -- Two intersection points
    local x1 = px + h * (-dy/d)
    local y1 = py + h * (dx/d)
    local x2 = px - h * (-dy/d)
    local y2 = py - h * (dx/d)
    
    -- Pick one intersection point randomly
    local chosen_point = random:table({{x = x1, y = y1}, {x = x2, y = y2}})

    if DEBUG_ENEMY_SEEK_TO_RANGE then
      DebugLine{
        group = main.current.effects,
        x1 = self.x,
        y1 = self.y,
        x2 = chosen_point.x,
        y2 = chosen_point.y,
        line_width = 2,
      }
    end
    
    -- Add random angle offset
    local offset_angle = random:float(-math.pi/6, math.pi/6) -- ±30 degrees
    local offset_distance = random:float(10, 30)
    
    chosen_point.x = chosen_point.x + offset_distance * math.cos(offset_angle)
    chosen_point.y = chosen_point.y + offset_distance * math.sin(offset_angle)
    
    self.target_location = chosen_point
  end
  
  -- Validate arena bounds and adjust if needed
  local max_attempts = 5
  for attempt = 1, max_attempts do
    if not Helper.Target:way_inside_camera_bounds(self.target_location.x, self.target_location.y) then
      
      -- Rotate towards arena center
      local center_x, center_y = gw/2, gh/2
      local angle_to_center = math.atan2(center_y - self.y, center_x - self.x)
      local angle_to_player = math.atan2(player_location.y - self.y, player_location.x - self.x)
      local rotation_amount = math.pi/6 * attempt -- Increase rotation each attempt
      
      local new_angle = angle_to_player + rotation_amount * (random:table({-1, 1}))
      -- Bias towards center
      new_angle = new_angle + (angle_to_center - new_angle) * 0.3
      
      self.target_location.x = self.x + desired_range * math.cos(new_angle)
      self.target_location.y = self.y + desired_range * math.sin(new_angle)

      if DEBUG_ENEMY_SEEK_TO_RANGE then
        DebugLine{
          main.current.effects,
          x1 = self.x,
          y1 = self.y,
          x2 = self.target_location.x,
          y2 = self.target_location.y,
          color = Helper.Color.red,
          line_width = 2,
        }
      end
    else
      break -- Valid location found
    end
  end
  
  -- Final fallback: move towards arena center if still invalid
  if not Helper.Target:way_inside_camera_bounds(self.target_location.x, self.target_location.y) then
    self.target_location = {x = gw/2, y = gh/2}
  end
  
  if self.target_location then
    return true
  end
  return false
end

function Enemy:acquire_target_random()
  self.target_location = Get_Point_In_Arena(self, MIN_DISTANCE_FOR_RANDOM_MOVEMENT)
  return true
end

-- Picks a fixed straight-line heading once, from the enemy's current position
-- through the map center and out the opposite edge. Re-used every time we
-- "re-acquire" so the enemy doesn't oscillate.
function Enemy:acquire_target_path_across()
  if not self.path_heading then
    local cx, cy = gw / 2, gh / 2
    local dx, dy = cx - self.x, cy - self.y
    if dx == 0 and dy == 0 then
      self.path_heading = random:float(0, 2 * math.pi)
    else
      self.path_heading = math.atan2(dy, dx)
    end
  end
  return true
end

-- Same as path_across but the angle to center is jittered by up to
-- PATH_ACROSS_VARIED_JITTER radians so a wave of enemies spreads across the
-- arena instead of all funneling through the middle.
function Enemy:acquire_target_path_across_varied()
  if not self.path_heading then
    local cx, cy = gw / 2, gh / 2
    local dx, dy = cx - self.x, cy - self.y
    local base
    if dx == 0 and dy == 0 then
      base = random:float(0, 2 * math.pi)
    else
      base = math.atan2(dy, dx)
    end
    self.path_heading = base + random:float(-PATH_ACROSS_VARIED_JITTER, PATH_ACROSS_VARIED_JITTER)
  end
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
      self:seek_point(self.target.x, self.target.y, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type))
      self:wander(ENEMY_WANDER_RADIUS, ENEMY_WANDER_DISTANCE, ENEMY_WANDER_JITTER, self.seek_wander_mult or 1) -- Add a little variation to the seek.
  end

  -- 3. Apply final steering adjustments in all active cases.
  self:rotate_towards_velocity(0.5)
  self:steering_separate(ENEMY_SEPARATION_RADIUS, {Enemy}, ENEMY_SEPARATION_WEIGHT, self._sep_comparator)

  -- 4. Return true because the movement action is successfully ongoing.
  return true
end

function Enemy:update_move_loose_seek()
  
  if self.target_location then
    if self:distance_to_point(self.target_location.x, self.target_location.y) < DISTANCE_TO_TARGET_FOR_IDLE then
      return false
    else
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type))
      self:wander(ENEMY_WANDER_RADIUS, ENEMY_WANDER_DISTANCE, ENEMY_WANDER_JITTER)
      self:rotate_towards_velocity(0.5)
      self:steering_separate(ENEMY_SEPARATION_RADIUS, {Enemy}, ENEMY_SEPARATION_WEIGHT, self._sep_comparator)
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
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type) or SEEK_WEIGHT)
      self:wander(ENEMY_WANDER_RADIUS, ENEMY_WANDER_DISTANCE, ENEMY_WANDER_JITTER)
      self:rotate_towards_velocity(0.5)
      self:steering_separate(ENEMY_SEPARATION_RADIUS, {Enemy}, ENEMY_SEPARATION_WEIGHT, self._sep_comparator)
      return true
    end
  end
  return false
end

function Enemy:update_move_path_across()
  if not self.path_heading then
    self:acquire_target_path_across()
  end
  -- Aim a fixed waypoint far ahead along the heading and seek toward it; the
  -- enemy never reaches it, so this is effectively constant forward motion.
  local far = 4000
  local tx = self.x + math.cos(self.path_heading) * far
  local ty = self.y + math.sin(self.path_heading) * far
  self:seek_point(tx, ty, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type))
  self:rotate_towards_velocity(0.5)
  self:steering_separate(ENEMY_SEPARATION_RADIUS, {Enemy}, ENEMY_SEPARATION_WEIGHT, self._sep_comparator)
  return true
end

function Enemy:update_move_random()
  if self.target_location then
    if self:distance_to_point(self.target_location.x, self.target_location.y) < DISTANCE_TO_TARGET_FOR_IDLE then
      return false
    else
      self:seek_point(self.target_location.x, self.target_location.y, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type))
      self:rotate_towards_velocity(1)
      self:steering_separate(ENEMY_SEPARATION_RADIUS, {Enemy}, ENEMY_SEPARATION_WEIGHT, self._sep_comparator)
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
  self:draw_targeted()
end

function Enemy:on_collision_enter(other, contact)
    local x, y = contact:getPositions()
    
    if other:is(Wall) then
        self:bounce(contact:getNormal())

    elseif table.any(main.current.friendlies, function(v) return other:is(v) end) then
      -- Contact spends the enemy: the troop takes the knockback and hp-scaled
      -- damage (Troop:on_collision_enter), the enemy dies. Bosses and
      -- minibosses keep pressing.
      if Dies_On_Contact(self) then
        --delay the death to avoid box2d lock
        self.t:after(0, function()
          if self and not self.dead then self:die() end
        end)
      elseif self.haltOnPlayerContact then
        self:set_velocity(0,0)
        Helper.Unit:set_state(self, unit_states['frozen'])
        self.t:after(0.8, function()
          if self.state == unit_states['frozen'] then
            Helper.Unit:set_state(self, unit_states['idle'])
          end
        end)
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
  
  -- Per-type death effect (exploder burst, poison pool). Runs from the
  -- group's cleanup pass, so both hit and contact deaths reach it.
  if self.on_death then self:on_death() end

  self.state_change_functions['death'](self)
  self.death_function()
end

function Enemy:die()
  if self.dead then return end
  self.super.die(self)
  self.dead = true
  -- Track defeated enemy power for the progress display.
  local sm = main.current and main.current.current_arena and main.current.current_arena.spawn_manager
  if sm and not self._counted_for_quota then
    self._counted_for_quota = true
    sm:on_enemy_removed(self)
  end
  _G[random:table{'enemy_die1', 'enemy_die2'}]:play{pitch = random:float(0.6, 0.8), volume = 0.25}

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

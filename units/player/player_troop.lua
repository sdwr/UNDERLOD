Troop = Unit:extend()
Troop:implement(GameObject)
Troop:implement(Physics)
function Troop:init(args)
  self.class = 'troop'
  self.faction = 'friendly'
  self.size = unit_size['medium-plus']
  self.is_troop = true
  self.target_rally = nil
  self.backswing = 0.2
  -- Cast/cooldown values are set in calculate_stats() first run
  --buff examples...
  --self.buffs[1] = {name = buff_types['dmg'], amount = 0.2, color = red_transparent_weak}
  --self.buffs[2] = {name = buff_types['aspd'], amount = 0.2, color = green_transparent_weak}
  self.beingHealed = false
  
  -- Position troop at center of screen (orb location)
  args.x = gw/2
  args.y = gh/2
  
  self:init_game_object(args)
  Helper.Unit:add_custom_variables_to_unit(self)
  -- Disable collision for troops
  if not self.is_player_cursor then
    self.no_collision = true
  end
  
  self:init_unit()
  local level = self.level or 1

  self.hfx:add('move_scale_x', 1, 80, 20)
  self.hfx:add('move_scale_y', 1, 80, 20)

  self.hfx:add('attack_scale_x', 1, 50, 8) 
  self.hfx:add('attack_scale_y', 1, 50, 8)

  self.hfx:add('survivor_scale', 1, 100, 20)

  -- This new variable will store the speed from the previous frame
  self.last_speed = 0

  self:calculate_stats(true)

  self.color = character_colors[self.character]
  self.type = character_types[self.character]
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 40)
  
  self:set_character()

  Helper.Unit:set_state(self, unit_states['idle'])

  self.offscreen = false
end


--called in oncastfinish for all troops
function Troop:stretch_on_attack()
  local stretch_factor = 0.4
  self.hfx:pull('attack_scale_y', stretch_factor)
  self.hfx:pull('attack_scale_x', - stretch_factor)
end

function Troop:follow_mouse()
  -- If not, continue moving towards the mouse.
  if self.being_knocked_back then return end
  if self:distance_to_mouse() > 10 then
    self:seek_mouse(SEEK_DECELERATION, TROOP_SEEK_WEIGHT)
    self:rotate_towards_velocity(1)
  else
      --self:set_velocity(0, 0) -- Stop when we reach the cursor
  end
end

function Troop:rally_to_point()
  -- If not, continue moving towards the rally point.
  if self.being_knocked_back then return end
  if not self.target_pos then return end
  
  local success, time_to_target, target_pos = self:predict_arrival(
    self.target_pos.x, self.target_pos.y, 
    RALLY_CIRCLE_STOP_DISTANCE, 
    RALLY_CIRCLE_OVERSHOOT_DISTANCE
  )
  
  if success then
    return
  end

  self:seek_point(self.target_pos.x, self.target_pos.y, SEEK_DECELERATION, SEEK_WEIGHT)
  self:wander(TROOP_WANDER_RADIUS, TROOP_WANDER_DISTANCE, TROOP_WANDER_JITTER)
  self:rotate_towards_velocity(1)
end

function Troop:update_movement_effect(dt)
  local vx, vy = self:get_velocity()
  local speed = math.length(vx, vy)
  
  -- Calculate acceleration by comparing the current speed to the last frame's
  -- A large negative value means we are braking hard.
  local acceleration = (speed - self.last_speed) / dt
  
  -- ### TUNING PARAMETERS ###
  local move_stretch_factor = 1.4  -- How TALL it gets when moving (130%)
  local brake_stretch_factor = 1.5 -- How WIDE it gets when braking (140%)
  local brake_sensitivity = -65   -- How hard the unit must decelerate to trigger the brake effect
  
  local target_scale_x = 1
  local target_scale_y = 1
  
  -- Check if the unit is braking hard
  if acceleration < brake_sensitivity then
      -- BRAKING EFFECT: Stretch horizontally
      local brake_ratio = math.clamp(acceleration / (brake_sensitivity * 2), 0, 1)
      target_scale_x = 1 + (brake_stretch_factor - 1) * brake_ratio
      target_scale_y = 1 / target_scale_x -- Squish vertically to conserve volume
  
  -- Otherwise, if the unit is moving normally, apply the vertical stretch
  elseif speed > 5 then
      -- MOVEMENT EFFECT: Stretch vertically
      local speed_ratio = math.min(speed / 150, 1.0) -- 150 is the speed for max deformation
      target_scale_y = 1 + (move_stretch_factor - 1) * speed_ratio
      target_scale_x = 1 / target_scale_y -- Squish horizontally to conserve volume
  end
  
  -- Animate the springs toward their new targets
  self.hfx:animate('move_scale_x', target_scale_x)
  self.hfx:animate('move_scale_y', target_scale_y)
  
  -- Finally, update last_speed for the next frame's calculation
  self.last_speed = speed
end

function Troop:update_survivor_effect(dt)
  local survivor_boost = Helper.Unit:get_survivor_size_boost(self)
  self.hfx:animate('survivor_scale', survivor_boost)
end

function Troop:update(dt)
  -- ===================================================================
  -- 1. ESSENTIAL HOUSEKEEPING (These should always run)
  -- ===================================================================
  Troop.super.update(self, dt)
  self:update_cast_cooldown(dt)
  self:onTickCallbacks(dt)
  self:update_buffs(dt)
  self:calculate_stats()
  self:update_targets() -- Updates who the unit is targeting

  -- Don't update movement effects since troops don't move
  -- self:update_movement_effect(dt)
  self:update_survivor_effect(dt)
  
  -- Keep troops at player cursor position (unless this IS the player cursor)
  if not self.is_player_cursor then
    -- Follow the player cursor if it exists
    if main.current and main.current.current_arena and main.current.current_arena.player_cursor then
      local cursor = main.current.current_arena.player_cursor
      self.x = cursor.x
      self.y = cursor.y
    else
      -- Fallback to center if no cursor
      self.x = gw/2
      self.y = gh/2
    end
    self:set_velocity(0, 0)
  end

  -- ===================================================================
  -- 2. THE STATE MACHINE (Hierarchical and Predictable)
  -- ===================================================================
  -- This is one big if/elseif block. Only ONE of these can run per frame,
  -- which prevents state flickering. The order is based on priority.

  -- Disable movement for troops
  -- if table.contains(unit_states_can_move, self.state) then
  --   self:follow_wasd()
  --   self:do_automatic_movement()
  -- end

  if table.contains(unit_states_can_cast, self.state) then
    if Helper.player_attack_location then
      if Helper.Unit:can_cast(self, Helper.player_attack_location) then
        self:setup_cast(Helper.player_attack_location)
      end
    end
  end

  if self.state == unit_states['casting'] then
    if not Helper.player_attack_location then
      self:cancel_cast()
    end
  end



  -- PRIORITY 1: Uninterruptible States
  -- If a unit is frozen, it can't do anything else.
  if self.state == unit_states['frozen'] then
      -- The logic that takes the unit *out* of these states (like a timer)
      -- is handled elsewhere.
      -- We do nothing else here.

  -- PRIORITY 2: Player-Commanded States
  -- If the unit is actively following the mouse.
  elseif self.state == unit_states['following'] then

      -- self:cancel_cast()
      -- self:clear_my_target()
      -- self:clear_assigned_target()

  -- PRIORITY 3: Action States (Busy States)
  -- If the unit is in the middle of casting an ability.
  elseif self.state == unit_states['casting'] then

  end

  -- ===================================================================
  -- 3. FINAL PHYSICS AND POSITIONING (These also always run)
  -- ===================================================================
  
  self.r = self:get_angle()
  self.attack_sensor:move_to(self.x, self.y)
end

function Troop:follow_wasd()
  if self.being_knocked_back then return end
  if Helper.Unit.wasd_released then
    self:start_deceleration()
  elseif Helper.Unit.wasd_pressed then
    self:seek_point(Helper.Unit.movement_target.x, Helper.Unit.movement_target.y, SEEK_DECELERATION, SEEK_WEIGHT)
    self.t:after(0, function()
      self:reset_physics_properties()
    end, 'reset_physics_properties')
  end
end

function Troop:do_automatic_movement()

  --separate from other troops
  local sameTeam = function(object) return object.team == self.team end
  local notSameTeam = function(object) return object.team ~= self.team end
  self:steering_separate(TROOP_SEPARATION_RADIUS, troop_classes, TROOP_SEPARATION_WEIGHT, notSameTeam)
  self:steering_separate(TROOP_SEPARATION_RADIUS_SAME_TEAM, troop_classes, TROOP_SEPARATION_WEIGHT_SAME_TEAM, sameTeam)

  --cohesion with other troops
  if self.team then
    local team = Helper.Unit.teams[self.team]
    self:add_cohesion(team:get_center(), TROOP_COHESION_MIN_DISTANCE, TROOP_COHESION_WEIGHT)
  end


  self:rotate_towards_velocity(1)
end


--ugly!!
--sets the progressive damping
--using the same tag so it can be reset by another movement effect
--should be able to do this with one tween
function Troop:start_deceleration()
  self:set_physics_properties({damping = 3})
  self.t:every(0.08, function()
    local damping = self:get_damping() or 1
    self:set_physics_properties({damping = damping + 1.5})
  end, 6, function()
    self:reset_physics_properties()
  end, 'reset_physics_properties')
end

-- ===================================================================
-- REFACTORED Troop:push
-- Now calls the standardized helper function.
-- ===================================================================
function Troop:push(f, r, push_invulnerable, duration)
  -- Set a default duration if one isn't provided
  duration = duration or KNOCKBACK_DURATION_ENEMY
  
  -- Call the universal knockback function
  Helper.Unit:apply_knockback(self, f, r, duration, push_invulnerable)
end


function Troop:draw()
  -- Troops are invisible - don't draw anything
  return

  -- if not self.selected then
  --   graphics.rectangle(self.x, self.y, 3, 3, 1, 1, self.color)
  -- end

  -- if self.state == unit_states['casting'] then
  --   self:draw_cast_timer()
  -- end
  -- if self.state == unit_states['channeling'] then
  --   self:draw_channeling()
  -- end

  -- if not Helper.Unit:cast_off_cooldown(self) then
  --   self:draw_cooldown_timer()
  -- end
  -- if self.bubbled then 
  --   graphics.circle(self.x, self.y, self.shape.w, yellow_transparent_weak)
  -- end
  -- --not going very transparent
  -- if self:isShielded() then
  --   local color = yellow[5]:clone()
  --   color.a = 0.3
  --   graphics.circle(self.x, self.y, self.shape.w*0.6, color)
  -- end

  -- --draw aggro sensor
  -- -- graphics.circle(self.x, self.y, self.aggro_sensor.rs, yellow[5], 2)

  -- graphics.pop()
  
  -- -- Debug steering forces
  -- self:draw_steering_debug()
end

function Troop:draw_distance_glow()
  local tier = Helper.Unit.closest_enemy_distance_tier
  if not tier or tier > 3 then return end

  if tier then
    local glow_multipliers = {
      [1] = 0.1,
      [2] = 0.07,
      [3] = 0.04,
    }

    local glow_intensity = glow_multipliers[tier]
    
    local glow_color = green[0]:clone()
    glow_color.a = glow_intensity

    local glow_color_2 = green[0]:clone()
    glow_color_2.a = glow_intensity * 0.5
    
    -- Draw glow rings
    local body_size = self.shape.w / 2
    graphics.circle(self.x, self.y, body_size, glow_color, 2)
    graphics.circle(self.x, self.y, body_size + 2, glow_color_2, 2)
  end
end

function Troop:create_distance_tier_effect(tier)
--pass
end


function Troop:draw_cooldown_timer()
  -- Show animation during both casting and cooldown
  local is_casting = (self.state == unit_states['casting'])
  local is_cooling = (self.attack_cooldown_timer and self.attack_cooldown_timer > 0)
  
  if not is_casting and not is_cooling then return end

  -- --- Configuration ---
  local bodySize = self.shape.rs or self.shape.w / 2 or 5
  local min_radius_mod = 0.3 -- Smaller min size 
  local max_radius_mod = 1.2 -- Smaller max size
  local current_radius = 0

  if is_casting then
      -- PHASE 1: EXPANDING during cast (grows outward)
      local cast_progress = 1 - ((self.castObject and self.castObject.elapsedTime) or 0) / (self.cast_time or 0.1)
      cast_progress = math.clamp(cast_progress, 0, 1)
      current_radius = (min_radius_mod * bodySize) + (max_radius_mod * bodySize - min_radius_mod * bodySize) * cast_progress
      
  elseif is_cooling then
      -- PHASE 2: SHRINKING during cooldown (shrinks inward)  
      local cooldown_progress = self.attack_cooldown_timer / self.attack_cooldown
      current_radius = (min_radius_mod * bodySize) + (max_radius_mod * bodySize - min_radius_mod * bodySize) * cooldown_progress
  end
  
  -- Ensure the radius never becomes negative
  current_radius = math.max(0, current_radius)

  -- Draw the final circle
  graphics.circle(self.x, self.y, current_radius, white_transparent_weak)
end

function Troop:attack(area, mods)

  --on attack callbacks
  if self.onAttackCallbacks then
    self:onAttackCallbacks(self.target)
  end
  mods = mods or {}
  local t = {group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = (area or 64), color = self.color, damage = function() return self.dmg end,
    character = self.character, level = self.level, parent = self, is_troop = true, unit = self}
  Area(table.merge(t, mods))

end

function Troop:bubble(duration)
  self.bubbled = true
  self.t:after(duration, function() self.bubbled = false end)
end


function Troop:onDeath()
  self.state_change_functions['death'](self)
  self.death_function()
end



function Troop:set_character()
  --override in subclasses
end

function Troop:hit(damage, from, damageType, playHitEffects, cannotProcOnHit)
  -- Mark this unit as a troop for the damage helper
  self.is_troop = true
  -- Use the indirect hit function (current behavior)
  table.random({player_hit1, player_hit2}):play{pitch = random:float(0.95, 1.05), volume = 0.5}
  Helper.Damage:indirect_hit(self, damage, from, damageType, playHitEffects)
end

function Troop:take_damage(damage)
  --self.hp = self.hp - damage

  --have level orb take damage instead
  if main.current.current_arena and main.current.current_arena.level_orb then
    main.current.current_arena.level_orb:hit(damage, nil, DAMAGE_TYPE_PHYSICAL)
  else
    self.hp = self.hp - damage
  end
end


function Troop:die()
  Troop.super.die(self)
  if self.dead then return end
  self.dead = true
  Stats_Current_Run_Troop_Deaths()

  if self.parent and self.parent.summons then
    self.parent.summons = self.parent.summons - 1
  end

  self.state_change_functions['death'](self)
  self.death_function()
end

function Troop:on_collision_enter(other, contact)
  local x, y = contact:getPositions()

  if other:is(Wall) then
      self:bounce(contact:getNormal())
      local r = random:float(0.9, 1.1)
      player_hit_wall1:play{pitch = r, volume = 0.1}
      pop1:play{pitch = r, volume = 0.2}
  elseif table.any(main.current.enemies, function(v) return other:is(v) end) then

    local duration = KNOCKBACK_DURATION_ENEMY
    local push_force = LAUNCH_PUSH_FORCE_ENEMY
    local dmg = REGULAR_PUSH_DAMAGE

    if other:is(Boss) then  
      duration = KNOCKBACK_DURATION_BOSS
      push_force = LAUNCH_PUSH_FORCE_BOSS
      dmg = BOSS_PUSH_DAMAGE
    elseif other.class == 'special_enemy' then
      duration = KNOCKBACK_DURATION_SPECIAL_ENEMY
      push_force = LAUNCH_PUSH_FORCE_SPECIAL_ENEMY
      dmg = SPECIAL_PUSH_DAMAGE
    end
    
    self:push(push_force, self:angle_to_object(other) + math.pi, nil, duration)
    --delay the damage to avoid box2d lock
    self.t:after(0, function()
      if self and not self.dead then
        self:hit(dmg, other, nil, false, true)
      end
    end)
  elseif table.any(main.current.friendlies, function(v) return other:is(v) end) then
      -- Handle damage impulse propagation
      local vx, vy = self:get_velocity()
      local speed = math.sqrt(vx * vx + vy * vy)
      if speed > 50 then -- Only propagate if moving fast enough
          local angle = math.atan2(vy, vx)
          other:push(LAUNCH_PUSH_FORCE_ENEMY, angle, nil)
      end
  end
end

function Troop:setup_cast(cast_target)
  --override in subclasses
end

function Troop:removeHealFlag(duration)
  self.t:after(duration, function() self.beingHealed = false end, 'cancelHealFlag')
end


function Troop:heal(amount)
  local hp = self.hp
  self.hfx:use('hit', 0.25, 200, 10)
  self.hp = self.hp + amount
  if self.hp > self.max_hp then self.hp = self.max_hp end
end

function Troop:get_hurt_ally(sensor)
  local allies = self:get_objects_in_shape(sensor, troop_classes)
  if not allies or #allies == 0 then return false end
  for _, ally in ipairs(allies) do
    if ally.hp < ally.max_hp and self.id ~= ally.id and ally.beingHealed == false then
      return ally
    end
  end
  return false
end

function Troop:get_most_hurt_ally(sensor)
  local allies = self:get_objects_in_shape(sensor, {Troop})
  if not allies or #allies == 0 then return false end
  local pct = 1
  local target = nil
  for _, ally in ipairs(allies) do
    if ally.hp < ally.max_hp and self.id ~= ally.id then
      if ( ally.hp / ally.max_hp ) < pct and not ally.bubbled and ally.beingHealed == false then
        target = ally
        pct = ally.hp / ally.max_hp
      end
    end
  end
  if target then return target end
  return false
end

function Troop:get_hurt_ally_without_shield(sensor)
  local allies = self:get_objects_in_shape(sensor, {Troop})
  if not allies or #allies == 0 then return false end
  for _, ally in ipairs(allies) do
    if ally.hp < ally.max_hp and self.id ~= ally.id and not ally.shielded and not ally.bubbled and ally.beingHealed == false then
      return ally
    end
  end
  return false
end

function Troop:get_team()
  if not self.team then return end
  return Helper.Unit.teams[self.team]
end

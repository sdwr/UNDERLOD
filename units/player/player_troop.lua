Troop = Unit:extend()
Troop:implement(GameObject)
Troop:implement(Physics)
function Troop:init(args)
  self.class = 'troop'
  self.faction = 'friendly'
  self.size = unit_size['medium']
  self.is_troop = true
  self.target_rally = nil
  self.castTime = 0.3
  self.backswing = 0.2
  self:reset_castcooldown(self.baseCast or 1)
  --buff examples...
  --self.buffs[1] = {name = buff_types['dmg'], amount = 0.2, color = red_transparent_weak}
  --self.buffs[2] = {name = buff_types['aspd'], amount = 0.2, color = green_transparent_weak}
  self.beingHealed = false
  self:init_game_object(args)
  Helper.Unit:add_custom_variables_to_unit(self)
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
  
  self.aggro_sensor = self.aggro_sensor or Circle(self.x, self.y, self.attack_sensor.rs + AGGRO_RANGE_BOOST)
  self:set_character()

  Helper.Unit:set_state(self, unit_states['normal'])
end


--called in oncastfinish for all troops
function Troop:stretch_on_attack()
  local stretch_factor = 0.4
  self.hfx:pull('attack_scale_y', stretch_factor)
  self.hfx:pull('attack_scale_x', - stretch_factor)
end

function Troop:follow_mouse()
  -- If not, continue moving towards the mouse.
  self:steering_separate(SEPARATION_RADIUS, troop_classes)
  if self:distance_to_mouse() > 10 then
    self:seek_mouse(SEEK_DECELERATION, SEEK_WEIGHT)
    self:wander(WANDER_RADIUS, WANDER_DISTANCE, WANDER_JITTER)
    self:rotate_towards_velocity(1)
  else
      --self:set_velocity(0, 0) -- Stop when we reach the cursor
  end
end

function Troop:rally_to_point()
  -- If not, continue moving towards the rally point.
  self:seek_point(self.target_pos.x, self.target_pos.y, SEEK_DECELERATION, SEEK_WEIGHT)
  self:steering_separate(SEPARATION_RADIUS, troop_classes)
  self:wander(WANDER_RADIUS, WANDER_DISTANCE, WANDER_JITTER)
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

  self:update_movement_effect(dt)
  self:update_survivor_effect(dt)

  -- ===================================================================
  -- 2. THE STATE MACHINE (Hierarchical and Predictable)
  -- ===================================================================
  -- This is one big if/elseif block. Only ONE of these can run per frame,
  -- which prevents state flickering. The order is based on priority.

  if self.state == unit_states['normal'] or self.state == unit_states['following'] then
    self:update_ai_logic()
  end

  -- PRIORITY 1: Uninterruptible States
  -- If a unit is knocked back or frozen, it can't do anything else.
  if self.state == unit_states['knockback'] or self.state == unit_states['frozen'] then
      -- The logic that takes the unit *out* of these states (like a timer)
      -- is handled elsewhere (e.g., in the Troop:push function).
      -- We do nothing else here.

  -- PRIORITY 2: Player-Commanded States
  -- If the unit is actively following the mouse.
  elseif self.state == unit_states['following'] then

      -- self:cancel_cast()
      -- self:clear_my_target()
      -- self:clear_assigned_target()

      -- Check if we should STOP following.
      if input['m1'].released or input['space'].released then
          Helper.Unit:set_state(self, unit_states['normal'])
      else
        self:follow_mouse()

      end

  -- If the unit is moving to a rally point.
  elseif self.state == unit_states['rallying'] then

    -- clear my target (but not assigned target)
    self:clear_my_target()

    -- Check if we have arrived at the rally point.
    local distance_to_target_pos = math.distance(self.x, self.y, self.target_pos.x, self.target_pos.y)
    if distance_to_target_pos < 9 or not self.rallying then -- Also stop if rally is cancelled
        Helper.Unit:set_state(self, unit_states['normal'])
    else
        self:rally_to_point()
    end

  -- PRIORITY 3: Action States (Busy States)
  -- If the unit is in the middle of casting an ability.
  elseif self.state == unit_states['casting'] then

      if self.castObject then
        if Helper.Unit:target_out_of_range(self, self.castObject.target) then
          self:cancel_cast()
        end
      end

      -- Allow movement while casting - troops can shoot while moving
      if self:should_follow() then
        self:follow_mouse()
      elseif self.rallying then
        self:rally_to_point()
      elseif self:my_target() then
        -- In range, allow some movement for positioning
        self:steering_separate(SEPARATION_RADIUS, troop_classes)
        self:rotate_towards_object(self:my_target(), 1)
      else
        -- No target, allow normal movement
        self:steering_separate(SEPARATION_RADIUS, troop_classes)
      end

  -- If the unit is in its "backswing" after an attack.
  elseif self.state == unit_states['stopped'] then
      -- The unit is still and cannot start a new action yet.
      -- A timer set by the Cast object should move it from 'stopped' to 'normal'.
      self:set_velocity(0, 0)

  -- PRIORITY 4: Autonomous AI State
  -- If the unit is not doing any of the above, it's 'normal' and can think for itself.
  elseif self.state == unit_states['normal'] then
      -- First, check if a player command is being issued that would override this state.
      if self:should_follow() then
          Helper.Unit:clear_all_rally_points()
          Helper.Unit:set_state(self, unit_states['following'])
          self.target = nil
          self.target_pos = nil
      elseif self.rallying then
          Helper.Unit:set_state(self, unit_states['rallying'])
          self:set_rally_position(random:int(1, 10))
      else
        --if in range of any target, don't move
        if self:in_range('assigned')() then
          self:steering_separate(SEPARATION_RADIUS, troop_classes)
          self:rotate_towards_object(self.assigned_target, 1)
        elseif self:in_range('regular')() then
          self:steering_separate(SEPARATION_RADIUS, troop_classes)
          self:rotate_towards_object(self.target, 1)
        else
          --move towards the closest enemy (don't bother targeting it)
          local movement_target = self:get_closest_object_in_shape(self.aggro_sensor, main.current.enemies)
          if movement_target then
            self:seek_point(movement_target.x, movement_target.y, SEEK_DECELERATION, SEEK_WEIGHT)
            self:steering_separate(SEPARATION_RADIUS, troop_classes)
            self:wander(WANDER_RADIUS, WANDER_DISTANCE, WANDER_JITTER)
            self:rotate_towards_velocity(1)
          else
            self:steering_separate(SEPARATION_RADIUS, troop_classes)
          end
        end
      end
    end

  -- ===================================================================
  -- 3. FINAL PHYSICS AND POSITIONING (These also always run)
  -- ===================================================================
  self.r = self:get_angle()
  self.attack_sensor:move_to(self.x, self.y)
  self.aggro_sensor:move_to(self.x, self.y)
end

function Troop:update_ai_logic()
  -- This function is only called when the unit is in the 'normal' state.
  -- It represents the unit's autonomous decision-making process.

  -- 1. VALIDATE CURRENT TARGET
  -- First, check if our current target is dead or invalid. If so, clear it.
  local assigned_target = self.assigned_target
  local regular_target = self.target

  if assigned_target and assigned_target.dead then
    self:clear_assigned_target()
  end

  if regular_target and regular_target.dead then
    self.clear_my_target()
  end

  local cast_target = nil
  if self:in_range('assigned')() then
    cast_target = assigned_target
  elseif self:in_range('regular')() then
    cast_target = regular_target
  end
  

  -- 2. ACQUIRE NEW TARGET
  -- If we don't have a target, try to find the closest one within our aggro range.
  if not cast_target then
      --find target if not already found
      -- pick random in attack range
      -- or closest in aggro range
      if self:has_potential_target_in_range() then
        self:set_target(self:get_random_object_in_shape(self.attack_sensor, main.current.enemies))
        cast_target = self.target
      else
        self:set_target(self:get_closest_object_in_shape(self.aggro_sensor, main.current.enemies))
      end
  end

  -- 3. ACT BASED ON TARGET STATUS
  -- If we have a valid target (either pre-existing or newly acquired)...
  if cast_target then
      -- 3a. CHECK IF WE CAN ATTACK.
      -- We must be in range AND our cast must be off cooldown.
      if Helper.Unit:can_cast(self, cast_target) then
          -- If yes, commit to casting.
          -- NOTE: Your can_cast helper might do both checks, which is fine!
          self:setup_cast(cast_target)
      end
  end
end


function Troop:set_rally_position(i)
  local team = Helper.Unit.teams[self.team]
  self.target_pos = sum_vectors({x = team.rallyCircle.x, y = team.rallyCircle.y}, rally_offsets(i))

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
  --graphics.circle(self.x, self.y, self.attack_sensor.rs, orange[0], 1)

  local final_scale_x = self.hfx.attack_scale_x.x 
    * self.hfx.move_scale_x.x 
    * self.hfx.survivor_scale.x
    * self.hfx.hit.x 
  local final_scale_y = self.hfx.attack_scale_y.x 
    * self.hfx.move_scale_y.x
    * self.hfx.survivor_scale.x
    * self.hfx.hit.x 

  graphics.push(self.x, self.y, self.r, final_scale_x, final_scale_y)
  self:draw_buffs()

  -- -- darken the non-selected units
  -- local color = self.color:clone()
  -- color = color:lighten(SELECTED_PLAYER_LIGHTEN)

  --draw unit model (rectangle not circle??)
  graphics.rectangle(self.x, self.y, self.shape.w*.66, self.shape.h*.66, 3, 3, self.hfx.hit.f and fg[0] or self.color)

  -- if not self.selected then
  --   graphics.rectangle(self.x, self.y, 3, 3, 1, 1, self.color)
  -- end

  if self.state == unit_states['casting'] then
    self:draw_cast_timer()
  end
  if self.state == unit_states['channeling'] then
    self:draw_channeling()
  end
  if self.state == unit_states['knockback'] then
    self:draw_knockback()
  end
  if not Helper.Unit:cast_off_cooldown(self) then
    self:draw_cooldown_timer()
  end
  if self.bubbled then 
    graphics.circle(self.x, self.y, self.shape.w, yellow_transparent_weak)
  end
  --not going very transparent
  if self:isShielded() then
    local color = yellow[5]:clone()
    color.a = 0.3
    graphics.circle(self.x, self.y, self.shape.w*0.6, color)
  end

  --draw aggro sensor
  -- graphics.circle(self.x, self.y, self.aggro_sensor.rs, yellow[5], 2)

  graphics.pop()
end

function Troop:draw_cooldown_timer()
  -- Only draw if the cooldown is active
  if not self.castcooldown or self.castcooldown <= 0 then return end

  -- --- Configuration ---
  local growth_duration = 0.1 -- The first 0.15 seconds are for growing
  local bodySize = self.shape.rs or self.shape.w / 2 or 5
  local min_radius_mod = 0.4 -- The smallest size of the circle (relative to bodySize)
  local max_radius_mod = 1.7 -- The largest size of the circle (relative to bodySize)

  -- --- Calculations ---
  local elapsed_time = self.total_castcooldown - self.castcooldown
  local current_radius = 0

  if elapsed_time < growth_duration then
      -- PHASE 1: GROWING
      -- Calculate the progress of the growth phase (from 0 to 1)
      local growth_pct = elapsed_time / growth_duration
      -- Interpolate the radius from min to max size
      current_radius = (min_radius_mod * bodySize) + (max_radius_mod * bodySize - min_radius_mod * bodySize) * growth_pct
  else
      -- PHASE 2: SHRINKING
      -- Calculate the duration and progress of the shrink phase
      local shrink_duration = self.total_castcooldown - growth_duration
      local shrink_elapsed = elapsed_time - growth_duration
      local shrink_pct = shrink_elapsed / shrink_duration
      -- Interpolate the radius from max back down to min size
      current_radius = (max_radius_mod * bodySize) - (max_radius_mod * bodySize - min_radius_mod * bodySize) * shrink_pct
  end
  
  -- Ensure the radius never becomes negative if timings are off
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
  local t = {group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(area or 64), color = self.color, damage = function() return self.dmg end,
    character = self.character, level = self.level, parent = self, is_troop = true}
  Area(table.merge(t, mods))

end

function Troop:bubble(duration)
  self.bubbled = true
  self.t:after(duration, function() self.bubbled = false end)
end


function Troop:onDeath()
  slow(0.25, 1.5)
  shoot1:play{pitch = random:float(0.95, 1.05), volume = 1}
  TroopDeathAnimation{group = main.current.effects, x = self.x, y = self.y}
  self.state_change_functions['death'](self)
  self.death_function()
end



function Troop:set_character()
  if self.character == 'pyro' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['long'])
    -- self.cooldownTime = 2
    self.castTime = 0

    self.state_change_functions['following_or_rallying'] = function(self)
      Helper.Time:cancel_wait(self.spell_wait_id)
      self.spell_wait_id = -1
    end


    self.state_change_functions['target_death'] = function(self)
      Helper.Unit:unclaim_target(self)
    end

    self.state_change_functions['death'] = function(self)
      Helper.Time:cancel_wait(self.spell_wait_id)
      self.spell_wait_id = -1
      -- Helper.Spell.Burst:stop_firing(self)
      Helper.Unit:unclaim_target(self)

    end



  elseif self.character == 'cannon' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['long'])

    --cooldown
    self.baseCooldown = attack_speeds['medium-fast']
    self.cooldownTime = self.baseCooldown
    self.baseCast = attack_speeds['short-cast']
    self.castTime = self.baseCast
    self.state_change_functions['normal'] = function() end

    --cancel on death
    self.state_change_functions['death'] = function()
      -- Helper.Spell.Missile:stop_aiming(self)
      Helper.Unit:unclaim_target(self)
    end

  elseif self.character == 'bomber' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['whole-map'])

    --cooldown
    self.baseCooldown = attack_speeds['medium']
    self.cooldownTime = self.baseCooldown
    self.baseCast = attack_speeds['long-cast']
    self.castTime = self.baseCast

    --attack
    self.explode_radius = 15

    self.state_change_functions['normal'] = function() end

    --cancel on death
    self.state_change_functions['death'] = function(self)
      Helper.Spell.Bomb:stop_aiming(self)
      Helper.Unit:unclaim_target(self)
    end

  elseif self.character == 'sniper' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['ultra-long'])

    --cooldown
    self.baseCooldown = attack_speeds['medium']
    self.cooldownTime = self.baseCooldown
    self.baseCast = attack_speeds['ultra-long-cast']
    self.castTime = self.baseCast

    self.state_change_functions['normal'] = function() end
    --cancel on death
    self.state_change_functions['death'] = function(self)
      self.spell:cancel()
    end
  end
end

function Troop:hit(damage, from, damageType, makesSound, cannotProcOnHit)
  -- Mark this unit as a troop for the damage helper
  self.is_troop = true
  -- Use the indirect hit function (current behavior)
  Helper.Damage:indirect_hit(self, damage, from, damageType, makesSound)
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

    player_hit1:play{pitch = random:float(0.95, 1.05), volume = 1.5}

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
    self:hit(dmg, other, nil, false, true)
  elseif table.any(main.current.friendlies, function(v) return other:is(v) end) then
      -- Handle knockback propagation
      if self.state == unit_states['knockback'] and other.state ~= unit_states['knockback'] then
          -- Transfer momentum to the other troop
          local vx, vy = self:get_velocity()
          local speed = math.sqrt(vx * vx + vy * vy)
          local angle = math.atan2(vy, vx)
          other:push(LAUNCH_PUSH_FORCE_ENEMY, angle, nil)
      end
  end
end

function Troop:setup_cast()
  --overridden in subclasses
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

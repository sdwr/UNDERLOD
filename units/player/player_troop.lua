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
  self.castcooldown = self.baseCast or 1
  --buff examples...
  --self.buffs[1] = {name = buff_types['dmg'], amount = 0.2, color = red_transparent_weak}
  --self.buffs[2] = {name = buff_types['aspd'], amount = 0.2, color = green_transparent_weak}
  self.beingHealed = false
  self:init_game_object(args)
  Helper.Unit:add_custom_variables_to_unit(self)
  self:init_unit()
  local level = self.level or 1



  self:calculate_stats(true)

  self.color = character_colors[self.character]
  self.type = character_types[self.character]
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 40)
  
  self.aggro_sensor = self.aggro_sensor or Circle(self.x, self.y, self.attack_sensor.rs + AGGRO_RANGE_BOOST)
  self:set_character()

  Helper.Unit:set_state(self, unit_states['normal'])
end

function Troop:follow_mouse()
  -- If not, continue moving towards the mouse.
  if self:distance_to_mouse() > 10 then
    self:seek_mouse(SEEK_DECELERATION, SEEK_WEIGHT)
    self:steering_separate(SEPARATION_RADIUS, troop_classes)
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

function Troop:update(dt)
  -- ===================================================================
  -- 1. ESSENTIAL HOUSEKEEPING (These should always run)
  -- ===================================================================
  self:update_game_object(dt)
  self:update_cast_cooldown(dt)
  self:onTickCallbacks(dt)
  self:update_buffs(dt)
  self:calculate_stats()
  self:update_targets() -- Updates who the unit is targeting

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
        if Helper.Unit:target_out_of_range(self) then
          Helper.Unit:unclaim_target(self)
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
        if self:my_target() then
          local target = self:my_target()
          if not self:in_range()() then
            -- If target is out of range, move towards it. This is the "aggro" behavior.
            self:seek_point(target.x, target.y, SEEK_DECELERATION, SEEK_WEIGHT)
            self:steering_separate(SEPARATION_RADIUS, troop_classes)
            self:wander(WANDER_RADIUS, WANDER_DISTANCE, WANDER_JITTER)
            self:rotate_towards_velocity(1)
        
          -- 3c. If we're in range but waiting for cooldown, stand still.
          else
              --self:set_velocity(0, 0)
              self:steering_separate(SEPARATION_RADIUS, troop_classes)
              -- Also, rotate to face the target while waiting.
              self:rotate_towards_object(target, 1)
          end
        else
          -- 4. NO TARGET
          -- If after all checks we still have no target, do nothing. Stand still.
          --self:set_velocity(0, 0)
          self:steering_separate(SEPARATION_RADIUS, troop_classes)
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
  local target = self:my_target()
  if target and target.dead then
    self:clear_my_target()
    target = nil -- Make sure our local variable is also nil
  elseif target and not self:in_range()() then
    self:clear_my_target()
    target = nil
  end
  

  -- 2. ACQUIRE NEW TARGET
  -- If we don't have a target, try to find the closest one within our aggro range.
  if not target then
      --find target if not already found
      -- pick random in attack range
      -- or closest in aggro range
      if self:has_potential_target_in_range() then
        self:set_target(self:get_random_object_in_shape(self.attack_sensor, main.current.enemies))
      else
        self:set_target(self:get_closest_object_in_shape(self.aggro_sensor, main.current.enemies))
      end

      target = self.target
  end

  -- 3. ACT BASED ON TARGET STATUS
  -- If we have a valid target (either pre-existing or newly acquired)...
  if target then
      -- 3a. CHECK IF WE CAN ATTACK.
      -- We must be in range AND our cast must be off cooldown.
      if Helper.Unit:can_cast(self) then
          -- If yes, commit to casting.
          -- NOTE: Your can_cast helper might do both checks, which is fine!
          self:setup_cast()
      end
  end
end


function Troop:set_rally_position(i)
  local team = Helper.Unit.teams[self.team]
  self.target_pos = sum_vectors({x = team.rallyCircle.x, y = team.rallyCircle.y}, rally_offsets(i))

end

function Troop:push(f, r, push_invulnerable, duration)
  --only push if not already pushing
  if self.state == unit_states['knockback'] then
    return
  end

  local mass
  if self.body then
    mass = self.body:getMass()
  else
    mass = 1
  end

  local n = 1 -- Push force multiplier
  self.push_invulnerable = push_invulnerable
  self.push_force = n * f * mass

  Helper.Unit:set_state(self, unit_states['knockback'])
  self.mass = TROOP_KNOCKBACK_MASS
  self:set_damping(LAUNCH_DAMPING)

  duration = duration or KNOCKBACK_DURATION_ENEMY

  -- Apply an immediate impulse
  self:set_velocity(0,0)
  self:apply_impulse(self.push_force * math.cos(r), self.push_force * math.sin(r))
  self:apply_angular_impulse(random:table{random:float(-12*math.pi, -4*math.pi), random:float(4*math.pi, 12*math.pi)})
  
  -- Cancel any existing during trigger for push
  if self.cancel_trigger_tag then
    self.t:cancel(self.cancel_trigger_tag)
  end

  -- Reset state after the duration
  self.cancel_trigger_tag = self.t:after(duration, function()
    if self.state == unit_states['knockback'] then
      Helper.Unit:set_state(self, unit_states['normal'])
    end
      self.mass = TROOP_MASS
      self:set_damping(TROOP_DAMPING)
  end)
end


function Troop:draw()
  --graphics.circle(self.x, self.y, self.attack_sensor.rs, orange[0], 1)
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
  self:draw_buffs()

  -- darken the non-selected units
  local color = self.color:clone()
  color = color:lighten(SELECTED_PLAYER_LIGHTEN)

  --draw unit model (rectangle not circle??)
  graphics.rectangle(self.x, self.y, self.shape.w*.66, self.shape.h*.66, 3, 3, self.hfx.hit.f and fg[0] or self.color)

  if not self.selected then
    graphics.rectangle(self.x, self.y, 3, 3, 1, 1, color)
  end

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
  local pct = self.castcooldown / self.total_castcooldown
  local bodySize = self.shape.rs or self.shape.w/2 or 5
  local rs = (pct * bodySize * 1.5) + bodySize * 0.5
  if time < Helper.Unit.cast_flash_duration then
    graphics.circle(self.x, self.y, rs, yellow_transparent_weak)
  elseif pct > 0 then
    graphics.circle(self.x, self.y, rs, white_transparent_weak)
  end
end

function Troop:draw_knockback()
  graphics.circle(self.x, self.y, self.shape.w/2 + 1, red_transparent)
end

function Troop:shoot(r, mods)
  mods = mods or {}

  local crit = false
  HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
  local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 250, r = r, color = self.color, dmg = self.dmg, crit = crit, character = self.character,
  parent = self, level = self.level}
  Projectile(table.merge(t, mods or {}))
end

function Troop:attack(area, mods)

  --on attack callbacks
  if self.onAttackCallbacks then
    self:onAttackCallbacks(self.target)
  end
  mods = mods or {}
  local t = {group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(area or 64), color = self.color, dmg = self.dmg,
    character = self.character, level = self.level, parent = self, is_troop = true}
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

  if self.invulnerable then return end

  if makesSound == nil then makesSound = true end
  if cannotProcOnHit == nil then cannotProcOnHit = false end

  if self.bubbled then return end
  if self.dead then return end

  --scale hit effect to damage
  --no damage won't grow model, up to max effect at 0.5x max hp
  local hitStrength = (damage * 1.0) / self.max_hp
  hitStrength = math.min(hitStrength, 0.5)
  hitStrength = math.remap(hitStrength, 0, 0.5, 0, 1)
  if makesSound then
    self.hfx:use('hit', 0.25 * hitStrength, 200, 10)
  end
  self:show_hp()

  --this should really be on the base unit class (objects.lua)!
  if self:isShielded() then
    if self.shielded > damage then 
      self.shielded = self.shielded - damage
      damage = 0
    else
      damage = damage - self.shielded
      self.shielded = 0
    end
  end

  local actual_damage = math.max(self:calculate_damage(damage), 0)
  
  self.hp = self.hp - actual_damage

  self:show_damage_number(damage, damageType)
  
  --on hit callbacks
  if from and from.onHitCallbacks and not cannotProcOnHit then
    from:onHitCallbacks(self, actual_damage, damageType)
  end
  self:onGotHitCallbacks(from, actual_damage, damageType)

  camera:shake(1, 0.5)

  if self.hp > 0 then
    if makesSound then
      _G[random:table{'player_hit1', 'player_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.8}
    end
  else
    if makesSound then
      hit4:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    end
    for i = 1, random:int(4, 6) do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 12}:scale_down(0.3):change_color(0.5, self.color)

    --on death callbacks
    if from and from.onKillCallbacks then
      from:onKillCallbacks(self)
    end
    self:onDeathCallbacks(from)

    self:die()
    if main.current:all_troops_dead() then
      main.current:die()
    end

    if self.dot_area then self.dot_area.dead = true; self.dot_area = nil end
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

    player_hit1:play{pitch = random:float(0.95, 1.05), volume = 1.5}

    local duration = KNOCKBACK_DURATION_ENEMY
    local push_force = LAUNCH_PUSH_FORCE_ENEMY
    local dmg = REGULAR_PUSH_DAMAGE
    if other:is(Boss) then  
      duration = KNOCKBACK_DURATION_BOSS
      push_force = LAUNCH_PUSH_FORCE_BOSS
      dmg = SPECIAL_PUSH_DAMAGE
    end
    self:push(push_force, self:angle_to_object(other) + math.pi, nil, duration)
    self:hit(dmg, other, nil, false)
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

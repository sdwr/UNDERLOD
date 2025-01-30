
Troop = Unit:extend()
Troop:implement(GameObject)
Troop:implement(Physics)
function Troop:init(args)
  self.size = unit_size['medium']
  self.class = 'troop'
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
  self:init_unit()
  local level = self.level or 1



  self:calculate_stats(true)

  self.color = character_colors[self.character]
  self.type = character_types[self.character]
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 40)
  
  self.aggro_sensor = self.aggro_sensor or Circle(self.x, self.y, 120)
  self:set_character()

  self.state = unit_states['normal']
end

function Troop:update(dt)
  self:update_game_object(dt)
  self:update_cast_cooldown(dt)

  self:onTickCallbacks(dt)
  self:update_buffs(dt)

  self:calculate_stats()

  --shouldn't be in here, but update the unit targets as well
  self:update_targets()

  --add for players too?
  --self:update_cast()

  --[[
  --steps should be:
  -- rally priority
  -- if target in range, wait
  -- else, find closest target
  -- if target out of range, move towards target

  to get a proper stutter step, unit needs to pause while attacking
  it's fine if attack is on its own timer, so long as it blocks movement for windup (and default movmeent for backswing baybeeee)

  need a timer where unit doesn't initiate moves (windup)
  and a timer where it doesn't move unless rallied (backswing)

  states: normal, frozen, stopped


  ]]--

  -- deal with mouse input first, set rally/follow
  if self:should_follow() then
    Helper.Unit:clear_all_rally_points()
    self.state = unit_states['following']

    --dont clear assigned target here
    self.target = nil
    self.target_pos = nil
  end

  --cancel follow if no longer pressing button
  if self.state == unit_states['following'] then
    if input['m1'].released or input['space'].released then
      self.state = unit_states['normal']
    end
  end

  if not self.being_pushed then
    self:update_movement()
  end
  
  self.r = self:get_angle()

  self.attack_sensor:move_to(self.x, self.y)
  self.aggro_sensor:move_to(self.x, self.y)
end

function Troop:update_movement()
  -- then do movement if rally/following
  if self.state == unit_states['following'] then
    --if not in range, move towards mouse
    if self:distance_to_mouse() > 10 then
      self:seek_mouse(SEEK_DECELERATION, SEEK_WEIGHT)
      self:steering_separate(SEPARATION_RADIUS, troop_classes)
      self:wander(WANDER_RADIUS, WANDER_DISTANCE, WANDER_JITTER)
      self:rotate_towards_velocity(1)
    else
      self:set_velocity(0,0)
    end

  elseif self.state == unit_states['rallying'] then
      self:seek_point(self.target_pos.x, self.target_pos.y, SEEK_DECELERATION, SEEK_WEIGHT)
      self:steering_separate(SEPARATION_RADIUS, troop_classes)
      self:wander(WANDER_RADIUS, WANDER_DISTANCE, WANDER_JITTER)
      self:rotate_towards_velocity(1)
      local distance_to_target_pos = math.distance(self.x, self.y, self.target_pos.x, self.target_pos.y)
      --if close enough, stop (which enables attacking)
      --when the rally circle disappears, it sets the unit back to 'normal' state
      if distance_to_target_pos < 5 then
        self.state = unit_states['stopped']
      end
  
  --then find target if not already moving
  elseif self.state == unit_states['normal'] then

    local target = self:my_target()
    --find target if not already found
    if not target then 
      self:set_target(self:get_closest_object_in_shape(self.aggro_sensor, main.current.enemies))
    end

    target = self:my_target()

    --if target not in attack range, close in
    if target and not self:in_range()() and self.state == unit_states['normal'] 
      and self:in_aggro_range()() then
      self:seek_point(target.x, target.y, SEEK_DECELERATION, SEEK_WEIGHT)
      self:steering_separate(SEPARATION_RADIUS, troop_classes)
      self:wander(WANDER_RADIUS, WANDER_DISTANCE, WANDER_JITTER)
      self:rotate_towards_velocity(1)
    --otherwise target is in attack range or doesn't exist, stay still
    else
      self:set_velocity(0,0)
      self:steering_separate(16, troop_classes)
    end
  else
    self:set_velocity(0,0)
  end
end

function Troop:push(f, r, push_invulnerable)
  local n = 1 -- Push force multiplier
  self.push_invulnerable = push_invulnerable
  self.push_force = n * f
  self.being_pushed = true -- Mark as being pushed
  self.steering_enabled = false -- Temporarily disable steering

  -- Apply a single impulse for immediate knockback
  self:apply_impulse(n * f * math.cos(r), n * f * math.sin(r))

  -- Apply angular impulse for rotation
  self:apply_angular_impulse(
      random:table{
          random:float(-12 * math.pi, -4 * math.pi),
          random:float(4 * math.pi, 12 * math.pi)
      }
  )

  -- Apply damping to control velocity decay (adjust for desired effect)
  self:set_damping(0.1) -- Low damping for sustained knockback
  self:set_angular_damping(0.1)

  -- Reset state after a fixed duration
  self.t:after(0.25, function()
      self.being_pushed = false
      self.steering_enabled = true
      self:set_damping(0.0) -- Reset linear damping
      self:set_angular_damping(0.0) -- Reset angular damping
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
  self.state_change_functions['death']()
  self.death_function()
end



function Troop:set_character()
  if self.character == 'pyro' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['long'])
    -- self.cooldownTime = 2
    self.castTime = 0

    self.state_always_run_functions['normal_or_stopped'] = function()
      if Helper.Spell:there_is_target_in_range(self, attack_ranges['long'], true) 
      and Helper.Time.time - self.last_attack_finished > 2 
      and Helper.Time.time - self.last_attack_started > 2 then
        self.last_attack_started = Helper.Time.time
        Helper.Time:wait(1, function()
          self.last_attack_finished = Helper.Time.time
        end)
        self.spell_wait_id = Helper.Time:wait(1, function()
          Helper.Unit:claim_target(self, Helper.Spell:get_nearest_target(self))
          -- Helper.Spell.Burst:create(Helper.Color.white, 5, self.dmg, 500, self, true)
        end)
      end
    end

    self.state_always_run_functions['always_run'] = function()
      if Helper.Spell:there_is_target_in_range(self, attack_ranges['long'], true) then
        Helper.Unit:claim_target(self, Helper.Spell:get_nearest_target(self))
      end
    end

    self.state_change_functions['following_or_rallying'] = function()
      Helper.Time:cancel_wait(self.spell_wait_id)
      self.spell_wait_id = -1
    end

    self.state_change_functions['target_death'] = function()
      Helper.Unit:unclaim_target(self)
    end

    self.state_change_functions['death'] = function()
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

    --if ready to cast and has target in range, start casting
    self.state_always_run_functions['always_run'] = function()
      if Helper.Unit:can_cast(self) then
        Helper.Unit:claim_target(self, Helper.Spell:get_nearest_target(self))
        Helper.Time:wait(get_random(0, 0.1), function()
          

          --on attack callbacks
          if self.onAttackCallbacks then
            self:onAttackCallbacks(self.target)
          end
          -- Helper.Spell.Missile:create(Helper.Color.orange, 10, self.dmg, 300, self, true, 15)
        end)
      end
    end

    --cancel on move
    self.state_always_run_functions['following_or_rallying'] = function()
      -- Helper.Spell.Missile:stop_aiming(self)
      Helper.Unit:unclaim_target(self)
    end

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

    self.state_always_run_functions['always_run'] = function()
      if Helper.Unit:can_cast(self) then
        
        --on attack callbacks
        if self.onAttackCallbacks then
          self:onAttackCallbacks(self.target)
        end

        Helper.Spell.Bomb:create(black[2], false, self.dmg, 4, self, 1.5, self.explode_radius, self.x, self.y)
      end
    end

    
    --cancel on move
    self.state_always_run_functions['following_or_rallying'] = function()
        Helper.Spell.Bomb:stop_aiming(self)
        Helper.Unit:unclaim_target(self)
    end

    self.state_change_functions['normal'] = function() end

    --cancel on death
    self.state_change_functions['death'] = function()
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

    --if ready to cast and has target in range, start casting
    self.state_always_run_functions['always_run'] = function()
      if Helper.Unit:can_cast(self) then
        Helper.Unit:claim_target(self, Helper.Spell:get_random_in_range(self, self.attack_sensor.rs))

        --on attack callbacks
        if self.onAttackCallbacks then
          self:onAttackCallbacks(self.target)
        end

        self.spell = Snipe{group = main.current.main, team = 'player', parent = self, target = self.target, dmg = self.dmg}
      end
    end
    
    --cancel on move
    self.state_always_run_functions['following_or_rallying'] = function()
      self.spell:cancel()
    end

    self.state_change_functions['normal'] = function() end
    --cancel on death
    self.state_change_functions['death'] = function()
      self.spell:cancel()
    end

  elseif self.character == 'wizard' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium-long'])
    self.t:cooldown(attack_speeds['slow'], self:in_range(), function ()
        self:castAnimation()
    end, nil, nil, 'cast')

  elseif self.character == 'shaman' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium-long'])
    self.t:cooldown(attack_speeds['medium-slow'], self:in_range(), function ()
      self:castAnimation()
    end, nil, nil, 'cast')

  elseif self.character == 'necromancer' then
    self.summons = 0
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['long'])
    self.t:cooldown(attack_speeds['fast'], self:in_range(), function ()
      self:castAnimation()
  end, nil, nil, 'cast')

  elseif self.character == 'paladin' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium-long'])
    self.t:cooldown(attack_speeds['slow'], self:in_range(), function ()
      self.target.beingHealed = true
      self.target:removeHealFlag(self.castTime)
      self:castAnimation()
    end, nil, nil, 'cast')

  elseif self.character == 'cleric' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium'])
    self.t:cooldown(attack_speeds['slow'], self:in_range(), function ()
      self.target.beingHealed = true
      self.target:removeHealFlag(self.castTime)
      self:castAnimation()
    end, nil, nil, 'cast')
  
  elseif self.character =='priest' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium'])
    self.t:cooldown(attack_speeds['slow'], self:in_range(), function ()
      self.target.beingHealed = true
      self.target:removeHealFlag(self.castTime)
      self:castAnimation()
    end, nil, nil, 'cast')

  elseif self.character == 'bard' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium'])
    self.t:cooldown(attack_speeds['buff'], function() return true end, function() 
      local targets = self:get_objects_in_shape(self.attack_sensor, main.current.friendlies)
      for i, t in ipairs(targets) do
        t:add_buff(Create_buff_dmg(2))
      end
    end, nil, nil, 'buff')
  elseif self.character == 'druid' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium'])
    self.t:cooldown(attack_speeds['slow'], self:in_range(), function()
      self:castAnimation()
    end, nil, nil, 'cast')

  end
end

function Troop:hit(damage, from, damageType)
  if self.bubbled then return end
  if self.dead then return end
  if self.magician_invulnerable then return end

  --scale hit effect to damage
  --no damage won't grow model, up to max effect at 0.5x max hp
  local hitStrength = (damage * 1.0) / self.max_hp
  hitStrength = math.min(hitStrength, 0.5)
  hitStrength = math.remap(hitStrength, 0, 0.5, 0, 1)
  self.hfx:use('hit', 0.25 * hitStrength, 200, 10)
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
  
  --on hit callbacks
  if from and from.onHitCallbacks then
    from:onHitCallbacks(self, actual_damage, damageType)
  end
  self:onGotHitCallbacks(from, actual_damage, damageType)

  camera:shake(2, 0.5)

  if self.hp > 0 then
    _G[random:table{'player_hit1', 'player_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  else
    hit4:play{pitch = random:float(0.95, 1.05), volume = 0.5}
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

  self.state_change_functions['death']()
  self.death_function()
end

function Troop:on_collision_enter(other, contact)
  local x, y = contact:getPositions()

  if other:is(Wall) then
      self:bounce(contact:getNormal())
      local r = random:float(0.9, 1.1)
      player_hit_wall1:play{pitch = r, volume = 0.1}
      pop1:play{pitch = r, volume = 0.2}
  elseif other.class == 'boss' then
    --move away from boss
    -- self:push(50, self:angle_to_object(other))

  elseif table.any(main.current.friendlies, function(v) return other:is(v) end) then
    --self:set_position()
    --other:push(random:float(25, 35)*(self.knockback_m or 1), self:angle_to_object(other))
  end
end

function Troop:shootAnimation(angle)
  self.startedCastingAt = love.timer.getTime()
  local castTime = self.castTime
  local backswing = self.backswing
  self.casting = true
  self.state = unit_states['frozen']
  self.t:after(castTime, function() 
    self.casting = false
    self.state = unit_states['stopped']
    self:shoot(angle)
    self.t:after(backswing, function() 
      if self.state == unit_states['stopped'] then
        self.state = unit_states['normal']
      end
    end, 'castAnimationEnd')
  end, 'castAnimation')
end

function Troop:castAnimation()
    self.startedCastingAt = love.timer.getTime()
    local castTime = self.castTime
    local backswing = self.backswing
    self.casting = true
    self.state = unit_states['frozen']
    self.t:after(castTime, function() 
      self.casting = false
      if self.state == unit_states['frozen'] then
        self.state = unit_states['stopped']
      end
      self:setup_cast()
      self.t:after(backswing, function() 
        if self.state == unit_states['stopped'] then
          self.state = unit_states['normal']
        end
      end, 'castAnimationEnd')
    end, 'castAnimation')
end

function Troop:setup_cast()
  if not self then return end
  if self.target and not self.target.dead then
    if self.character == 'wizard' then
      frost1:play{pitch = random:float(0.8, 1.2), volume = 0.4}
      self.dot_area = DotArea{group = main.current.effects, x = self.target.x, y = self.target.y, rs = 24,
      character = self.character, color = self.color, dmg = 5, level = self.level, parent = self, duration = 2}
    elseif self.character == 'shaman' then
      ChainLightning{group = main.current.main, target = self.target, rs = 50, dmg = self.dmg, color = self.color, parent = self, level = self.level}
    elseif self.character == 'cleric' then
      heal1:play({pitch = random:float(0.9,1.1), volume = 0.3})
      self.target:heal(30)
      LightningLine{group = main.current.effects, duration = 0.2, src = self, dst = self.target, color = green_transparent_weak}
    elseif self.character == 'necromancer' then
      if not self.target.dug_up and self.summons < 3 then
        critter3:play({pitch = random:float(0.8,1.2), volume = 0.5})
        self.summons = self.summons + 1
        Critter{group = main.current.main, x = self.target.x, y = self.target.y, color = white[0], r = random:float(0, 2*math.pi), v = 10, parent = self}
        self.target:kill()
        self.target = nil
      end
    elseif self.character == 'paladin' then
      buff1:play({pitch = random:float(0.8,1.2), volume = 0.5})
        self.target:bubble(2)
        LightningLine{group = main.current.effects, duration = 0.2, src = self, dst = self.target, color = yellow_transparent_weak}
    elseif self.character == 'priest' then
      buff1:play({pitch = random:float(0.8,1.2), volume = 0.5})
        self.target:shield(30, 3)
        LightningLine{group = main.current.effects, duration = 0.2, src = self, dst = self.target, color = white_transparent_weak}
    elseif self.character == 'druid' then
      buff1:play({pitch = random:float(0.8, 1.2), volume = 0.7})
      self.target:add_buff(Create_buff_druid_hot(5))
      LightningLine{group = main.current.effects, duration = 0.2, src = self, dst = self.target, color = green_transparent_weak}
    end
  end
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

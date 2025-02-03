
enemy_to_class = {}

Enemy = Unit:extend()
Enemy:implement(GameObject)
Enemy:implement(Physics)
function Enemy:init(args)
  self:init_game_object(args)

  self.state = 'normal'
  self:setExtraFunctions()
  
  self.init_enemy(self)
  self:init_unit()
  self:init_hitbox_points()

  self:calculate_stats(true)

  self.movementStyle = self.movementStyle or MOVEMENT_TYPE_SEEK

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

--set castcooldown and self.base_castcooldown in the enemy file (init)
function Enemy:update(dt)
    self:update_game_object(dt)
    self:update_cast_cooldown(dt)

    self:onTickCallbacks(dt)
    self:update_buffs(dt)

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
    if self.state == unit_states['normal'] then
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
    if self.state == unit_states['normal'] then
      if self.movementStyle == MOVEMENT_TYPE_SEEK then
        self:update_move_seek()
      elseif self.movementStyle == MOVEMENT_TYPE_RANDOM then
        self:update_move_random()
      else
        --pass, add flee later
      end
    elseif self.state == unit_states['frozen'] or unit_states['channeling'] then
      self:set_velocity(0,0)
    end

    self.r = self:get_angle()
  
  
    self.attack_sensor:move_to(self.x, self.y)
    self.aggro_sensor:move_to(self.x, self.y)
  
    if self.area_sensor then self.area_sensor:move_to(self.x, self.y) end
end

function Enemy:update_target_seek()
  if not self:in_range()() then
    self.target = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
  end
  if self.target and self.target.dead then self.target = nil end
  if self.target then
    self:rotate_towards_object(self.target, 0.5)
  end
end

function Enemy:update_move_seek()
  if self:in_range()() then
    -- dont need to move
  elseif self.target then
  --can't change speed?
    self:seek_point(self.target.x, self.target.y, SEEK_DECELERATION, SEEK_WEIGHT)
    -- self:rotate_towards_velocity(0.5)
  else
    -- dont need to move
  end
end

function Enemy:update_target_random()
  if not self:in_range()() then
    self.target = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
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
end

function Enemy:draw()
  self:draw_targeted()
  self:draw_buffs()
  self.draw_enemy(self)
  self:draw_launching()
  self:draw_channeling()
  self:draw_cast_timer()
end

function Enemy:on_collision_enter(other, contact)
    local x, y = contact:getPositions()
    
    if other:is(Wall) then
        self.hfx:use('hit', 0.15, 200, 10, 0.1)
        self:bounce(contact:getNormal())
    
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

function Enemy:hit(damage, from, damageType)
    if self.invulnerable then return end
    if self.dead then return end
    if self.isBoss then
      self.hfx:use('hit', 0.005, 200, 20)
    else
      --scale hit effect to damage
      --no damage won't grow model, up to max effect at 0.5x max hp
      local hitStrength = (damage * 1.0) / self.max_hp
      hitStrength = math.min(hitStrength, 0.5)
      hitStrength = math.remap(hitStrength, 0, 0.5, 0, 1)
      self.hfx:use('hit', 0.25 * hitStrength, 200, 10)
    end
    if self.push_invulnerable then return end
    self:show_hp()
  
    local actual_damage = math.max(self:calculate_damage(damage)*(self.stun_dmg_m or 1), 0)
    self:show_damage_number(actual_damage, damageType)

    self.hp = self.hp - actual_damage
    if self.hp > self.max_hp then self.hp = self.max_hp end
    main.current.damage_dealt = main.current.damage_dealt + actual_damage
  
    --callbacks
    if from and from.onHitCallbacks then
      from:onHitCallbacks(self, actual_damage, damageType)
    end
    self:onGotHitCallbacks(from, actual_damage, damageType)

    if self.hp <= 0 then
      --on death callbacks
      if from and from.onKillCallbacks then
        from:onKillCallbacks(self)
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

function Enemy:push(f, r, push_invulnerable)
    local n = 1
    if self.tank then n = 0.7 end
    if self.boss then n = 0.2 end
    if self.level % 25 == 0 and self.boss then n = 0.7 end
    self.push_invulnerable = push_invulnerable
    self.push_force = n*f
    self.being_pushed = true
    self.steering_enabled = false
    self:apply_impulse(n*f*math.cos(r), n*f*math.sin(r))
    self:apply_angular_impulse(random:table{random:float(-12*math.pi, -4*math.pi), random:float(4*math.pi, 12*math.pi)})
    self:set_damping(1.5*(1/n))
    self:set_angular_damping(1.5*(1/n))
end

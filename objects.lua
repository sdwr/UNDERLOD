-- ===================================================================
-- NEW Animated Spawn Circle Class
-- Draws a circle outline that flashes twice before disappearing.
-- ===================================================================
AnimatedSpawnCircle = Object:extend()
AnimatedSpawnCircle:implement(GameObject)

function AnimatedSpawnCircle:init(args)
    self:init_game_object(args)
    self.radius = 0
    
    -- Calculate size based on enemy type if provided
    if args.enemy_type and enemy_type_to_size and enemy_size_to_xy then
        local size_category = enemy_type_to_size[args.enemy_type]
        if size_category and enemy_size_to_xy[size_category] then
            local size_xy = enemy_size_to_xy[size_category]
            -- Calculate the actual size the enemy will be (use the larger dimension)
            local enemy_size = math.max(size_xy.x, size_xy.y)
            -- Make the spawn circle proportional to the enemy size
            self.radius = math.max(6, enemy_size / 2)
        else
            self.radius = 6 -- Default fallback
        end
    else
        self.radius = 6 -- Default size
    end

    self.exclamation_point_size = self.radius * 0.5
    self.exclamation_point_scale_x = (self.exclamation_point_size / EXCLAMATION_POINT_W) * EXCLAMATION_POINT_SCALE
    self.exclamation_point_scale_y = (self.exclamation_point_size / EXCLAMATION_POINT_H) * EXCLAMATION_POINT_SCALE
    
    self.outline_color = red[0]:clone()
    self.fill_color = red[0]:clone()

    self.line_width = 2
    local duration = args.duration or 2
    local expected_spawn_time = args.expected_spawn_time or 2

    -- ===================================================================
    -- Flashing Animation Logic
    -- ===================================================================
    self.visible = true -- Start visible
    self.is_flashing = false -- Track if we're in flashing state

    local flash_start_time = math.max(0, expected_spawn_time - 1)
    local flash_interval = 0.5 

    -- Schedule when to start flashing
    self.t:after(flash_start_time, function() 
        self.is_flashing = true
        self:start_flashing()
    end)

    -- Schedule the object to be destroyed at the end of its duration
    self.t:after(duration, function()
        self:die()
    end)
end

function AnimatedSpawnCircle:update(dt)
    self:update_game_object(dt)
end

function AnimatedSpawnCircle:start_flashing()
    -- Only start flashing if we're not already dead
    if self.dead then return end
    
    -- Toggle visibility every 0.2 seconds
    self.t:every(0.2, function()
        if not self.dead then
            self.visible = not self.visible
        end
    end)
end

function AnimatedSpawnCircle:draw()
    -- Only draw the object if it's currently visible
    if not self.visible then return end

    graphics.circle(self.x, self.y, self.radius, self.fill_color, self.line_width)
    
    exclamation_point_small:draw(self.x, self.y, 0, self.exclamation_point_scale_x, self.exclamation_point_scale_y, 1, 1)
end

function AnimatedSpawnCircle:die()
    self.dead = true
end


WallKnife = Object:extend()
WallKnife:implement(GameObject)
WallKnife:implement(Physics)
function WallKnife:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(10, 4, 'dynamic', 'projectile')
  self.hfx:add('hit', 1)
  self.hfx:use('hit', 0.25)
  self.t:tween({0.8, 1.6}, self, {v = 0}, math.linear, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)

  self.vr = self.r
  self.dvr = random:table{random:float(-8*math.pi, -4*math.pi), random:float(4*math.pi, 8*math.pi)}
end


function WallKnife:update(dt)
  self:update_game_object(dt)

  self:set_angle(self.r)
  self:move_along_angle(self.v, self.r)
  self.vr = self.vr + self.dvr*dt
end


function WallKnife:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.vr, self.hfx.hit.x, self.hfx.hit.x)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end




WallArrow = Object:extend()
WallArrow:implement(GameObject)
function WallArrow:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, 10, 4)
  self.hfx:add('hit', 1)
  self.hfx:use('hit', 0.25)
  self.t:after({0.8, 2}, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end


function WallArrow:update(dt)
  self:update_game_object(dt)
end


function WallArrow:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end





Unit = Object:extend()
function Unit:init_unit()
  self.level = self.level or 1

  self:config_physics_object()

  --also set in child classes
  self:reset_castcooldown(self.castcooldown or 0)

  self.target = nil
  self.assigned_target = nil
  self.buffs = {}
  self.toggles = {}
  self.hfx:add('hit', 1)
  self.hfx:add('shoot', 1)
  self.hp_bar = HPBar{group = main.current.effects, parent = self, isBoss = self.isBoss}
  self.effect_bar = EffectBar{group = main.current.effects, parent = self}

  --chill system
  self.freeze_gauge = 0
  
  -- Combat tracking
  self.total_damage_dealt = 0
  self.kills = 0
  self.time_alive = 0
  
  Helper.Unit:set_state(self, unit_states['idle'])
end

function Unit:config_physics_object()
  
  if self.class == 'boss' then

    self:set_damping(BOSS_DAMPING)
    self:set_restitution(BOSS_RESTITUTION)
    self:set_friction(BOSS_FRICTION)

    self:set_mass(BOSS_MASS)

    --heigan had 1000, stompy had 10000, dragon had default
    self:set_as_steerable(MAX_V, MAX_BOSS_FORCE, 2*math.pi, 2)

  elseif self.class == 'miniboss' then
    --ignore for now
  elseif self.class == 'special_enemy' then

    self:set_damping(SPECIAL_ENEMY_DAMPING)
    self:set_restitution(SPECIAL_ENEMY_RESTITUTION)
    self:set_friction(ENEMY_FRICTION)

    self:set_mass(SPECIAL_ENEMY_MASS)

    self:set_as_steerable(MAX_V, MAX_ENEMY_FORCE, 4*math.pi, 4)

  elseif self.class == 'regular_enemy' then
    
    self:set_damping(REGULAR_ENEMY_DAMPING)
    self:set_restitution(REGULAR_ENEMY_RESTITUTION)
    self:set_friction(ENEMY_FRICTION)

    self:set_mass(REGULAR_ENEMY_MASS)

    self:set_as_steerable(MAX_V, MAX_ENEMY_FORCE, 4*math.pi, 4)
  
  elseif self.class == 'enemy_critter' then
    self:set_damping(CRITTER_DAMPING)
    self:set_restitution(CRITTER_RESTITUTION)
    self:set_friction(ENEMY_FRICTION)

    self:set_mass(CRITTER_MASS)
    self:set_as_steerable(MAX_V, MAX_ENEMY_FORCE, 4*math.pi, 4)
  elseif self.class =='critter' then
    self:set_damping(CRITTER_DAMPING)
    self:set_restitution(CRITTER_RESTITUTION)
    self:set_friction(ENEMY_FRICTION)

    self:set_mass(CRITTER_MASS)
    self:set_as_steerable(MAX_V, MAX_ENEMY_FORCE, 4*math.pi, 4)

  elseif self.class == 'troop' then
    if self.ghost == true then
      self:set_as_rectangle(self.size, self.size,'dynamic', 'ghost')
    else
      self:set_as_rectangle(self.size, self.size,'dynamic', 'troop')
    end

    self:set_damping(TROOP_DAMPING)
    self:set_restitution(TROOP_RESITUTION)
    self:set_friction(TROOP_FRICTION)

    self:set_mass(TROOP_MASS)

    self:set_as_steerable(MAX_V, MAX_TROOP_FORCE, 4*math.pi, 4)

  end
  
end

function Unit:init_hitbox_points()
  
  if self.boss_name == 'stompy' then
    local step = (self.shape.w - 4) / 5
    for x = -self.shape.w/2 + 2, self.shape.w/2 - 2, step do
      for y = -self.shape.h/2 + 2, self.shape.h/2 - 2, step do
        if x == -self.shape.w/2 + 2 and y == -self.shape.h/2 + 2 then
          Helper.Unit:add_point(self, x + 2, y + 2)
        elseif x == -self.shape.w/2 + 2 and near(y, self.shape.h/2 - 2, 0.01) then
          Helper.Unit:add_point(self, x + 2, y - 2)
        elseif near(x, self.shape.w/2 - 2, 0.01) and y == -self.shape.h/2 + 2 then
          Helper.Unit:add_point(self, x - 2, y + 2)
        elseif near(x, self.shape.w/2 - 2, 0.01) and near(y, self.shape.h/2 - 2, 0.01) then
          Helper.Unit:add_point(self, x - 2, y - 2)
        else
          Helper.Unit:add_point(self, x, y)
        end
      end
    end
  end

  --if enemy is dragon
  if self.boss_name == 'dragon' then
    self.hitbox_points_can_rotate = true
    Helper.Unit:add_point(self, 32, 0)
    Helper.Unit:add_point(self, -15, 27)
    Helper.Unit:add_point(self, -15, -27)
    Helper.Unit:add_point(self, 23, 5)
    Helper.Unit:add_point(self, 23, -5)
    Helper.Unit:add_point(self, 16, 9)
    Helper.Unit:add_point(self, 16, -9)
    Helper.Unit:add_point(self, 10, 12)
    Helper.Unit:add_point(self, 10, -12)
    Helper.Unit:add_point(self, -9, 23)
    Helper.Unit:add_point(self, -9, -23)
    Helper.Unit:add_point(self, -3, 19)
    Helper.Unit:add_point(self, -3, -19)
    Helper.Unit:add_point(self, 3, 16)
    Helper.Unit:add_point(self, 3, -16)
    Helper.Unit:add_point(self, -16, 21)
    Helper.Unit:add_point(self, -16, -21)
    Helper.Unit:add_point(self, -16, 14)
    Helper.Unit:add_point(self, -16, -14)
    Helper.Unit:add_point(self, -16, 6)
    Helper.Unit:add_point(self, -16, -6)
    Helper.Unit:add_point(self, -16, 0)
    Helper.Unit:add_point(self, -9, 16)
    Helper.Unit:add_point(self, -9, -16)
    Helper.Unit:add_point(self, -9, 7)
    Helper.Unit:add_point(self, -9, -7)
    Helper.Unit:add_point(self, -9, 0)
    Helper.Unit:add_point(self, -2, 11)
    Helper.Unit:add_point(self, -2, -11)
    Helper.Unit:add_point(self, -2, 3)
    Helper.Unit:add_point(self, -2, -3)
    Helper.Unit:add_point(self, 5, 8)
    Helper.Unit:add_point(self, 5, -8)
    Helper.Unit:add_point(self, 5, -0)
    Helper.Unit:add_point(self, 10, 4)
    Helper.Unit:add_point(self, 10, -4)
    Helper.Unit:add_point(self, 18, -3)
    Helper.Unit:add_point(self, 18, 3)
    Helper.Unit:add_point(self, 25, 0)
  end
end

function Unit:update(dt)
  self:update_game_object(dt)
  if self.hp < self.max_hp or self.isBoss then
    self:show_hp()
  elseif not self.isBoss then
    self:hide_hp()
  end
  
  -- Track time alive
  if not self.dead then
    self.time_alive = self.time_alive + dt
  end

  if self.stun_cooldown and self.stun_cooldown > 0 then
    self.stun_cooldown = self.stun_cooldown - dt
  end
end

function Unit:bounce(nx, ny)
  local vx, vy = self:get_velocity()
  if nx == 0 then
    self:set_velocity(vx, -vy)
    self.r = 2*math.pi - self.r
  end
  if ny == 0 then
    self:set_velocity(-vx, vy)
    self.r = math.pi - self.r
  end
  return self.r
end

--self is enemy, other is player
function Unit:on_trigger_enter(other)
end

function Unit:on_trigger_exit(other)

end


function Unit:show_hp(n)
  if self.hp_bar then
    self.hp_bar.hidden = false
    self.hp_bar.color = red[0]
  end
end

function Unit:hide_hp()
  self.hp_bar.hidden = true
end

--have full data passed in instead of just type?
--keep track of how many damage numbers are on screen
--delete the oldest one when we hit the limit

function Unit:show_damage_number(dmg, damagetype)
  if state.show_damage_numbers == 'off' then return end
  if state.show_damage_numbers == 'enemies' and self.faction ~= 'enemy' then return end
  if state.show_damage_numbers == 'friendlies' and self.faction ~= 'friendly' then return end

  local color = DAMAGE_TYPE_TO_COLOR[damagetype] or white[0]
  local roundedDmg = math.floor(dmg)

  local data = {
    group = main.current.effects,
    color = color,
    x = self.x + random_offset(4),
    y = self.y + random_offset(4),
    rs = 6,
    lines = {{text =  '' .. roundedDmg, font = pixul_font }},
    damage = roundedDmg,
  }
  Helper.DamageNumbers.Add(data)
end

function Unit:heal(amount)
  self.hp = math.min(self.hp + amount, self.max_hp)
  self.hfx:use('hit', 0.25, 200, 10)
  --missing effect here
end


function Unit:show_heal(n)
  self.effect_bar.hidden = false
  self.effect_bar.color = green[0]
  self.t:after(n or 4, function() self.effect_bar.hidden = true end, 'effect_bar')
end


function Unit:show_infused(n)
  self.effect_bar.hidden = false
  self.effect_bar.color = blue[0]
  self.t:after(n or 4, function() self.effect_bar.hidden = true end, 'effect_bar')
end

function Unit:calculate_damage(dmg)
  if self.def >= 0 then dmg = dmg*(100/(100+self.def))
  else dmg = dmg*(2 - 100/(100+self.def)) end
  return dmg
end

--can only have 1 buff with the each name
--if a buff with the same name is added, the duration is updated
--but stats are not added together yet (will need for slow stacking etc.)

--add toggles for buffs that have a binary effect
--increment when a new buff is added, decrement when it is removed
--don't increment if the buff is already present and we are just updating the duration

--don't need to deep copy the buff, since a new proc is created each time
--will need to when the proc starts reapplying the buff?
function Unit:get_buff_names()
  local buff_names = {}
  for k, v in pairs(self.buffs) do
    table.insert(buff_names, k)
  end
  return buff_names
end

function Unit:has_buff(buffName)
  return self.buffs[buffName] ~= nil
end

function Unit:get_buff(buffName)
  return self.buffs[buffName]
end

function Unit:count_elemental_afflictions()
  if not self.buffs then return 0 end
  
  local count = 0
  for _, affliction_name in ipairs(elemental_affliction_buffs) do
    if self.buffs[affliction_name] then
      count = count + 1
    end
  end
  
  return count
end

function Unit:add_buff(buff)
  --copy the buff so we don't modify the original (procs are reusing the same buff data object)
  local buffCopy = {}
  for k, v in pairs(buff) do
    buffCopy[k] = v
  end

  local existing_buff = self.buffs[buffCopy.name]

  --overwrite duration and nextTick if the buff is already present
  if existing_buff then
    self.buffs[buffCopy.name].duration = math.max(existing_buff.duration, buffCopy.duration)
    if buffCopy.nextTick then
      self.buffs[buffCopy.name].nextTick = buffCopy.nextTick
    end
    if buffCopy.from then
      self.buffs[buffCopy.name].from = buffCopy.from
    end
  else
    if buffCopy.color then
      local color = buffCopy.color:clone()
      color.a = 0.6
      buffCopy.color = color
    end
    self.buffs[buffCopy.name] = buffCopy
    self:increment_buff_toggles(buffCopy)
  end
end

function Unit:remove_buff(buffName)
  local existing_buff = self.buffs[buffName]
  if existing_buff then
    self.buffs[buffName] = nil
  end
  if buffName == 'shield' then
    self:remove_shield()
  end
  if existing_buff then
    self:decrement_buff_toggles(existing_buff)
  end
end

function Unit:draw_buffs()
  local i = 0.5
  for _ , buff in pairs(self.buffs) do
    if buff.name == 'chill' and self:get_buff('freeze') then
      --dont draw chill if freeze is present
    elseif buff.color then
      graphics.circle(self.x, self.y, ((self.shape.w) / 2) + (i), buff.color, 1)
      i = i + 1
    end
  end
end

function Unit:draw_launching()
  -- if self.is_launching then
  --   graphics.circle(self.x, self.y, self.shape.w/2 + 2, orange_transparent)
  -- end
end

function Unit:draw_targeted()
  if self:has_buff('targeted') then
    graphics.circle(self.x, self.y, ((self.shape.w) / 2) + 3, yellow[0], 1)
  end
end

function Unit:draw_channeling()
  -- if self.state == unit_states['channeling'] then
  --   local bodySize = self.shape.rs or self.shape.w/2 or 5
  --   graphics.circle(self.x, self.y, bodySize, blue_transparent)
  -- end
end

function Unit:draw_status_effects()
  local color = nil
  if self.buffs['freeze'] then
    color = blue_transparent
  elseif self.buffs['stunned'] then
    color = black_transparent
  elseif self.buffs['burn'] then
    color = red_transparent
  end

  if color then
    graphics.circle(self.x, self.y, self.shape.w/2 + 2, color)
  end
end

function Unit:draw_knockback()
  -- Knockback is now handled as damage impulse, no visual needed
end

function Unit:draw_cast_timer()
  if self.state == unit_states['casting'] then
    if self.castObject and self.castObject.hide_cast_timer then return end

    local currentTime = love.timer.getTime()
    local time = currentTime - self.last_attack_started
    local pct = 0
    if self.castObject then
      pct = self.castObject:get_cast_percentage()
    else
      local pct = time / self.castTime
    end
    local bodySize = self.shape.rs or self.shape.w/2 or 5
    local rs = pct * bodySize
    if pct < 1 then
      graphics.circle(self.x, self.y, rs, white_transparent)
    end
  end
end

function Unit:draw_debug_info()
  if self.target_location then
    graphics.circle(self.target_location.x, self.target_location.y, 5, green[0])
  end
  if self.target and self.target.x and self.target.y then
    graphics.circle(self.target.x, self.target.y, 10, red[0], 2)
  end
  if self.attack_sensor then
    graphics.circle(self.attack_sensor.x, self.attack_sensor.y, self.attack_sensor.rs, yellow[0] ,1)
  end
  if self.aggro_sensor then
    graphics.circle(self.aggro_sensor.x, self.aggro_sensor.y, self.aggro_sensor.rs, blue[0], 2)
  end
end

--should move this somewhere, maybe to the proc class
-- dont want to have a bunch of if statements in here
-- with special logic for each buff
function Unit:update_buffs(dt)
  for k, v in pairs(self.buffs) do
    --on buff start
    if k == 'stunned' then
      Helper.Unit:set_state(self, unit_states['stunned'])
    end
    if k == 'rooted' then
      Helper.Unit:set_state(self, unit_states['stopped'])
    end
    if k == 'freeze' then
      Helper.Unit:set_state(self, unit_states['stunned'])
    end
    if k == 'invulnerable' then
      self.invulnerable = true
    end

    --dec duration
    if v.duration then
      v.duration = v.duration - dt
    end

    -- In your buff update loop, where 'v' is the burn buff table
    if k == 'burn' then
      v.elapsed_time = v.elapsed_time + dt
      
      -- Check if it's time for a tick (e.g., every 1 second)
      if v.elapsed_time >= 1 then
          v.elapsed_time = v.elapsed_time - 1 -- Reset timer for the next tick

          -- Play a subtle sound for the tick
          
          -- 1. Calculate the damage and decay amount for this tick
          local damage_this_tick = v.total_damage * BURN_DPS_DECAY_RATE
          fire3:play{pitch = random:float(0.8, 1.2), volume = 0.15}
          
          -- 2. Deal the damage
          if damage_this_tick > 0 then
              -- Burn damage should not be attributed to anyone (environmental damage)
              self:hit(damage_this_tick, nil, DAMAGE_TYPE_BURN, false, true)
          end

          v.total_damage = v.total_damage - damage_this_tick

          
          self:try_trigger_burn_explosion()
      end
    end

    if k == 'chill' then
      self:freeze_gauge_fill(CHILL_FREEZE_GAUGE_FILL_PER_SECOND * dt)
    end

    --on buff end
    if v.duration and v.duration < 0 then
      if k == 'bash_cd' then
        self.canBash = true
      elseif k == 'stunned' then
        if self.state == unit_states['stunned'] then
          Helper.Unit:set_state(self, unit_states['idle'])
        end
      elseif k == 'rooted' then
        if self.state == unit_states['stopped'] then
          Helper.Unit:set_state(self, unit_states['idle'])
        end
      elseif k == 'freeze' then
        self:on_freeze_expired()
        if self.state == unit_states['stunned'] then
          Helper.Unit:set_state(self, unit_states['idle'])
        end
      elseif k == 'invulnerable' then
        self.invulnerable = false
      elseif k == 'shield' then
        self:remove_shield()
      elseif k == 'curse' then
        self:remove_curse()
      end
      --this is where buff stacks tick down
      if v.stacks and v.stacks > 1 and not v.stacks_expire_together then
        v.stacks = v.stacks - 1
        v.duration = v.maxDuration
      else
        self.buffs[k] = nil
      end
    end
  end
end

function Unit:has_toggle(name)
  return self.toggles[name] and self.toggles[name] > 0
end

function Unit:increment_buff_toggles(buff)
  if buff.toggles then
    for k, v in pairs(buff.toggles) do
      self.toggles[k] = (self.toggles[k] or 0) + v
    end
  end
end

function Unit:decrement_buff_toggles(buff)
  if buff.toggles then
    for k, v in pairs(buff.toggles) do
      self.toggles[k] = self.toggles[k] - v
    end
  end
end


function Unit:init_stats()

  _set_unit_base_stats(self)

  _set_unit_item_config(self)
end

--different from calculate_stats :( 
--used for the character tooltip in buy screen
function Unit:get_item_stats_for_display()
  -- Step A: Aggregate all stats into a temporary hash table for quick summation.
  local aggregated_stats = {}
  for i = 1, UNIT_LEVEL_TO_NUMBER_OF_ITEMS[self.level] do
      local item = self.items[i]
      if item and item.stats then
          for stat, amt in pairs(item.stats) do
              -- For V2 items, amt is the incremental value (e.g., 2 for +2 move)
              -- For V1 items, amt is the raw value (e.g., 0.15 for 15% move)
              -- The display layer will handle the formatting difference
              aggregated_stats[stat] = (aggregated_stats[stat] or 0) + amt
          end
      end
  end

  return aggregated_stats
end

function Unit:calculate_stats(first_run)
  local level = self.level or 1
  local hpMod = 1 + ((level - 1) / 2)
  local dmgMod = 1 + ((level - 1) / 2)
  local spdMod = 1

  --set base stats to default values
  --and add procs (+buffs) from items
  if(first_run) then
    self:init_stats()
  end

  self.base_aspd_m = 1
  self.base_area_dmg_m = 1
  self.base_area_size_m = 1
  self.base_def = 25
  self.class_hp_a = 0
  self.class_dmg_a = 0
  self.class_def_a = 0
  self.class_mvspd_a = 0
  self.class_hp_m = 1
  self.class_dmg_m = 1
  if self.type == 'laser' then
    self.class_dmg_m = 2
  end
  self.class_aspd_m = 1
  self.class_area_dmg_m = 1
  self.class_area_size_m = 1
  self.class_def_m = 1
  self.class_mvspd_m = 1
  self.buff_hp_a = 0
  self.buff_dmg_a = 0
  self.buff_def_a = 0
  self.buff_mvspd_a = 0
  self.buff_hp_m = 1
  self.buff_dmg_m = 1
  self.buff_aspd_m = 1
  self.buff_area_dmg_m = 1
  self.buff_area_size_m = 1
  self.buff_def_m = 1
  self.buff_mvspd_m = 1
  self.slow_mvspd_m = 1
  self.buff_range_a = 0
  self.buff_range_m = 1
  self.buff_cdr_m = 1

  self.buff_repeat_attack_chance = 0
  self.crit_chance = 0
  self.crit_mult = BASE_CRIT_MULT
  self.stun_chance = 0
  self.knockback_resistance = 0
  self.cooldown_reduction = 0
  self.slow_per_element = 0

  self.eledmg_m = 1

  self.buff_fire_damage_a = 0
  self.buff_lightning_damage_a = 0
  self.buff_cold_damage_a = 0
  self.buff_fire_damage_m = 1
  self.buff_lightning_damage_m = 1
  self.buff_cold_damage_m = 1

  self.vamp = 0
  self.elevamp = 0

  self.status_resist = 0
  if self.class == 'miniboss' then
    self.status_resist = 0.5
  elseif self.class == 'boss' then
    self.status_resist = 0.8
  end

  self.knockback_resistance = 0
  if self.class == 'special_enemy' then
    self.knockback_resistance = 0.5
  elseif self.class == 'miniboss' then
    self.knockback_resistance = 0.8
  elseif self.class == 'boss' then
    self.knockback_resistance = 0.9
  end

  if self.class == 'regular_enemy' then
    local enemy_stats = enemy_type_to_stats[self.type]
    if enemy_stats then
      for stat, amt in pairs(enemy_stats) do
        if stat == buff_types['dmg'] then
          self.class_dmg_m = amt
        elseif stat == buff_types['flat_def'] then
          self.class_def_a = amt
        elseif stat == buff_types['percent_def'] then
          self.class_def_m = amt
        elseif stat == buff_types['mvspd'] then
          self.class_mvspd_m = amt
        elseif stat == buff_types['aspd'] then
          self.class_aspd_m = amt
        elseif stat == buff_types['area_dmg'] then
          self.class_area_dmg_m = amt
        elseif stat == buff_types['area_size'] then
          self.class_area_size_m = amt
        elseif stat == buff_types['hp'] then
          self.class_hp_m = amt
        elseif stat == buff_types['status_resist'] then
          self.status_resist = amt
        end
      end
    end
  end

  -- Process buffs, items, and perks using unified stat addition
  self:add_stats(self:process_buffs_to_stats())
  self:add_stats(self:process_items_to_stats())
  self:add_stats(self:process_set_bonuses_to_stats())
  self:add_stats(self:preprocess_perks_to_stats())



  local unit_stat_mult = unit_stat_multipliers[self.character] or unit_stat_multipliers['none']

  self.class_hp_m = self.class_hp_m*unit_stat_mult.hp
  self.max_hp = (self.base_hp + self.class_hp_a + self.buff_hp_a)*self.class_hp_m*self.buff_hp_m
  --need to set hp after buffs
  if first_run then self.hp = self.max_hp end

  self.class_dmg_m = self.class_dmg_m*unit_stat_mult.dmg
  self.dmg = (self.base_dmg + self.class_dmg_a + self.buff_dmg_a)*self.class_dmg_m*self.buff_dmg_m
  self.dmg = self.dmg * Helper.Unit:get_survivor_damage_boost(self)

  self.class_def_m = self.class_def_m*unit_stat_mult.def
  self.buff_def_m = math.max(self.buff_def_m, 0.2)
  local flat_def = self.base_def + self.class_def_a + self.buff_def_a
  flat_def = math.max(flat_def, 0)

  self.def = flat_def*self.class_def_m*self.buff_def_m

  self.aspd_m = 1/(self.base_aspd_m*self.buff_aspd_m)

  self.repeat_attack_chance = self.buff_repeat_attack_chance

  -- Stats_Max_Aspd(self.buff_aspd_m)
  -- if self.buff_hp_m == 1 then
  --   Stats_Max_Dmg_Without_Hp(self.buff_dmg_m or 0)
  -- end
  if self.baseCooldown then
    self.cooldownTime = self.baseCooldown * self.aspd_m
  end
  if self.baseCast then
    self.castTime = self.baseCast * self.aspd_m
  end

  self.attack_range = ((self.base_attack_range or 0) + self.buff_range_a) * self.buff_range_m

  self.area_size_m = self.base_area_size_m*self.buff_area_size_m

  self.class_mvspd_m = self.class_mvspd_m*unit_stat_mult.mvspd

  local elemental_slow_m = 1
  local num_elemental_afflictions = self:count_elemental_afflictions()
  if self.slow_per_element > 0 and num_elemental_afflictions > 0 then
    elemental_slow_m = 1 - (self.slow_per_element*num_elemental_afflictions)
  end

  self.max_move_v = (self.base_mvspd + self.class_mvspd_a + self.buff_mvspd_a)*self.class_mvspd_m*self.buff_mvspd_m*self.slow_mvspd_m*elemental_slow_m
  self.max_v = self.max_move_v * 50

  -- Calculate final elemental damage stats
  self.fire_damage = self.buff_fire_damage_a * self.buff_fire_damage_m
  self.lightning_damage = self.buff_lightning_damage_a * self.buff_lightning_damage_m
  self.cold_damage = self.buff_cold_damage_a * self.buff_cold_damage_m

  self.crit_chance = math.clamp(self.crit_chance, 0, 1)
  self.stun_chance = math.clamp(self.stun_chance, 0, 1)
  self.knockback_resistance = math.clamp(self.knockback_resistance, -1, 0.8)
  self.cooldown_reduction = math.clamp(self.cooldown_reduction, 0, 0.8)
end  

function Unit:onTickCallbacks(dt)
  if not main.current:is(WorldManager) then return end

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_TICK]) do
    proc:onTick(dt, self)
  end

  for k, proc in ipairs(self.onTickProcs) do
    proc:onTick(dt, self)
  end
end

--warning, target can be either a unit or a coordinate
function Unit:onAttackCallbacks(target)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_ATTACK]) do
    proc:onAttack(target, self)
  end

  for k, proc in ipairs(self.onAttackProcs) do
    proc:onAttack(target, self)
  end

  -- Handle elemental damage on attack
  self:handle_elemental_damage_on_attack(target)
end

function Unit:handle_elemental_damage_on_attack(target)
  -- Only apply elemental damage if target is a valid unit
  if not target or not target.hit then return end
  
  -- Fire damage
  if self.fire_damage and self.fire_damage > 0 then
    local fire_damage = self.dmg * self.fire_damage
    target:hit(fire_damage, self, DAMAGE_TYPE_FIRE, false, true)
  end
  
  -- Lightning damage
  if self.lightning_damage and self.lightning_damage > 0 then
    local lightning_damage = self.dmg * self.lightning_damage
    target:hit(lightning_damage, self, DAMAGE_TYPE_LIGHTNING, false, true)
  end
  
  -- Cold damage
  if self.cold_damage and self.cold_damage > 0 then
    local cold_damage = self.dmg * self.cold_damage
    target:hit(cold_damage, self, DAMAGE_TYPE_COLD, false, true)
  end
end

function Unit:onHitCallbacks(target, damage, damageType)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_HIT]) do
    proc.globalUnit = self
    proc:onHit(target, damage, damageType)
  end

  for k, proc in ipairs(self.onHitProcs) do
    proc:onHit(target, damage, damageType)
  end
end

function Unit:onPrimaryHitCallbacks(target, damage, damageType)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_PRIMARY_HIT]) do
    proc.globalUnit = self
    proc:onPrimaryHit(target, damage, damageType)
  end

  for k, proc in ipairs(self.onPrimaryHitProcs) do
    proc:onPrimaryHit(target, damage, damageType)
  end
end

function Unit:onGotHitCallbacks(from, damage)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_GOT_HIT]) do
    proc.globalUnit = self
    proc:onGotHit(from, damage)
  end
  for k, proc in ipairs(self.onGotHitProcs) do
    proc:onGotHit(from, damage)
  end
end

function Unit:onKillCallbacks(target, overkill)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_KILL]) do
    proc.globalUnit = self
    proc:onKill(target, overkill)
  end
  for k, proc in ipairs(self.onKillProcs) do
    proc:onKill(target, overkill)
  end
end

function Unit:onDeathCallbacks(from)
  
  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_DEATH]) do
    proc.globalUnit = self
    proc:onDeath(from)
  end

  
  for k, proc in ipairs(self.onDeathProcs) do
    proc:onDeath(from)
  end

  --some global procs here, could maybe be moved into onDeathProcs
  self:burn_explode_or_fizzle()

end

function Unit:onMoveCallbacks(distance)
  for k, proc in ipairs(self.onMoveProcs) do
    proc:onMove(distance)
  end
end

function Unit:onRoundStartCallbacks()
  for k, proc in ipairs(self.onRoundStartProcs) do
    proc:onRoundStart()
  end
end

--seems like body.v does not change from nil
function Unit:isMoving(dt)
  local diff = math.distance(self.x, self.y, self.last_x or self.x, self.last_y or self.y)
  self.last_x = self.x
  self.last_y = self.y
  return diff > 0.1
end

--BURN SYSTEM

function Unit:burn(damage, from)
  local existing_buff = self.buffs['burn']
  
  if existing_buff then
    -- Add damage to existing burn buff
    existing_buff.from = from
    existing_buff.total_damage = existing_buff.total_damage + damage
    existing_buff.peak_damage = math.max(existing_buff.peak_damage, existing_buff.total_damage)


  else
    -- Create new burn buff
    local burnBuff = {
      name = 'burn',
      from = from,
      total_damage = damage, 
      peak_damage = damage,
      nextTick = 1.0, -- Tick every second
      elapsed_time = 0,
    }
    self:add_buff(burnBuff)

    for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_BURN]) do
      proc.globalUnit = self
      proc:onBurn(from, self)
    end
    if from and from.onBurnProcs then
      for k, proc in ipairs(from.onBurnProcs) do
        proc:onBurn(from, self)
      end
    end
  end
end

function Unit:try_trigger_burn_explosion()
  local burn_buff = self.buffs['burn']
  if not burn_buff then return end

  -- 4. Check the end conditions
  local cancel_threshold = self.max_hp * BURN_CANCEL_IF_DPS_BELOW_PERCENT_OF_HP * BURN_DPS_DECAY_RATE

  local damage_required_to_explode_instantly = self.max_hp * BURN_THRESHOLD_FOR_INSTANT_EXPLOSION_PERCENT_OF_HP
  
  if burn_buff.total_damage >= damage_required_to_explode_instantly then
    self:burn_explode_or_fizzle()
    return
  elseif burn_buff.total_damage < cancel_threshold then
      -- The burn has fizzled. Now we decide if it explodes or just disappears.
      local min_explosion_threshold = self.max_hp * BURN_MIN_EXPLOSION_THRESHOLD_PERCENT_OF_HP
      
      if burn_buff.peak_damage >= min_explosion_threshold then
          -- Condition Met: Fizzle with Explosion
          -- The burn was powerful enough at its peak to warrant a final boom.
          self:burn_explode_or_fizzle()
      end
      -- else: Condition Met: Fizzle without Explosion.
      -- The peak was never high enough, so it just disappears silently.
      
      -- In both fizzle cases, we remove the buff.
      self:remove_buff('burn')
  end
end

function Unit:burn_explode_or_fizzle()
  local burn_buff = self.buffs['burn']
  if not burn_buff then return end

  if burn_buff.total_damage >= BURN_MIN_EXPLOSION_THRESHOLD_PERCENT_OF_HP 
  and Does_Static_Proc_Exist('burnexplode') then
    self:burn_explode()
  else
    self:remove_buff('burn')
  end
end

function Unit:burn_explode(from)
  -- Remove the burn buff
  if not self.buffs['burn'] then return end

  local peak_damage = self.buffs['burn'].peak_damage
  local from = self.buffs['burn'].from
  self:remove_buff('burn')
  
  -- Calculate explosion damage based on max HP
  local explosion_damage = peak_damage / 2

  local total_power = CALCULATE_BURN_EFFORT_FACTOR(peak_damage, self.max_hp) + CALCULATE_BURN_QUALITY_FACTOR(self.baseline_hp)

  local explosion_radius = BURN_EXPLOSION_BASE_RADIUS * (1 + total_power)
  local explosion_knockback = BURN_EXPLOSION_BASE_KNOCKBACK * (1 + total_power)
  local explosion_knockback_duration = BURN_EXPLOSION_BASE_KNOCKBACK_DURATION * (0.6 + total_power)
  
  local explosion_volume = 0.3 * (1 + total_power)

  Knockback_Area_Spell{
    group = main.current.effects,
    is_troop = true,
    unit = from,
    x = self.x,
    y = self.y,
    radius = explosion_radius,
    damage = explosion_damage,
    duration = 0.3,
    area_type = 'area',
    pick_shape = 'circle',
    color = red[0],
    knockback_force = explosion_knockback,
    knockback_duration = explosion_knockback_duration,
    damage_type = DAMAGE_TYPE_BURN,
  }
  
  -- Play fire explosion sound
  fire1:play{pitch = random:float(0.8, 1.2), volume = explosion_volume}
end

--SHOCK SYSTEM
function Unit:shock()
  if not Does_Static_Proc_Exist('shock') then
    return
  end

  local shockBuff = {name = 'shock', color = yellow[0], duration = SHOCK_DURATION, maxDuration = SHOCK_DURATION, stats = {buff_def_m = SHOCK_DEF_REDUCTION}}

  self:remove_buff('shock')
  self:add_buff(shockBuff)
end

--CHILL SYSTEM
function Unit:chill(damage, from)
  --add chill buff
  local chillBuff = {name = 'chill', color = blue[0], duration = CHILL_DURATION, maxDuration = CHILL_DURATION, stats = {mvspd = -1 * CHILL_SLOW_PERCENT}}
  self:remove_buff('chill')
  self:add_buff(chillBuff)

  --add freeze gauge from damage
  local damage_percent = damage / self.max_hp
  local freeze_gauge_fill_amount = damage_percent * FREEZE_GAUGE_GAINED_PER_DAMAGE_PERCENT

end

function Unit:freeze(from)
  freeze_sound:play{pitch = random:float(0.8, 1.2), volume = 1.1}
  local freezeBuff = {name = 'freeze', duration = FREEZE_DURATION, maxDuration = FREEZE_DURATION}
  self:add_buff(freezeBuff)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_FREEZE]) do
    proc.globalUnit = self
    proc:onFreeze(from, self)
  end
  if from and from.onFreezeProcs then
    for k, proc in ipairs(from.onFreezeProcs) do
      proc:onFreeze(from, self)
    end
  end
end

function Unit:freeze_gauge_fill(amount)
  local freeze_buff = self.buffs['freeze']
  local freeze_immunity_buff = self.buffs['freeze_immunity']
  if freeze_buff or freeze_immunity_buff then return end
  
  self.freeze_gauge = self.freeze_gauge + amount
  if self.freeze_gauge > FREEZE_GAUGE_MAX then
    self:freeze()
    self.freeze_gauge = 0
  end
end

function Unit:on_freeze_expired()
  self.freeze_gauge = 0
  local freeze_immunity_buff = {name = 'freeze_immunity', duration = FREEZE_IMMUNITY_DURATION, maxDuration = FREEZE_IMMUNITY_DURATION}
  self:add_buff(freeze_immunity_buff)
end

function Unit:remove_curse()
  local curse_buff = self.buffs['curse']
  if not curse_buff then return end
  if curse_buff.from and Has_Static_Proc(curse_buff.from, 'curseHeal') then
    --pick a random damaged target from the curse buff's team
    local target = curse_buff.from
    local team = curse_buff.from:get_team()
    if team then
      target = team:get_random_hurt_troop()
    end
    
    if target then
      --cast a heal line from the cursed unit to the curser
      ChainHeal{
        group = main.current.main,
        parent = self,
        target = curse_buff.from,
        range = 0,
        is_troop = curse_buff.from.is_troop,
        color = purple[0],
        max_chains = 1,
        heal_amount = curse_buff.damage_taken * CURSE_HEAL_PERCENT_OF_DAMAGE_TAKEN,
      }
    end
  end
  self:remove_buff('curse')
end

function Unit:isShielded()
  return self.shielded > 0
end

function Unit:remove_shield()
  self.shielded = 0
end

--keep the highest shield value, don't stack, don't refresh duration
function Unit:shield(amount, duration)
  if self.shielded > amount then return end
  
  local shieldBuff = {name = 'shield', duration = duration, maxDuration = duration, stats = {}}
  self:remove_buff('shield')
  self:add_buff(shieldBuff)
  self.shielded = amount
end

function Unit:redshield(duration)
  local redshieldBuff = {name = 'redshield', color = grey[0], duration = duration, maxDuration = duration,
    stacks = 1, stats = {def = 1}}
  local existing_buff = self.buffs['redshield']

  if existing_buff then
    redshieldBuff.stacks = math.min((existing_buff.stack or 1) + 1, MAX_STACKS_REDSHIELD)
  end
  self:remove_buff('redshield')
  self:add_buff(redshieldBuff)
end

function Unit:stun()
  if self:has_buff('stunned') then
    return
  end
  if self.stun_cooldown and self.stun_cooldown > 0 then
    return
  end

  local duration  = STUN_DURATION_BOSS

  if self.class == 'regular_enemy' then
    duration = STUN_DURATION_REGULAR_ENEMY
  elseif self.class == 'special_enemy' then
    duration = STUN_DURATION_SPECIAL_ENEMY
  elseif self.class == 'critter' then
    duration = STUN_DURATION_CRITTER
  elseif self.class == 'miniboss' then
    duration = STUN_DURATION_MINIBOSS
  elseif self.class == 'boss' then
    duration = STUN_DURATION_BOSS
  end

  player_hit_wall1:play{pitch = random:float(0.8, 1.2), volume = 1.2}
  local stunBuff = {name = 'stunned', duration = duration}
  self.stun_cooldown = STUN_COOLDOWN
  self:add_buff(stunBuff)
  self:interrupt_cast()
end

function Unit:root(duration)
  if self.class == 'boss' then
    return
  end
  local rootBuff = {name = 'rooted', color = green[0], duration = duration}
  self:add_buff(rootBuff)
end

--only keep the highest slow amount
function Unit:slow(amount, duration, from)
  local slowBuff = {name = 'slowed', color = blue[2], duration = duration, maxDuration = duration, stats = {mvspd = -1 * amount}}
  local existing_buff = self.buffs['slowed']

  if existing_buff and existing_buff.stats.mvspd > slowBuff.stats.mvspd then
    return
  else
    self:remove_buff('slowed')
    self:add_buff(slowBuff)
  end

end

function Unit:set_invulnerable(duration)
  local invulnerableBuff = {name = 'invulnerable', color = white[0], duration = duration, maxDuration = duration}
  self:add_buff(invulnerableBuff)
end

function Unit:bloodlust(duration)
  local bloodlustBuff = {name = 'bloodlust', color = purple[5], duration = duration, maxDuration = duration, 
    stats = {aspd = 0.1}
  }

  if Has_Static_Proc(self, 'bloodlustSpeedBoost') then
    bloodlustBuff.stats.mvspd = 0.05
  end

  local existing_buff = self.buffs['bloodlust']

  bloodlustBuff.stacks = 1
  if existing_buff then
    local max_stacks = MAX_STACKS_BLOODLUST
    if Has_Static_Proc(self, 'bloodlustMaxStacks') then
      max_stacks = MAX_STACKS_BLOODLUST_WITH_BOOST
    end
    bloodlustBuff.stacks = math.min((existing_buff.stacks or 1) + 1, max_stacks)
  end

  self:remove_buff('bloodlust')
  self:add_buff(bloodlustBuff)
end

function Unit:set_as_target()
  local targetBuff = {name = 'target', color = yellow[0], duration = 9999, stats = nil}
  self:add_buff(targetBuff)
end

function Unit:untarget()
  self:remove_buff('target')
end

function Unit:get_closest_target(shape, classes)
  local target = self:get_closest_object_in_shape(shape, classes)
  if target then
    return target
  end
end

function Unit:get_random_target(shape, classes)
  local targets = self:get_objects_in_shape(shape, classes)
  if targets and #targets > 0 then
    return targets[math.random(#targets)]
  end
end

function Unit:get_targets_that_satisfy(shape, classes, conditional)
  local targets = self:get_objects_in_shape(shape, classes)
  local out = {}
  for _, target in ipairs(targets) do
    if conditional(target) then
      table.insert(out, target)
    end
  end
  return out
end

function Unit:get_cursed_targets(shape, classes)
  return self:get_targets_that_satisfy(shape, classes, function(target)
    return target and target.buffs and target.buffs['curse']
  end)
end



function Unit:get_closest_hurt_target(shape, classes)
  local targets = self:get_objects_in_shape(shape, classes)
  if targets and #targets > 0 then
    return targets[math.random(#targets)]
  end

end

function Unit:start_curse(from)
  -- Random delay between 0.25 and 0.5 seconds
  local delay = random:float(0.1, 0.4)
  
  -- Create curse data
  local curseBuff = {name = 'curse', from = from, duration = 4, damage_taken = 0, color = purple[0], stats = {percent_def = -0.4}}
  
  -- Apply curse debuff and create visual effect after delay
  self.t:after(delay, function()
    -- Only draw the line if from is not nil
    if from then
      -- Create ChainCurse with max_chains = 1 for single line effect
      ChainCurse{
        group = main.current.main,
        parent = from,
        target = self,
        range = 0, -- No additional chaining
        is_troop = from.is_troop,
        apply_curse = true,
        color = purple[-3], -- Dark purple
        max_chains = 1 -- Only one line from caster to target
      }
    else
      --add buff if the line is not drawn
      self:curse(from)
    end
  end)
end

function Unit:curse(from)
  local curseBuff = {name = 'curse', from = from, duration = 4, damage_taken = 0, color = purple[0], stats = {percent_def = -0.4}}
  self:remove_curse()
  self:add_buff(curseBuff)
end

--unit level state functions
function Unit:start_backswing()
  --unit should always be 'casting' when this is called
  --if the unit stops casting, the spell should be cancelled
  if self.state == unit_states['casting'] then
    Helper.Unit:set_state(self, unit_states['stopped'])
  else
    print('error: unit not casting when start_backswing called', self.type)
  end
end

function Unit:end_backswing()
  if self.state == unit_states['stopped'] then
    Helper.Unit:set_state(self, unit_states['idle'])
  end
end

--2 types of target, assigned target is set by the player (RMB)
--the regular target is temporary and is set by the unit itself
function Unit:my_target()
  return self.assigned_target or self.target
end

function Unit:set_target(target)
  self.target = target
end

function Unit:set_assigned_target(target)
  self.assigned_target = target
end

function Unit:clear_assigned_target()
  self.assigned_target = nil
end

function Unit:clear_my_target()
  self.target = nil
end

function Unit:update_targets()
  if self.target and self.target.dead then
    self.target = nil
  end
  if self.assigned_target and self.assigned_target.dead then
    self.assigned_target = nil
  end
end


function Unit:has_potential_target_in_range()
  local target = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
  if target then
    return true
  end
  return false
end


--need melee units to not move inside the target
--need ranged units to move close enough to attack
function Unit:in_range(target_type)
  return function()
    local target = nil
    if target_type == 'assigned' then
      target = self.assigned_target
    elseif target_type == 'regular' then
      target = self.target
    end
      
    return self:in_range_of(target)
  end
end

function Unit:in_range_of(target)
  local target_size_offset = 0
  if self.attack_range and self.attack_range < MELEE_ATTACK_RANGE and target and not target.dead then
    target_size_offset = target.shape.w/2
  end
  return target and 
    not target.dead and 
    table.any(unit_states_can_target, function(v) return self.state == v end) and 
    self:distance_to_object(target) - target_size_offset < self.attack_sensor.rs
end

function Unit:in_aggro_range()
  return function()
    local target = self:my_target()
    local target_size_offset = 0
    if self.attack_range and self.attack_range < MELEE_ATTACK_RANGE and target and not target.dead then
      target_size_offset = target.shape.w/2
    end
    return target and 
      not target.dead and 
      table.any(unit_states_can_target, function(v) return self.state == v end) and 
      self:distance_to_object(target) - target_size_offset < self.aggro_sensor.rs
  end
end

--looks like space is the override for all units move
--and RMB sets 'following' or 'rallying' state in player_troop?
--change to the original control design
-- space for "all units follow mouse"
-- LMB for "selected troop follows mouse"
-- shift+ LMB for "selected troop rallies to mouse"
-- RMB for "selected troop targets enemy"


--controls possibiltiies:
-- RMB - target enemy
-- RMB - target enemy OR rally to location
-- RMB - target enemy OR attack move while holding button
-- RMB- target enemy OR attack move to location
function Unit:should_follow()
  local input = input['space'].down
  if input then
    Helper.Unit:clear_all_rally_points()
  end
  local canMove = table.any(unit_states_can_move, function(v) return self.state == v end)
  return input and canMove
end

--casting functions
-- uses 
-- self.castcooldown as the cooldown until the next spell
-- self.base_castcooldown as the base cooldown for the unit
-- self.baseCast ?? as the cast time for the spell (unless otherwise specified)

-- in update(), calls pick_cast() if the unit has spells and is ready to cast
-- 'normal' and castcooldown exists and is <= 0

-- pick_cast() calls start_cast()
-- which sets the unit state to 'casting'
-- sets currentcast to be the spell.cast()
-- casts the spell.oncaststart()
-- and sets currentcast to be the spell castcooldown

--then the update_cast()
-- ticks based on last_attack_started
-- and calls the currentcast() when the time is up

--confusing between castTime, baseCast, currentcast
-- need baseCast and castTime for player units w aspd
-- spell castcooldown should be modified by aspd as well

-- currentcast is the function that is called when the cast is finished
-- castcooldown is the unit's cooldown until the next cast

--freezeduration is the time before the cast is finished when the unit stops rotating
--(so player can escape the cast), linked to freezerotation

--should be able to interrupt the cast with stuns or something, and have it kill the 
--existing spell (say for a channeling spell)

function Unit:pick_action()
  -- Don't pick actions if transition is not complete (for enemies)
  if self.transition_active == false then
    return false
  end
  
  local attack_options = self.attack_options or {}
  local movement_options = self.movement_options or {}

  local viable_attacks = {}
  local viable_movements = {}

  if self.castcooldown ~= nil and self.castcooldown <= 0 then
    for k, v in pairs(attack_options) do
      if v.viable(self) then
        table.insert(viable_attacks, v)
      end
    end
  end

  for k, v in pairs(movement_options) do
    table.insert(viable_movements, v)
  end

  if #viable_attacks > 0 and math.random() > (self.move_option_weight or 0.15) then
    local attack = random:table(viable_attacks)
    while #viable_attacks > 1 and self.last_cast == attack.name do
      attack = random:table(viable_attacks)
    end
    self:cast(attack)
    self.last_cast = attack.name
    return true
  else
    local chosen_movement

    if #viable_movements > 0 then
        -- We have dynamic options, pick one.
        chosen_movement = random:table(viable_movements)
    else
        -- No dynamic options, use the enemy's default style.
        chosen_movement = self.movementStyle or MOVEMENT_TYPE_RANDOM
    end

    -- Now, commit to the chosen movement action once.
    self:set_movement_action(chosen_movement)
    return true
  end
end


function Unit:update_cast_cooldown(dt)
  if not self.castcooldown then
    print('no castcooldown in update_cast_cooldown', self.type)
    return
  end

  if self.castcooldown > 0 then
    self:set_castcooldown(self.castcooldown - dt)
  end
end

function Unit:cast(castData)
  if castData.spellclass then
    if castData.oncast then
      castData.oncast(self)
    end
    local castCopy = Deep_Copy_Cast(castData)
    castCopy.x = self.x
    castCopy.y = self.y
    castCopy.unit = self
    castCopy.target = self:my_target()
    self.castObject = Cast(castCopy)
  else
    print('spellclass not found', castData.name)
  end
end

function Unit:should_freeze_rotation()
  return self.freezerotation
    or (self.castObject and self.castObject.freeze_rotation)
end

function Unit:end_cast(cooldown, spell_duration)
  local random_cooldown = self:get_random_cooldown(cooldown)
  
  self:reset_castcooldown(random_cooldown)
  self.spelldata = nil
  self.freezerotation = false

  if self.state == unit_states['casting']then
    if self:try_backswing() then
      return
    else
      Helper.Unit:set_state(self, unit_states['idle'])
    end
  end

  self.castObject = nil
end

function Unit:try_backswing()
  if self.castObject and self.castObject.backswing then
    if self.state == unit_states['casting'] then
      Helper.Unit:set_state(self, unit_states['stopped'])
      self.t:after(self.castObject.backswing, function()
        if self.state == unit_states['stopped'] then
          Helper.Unit:set_state(self, unit_states['idle'])
        end
      end)
      return true
    end
  end
  return false
end

function Unit:get_random_cooldown(cooldown)
  return cooldown + ((math.random() * RANDOM_COOLDOWN_VARIANCE) - 0.5 * RANDOM_COOLDOWN_VARIANCE)
end

function Unit:end_channel(cooldown)
  if self.state == unit_states['channeling'] then
    local random_cooldown = self:get_random_cooldown(self.baseCooldown)
    self:reset_castcooldown(random_cooldown)
    self.spelldata = nil
    self.freezerotation = false
    Helper.Unit:set_state(self, unit_states['idle'])
  end
end


--remove the castObject before calling die()
-- to prevent the infinite loop
function Cancel_Cast(unit)
  local castObject = unit.castObject
  unit.castObject = nil
  if castObject then
    castObject:cancel()
  end
end


--infinite loop, this calls cast:cancel() which calls this
--but broken by removing the castObject before calling die()
-- and the death check
function Unit:cancel_cast()

  if self.state == unit_states['casting'] or self.state == unit_states['channeling'] then
    Helper.Unit:set_state(self, unit_states['idle'])
    self:reset_castcooldown(0)
    self.spelldata = nil
  end

  Cancel_Cast(self)
end

function Unit:interrupt_cast()
  if self.castObject then
    self:reset_castcooldown(self.baseCast or 1)
    self.spelldata = nil
    Cancel_Cast(self)
  end
end

function Unit:interrupt_channel()
  if self.state == unit_states['channeling'] then
    self:reset_castcooldown(0)
    self.spelldata = nil
    Cancel_Cast(self)
  end
end

--for channeling spells, if they are hit while casting
function Unit:delay_cast()

end

function Unit:is_facing_left()
  local r = self:get_angle() or 0
  return math.cos(r) < 0
end

function Unit:launch_at_facing(force_magnitude, duration)
  if self.state == unit_states['casting'] then
    self:end_cast()
  elseif self.state == unit_states['channeling'] then
    self:end_channel()
  end

  duration = duration or 0.7

  local mass
  if self.body then
    mass = self.body:getMass()
  else
    mass = 1
  end

  self.is_launching = true
  self.t:after(duration, function() self.is_launching = false end, 'launch_end')
  local facing = self:get_angle()
  self.launch_force_x = math.cos(facing) * force_magnitude * mass
  self.launch_force_y = math.sin(facing) * force_magnitude * mass
  self:set_velocity(0, 0)
  self:apply_impulse(self.launch_force_x, self.launch_force_y)
  

  local orig_damping
  if self.body then
    orig_damping = self:get_damping()
  else
    orig_damping = BOSS_DAMPING
  end

  local orig_friction
  if self.body then
    orig_friction = self:get_friction()
  else
    orig_friction = 0
  end

  self:set_damping(0)
  self:set_friction(0.4)

  self.t:after(duration, function()
    if self.is_launching then
      self:set_velocity(0, 0)
      self.is_launching = false
    end
    self:set_damping(orig_damping)
    self:set_friction(orig_friction)
  end)



end

function Unit:die()
  --cleanup buffs
  for k, v in pairs(self.buffs) do
    if k == 'curse' then
      self:remove_curse()
    else
      self:remove_buff(k)
    end
  end
  for k, v in pairs(self.procs) do
    v:die()
  end
  --killing the items should kill the procs as well
  --but it is only the itemdata on the unit, not the actual item
  -- for k, v in pairs(self.items) do
  --   v:die()
  -- end

end

function Unit:set_castcooldown(value)
  self.castcooldown = value
end

function Unit:reset_castcooldown(value)
  self.castcooldown = value
  self.total_castcooldown = value
end


EffectBar = Object:extend()
EffectBar:implement(GameObject)
EffectBar:implement(Parent)
function EffectBar:init(args)
  self:init_game_object(args)
  self.hidden = true
  self.color = fg[0]
end


function EffectBar:update(dt)
  self:update_game_object(dt)
  self:follow_parent_exclusively()
end


function EffectBar:draw()
  if self.hidden then return end
  --[[
  local p = self.parent
  graphics.push(p.x, p.y, p.r, p.hfx.hit.x, p.hfx.hit.x)
    graphics.rectangle(p.x, p.y, 3, 3, 1, 1, self.color)
  graphics.pop()
  ]]--
end




HPBar = Object:extend()
HPBar:implement(GameObject)
HPBar:implement(Parent)
function HPBar:init(args)
  self:init_game_object(args)
  self.hidden = true
  if self.isBoss then
    self.hidden = false
  end

  self.last_hp = self.parent.hp
end


function HPBar:update(dt)
  self:update_game_object(dt)
  self:follow_parent_exclusively()

  --update "last hp" for the hp bar effect
  --messy AF!
  if self.isBoss and self.parent and self.last_hp ~= self.parent.hp then
    local w = 200
    local x = gw/2 - w/2

    local x1 = self:get_percent_hp() * w + x 
    local x2 = self:get_percent_hp(self.last_hp) * w + x
    
    HPBar_Damage_Chunk{
      group = main.current.effects,
      x1 = x1,
      y1 = 20,
      x2 = x2,
      y2 = 20,
    }
    self.last_hp = self.parent.hp
  end
end

function HPBar:get_percent_hp(hp)
  local p = self.parent
  return math.remap(hp or p.hp, 0, p.max_hp, 0, 1)
end


function HPBar:draw()
  if self.hidden then return end
  
  local p = self.parent
  local n = self:get_percent_hp()

  if self.isBoss then
    local w = 200
    local h = 10
    local x = gw/2 - w/2
    local y = 20
    graphics.line(x, y, x + w, y, bg[-3], h)
    graphics.line(x, y, x + n*w, y, red[0], h)
    skull:draw(x + n*w, y, 0, 0.4, 0.4)
  else
    if p.hp < p.max_hp then
      graphics.push(p.x, p.y, 0, p.hfx.hit.x, p.hfx.hit.x)
        graphics.line(p.x - 0.5*p.shape.w, p.y - p.shape.h, p.x + 0.5*p.shape.w, p.y - p.shape.h, bg[-3], 2)
        graphics.line(p.x - 0.5*p.shape.w, p.y - p.shape.h, p.x - 0.5*p.shape.w + n*p.shape.w, p.y - p.shape.h,
        p.hfx.hit.f and fg[0] or (((p:is(Player) or p.is_troop) and green[0]) or (table.any(main.current.enemies, function(v) return p:is(v) end) and red[0])), 2)
      graphics.pop()
    end
  end
end

HPBar_Damage_Chunk = Object:extend()
HPBar_Damage_Chunk:implement(GameObject)
function HPBar_Damage_Chunk:init(args)
  self:init_game_object(args)
  self.start_time = Helper.Time.time
  self.duration = 1
  self.a = 1
  self.color = white[0]
end

function HPBar_Damage_Chunk:update(dt)
  self:update_game_object(dt)
  if Helper.Time.time - self.start_time > self.duration then
    self.dead = true
  end
  self.a = math.remap(Helper.Time.time - self.start_time, 0, self.duration, 1, 0)
end

function HPBar_Damage_Chunk:draw()
  local color = self.color:clone()
  color.a = self.a
  graphics.line(self.x1, self.y1, self.x2, self.y2, color, 10)
end

-- Get perk stats for display in buy screen tooltips
function Unit:get_perk_stats_for_display()
  -- Get perk stats that would apply to this unit
  local perk_stats = {}
  if self.perks then
    for perk_name, perk in pairs(self.perks) do
      local perk_stat_data = Get_Perk_Stats(perk)
      for stat, value in pairs(perk_stat_data) do
        local actual_stat = Helper.Unit:process_perk_name(stat, self)
        if actual_stat then
          perk_stats[actual_stat] = (perk_stats[actual_stat] or 0) + value
        end
      end
    end
  end
  
  return perk_stats
end

-- Unified stat addition function
function Unit:add_stats(stats_list)
  for stat_name, amount in pairs(stats_list) do
    if stat_name == buff_types['dmg'] then
      self.buff_dmg_m = self.buff_dmg_m + amount
    elseif stat_name == buff_types['hp'] then
      self.buff_hp_m = self.buff_hp_m + amount
    elseif stat_name == buff_types['mvspd'] then
      self.buff_mvspd_m = self.buff_mvspd_m + amount
    elseif stat_name == buff_types['aspd'] then
      self.buff_aspd_m = self.buff_aspd_m + amount

    elseif stat_name == buff_types['area_dmg'] then
      self.buff_area_dmg_m = self.buff_area_dmg_m + amount
    elseif stat_name == buff_types['area_size'] then
      self.buff_area_size_m = self.buff_area_size_m + amount
      
    elseif stat_name == buff_types['status_resist'] then
      self.status_resist = self.status_resist + amount
    elseif stat_name == buff_types['range'] then
      self.buff_range_m = self.buff_range_m + amount
    elseif stat_name == buff_types['cdr'] then
      self.buff_cdr_m = self.buff_cdr_m + amount

    elseif stat_name == buff_types['flat_def'] then
      self.buff_def_a = self.buff_def_a + amount
    elseif stat_name == buff_types['percent_def'] then
      self.buff_def_m = self.buff_def_m + amount
      
    elseif stat_name == buff_types['eledmg'] then
      self.eledmg_m = self.eledmg_m + amount
    elseif stat_name == buff_types['elevamp'] then
      self.elevamp = self.elevamp + amount
    elseif stat_name == buff_types['vamp'] then
      self.vamp = self.vamp + amount

    elseif stat_name == buff_types['fire_damage'] then
      self.buff_fire_damage_a = self.buff_fire_damage_a + amount
    elseif stat_name == buff_types['lightning_damage'] then
      self.buff_lightning_damage_a = self.buff_lightning_damage_a + amount
    elseif stat_name == buff_types['cold_damage'] then
      self.buff_cold_damage_a = self.buff_cold_damage_a + amount
    elseif stat_name == buff_types['fire_damage_m'] then
      self.buff_fire_damage_m = self.buff_fire_damage_m + amount
    elseif stat_name == buff_types['lightning_damage_m'] then
      self.buff_lightning_damage_m = self.buff_lightning_damage_m + amount
    elseif stat_name == buff_types['cold_damage_m'] then
      self.buff_cold_damage_m = self.buff_cold_damage_m + amount
      
    elseif stat_name == buff_types['repeat_attack_chance'] then
      self.buff_repeat_attack_chance = self.buff_repeat_attack_chance + amount
    elseif stat_name == buff_types['crit_chance'] then
      self.crit_chance = self.crit_chance + amount
    elseif stat_name == buff_types['crit_mult'] then
      self.crit_mult = self.crit_mult + amount
    elseif stat_name == buff_types['stun_chance'] then
      self.stun_chance = self.stun_chance + amount
    elseif stat_name == buff_types['cooldown_reduction'] then
      self.cooldown_reduction = self.cooldown_reduction + amount
    elseif stat_name == buff_types['slow_per_element'] then
      self.slow_per_element = (self.slow_per_element or 0) + amount
    else
      -- print("unknown stat: " .. stat_name, amount)
    end
  end
end

-- Preprocess perks into actual stats
function Unit:preprocess_perks_to_stats()
  local processed_stats = {}
  
  if not self.perks then return processed_stats end
  
  for perk_name, perk in pairs(self.perks) do
    local perk_stats = Get_Perk_Stats(perk)
    for stat, value in pairs(perk_stats) do
      local actual_stat = Helper.Unit:process_perk_name(stat, self)
      if actual_stat then
        processed_stats[actual_stat] = (processed_stats[actual_stat] or 0) + value
      end
    end
  end
  
  return processed_stats
end

-- Process buffs with stack multiplication
function Unit:process_buffs_to_stats()
  local processed_stats = {}
  
  if not self.buffs then return processed_stats end
  
  for _, buff in pairs(self.buffs) do
    if buff.stats then
      for stat, amt in pairs(buff.stats) do
        local amtWithStacks = amt * (buff.stacks or 1)
        processed_stats[stat] = (processed_stats[stat] or 0) + amtWithStacks
      end
    end
  end
  
  return processed_stats
end

-- Process items to stats
function Unit:process_items_to_stats()
  local processed_stats = {}
  
  if not self.items or #self.items == 0 then return processed_stats end
  
  for _, item in ipairs(self.items) do
    if item.stats then
      for stat, amt in pairs(item.stats) do
        -- Add sanity check for valid stat values
        if type(amt) ~= "number" then
          print("Warning: Invalid stat value for '" .. stat .. "' on item: " .. (item.name or "unknown"))
          amt = 0
        end
        
        -- Check if this is a V2 item with increment values
        if ITEM_STATS and ITEM_STATS[stat] and ITEM_STATS[stat].increment then
          -- Add sanity check for increment value
          if type(ITEM_STATS[stat].increment) ~= "number" then
            print("Warning: Invalid increment value for V2 stat '" .. stat .. "'")
          else
            -- Use the increment value to calculate the actual stat bonus
            local actual_amount = amt * ITEM_STATS[stat].increment
            processed_stats[stat] = (processed_stats[stat] or 0) + actual_amount
          end
        else
          -- Legacy item system - use the amount directly
          processed_stats[stat] = (processed_stats[stat] or 0) + amt
        end
      end
    end
  end
  
  return processed_stats
end

function Unit:process_set_bonuses_to_stats()
  local set_bonus_stats = {}
  local sets = {}
  
  if not self.items or #self.items == 0 then return set_bonus_stats end
  
  for _, item in ipairs(self.items) do
    if item.sets and #item.sets > 0 then
      for _, set in ipairs(item.sets) do
        sets[set] = (sets[set] or 0) + 1
      end
    end
  end
  
  for set, count in pairs(sets) do
    local set_data = ITEM_SETS[set]
    if set_data then
      for number_required, bonus in ipairs(set_data.bonuses) do
        if count >= number_required then
          if bonus.stats then
            for stat, value in pairs(bonus.stats) do
              local actual_amount = value * (ITEM_STATS[stat].increment or 1)
              set_bonus_stats[stat] = (set_bonus_stats[stat] or 0) + actual_amount
            end
          end
        end
      end
    else
      print("Unknown set: " .. set)
    end
  end
  
  return set_bonus_stats
end

function Unit:get_set_procs()
  local set_bonus_procs = {}
  local sets = {}

  if not self.items or #self.items == 0 then return set_bonus_procs end

  for _, item in ipairs(self.items) do
    if item.sets and #item.sets > 0 then
      for _, set in ipairs(item.sets) do
        sets[set] = (sets[set] or 0) + 1
      end
    end
  end

  for set, count in pairs(sets) do
    local set_data = ITEM_SETS[set]
    if set_data then
      for key, bonus in pairs(set_data.bonuses) do
        if count >= key then
          if bonus.procs then
            for _, proc_name in ipairs(bonus.procs) do
              table.insert(set_bonus_procs, proc_name)
            end
          end
        end
      end
    else
      print("Unknown set: " .. set)
    end
  end

  return set_bonus_procs
end



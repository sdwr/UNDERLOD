Player = Object:extend()
Player:implement(GameObject)
Player:implement(Physics)
Player:implement(Unit)
function Player:init(args)
  self:init_game_object(args)
  self:init_unit()

  if self.passives then for k, v in pairs(self.passives) do self[v.passive] = v.level end end

  self.color = character_colors[self.character]
  self:set_as_rectangle(9, 9, 'dynamic', 'player')
  self.visual_shape = 'rectangle'
  self.class = character_types[self.character]
  self.damage_dealt = 0

  self.mouse_control_v_buffer = {}

  if main.current:is(MainMenu) then
    self.r = random:table{-math.pi/4, math.pi/4, 3*math.pi/4, -3*math.pi/4}
    self:set_angle(self.r)
  end
end


function Player:update(dt)
  self:update_game_object(dt)

  self.buff_def_a = (self.warrior_def_a or 0)
  self.buff_aspd_m = (self.chronomancer_aspd_m or 1)*(self.vagrant_aspd_m or 1)*(self.outlaw_aspd_m or 1)*(self.fairy_aspd_m or 1)*(self.psyker_aspd_m or 1)*(self.chronomancy_aspd_m or 1)*(self.awakening_aspd_m or 1)*(self.berserking_aspd_m or 1)*(self.reinforce_aspd_m or 1)*(self.squire_aspd_m or 1)*(self.speed_3_aspd_m or 1)*(self.last_stand_aspd_m or 1)*(self.enchanted_aspd_m or 1)*(self.explorer_aspd_m or 1)*(self.magician_aspd_m or 1)
  self.buff_dmg_m = (self.squire_dmg_m or 1)*(self.vagrant_dmg_m or 1)*(self.enchanter_dmg_m or 1)*(self.swordsman_dmg_m or 1)*(self.flagellant_dmg_m or 1)*(self.psyker_dmg_m or 1)*(self.ballista_dmg_m or 1)*(self.awakening_dmg_m or 1)*(self.reinforce_dmg_m or 1)*(self.payback_dmg_m or 1)*(self.immolation_dmg_m or 1)*(self.damage_4_dmg_m or 1)*(self.offensive_stance_dmg_m or 1)*(self.last_stand_dmg_m or 1)*(self.dividends_dmg_m or 1)*(self.explorer_dmg_m or 1)
  self.buff_def_m = (self.squire_def_m or 1)*(self.ouroboros_def_m or 1)*(self.unwavering_stance_def_m or 1)*(self.reinforce_def_m or 1)*(self.defensive_stance_def_m or 1)*(self.last_stand_def_m or 1)*(self.unrelenting_stance_def_m or 1)*(self.hardening_def_m or 1)
  self.buff_area_size_m = (self.nuker_area_size_m or 1)*(self.magnify_area_size_m or 1)*(self.unleash_area_size_m or 1)*(self.last_stand_area_size_m or 1)
  self.buff_area_dmg_m = (self.nuker_area_dmg_m or 1)*(self.amplify_area_dmg_m or 1)*(self.unleash_area_dmg_m or 1)*(self.last_stand_area_dmg_m or 1)
  self.buff_mvspd_m = (self.wall_rider_mvspd_m or 1)*(self.centipede_mvspd_m or 1)*(self.squire_mvspd_m or 1)*(self.last_stand_mvspd_m or 1)*(self.haste_mvspd_m or 1)
  self.buff_hp_m = (self.flagellant_hp_m or 1)
  self.class = 'warrior'
  self:calculate_stats()

  if self.attack_sensor then self.attack_sensor:move_to(self.x, self.y) end
  if self.wide_attack_sensor then self.wide_attack_sensor:move_to(self.x, self.y) end
  if self.gun_kata_sensor then self.gun_kata_sensor:move_to(self.x, self.y) end
  self.t:set_every_multiplier('shoot', self.aspd_m)
  self.t:set_every_multiplier('attack', self.aspd_m)

  if self.leader then
    if not main.current:is(MainMenu) then
      if input.move_left.pressed and not self.move_right_pressed then self.move_left_pressed = love.timer.getTime() end
      if input.move_right.pressed and not self.move_left_pressed then self.move_right_pressed = love.timer.getTime() end
      if input.move_left.released then self.move_left_pressed = nil end
      if input.move_right.released then self.move_right_pressed = nil end

      if state.mouse_control then
        self.mouse_control_v = Vector(math.cos(self.r), math.sin(self.r)):perpendicular():dot(Vector(math.cos(self:angle_to_mouse()), math.sin(self:angle_to_mouse())))
        self.r = self.r + math.sign(self.mouse_control_v)*1.66*math.pi*dt
        table.insert(self.mouse_control_v_buffer, 1, self.mouse_control_v)
        if #self.mouse_control_v_buffer > 64 then self.mouse_control_v_buffer[65] = nil end
      else
        if input.move_left.down then self.r = self.r - 1.66*math.pi*dt end
        if input.move_right.down then self.r = self.r + 1.66*math.pi*dt end
      end
    end

    local total_v = 0

    self:set_velocity(total_v*math.cos(self.r), total_v*math.sin(self.r))

    if not main.current.won and not main.current.choosing_passives then
      if not state.no_screen_movement then
        local vx, vy = self:get_velocity()
        local hd = math.remap(math.abs(self.x - gw/2), 0, 192, 1, 0)
        local vd = math.remap(math.abs(self.y - gh/2), 0, 108, 1, 0)
        camera.x = camera.x + math.remap(vx, -100, 100, -24*hd, 24*hd)*dt
        camera.y = camera.y + math.remap(vy, -100, 100, -8*vd, 8*vd)*dt
        if input.move_right.down then camera.r = math.lerp_angle_dt(0.01, dt, camera.r, math.pi/256)
        elseif input.move_left.down then camera.r = math.lerp_angle_dt(0.01, dt, camera.r, -math.pi/256)
          --[[
        elseif input.move_down.down then camera.r = math.lerp_angle_dt(0.01, dt, camera.r, math.pi/256)
        elseif input.move_up.down then camera.r = math.lerp_angle_dt(0.01, dt, camera.r, -math.pi/256)
        ]]--
        else camera.r = math.lerp_angle_dt(0.005, dt, camera.r, 0) end
      end
    end

    self:set_angle(self.r)

  else
    local target_distance = 10.4*(self.follower_index or 0)
    local distance_sum = 0
    local p
    local previous = self.parent
    for i, point in ipairs(self.parent.previous_positions) do
      local distance_to_previous = math.distance(previous.x, previous.y, point.x, point.y)
      distance_sum = distance_sum + distance_to_previous
      if distance_sum >= target_distance then
        p = self.parent.previous_positions[i-1]
        break
      end
      previous = point
    end

    if p then
      self:set_position(p.x, p.y)
      self.r = p.r
      if not self.following then
        spawn1:play{pitch = random:float(0.8, 1.2), volume = 0.15}
        for i = 1, random:int(3, 4) do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
        HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 10, color = fg[0]}:scale_down(0.3):change_color(0.5, self.color)
        self.following = true
      end
    else
      self.r = self:get_angle()
    end
  end
end


function Player:draw()
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x*self.hfx.shoot.x, self.hfx.hit.x*self.hfx.shoot.x)
  if self.visual_shape == 'rectangle' then
    if self.magician_invulnerable then
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, blue_transparent)
    elseif self.undead then
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.color, 1)
    else
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, (self.hfx.hit.f or self.hfx.shoot.f) and fg[0] or self.color)
    end

    if self.leader and state.arrow_snake then
      local x, y = self.x + 0.9*self.shape.w, self.y
      graphics.line(x + 3, y, x, y - 3, character_colors[self.character], 1)
      graphics.line(x + 3, y, x, y + 3, character_colors[self.character], 1)
    end

    if self.ouroboros_def_m and self.ouroboros_def_m > 1 then
      graphics.rectangle(self.x, self.y, 1.25*self.shape.w, 1.25*self.shape.h, 3, 3, yellow_transparent)
    end

    if self.divined then
      graphics.rectangle(self.x, self.y, 1.25*self.shape.w, 1.25*self.shape.h, 3, 3, green_transparent)
    end

    if self.fairyd then
      graphics.rectangle(self.x, self.y, 1.25*self.shape.w, 1.25*self.shape.h, 3, 3, blue_transparent)
    end
  end
  graphics.pop()
end


function Player:on_collision_enter(other, contact)
  local x, y = contact:getPositions()

  if other:is(Wall) then
    if self.leader then
      if other.snkrx then
        main.current.level_1000_text:pull(0.2, 200, 10)
      end
      self.hfx:use('hit', 0.5, 200, 10, 0.1)
      camera:spring_shake(2, math.pi - self.r)
      self:bounce(contact:getNormal())
      local r = random:float(0.9, 1.1)
      player_hit_wall1:play{pitch = r, volume = 0.1}
      pop1:play{pitch = r, volume = 0.2}

      if self.wall_echo then
        if random:bool(34) then
          local target = self:get_closest_object_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
          if target then
            self:barrage(self:angle_to_object(target), 2)
          else
            local r = Vector(contact:getNormal()):angle()
            self:barrage(r, 2)
          end
        end
      end

      if self.wall_rider then
        local units = self:get_all_units()
        for _, unit in ipairs(units) do unit.wall_rider_mvspd_m = 1.25 end
        trigger:after(1, function()
          for _, unit in ipairs(units) do unit.wall_rider_mvspd_m = 1 end
        end, 'wall_rider')
      end
    end

  elseif table.any(main.current.enemies, function(v) return other:is(v) end) then
    other:push(random:float(25, 35)*(self.knockback_m or 1), self:angle_to_object(other))
    if self.character == 'vagrant' or self.character == 'psykeeper' then other:hit(2*self.dmg)
    else other:hit(self.dmg) end
    if other.headbutting then
      self:hit((4 + math.floor(other.level/3))*other.dmg)
      other.headbutting = false
    else self:hit(other.dmg) end
    HitCircle{group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1}
    for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = self.color} end
    for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = other.color} end
  end
end


function Player:hit(damage, from_undead)
  if self.dead then return end
  if self.magician_invulnerable then return end
  if self.undead and not from_undead then return end
  self.hfx:use('hit', 0.25, 200, 10)
  self:show_hp()

  local actual_damage = math.max(self:calculate_damage(damage), 0)
  self.hp = self.hp - actual_damage
  _G[random:table{'player_hit1', 'player_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  camera:shake(4, 0.5)
  main.current.damage_taken = main.current.damage_taken + actual_damage

  if self.payback and self.class == 'enchanter' then
    local units = self:get_all_units()
    for _, unit in ipairs(units) do
      if not unit.payback_dmg_m then unit.payback_dmg_m = 1 end
      unit.payback_dmg_m = unit.payback_dmg_m + ((self.payback == 1 and 0.02) or (self.payback == 2 and 0.05) or (self.payback == 3 and 0.08) or 0)
    end
  end

  if self.unrelenting_stance and self.class == 'warrior' then
    local units = self:get_all_units()
    for _, unit in ipairs(units) do
      if not unit.unrelenting_stance_def_m then unit.unrelenting_stance_def_m = 1 end
      unit.unrelenting_stance_def_m = unit.unrelenting_stance_def_m + ((self.unrelenting_stance == 1 and 0.02) or (self.unrelenting_stance == 2 and 0.05) or (self.unrelenting_stance == 3 and 0.08) or 0)
    end
  end

  if self.character == 'beastmaster' and self.level == 3 then
    critter1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    trigger:after(0.01, function()
      for i = 1, 4 do
        Critter{group = main.current.main, x = self.x, y = self.y, color = orange[0], r = random:float(0, 2*math.pi), v = 20, dmg = self.dmg, parent = self}
      end
    end)
  end

  if self.crucio then
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    for _, enemy in ipairs(enemies) do
      enemy:hit(((self.crucio == 1 and 0.2) or (self.crucio == 2 and 0.3) or (self.crucio == 3 and 0.4))*actual_damage)
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = fg[0], duration = 0.1}
    end
  end

  if self.character == 'psykeeper' then
    self.stored_heal = self.stored_heal + actual_damage
    if self.stored_heal > (0.25*self.max_hp) then
      self.stored_heal = 0
      local check_circle = Circle(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16), 2)
      local objects = main.current.main:get_objects_in_shape(check_circle, {Enemy, EnemyCritter, Critter, Volcano, Saboteur, Bomb, Pet, Turret, Sentry, Automaton})
      while #objects > 0 do
        check_circle:move_to(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16))
        objects = main.current.main:get_objects_in_shape(check_circle, {Enemy, EnemyCritter, Critter, Volcano, Saboteur, Bomb, Pet, Turret, Sentry, Automaton})
      end
      for i = 1, 3 do
        SpawnEffect{group = main.current.effects, x = check_circle.x, y = check_circle.y, color = green[0], action = function(x, y)
          local check_circle = Circle(x, y, 2)
          local objects = main.current.main:get_objects_in_shape(check_circle, {Enemy, EnemyCritter, Critter, Sentry, Volcano, Saboteur, Bomb, Pet, Turret, Automaton})
          if #objects == 0 then
            HealingOrb{group = main.current.main, x = x, y = y}
          end
        end}
      end
    end

    if self.level == 3 then
      local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
      for _, enemy in ipairs(enemies) do
        enemy:hit(2*actual_damage/#enemies)
      end
    end
  end

  self.character_hp:change_hp()

  if self.hp <= 0 then
    if self.divined then
      self:heal(self.max_hp)
      heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      buff1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      for i = 1, random:int(4, 6) do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 12}:scale_down(0.3):change_color(0.5, self.color)
      self.divined = false

    elseif self.lasting_7 and self.follower_index == 6 and not self.undead then
      self.undead = true
      self.t:after(10, function() self:hit(10000, true) end)

    else
      hit4:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      slow(0.25, 1)
      for i = 1, random:int(4, 6) do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 12}:scale_down(0.3):change_color(0.5, self.color)

      if self.kinetic_bomb then
        elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
        local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
        for _, enemy in ipairs(enemies) do
          enemy:push(random:float(30, 50)*(self.knockback_m or 1), self:angle_to_object(enemy))
        end
      end

      if self.porcupine_technique then
        main.current.t:after(0.01, function()
          local r = 0
          for i = 1, 8 do
            archer1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
            HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
            local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 250, r = r, color = self.color, dmg = self.dmg,
            parent = self, character = 'barrage', level = self.level, pierce = 1000, ricochet = 2}
            Projectile(table.merge(t, mods or {}))
            r = r + math.pi/4
          end
        end)
      end

      if self.hardening then
        local units = self:get_all_units()
        for _, unit in ipairs(units) do
          unit.hardening_def_m = 2.5
          unit.t:after(3, function() unit.hardening_def_m = 1 end)
        end
      end

      if self.annihilation and self.class == 'voider' then
        local enemies = self.group:get_objects_by_classes({Enemy, EnemyCritter})
        for _, enemy in ipairs(enemies) do
          enemy:apply_dot(self.dmg*(self.dot_dmg_m or 1)*(main.current.chronomancer_dot or 1), 3)
        end
      end

      if self.insurance then
        if random:bool(4*((main.current.mercenary_level == 2 and 16) or (main.current.mercenary_level == 1 and 8) or 0)) then
          main.current.t:after(0.01, function()
            Gold{group = main.current.main, x = self.x, y = self.y}
            Gold{group = main.current.main, x = self.x, y = self.y}
          end)
        end
      end

      if self.dot_area then self.dot_area.dead = true; self.dot_area = nil end
    end
  end
end


function Player:sorcerer_repeat()
  local enemies = self.group:get_objects_by_classes(main.current.enemies)
  if not enemies then return end
  local enemy = random:table(enemies)
  if enemy then
    if self.gravity_field then
      ForceArea{group = main.current.effects, x = enemy.x, y = enemy.y, rs = self.area_size_m*24, color = fg[0], character = 'gravity_field', parent = self}
    end
  end

  local enemy = random:table(enemies)
  if enemy then
    if self.burning_field then
      fire1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
      DotArea{group = main.current.effects, x = enemy.x, y = enemy.y, rs = self.area_size_m*24, color = red[0], dmg = 30*self.area_dmg_m*(self.dot_dmg_m or 1), duration = 2, character = 'burning_field'}
    end
  end

  local enemy = random:table(enemies)
  if enemy then
    if self.freezing_field then
      frost1:play{pitch = random:float(0.8, 1.2), volume = 0.3}
      elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.3}
      Area{group = main.current.effects, x = enemy.x, y = enemy.y, w = self.area_size_m*36, color = blue[0], character = 'freezing_field', parent = self}
    end
  end
end


function Player:heal(amount)
  local hp = self.hp

  self.hfx:use('hit', 0.25, 200, 10)
  self:show_hp(1.5)
  self:show_heal(1.5)
  self.hp = self.hp + amount
  if self.hp > self.max_hp then self.hp = self.max_hp end

  self.character_hp:change_hp()
end


function Player:chain_infuse(duration)
  self.chain_infused = true
  self.t:after(duration or 2, function() self.chain_infused = false end, 'chain_infuse')
end


function Player:get_all_units()
  local followers
  local leader = (self.leader and self) or self.parent
  if self.leader then followers = self.followers else followers = self.parent.followers end
  return {leader, unpack(followers)}
end


function Player:get_leader()
  return (self.leader and self) or self.parent
end


function Player:get_unit(character)
  local all_units = self:get_all_units()
  for _, unit in ipairs(all_units) do
    if unit.character == character then return unit end
  end
end


function Player:recalculate_followers()
  if self.dead then
    local new_leader = table.remove(self.followers, 1)
    new_leader.leader = true
    new_leader.previous_positions = {}
    new_leader.followers = self.followers
    new_leader.t:every(0.01, function()
      table.insert(new_leader.previous_positions, 1, {x = new_leader.x, y = new_leader.y, r = new_leader.r})
      if #new_leader.previous_positions > 256 then new_leader.previous_positions[257] = nil end
    end)
    main.current.player = new_leader
    for i, follower in ipairs(self.followers) do
      follower.parent = new_leader
      follower.follower_index = i
    end

  else
    for i = #self.followers, 1, -1 do
      if self.followers[i].dead then
        table.remove(self.followers, i)
        break
      end
    end
    for i, follower in ipairs(self.followers) do
      follower.follower_index = i
    end
  end
end


function Player:add_follower(unit)
  table.insert(self.followers, unit)
  unit.parent = self
  unit.follower_index = #self.followers
end

function Player:shoot(r, mods)
  
--[[
  mods = mods or {}
  camera:spring_shake(2, r)
  self.hfx:use('shoot', 0.25)

  local dmg_m = 1
  local crit = false
  if self.character == 'beastmaster' then crit = random:bool(10) end
  if self.chance_to_crit and random:bool(self.chance_to_crit) then dmg_m = ((self.assassination == 1 and 8) or (self.assassination == 2 and 10) or (self.assassination == 3 and 12) or 4); crit = true end
  if self.assassination and self.class == 'rogue' then
    if not crit then
      dmg_m = 0.5
    end
  end

  if self.character == 'thief' then
    dmg_m = dmg_m*2
    if self.level == 3 and crit then
      dmg_m = dmg_m*10
      main.current.gold_picked_up = main.current.gold_picked_up + 1
    end
  end

  if crit and mods.spawn_critters_on_crit then
    critter1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    trigger:after(0.01, function()
      for i = 1, mods.spawn_critters_on_crit do
        Critter{group = main.current.main, x = self.x, y = self.y, color = orange[0], r = random:float(0, 2*math.pi), v = 10, dmg = self.dmg, parent = self}
      end
    end)
  end

  if self.character == 'outlaw' then
    HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
    r = r - 2*math.pi/8
    for i = 1, 5 do
      local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 250, r = r, color = self.color, dmg = self.dmg*dmg_m, crit = crit, character = self.character,
        parent = self, level = self.level}
      Projectile(table.merge(t, mods or {}))
      r = r + math.pi/8
    end

  elseif self.character == 'blade' then
    local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies)
    if enemies and #enemies > 0 then
      for _, enemy in ipairs(enemies) do
        local r = self:angle_to_object(enemy)
        HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
        local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 250, r = r, color = self.color, dmg = self.dmg*dmg_m, crit = crit, character = self.character,
          parent = self, level = self.level}
        Projectile(table.merge(t, mods or {}))
      end
    end

  elseif self.character == 'sage' then
    HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
    local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 25, r = r, color = self.color, dmg = self.dmg, pierce = 1000, character = 'sage',
      parent = self, level = self.level}
    Projectile(table.merge(t, mods or {}))

  elseif self.character == 'dual_gunner' then
    HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r) + 4*math.cos(r - math.pi/2), y = self.y + 0.8*self.shape.w*math.sin(r) + 4*math.sin(r - math.pi/2), rs = 6}
    HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r) + 4*math.cos(r + math.pi/2), y = self.y + 0.8*self.shape.w*math.sin(r) + 4*math.sin(r + math.pi/2), rs = 6}
    local t1 = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r) + 4*math.cos(r - math.pi/2) , y = self.y + 1.6*self.shape.w*math.sin(r) + 4*math.sin(r - math.pi/2),
    v = 300, r = r, color = self.color, dmg = self.dmg*dmg_m, crit = crit, character = self.character, parent = self, level = self.level}
    local t2 = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r) + 4*math.cos(r + math.pi/2) , y = self.y + 1.6*self.shape.w*math.sin(r) + 4*math.sin(r + math.pi/2),
    v = 300, r = r, color = self.color, dmg = self.dmg*dmg_m, crit = crit, character = self.character, parent = self, level = self.level}
    Projectile(table.merge(t1, mods or {}))
    Projectile(table.merge(t2, mods or {}))
    self.dg_counter = self.dg_counter + 1
    if self.dg_counter == 5 and self.level == 3 then
      self.dg_counter = 0
      self.t:every(0.1, function()
        local random_enemy = self:get_random_object_in_shape(self.attack_sensor, main.current.enemies)
        if random_enemy then
          _G[random:table{'gun_kata1', 'gun_kata2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.35}
          camera:spring_shake(2, r)
          self.hfx:use('shoot', 0.25)
          local r = self:angle_to_object(random_enemy)
          HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r) + 4*math.cos(r - math.pi/2), y = self.y + 0.8*self.shape.w*math.sin(r) + 4*math.sin(r - math.pi/2), rs = 6}
          local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 300, r = r, color = self.color, dmg = self.dmg, character = self.character,
            parent = self, level = self.level}
          Projectile(table.merge(t, mods or {}))
        end
      end, 20)
    end
  else
    HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
    local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 250, r = r, color = self.color, dmg = self.dmg*dmg_m, crit = crit, character = self.character,
    parent = self, level = self.level}
    Projectile(table.merge(t, mods or {}))
  end

  if self.character == 'vagrant' or self.character == 'artificer' then
    shoot1:play{pitch = random:float(0.95, 1.05), volume = 0.2}
  elseif self.character == 'dual_gunner' then
    dual_gunner1:play{pitch = random:float(0.95, 1.05), volume = 0.3}
    dual_gunner2:play{pitch = random:float(0.95, 1.05), volume = 0.3}
  elseif self.character == 'archer' or self.character == 'hunter' or self.character == 'barrager' or self.character == 'corruptor' or self.character == 'sniper' then
    archer1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
  elseif self.character == 'wizard' or self.character == 'lich' or self.character == 'arcanist' then
    wizard1:play{pitch = random:float(0.95, 1.05), volume = 0.15}
  elseif self.character == 'scout' or self.character == 'outlaw' or self.character == 'blade' or self.character == 'spellblade' or self.character == 'jester' or self.character == 'assassin' or self.character == 'beastmaster' or
         self.character == 'thief' then
    _G[random:table{'scout1', 'scout2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    if self.character == 'spellblade' then
      wizard1:play{pitch = random:float(0.95, 1.05), volume = 0.15}
    end
  elseif self.character == 'cannoneer' then
    _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  end

  if self.character == 'lich' then
    frost1:play{pitch = random:float(0.95, 1.05), volume = 0.3}
  end

  if self.character == 'arcanist' then
    arcane1:play{pitch = random:float(0.95, 1.05), volume = 0.3}
  end

  if self.chance_to_barrage and random:bool(self.chance_to_barrage) then
    self:barrage(r, 3)
  end
  
]]--
end



function Player:attack(area, mods)
  
--[[
  mods = mods or {}
  camera:shake(2, 0.5)
  self.hfx:use('shoot', 0.25)
  local t = {group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(area or 64), color = self.color, dmg = self.area_dmg_m*self.dmg,
    character = self.character, level = self.level, parent = self}
  Area(table.merge(t, mods))

  if self.character == 'swordsman' or self.character == 'barbarian' or self.character == 'juggernaut' or self.character == 'highlander' then
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  elseif self.character == 'elementor' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
  elseif self.character == 'psychic' then
    psychic1:play{pitch = random:float(0.9, 1.1), volume = 0.4}
  elseif self.character == 'launcher' then
    buff1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
  end

  if self.character == 'juggernaut' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
  end
]]--
end


function Player:dot_attack(area, mods)
  --[[
  mods = mods or {}
  camera:shake(2, 0.5)
  self.hfx:use('shoot', 0.25)
  local t = {group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, rs = self.area_size_m*(area or 64), color = self.color, dmg = self.area_dmg_m*self.dmg*(self.dot_dmg_m or 1),
    character = self.character, level = self.level, parent = self}
  DotArea(table.merge(t, mods))

  dot1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
end


function Player:barrage(r, n, pierce, ricochet, shoot_5, homing)
  n = n or 8
  for i = 1, n do
    self.t:after((i-1)*0.075, function()
      if shoot_5 then archer1:play{pitch = random:float(0.95, 1.05), volume = 0.2}
      else archer1:play{pitch = random:float(0.95, 1.05), volume = 0.35} end
      HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
      local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 250, r = r + random:float(-math.pi/16, math.pi/16), color = self.color, dmg = self.dmg,
      parent = self, character = 'barrage', level = self.level, pierce = pierce or 0, ricochet = ricochet or 0, shoot_5 = shoot_5, homing = homing}
      Projectile(table.merge(t, mods or {}))
    end)
  end
  
]]--
end




Projectile = Object:extend()
Projectile:implement(GameObject)
Projectile:implement(Physics)
function Projectile:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self.hfx:add('hit', 1)
  self:set_as_rectangle(10, 4, 'dynamic', 'projectile')
  self.pierce = args.pierce or 0
  self.chain = args.chain or 0
  self.ricochet = args.ricochet or 0
  self.chain_enemies_hit = {}
  self.infused_enemies_hit = {}

  if self.character == 'sage' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    self.compression_dmg = self.dmg
    self.dmg = 0
    self.pull_sensor = Circle(self.x, self.y, 64*self.parent.area_size_m)
    self.rs = 0
    self.t:tween(0.05, self, {rs = self.shape.w/2.5}, math.cubic_in_out, function() self.spring:pull(0.15) end)
    self.t:after(4, function()
      self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function()
        self:die()
        if self.level == 3 then
          _G[random:table{'saboteur_hit1', 'saboteur_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.2}
          magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
          local enemies = self:get_objects_in_shape(self.pull_sensor, main.current.enemies)
          for _, enemy in ipairs(enemies) do
            enemy:hit(3*self.compression_dmg)
          end
        end
      end)
    end)

    self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
    self.t:every(0.08, function()
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
    end)
    self.vr = 0
    self.dvr = random:float(-math.pi/4, math.pi/4)

  elseif self.character == 'spellblade' then
    if self.level == 3 then
      self.v = 1.5*self.v
      self.pierce = 1000
      self.orbit_r = 0
      self.orbit_vr = 12*math.pi
      self.t:tween(6.25, self, {orbit_vr = 4*math.pi}, math.expo_out, function()
        self.t:tween(12.25, self, {orbit_vr = 0}, math.linear)
      end)
    else
      self.pierce = 1000
      self.orbit_r = 0
      self.orbit_vr = 8*math.pi
      self.t:tween(6.25, self, {orbit_vr = math.pi}, math.expo_out, function()
        self.t:tween(12.25, self, {orbit_vr = 0}, math.linear)
      end)
    end

  elseif self.character == 'psyker' then
    self.pierce = 10000
    self.orbit_distance = random:float(56, 64)
    self.orbit_speed = random:float(2, 4)*((self.parent.orbitism == 1 and 1.25) or (self.parent.orbitism == 2 and 1.50) or (self.parent.orbitism == 3 and 1.75) or 1)*(1/self.parent.aspd_m)
    self.orbit_offset = random:float(0, 2*math.pi)
    self.dmg = self.dmg*((self.parent.psychosink == 1 and 1.4) or (self.parent.psychosink == 2 and 1.8) or (self.parent.psychosink == 3 and 2.2) or 1)

  elseif self.character == 'lich' then
    self.spring:pull(0.15)
    self.t:every(0.08, function()
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
    end)

  elseif self.character == 'arcanist' then
    self.dmg = 0.2*self.dmg
    self.t:every(0.08, function() HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color, r = self.r + math.pi + random:float(-math.pi/6, math.pi/6), v = random:float(10, 25), parent = self} end)
    self.t:every(self.parent.level == 3 and 0.54 or 0.8, function()
      local enemies = table.head(self:get_objects_in_shape(Circle(self.x, self.y, 128), main.current.enemies), self.level == 3 and 2 or 1)
      for _, enemy in ipairs(enemies) do
        arcane2:play{pitch = random:float(0.7, 1.3), volume = 0.15}
        self.hfx:use('hit', 0.5)
        local r = self:angle_to_object(enemy)
        local t = {group = main.current.main, x = self.x + 8*math.cos(r), y = self.y + 8*math.sin(r), v = 250, r = r, color = self.parent.color, dmg = self.parent.dmg, pierce = 2, character = 'arcanist_projectile',
        parent = self.parent, level = self.parent.level}
        local check_circle = Circle(t.x, t.y, 2)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Player, Enemy, EnemyCritter, Critter, Sentry, Volcano, Saboteur, Bomb, Pet, Turret, Automaton})
        if #objects == 0 then Projectile(table.merge(t, mods or {})) end
      end
    end)

  elseif self.character == 'witch' and self.level == 3 then
    self.chain = 1

  elseif self.character == 'miner' then
    self.homing = true
    if self.level == 3 then
      self.pierce = 2
    end
  end

  if self.parent.divine_machine_arrow and self.class == 'ranger' then
    if random:bool((self.parent.divine_machine_arrow == 1 and 10) or (self.parent.divine_machine_arrow == 2 and 20) or (self.parent.divine_machine_arrow == 3 and 30)) then
      self.homing = true
      self.pierce = self.parent.divine_machine_arrow or 0
    end
  end

  if self.homing then
    self.homing = false
    self.t:after(0.1, function()
      self.homing = true
      self.closest_sensor = Circle(self.x, self.y, 64)
    end)
  end

  self.distance_travelled = 0
  self.distance_dmg_m = 1

  if self.parent.blunt_arrow and self.class == 'ranger' then
    if random:bool((self.parent.blunt_arrow == 1 and 10) or (self.parent.blunt_arrow == 2 and 20) or (self.parent.blunt_arrow == 3 and 30)) then
      self.knockback = 10
    end
  end

  if self.parent.flying_daggers and self.class == 'rogue' then
    self.chain = self.chain + ((self.parent.flying_daggers == 1 and 2) or (self.parent.flying_daggers == 2 and 3) or (self.parent.flying_daggers == 3 and 4))
  end
end


function Projectile:update(dt)
  self:update_game_object(dt)

  if self.character == 'psyker' then
    if self.parent.dead then self.dead = true; self.parent = nil; return end
    self:set_position(self.parent.x + self.orbit_distance*math.cos(self.orbit_speed*main.current.t.time + self.orbit_offset),
      self.parent.y + self.orbit_distance*math.sin(self.orbit_speed*main.current.t.time + self.orbit_offset))
    local dx, dy = self.x - (self.previous_x or 0), self.y - (self.previous_y or 0)
    self.r = Vector(dx, dy):angle()
    self:set_angle(self.r)
    self.previous_x, self.previous_y = self.x, self.y
    return
  end

  if self.character == 'spellblade' then
    self.orbit_r = self.orbit_r + self.orbit_vr*dt
  end

  if self.homing then
    self.closest_sensor:move_to(self.x, self.y)
    local target = self:get_closest_object_in_shape(self.closest_sensor, main.current.enemies)
    if target then
      self:rotate_towards_object(target, 0.1)
      self.r = self:get_angle()
      self:move_along_angle(self.v, self.r + (self.orbit_r or 0))
    else
      self:set_angle(self.r)
      self:move_along_angle(self.v, self.r + (self.orbit_r or 0))
    end
  else
    self:set_angle(self.r)
    self:move_along_angle(self.v, self.r + (self.orbit_r or 0))
  end

  if self.character == 'sage' then
    self.pull_sensor:move_to(self.x, self.y)
    local enemies = self:get_objects_in_shape(self.pull_sensor, main.current.enemies)
    for _, enemy in ipairs(enemies) do
      enemy:apply_steering_force(math.remap(self:distance_to_object(enemy), 0, 100, 250, 50), enemy:angle_to_object(self))
    end
    self.vr = self.vr + self.dvr*dt
  end

  --[[
  if self.parent.point_blank or self.parent.longshot then
    self.distance_travelled = self.distance_travelled + math.length(self:get_velocity())
    if self.parent.point_blank and self.parent.longshot then
      self.distance_dmg_m = 1
    elseif self.parent.point_blank then
      self.distance_dmg_m = math.remap(self.distance_travelled, 0, 15000, 2, 0.75)
    elseif self.parent.longshot then
      self.distance_dmg_m = math.remap(self.distance_travelled, 0, 15000, 0.75, 2)
    end
  end
  ]]--
end


function Projectile:draw()
  if self.character == 'sage' then
    if self.hidden then return end

    graphics.push(self.x, self.y, self.r + self.vr, self.spring.x, self.spring.x)
      graphics.circle(self.x, self.y, self.rs + random:float(-1, 1), self.color)
      graphics.circle(self.x, self.y, self.pull_sensor.rs, self.color_transparent)
      local lw = math.remap(self.pull_sensor.rs, 32, 256, 2, 4)
      for i = 1, 4 do graphics.arc('open', self.x, self.y, self.pull_sensor.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
    graphics.pop()

  elseif self.character == 'lich' then
    graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
      graphics.circle(self.x, self.y, 3 + random:float(-1, 1), self.color)
    graphics.pop()

  elseif self.character == 'arcanist' then
    graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
      graphics.circle(self.x, self.y, 4, self.hfx.hit.f and fg[0] or self.color)
    graphics.pop()

  elseif self.character == 'psyker' then
    graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
      graphics.circle(self.x, self.y, 2.5, self.hfx.hit.f and fg[0] or self.color)
    graphics.pop()

  else
    graphics.push(self.x, self.y, self.r + (self.orbit_r or 0))
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.color)
    graphics.pop()
  end
end


function Projectile:die(x, y, r, n)
  if self.dead then return end
  x = x or self.x
  y = y or self.y
  n = n or random:int(3, 4)
  for i = 1, n do HitParticle{group = main.current.effects, x = x, y = y, r = random:float(0, 2*math.pi), color = self.color} end
  HitCircle{group = main.current.effects, x = x, y = y}:scale_down()
  self.dead = true

  if self.character == 'wizard' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*24, color = self.color, dmg = self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  elseif self.character == 'cannon' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*32, color = self.color, dmg = self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  elseif self.character == 'blade' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*64, color = self.color, dmg = self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  elseif self.character == 'cannoneer' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*96, color = self.color, dmg = 2*self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
    if self.level == 3 then
      self.parent.t:every(0.3, function()
        _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        Area{group = main.current.effects, x = self.x + random:float(-32, 32), y = self.y + random:float(-32, 32), r = self.r + random:float(0, 2*math.pi), w = self.parent.area_size_m*48, color = self.color, 
          dmg = 0.5*self.parent.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self, void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
      end, 7)
    end
  end
end


function Projectile:on_collision_enter(other, contact)
  local x, y = contact:getPositions()
  local nx, ny = contact:getNormal()
  local r = 0
  if nx == 0 and ny == -1 then r = -math.pi/2
  elseif nx == 0 and ny == 1 then r = math.pi/2
  elseif nx == -1 and ny == 0 then r = math.pi
  else r = 0 end

  if other:is(Wall) then
    if self.character == 'archer' or self.character == 'hunter' or self.character == 'barrage' or self.character == 'barrager' or self.character == 'sentry' then
      if self.ricochet <= 0 then
        self:die(x, y, r, 0)
        WallArrow{group = main.current.main, x = x, y = y, r = self.r, color = self.color}
      else
        local r = Unit.bounce(self, nx, ny)
        self.r = r
        self.ricochet = self.ricochet - 1
      end
      _G[random:table{'arrow_hit_wall1', 'arrow_hit_wall2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.2}
    elseif self.character == 'scout' or self.character == 'outlaw' or self.character == 'blade' or self.character == 'spellblade' or self.character == 'jester' or self.character == 'beastmaster' or self.character == 'witch' or
           self.character == 'thief' then
      self:die(x, y, r, 0)
      knife_hit_wall1:play{pitch = random:float(0.9, 1.1), volume = 0.2}
      local r = Unit.bounce(self, nx, ny)
      self.parent.t:after(0.01, function()
        WallKnife{group = main.current.main, x = x, y = y, r = r, v = self.v*0.1, color = self.color}
      end)
      if self.character == 'spellblade' then
        magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
      end
    elseif self.character == 'artificer_death' then
      if self.ricochet <= 0 then
        self:die(x, y, r, random:int(2, 3))
        magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
      else
        local r = Unit.bounce(self, nx, ny)
        self.r = r
        self.ricochet = self.ricochet - 1
      end
    elseif self.character == 'wizard' or self.character == 'lich' or self.character == 'arcanist' or self.character == 'arcanist_projectile' or self.character == 'witch' then
      self:die(x, y, r, random:int(2, 3))
      magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
    elseif self.character == 'cannoneer' then
      self:die(x, y, r, random:int(2, 3))
      cannon_hit_wall1:play{pitch = random:float(0.95, 1.05), volume = 0.1}
    elseif self.character == 'engineer' or self.character == 'dual_gunner' or self.character == 'miner' then
      self:die(x, y, r, random:int(2, 3))
      _G[random:table{'turret_hit_wall1', 'turret_hit_wall2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.2}
    elseif self.character == 'psyker' then
    else
      self:die(x, y, r, random:int(2, 3))
      proj_hit_wall1:play{pitch = random:float(0.9, 1.1), volume = 0.2}
    end
  end
end


function Projectile:on_trigger_enter(other, contact)
  if self.character == 'sage' then return end

  if table.any(main.current.enemies, function(v) return other:is(v) end) then
    if self.pierce <= 0 and self.chain <= 0 then
      self:die(self.x, self.y, nil, random:int(2, 3))
    else
      if self.pierce > 0 then
        self.pierce = self.pierce - 1
      end
      if self.chain > 0 then
        self.chain = self.chain - 1
        table.insert(self.chain_enemies_hit, other)
        local object = self:get_random_object_in_shape(Circle(self.x, self.y, 48), main.current.enemies, self.chain_enemies_hit)
        if object then
          self.r = self:angle_to_object(object)
          if self.character == 'lich' then
            self.v = self.v*1.1
            if self.level == 3 then
              object:slow(0.2, 2)
            end
          else
            self.v = self.v*1.25
          end
          if self.level == 3 and self.character == 'scout' then
            self.dmg = self.dmg*1.25
          end
          if self.parent.ultimatum then
            self.dmg = self.dmg*((self.parent.ultimatum == 1 and 1.1) or (self.parent.ultimatum == 2 and 1.2) or (self.parent.ultimatum == 3 and 1.3))
          end
        end
      end
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = fg[0], duration = 0.1}
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = other.color}
    end

    if self.character == 'archer' or self.character == 'scout' or self.character == 'outlaw' or self.character == 'blade' or self.character == 'hunter' or self.character == 'spellblade' or self.character == 'engineer' or
    self.character == 'jester' or self.character == 'assassin' or self.character == 'barrager' or self.character == 'beastmaster' or self.character == 'witch' or self.character == 'miner' or self.character == 'thief' or 
    self.character == 'psyker' or self.character == 'sentry' then
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
      if self.character == 'spellblade' or self.character == 'psyker' then
        magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.15}
      end
    elseif self.character == 'wizard' or self.character == 'lich' or self.character == 'arcanist' then
      magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.15}
    elseif self.character == 'arcanist_projectile' then
      magic_area1:play{pitch = random:float(0.95, 1.05), volume = 0.075}
    else
      hit3:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    end

    other:hit(self.dmg*(self.distance_dmg_m or 1), self)

    if self.character == 'wizard' and self.level == 3 then
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*32, color = self.color, dmg = self.parent.area_dmg_m*self.dmg, character = self.character, parent = self,
        void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
    end

    if self.character == 'hunter' and random:bool(40) then
      trigger:after(0.01, function()
        if self.level == 3 then
          local r = self.parent:angle_to_object(other)
          SpawnEffect{group = main.current.effects, x = self.parent.x, y = self.parent.y, color = green[0], action = function(x, y)
            Pet{group = main.current.main, x = x, y = y, r = r, v = 150, parent = self.parent, conjurer_buff_m = self.conjurer_buff_m or 1}
            Pet{group = main.current.main, x = x + 12*math.cos(r + math.pi/2), y = y + 12*math.sin(r + math.pi/2), r = r, v = 150, parent = self.parent, conjurer_buff_m = self.conjurer_buff_m or 1}
            Pet{group = main.current.main, x = x + 12*math.cos(r - math.pi/2), y = y + 12*math.sin(r - math.pi/2), r = r, v = 150, parent = self.parent, conjurer_buff_m = self.conjurer_buff_m or 1}
          end}
        else
          SpawnEffect{group = main.current.effects, x = self.parent.x, y = self.parent.y, color = orange[0], action = function(x, y)
            Pet{group = main.current.main, x = x, y = y, r = self.parent:angle_to_object(other), v = 150, parent = self.parent, conjurer_buff_m = self.conjurer_buff_m or 1}
          end}
        end
      end)
    end

    if self.character == 'assassin' then
      other:apply_dot((self.crit and 4*self.dmg or self.dmg/2)*(self.dot_dmg_m or 1)*(main.current.chronomancer_dot or 1), 3)
    end

    if self.parent and self.parent.chain_infused then
      local units = self.parent:get_all_units()
      local stormweaver_level = 0
      for _, unit in ipairs(units) do
        if unit.character == 'stormweaver' then
          stormweaver_level = unit.level
          break
        end
      end
      local src = other
      for i = 1, 2 + (stormweaver_level == 3 and 2 or 0) do
        _G[random:table{'spark1', 'spark2', 'spark3'}]:play{pitch = random:float(0.9, 1.1), volume = 0.3}
        table.insert(self.infused_enemies_hit, src)
        local dst = src:get_random_object_in_shape(Circle(src.x, src.y, (stormweaver_level == 3 and 128 or 64)), main.current.enemies, self.infused_enemies_hit)
        if dst then
          dst:hit(0.2*self.dmg*(self.distance_dmg_m or 1))
          LightningLine{group = main.current.effects, src = src, dst = dst}
          src = dst 
        end
      end
    end

    if self.parent and self.parent.lightning_strike then
      if random:bool((self.parent.lightning_strike == 1 and 5) or (self.parent.lightning_strike == 2 and 10) or (self.parent.lightning_strike == 3 and 15)) then
        local src = other
        for j = 1, 3 do
          main.current.t:after((j-1)*0.1, function()
            if not self.parent then return end
            _G[random:table{'spark1', 'spark2', 'spark3'}]:play{pitch = random:float(0.9, 1.1), volume = 0.3}
            for i = 1, 3 do
              table.insert(self.infused_enemies_hit, src)
              local dst = src:get_random_object_in_shape(Circle(src.x, src.y, 64), main.current.enemies, self.infused_enemies_hit)
              if dst then
                dst:hit(0.33*((self.parent.lightning_strike == 1 and 0.6) or (self.parent.lightning_strike == 2 and 0.8) or (self.parent.lightning_strike == 3 and 1))*self.dmg*(self.distance_dmg_m or 1))
                LightningLine{group = main.current.effects, src = src, dst = dst}
                src = dst 
              end
            end
          end)
        end
      end
    end

    if self.crit then
      --camera:shake(5, 0.25)
      rogue_crit1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      rogue_crit2:play{pitch = random:float(0.95, 1.05), volume = 0.15}
      for i = 1, 3 do HitParticle{group = main.current.effects, x = other.x, y = other.y, color = self.color, v = random:float(100, 400)} end
      for i = 1, 3 do HitParticle{group = main.current.effects, x = other.x, y = other.y, color = other.color, v = random:float(100, 400)} end
      HitCircle{group = main.current.effects, x = other.x, y = other.y, rs = 12, color = fg[0], duration = 0.3}:scale_down():change_color(0.5, self.color)
    end

    if self.knockback then
      other:push(self.knockback*(self.knockback_m or 1), self.r)
    end

    if self.parent and self.parent.explosive_arrow and self.class == 'ranger' then
      if random:bool((self.parent.explosive_arrow == 1 and 10) or (self.parent.explosive_arrow == 2 and 20) or (self.parent.explosive_arrow == 3 and 30)) then
        _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        Area{group = main.current.effects, x = self.x, y = self.y, r = self.r + random:float(0, 2*math.pi), w = self.parent.area_size_m*32, color = self.color, 
          dmg = ((self.parent.explosive_arrow == 1 and 0.1) or (self.parent.explosive_arrow == 2 and 0.2) or (self.parent.explosive_arrow == 3 and 0.3))*self.parent.area_dmg_m*self.dmg, character = self.character,
          level = self.level, parent = self, void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
      end
    end

    if self.parent and self.parent.void_rift and self.class == 'mage' then
      if random:bool(20) then
        DotArea{group = main.current.effects, x = self.x, y = self.y, rs = self.parent.area_size_m*24, color = self.color, dmg = self.parent.area_dmg_m*self.dmg*(self.parent.dot_dmg_m or 1), void_rift = true, duration = 1}
      end
    end
  end
end




Area = Object:extend()
Area:implement(GameObject)
function Area:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, 1.5*self.w, 1.5*self.w, self.r)
  local targets = {}
  if self.team == "enemy" then 
    targets = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  else
    targets = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
  end
  for _, target in ipairs(targets) do
    if self.character == 'freezing_field' then
      --make slow for troops as well
      target:slow(0.5, 2)
    else
      target:hit(self.dmg, self)
    end
    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
    hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}

  end

  local flashFactor = self.dmg / 30

  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.w = 0
  self.hidden = false
  self.t:tween(0.05, self, {w = args.w}, math.cubic_in_out, function() self.spring:pull(0.15 * flashFactor) end)
  self.t:after(0.2, function()
    self.color = args.color
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end


function Area:update(dt)
  self:update_game_object(dt)
end


function Area:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
  local flashFactor = self.dmg / 30
  local w = self.w/2
  local w10 = self.w/10
  local x1, y1 = self.x - w, self.y - w
  local x2, y2 = self.x + w, self.y + w
  local lw = math.remap(w, 32, 256, 2, 4)
  graphics.polyline(self.color, lw, x1, y1 + w10, x1, y1, x1 + w10, y1)
  graphics.polyline(self.color, lw, x2 - w10, y1, x2, y1, x2, y1 + w10)
  graphics.polyline(self.color, lw, x2 - w10, y2, x2, y2, x2, y2 - w10)
  graphics.polyline(self.color, lw, x1, y2 - w10, x1, y2, x1 + w10, y2)
  graphics.rectangle((x1+x2)/2, (y1+y2)/2, x2-x1, y2-y1, nil, nil, self.color_transparent)
  graphics.rectangle((x1+x2)/2, (y1+y2)/2, x2-x1, y2-y1, nil, nil, self.color, 1 * flashFactor)
  graphics.pop()
end




DotArea = Object:extend()
DotArea:implement(GameObject)
DotArea:implement(Physics)
function DotArea:init(args)
  self:init_game_object(args)
  self:make_shape()

  self.closest_sensor = Circle(self.x, self.y, 128)

  if not self.character or self.character == 'base' then
    self.t:every(0.2, function()
      local targets = {}
      if self.team == 'enemy' then
        targets = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
      else
        targets = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      end
      for _, target in ipairs(targets) do
        target:hit(self.dmg/5, self, true)
        HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
      end
    end, nil, nil, 'dot')
  
  elseif self.character == 'wizard' then
    self.t:every(0.2, function()
    local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
    if #enemies > 0 then self.spring:pull(0.05, 200, 10) end
    for _, enemy in ipairs(enemies) do
      enemy:hit(self.dmg/5, self, true)
      enemy:slow(0.8, 1)
      HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
      for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = self.color} end
      for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
    end
    end, nil, nil, 'dot')
end

  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.18)
  self.rs = 0
  self.hidden = false
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function() self.color = args.color end)
  if self.duration and self.duration > 0.5 then
    self.t:after(self.duration - 0.35, function()
      self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
    end)
  end

  self.vr = 0
  self.dvr = random:float(-math.pi/4, math.pi/4)

  if self.void_rift then
    self.dvr = random:table{random:float(-4*math.pi, -2*math.pi), random:float(2*math.pi, 4*math.pi)}
  end
end

function DotArea:make_shape()
  if self.area_type == 'circle' or not self.area_type then
    self.shape = Circle(self.x, self.y, self.rs)
  elseif self.area_type == 'triangle' then
    self.shape = Polygon(self.caster:make_triangle_from_origin(math.pi / 4, self.rs))
    self.shape:move_to(((self.shape.x2 - self.shape.x1) / 2) + self.shape.x1, ((self.shape.y2 - self.shape.y1) / 2) + self.shape.y1)
    self.x, self.y = self.shape.x, self.shape.y
  else
    error('dot area shape type ' .. self.area_type .. ' not found')
  end
end


function DotArea:update(dt)
  self:update_game_object(dt)

  if self.caster and self.follows_caster then
    self:make_shape()
  end

  self.t:set_every_multiplier('dot', (main.current.chronomancer_dot or 1))
  self.vr = self.vr + self.dvr*dt

  if self.parent then
    if (self.character == 'plague_doctor' and self.level == 3 and not self.plague_doctor_unmovable) or self.character == 'cryomancer' or self.character == 'pyromancer' then
      self.x, self.y = self.parent.x, self.parent.y
      self.shape:move_to(self.x, self.y)
    end
  end

  if self.character == 'witch' then
    self.x, self.y = self.x + self.v*math.cos(self.r)*dt, self.y + self.v*math.sin(self.r)*dt
    if self.x >= main.current.x2 - self.shape.rs/2 or self.x <= main.current.x1 + self.shape.rs/2 then
      self.r = math.pi - self.r
    end
    if self.y >= main.current.y2 - self.shape.rs/2 or self.y <= main.current.y1 + self.shape.rs/2 then
      self.r = 2*math.pi - self.r
    end
    self.shape:move_to(self.x, self.y)
  end
end


function DotArea:draw()
  if self.hidden then return end

  --graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
    if self.area_type == 'circle' or not self.area_type then
      graphics.circle(self.x, self.y, self.shape.rs, self.color_transparent)
    elseif self.area_type == 'triangle' then
      graphics.polygon(self.shape.vertices, self.color_transparent)
    else
      error('dot area shape ' .. self.area_type .. 'not found')
    end
    --local lw = math.remap(self.shape.rs, 32, 256, 2, 4)
    --for i = 1, 4 do graphics.arc('open', self.x, self.y, self.shape.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
  --graphics.pop()
end


function DotArea:scale(v)
  self.shape = Circle(self.x, self.y, (v or 1)*self.rs)
end




ForceArea = Object:extend()
ForceArea:implement(GameObject)
ForceArea:implement(Physics)
function ForceArea:init(args)
  self:init_game_object(args)
  self.shape = Circle(self.x, self.y, self.rs)
  
  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.rs = 0
  self.hidden = false
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function() self.color = args.color end)

  self.vr = 0
  self.dvr = random:table{random:float(-6*math.pi, -4*math.pi), random:float(4*math.pi, 6*math.pi)}

  if self.character == 'psykino' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    self.t:tween(2, self, {dvr = 0}, math.linear)

    self.t:during(2, function()
      local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      local t = self.t:get_during_elapsed_time('psykino')
      for _, enemy in ipairs(enemies) do
        enemy:apply_steering_force(600*(1-t), enemy:point_to_angle(self.x, self.y))
      end
    end, nil, 'psykino')
    self.t:after(2 - 0.35, function()
      self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
      if self.level == 3 then
        elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
        local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
        for _, enemy in ipairs(enemies) do
          enemy:hit(4*self.parent.dmg)
          enemy:push(50*(self.knockback_m or 1), self:angle_to_object(enemy))
        end
      end
    end)

  elseif self.character == 'gravity_field' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.4}
    self.t:tween(1, self, {dvr = 0}, math.linear)

    self.t:during(1, function()
      local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      local t = self.t:get_during_elapsed_time('gravity_field')
      for _, enemy in ipairs(enemies) do
        enemy:apply_steering_force(400*(1-t), enemy:point_to_angle(self.x, self.y))
      end
    end, nil, 'gravity_field')
    self.t:after(1 - 0.35, function()
      self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
    end)
  end
end


function ForceArea:update(dt)
  self:update_game_object(dt)
  self.vr = self.vr + self.dvr*dt
end


function ForceArea:draw()
  if self.hidden then return end

  graphics.push(self.x, self.y, self.r + self.vr, self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, self.shape.rs, self.color_transparent)
    local lw = math.remap(self.shape.rs, 32, 256, 2, 4)
    for i = 1, 4 do graphics.arc('open', self.x, self.y, self.shape.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
  graphics.pop()
end



Tree = Object:extend()
Tree:implement(GameObject)
Tree:implement(Physics)
function Tree:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(9, 9, 'static', 'player')
  self:set_restitution(0.5)
  self.hfx:add('hit', 1)
  self.color = orange[0]
  self.heal_sensor = Circle(self.x, self.y, 48)

  self.vr = 0
  self.dvr = random:float(-math.pi/4, math.pi/4)

  buff1:play{pitch = random:float(0.95, 1.05), volume = 0.5}

  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.rs = 0
  self.hidden = false
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function() self.color = args.color end)

  self.t:every(self.parent.level == 3 and 3 or 6, function()
    self.hfx:use('hit', 0.2)
    HealingOrb{group = main.current.main, x = self.x, y = self.y}
    if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
      local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)

      if #enemies > 0 then
        for _, enemy in ipairs(enemies) do
          enemy.taunted = self
          enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
        end
      end
    end

    if self.parent.rearm then
      self.t:after(0.25, function()
        self.hfx:use('hit', 0.2)
        HealingOrb{group = main.current.main, x = self.x, y = self.y}

        if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
          local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
          if #enemies > 0 then
            for _, enemy in ipairs(enemies) do
              enemy.taunted = self
              enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
            end
          end
        end
      end)
    end
  end)

  --[[
  self.t:cooldown(3.33/(self.level == 3 and 2 or 1), function() return #self:get_objects_in_shape(self.heal_sensor, {Player}) > 0 end, function()
    local n = n or random:int(3, 4)
    for i = 1, n do HitParticle{group = main.current.effects, x = self.x, y = self.y, r = random:float(0, 2*math.pi), color = self.color} end
    heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    local units = self:get_objects_in_shape(self.heal_sensor, {Player})
    if self.level == 3 then
      local unit_1 = random:table_remove(units)
      local unit_2 = random:table_remove(units)
      if unit_1 then
        unit_1:heal(0.2*unit_1.max_hp*(self.heal_effect_m or 1))
        LightningLine{group = main.current.effects, src = self, dst = unit_1, color = green[0]}
      end
      if unit_2 then
        unit_2:heal(0.2*unit_2.max_hp*(self.heal_effect_m or 1))
        LightningLine{group = main.current.effects, src = self, dst = unit_2, color = green[0]}
      end
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = green[0], duration = 0.1}

      if self.parent.rearm then
        self.t:after(1, function()
          heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          local unit_1 = random:table_remove(units)
          local unit_2 = random:table_remove(units)
          if unit_1 then
            unit_1:heal(0.2*unit_1.max_hp*(self.heal_effect_m or 1))
            LightningLine{group = main.current.effects, src = self, dst = unit_1, color = green[0]}
          end
          if unit_2 then
            unit_2:heal(0.2*unit_2.max_hp*(self.heal_effect_m or 1))
            LightningLine{group = main.current.effects, src = self, dst = unit_2, color = green[0]}
          end
          HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = green[0], duration = 0.1}
        end)
      end

      if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
        local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
        if #enemies > 0 then
          for _, enemy in ipairs(enemies) do
            enemy.taunted = self
            enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
          end
        end
      end

    else
      local unit = random:table(units)
      unit:heal(0.2*unit.max_hp*(self.heal_effect_m or 1))
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = green[0], duration = 0.1}
      LightningLine{group = main.current.effects, src = self, dst = unit, color = green[0]}

      if self.parent.rearm then
        self.t:after(1, function()
          heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          local unit = random:table(units)
          unit:heal(0.2*unit.max_hp*(self.heal_effect_m or 1))
          HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = green[0], duration = 0.1}
          LightningLine{group = main.current.effects, src = self, dst = unit, color = green[0]}
        end)
      end

      if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
        local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
        if #enemies > 0 then
          for _, enemy in ipairs(enemies) do
            enemy.taunted = self
            enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
          end
        end
      end
    end
  end)
  ]]--

  self.t:after(12*(self.parent.conjurer_buff_m or 1), function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function()
      self.dead = true

      if self.parent.construct_instability then
        camera:shake(2, 0.5)
        local n = (self.parent.construct_instability == 1 and 1) or (self.parent.construct_instability == 2 and 1.5) or (self.parent.construct_instability == 3 and 2) or 1
        Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*48, color = self.color, dmg = n*self.parent.dmg*self.parent.area_dmg_m, parent = self.parent}
        _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      end
    end)
  end)
end


function Tree:update(dt)
  self:update_game_object(dt)
  self.vr = self.vr + self.dvr*dt
end


function Tree:draw()
  if self.hidden then return end

  graphics.push(self.x, self.y, math.pi/4, self.spring.x, self.spring.x)
    graphics.rectangle(self.x, self.y, 1.5*self.shape.w, 4, 2, 2, self.hfx.hit.f and fg[0] or self.color)
    graphics.rectangle(self.x, self.y, 4, 1.5*self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()

  graphics.push(self.x, self.y, self.r + self.vr, self.spring.x, self.spring.x)
    -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
    graphics.circle(self.x, self.y, self.heal_sensor.rs, self.color_transparent)
    local lw = math.remap(self.heal_sensor.rs, 32, 256, 2, 4)
    for i = 1, 4 do graphics.arc('open', self.x, self.y, self.heal_sensor.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
  graphics.pop()
end



ForceField = Object:extend()
ForceField:implement(GameObject)
ForceField:implement(Physics)
function ForceField:init(args)
  self:init_game_object(args)
  self:set_as_circle((self.parent and self.parent.magnify and (self.parent.magnify == 1 and 14) or (self.parent.magnify == 2 and 17) or (self.parent.magnify == 3 and 20)) or 12, 'static', 'force_field')
  self.hfx:add('hit', 1)
  
  self.color = fg[0]
  self.color_transparent = Color(yellow[0].r, yellow[0].g, yellow[0].b, 0.08)
  self.rs = 0
  self.hidden = false
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function() self.color = yellow[0] end)

  self.t:after(6, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
    dot1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  end)
end


function ForceField:update(dt)
  self:update_game_object(dt)
  if not self.parent then self.dead = true; return end
  if self.parent and self.parent.dead then self.dead = true; return end
  self:set_position(self.parent.x, self.parent.y)
end


function ForceField:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, 0, self.spring.x*self.hfx.hit.x, self.spring.x*self.hfx.hit.x)
    graphics.circle(self.x, self.y, self.shape.rs, self.hfx.hit.f and fg[0] or self.color, 2)
    graphics.circle(self.x, self.y, self.shape.rs, self.hfx.hit.f and fg_transparent[0] or self.color_transparent)
  graphics.pop()
end


function ForceField:on_collision_enter(other, contact)
  local x, y = contact:getPositions()
  if table.any(main.current.enemies, function(v) return other:is(v) end) then
    other:push(random:float(15, 20)*(self.parent.knockback_m or 1), self.parent:angle_to_object(other))
    other:hit(0)
    HitCircle{group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1}
    for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = self.color} end
    for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = other.color} end
    self.hfx:use('hit', 0.2)
    dot1:play{pitch = random:float(0.95, 1.05), volume = 0.3}
  end
end

Snipe = Object:extend()
Snipe:implement(GameObject)
Snipe:implement(Physics)
function Snipe:init(args)
  self:init_game_object(args)
  if not self.group.world then self.recover() return end

  self.color = red[0]:clone()
  self.currentTime = 0

  self.state = "charging"
  self.parent.state = 'frozen'
  sniper_load:play({volume = 0.5})
  self.t:after(1, function() self:fire() end)
  self.t:after(1.25, function() self:recover() end)

end

function Snipe:update(dt)
  if self.parent and self.parent.dead == true then self.recover() return end
  if not self.target or self.target.dead == true then self:recover() return end
  self:update_game_object(dt)
  self.currentTime = self.currentTime + dt

  self.color.a = math.min(self.currentTime, 1)

end

function Snipe:fire()
  if self then self.state = "recovering" else return end
  if self.parent then self.parent.state = 'stopped' end
  dual_gunner2:play({pitch = random:float(0.9, 1.1), volume = 0.7})
  if self.target then self.target:hit(self.dmg) end
end

function Snipe:recover()
  if self then self.dead = true else return end
  if self.parent then self.parent.state = 'normal' end
end

function Snipe:draw()
  if self.state == 'charging' and self.parent and not self.parent.dead and self.target then
    graphics.line(self.parent.x, self.parent.y, self.target.x, self.target.y, self.color, 1)
  end
end

Blizzard = Object:extend()
Blizzard:implement(GameObject)
Blizzard:implement(Physics)
function Blizzard:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:set_as_rectangle(9, 9, 'static', 'player')
  self:set_restitution(0.5)
  self.hfx:add('hit', 1)
  self.color = blue[0]

  self.vr = 0
  self.dvr = random:float(-math.pi/4, math.pi/4)

  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.rs = 0
  self.hidden = false
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function() self.color = args.color end)

  frost1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.dot_area = DotArea{group = main.current.effects, x=self.x, y=self.y, r=self.r, rs = 24, w = self.parent.area_size_m*72, color = self.color, dmg = self.parent.dmg,
    character = self.parent.character, level = self.parent.level, parent = self, duration = 2}

  self.t:after(2, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end

function Blizzard:update(dt)
  self:update_game_object(dt)
  if self.dvr then self.vr = self.vr + self.dvr*dt end
end

function Blizzard:draw()
  if self.hidden then return end
  if not self.hfx.hit then return end

  graphics.push(self.x, self.y, -math.pi/2, self.spring.x, self.spring.x)
    graphics.triangle_equilateral(self.x, self.y, 1.5*self.shape.w, self.hfx.hit.f and fg[0] or self.color, 3)
  graphics.pop()

  graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
    -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
    graphics.circle(self.x, self.y, 24, self.color_transparent)
    --local lw = 2
    --for i = 1, 4 do graphics.arc('open', self.x, self.y, 24, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
  graphics.pop()
end

BreatheFire = Object:extend()
BreatheFire:implement(GameObject)
BreatheFire:implement(Physics)
function BreatheFire:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end


  self.currentTime = 0
  self.dot_area = DotArea{follows_caster = true, area_type = 'triangle', team = self.team,
    group = main.current.effects, x = self.x, y = self.y, rs = self.rs, caster = self.parent, parent = self, dmg = self.dmg, duration = self.duration,
    color = self.color}
  self.parent.state =  unit_states['channeling']
  pyro1:play{volume=0.9}
end

function BreatheFire:update(dt)
  if not self.parent or self.parent.dead then self.dead = true end
  self.currentTime = self.currentTime + dt
  if self.currentTime > self.duration then
    self:recover()
  end
end

function BreatheFire:recover()
  self.parent.state = unit_states['normal']
  self.dead = true
end

function BreatheFire:draw()
  --happens in dotArea
end


ChainLightning = Object:extend()
ChainLightning:implement(GameObject)
ChainLightning:implement(Physics)
function ChainLightning:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end

  self.attack_sensor = Circle(self.target.x, self.target.y, self.rs)
  local total_targets = 2 + self.level

  local target_classes = nil
  if self.team == "enemy" then
    target_classes = main.current.friendlies
  else
    target_classes = main.current.enemies
  end
  
  self.targets = {self.target}
  self.i = 0

  local bounce = function()
    self.i = self.i + 1
    if #self.targets >= self.i then
      local target = self.targets[self.i]
      if not target then return end
      target:hit(self.dmg)
      spark2:play{pitch = random:float(0.8, 1.2), volume = 0.7}

      local lastTarget = nil
      local currentTarget = nil
      if self.i == 1 then
        lastTarget = self.parent
        currentTarget = self.targets[self.i]
      else
        lastTarget = self.targets[self.i-1]
        currentTarget = self.targets[self.i]
      end

      if lastTarget and currentTarget then
        LightningLine{group = main.current.effects, src = lastTarget, dst = currentTarget, color = self.color}
      end
    end
  end


  local targets_in_range = self:get_objects_in_shape(self.attack_sensor, target_classes)
  for _, target in ipairs(targets_in_range) do
    if target.id ~= self.target.id and #self.targets < total_targets then
      table.insert(self.targets, target)
    end
  end

  
  bounce()
  self.t:every(0.2, bounce, total_targets, function() self.dead = true end)

end



function ChainLightning:update(dt)
  self:update_game_object(dt)
end

function ChainLightning:draw()
end

Stomp = Object:extend()
Stomp:implement(GameObject)
Stomp:implement(Physics)
function Stomp:init(args)
  self:init_game_object(args)
  self.attack_sensor = Circle(self.x, self.y, self.rs)
  self.currentTime = 0

  self.state = "charging"

  self.parent.state = 'frozen'

  orb1:play({volume = 0.5})

  self.t:after(1, function() self:stomp() end)
  self.t:after(1 + 0.25, function() self:recover() end)

end

function Stomp:update(dt)
  if self.parent and self.parent.dead then self.dead = true; return end
  self:update_game_object(dt)
  self.attack_sensor:move_to(self.x, self.y)
  self.currentTime = self.currentTime + dt
end

function Stomp:stomp()
  if self then self.state = "recovering" else return end

  usurer1:play{pitch = random:float(0.95, 1.05), volume = 0.9}

  local targets = {}
  if self.team == 'enemy' then
    targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.friendlies)
  else
    targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies)
  end
  if #targets > 0 then self.spring:pull(0.05, 200, 10) end
  for _, target in ipairs(targets) do
    target:hit(self.dmg, self, true)
    target:slow(0.8, 1)
    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
  end
end

function Stomp:recover()
  if self then self.dead = true else return end
  if self.parent then self.parent.state = 'normal' end
end

function Stomp:draw()
  if self.hidden then return end

  if self.state == 'charging' then
    graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
      -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
      graphics.circle(self.x, self.y, self.attack_sensor.rs * math.min(self.currentTime, 1) , red_transparent)
      graphics.circle(self.x, self.y, self.attack_sensor.rs, red[0], 1)
    graphics.pop()
  end
end

Mortar = Object:extend()
Mortar:implement(GameObject)
Mortar:implement(Physics)
function Mortar:init(args)
  self:init_game_object(args)

  self.state = "charging"

  self.parent.state = 'frozen'
  local fire_speed = 0.70
  self.t:after(fire_speed, function() self:fire() end)
  self.t:after(fire_speed * 2, function() self:fire() end)
  self.t:after(fire_speed * 3, function() self:fire() end)
  self.t:after(fire_speed * 3 + 1.1, function() self:recover() end)

end

function Mortar:update(dt)
  self:update_game_object(dt)
  if self.parent and self.parent.dead then self.dead = true end
end

function Mortar:fire()
  cannoneer1:play{pitch = random:float(0.95, 1.05), volume = 0.9}
  Stomp{group = main.current.main, team = self.team, x = self.target.x + math.random(-10, 10), y = self.target.y + math.random(-10, 10), rs = self.rs, color = self.color, dmg = self.dmg, level = self.level, parent = self}
end

function Mortar:recover()
  if self then self.dead = true else return end
  if self.parent then self.parent.state = 'normal' end
end

function Mortar:draw()
end

Summon = Object:extend()
Summon:implement(GameObject)
Summon:implement(Physics)
function Summon:init(args)
  self:init_game_object(args)
  self.attack_sensor = Circle(self.x, self.y, self.rs)
  self.currentTime = 0

  self.state = "charging"

  self.parent.state = 'frozen'

  self.summonTime = 3
  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.t:after(self.summonTime, function() self:spawn() end)

end

function Summon:update(dt)
  if self.parent and self.parent.dead then self.dead = true; return end
  self:update_game_object(dt)
  self.x = self.parent.x
  self.y = self.parent.y
  self.currentTime = self.currentTime + dt
end

function Summon:spawn()
  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  spawn1:play{pitch = random:float(0.8, 1.2), volume = 0.15}
  if self.parent.summons < 4 then
    self.parent.summons = self.parent.summons + 1
    local args ={group = main.current.main, x= self.x + 10, y = self.y, level = self.level, parent = self.parent}
    Enemy{type = 'rager', group = main.current.main, x= self.x + 10, y = self.y, level = self.level, parent = self.parent}
  end
  self:recover()
end

function Summon:recover()
  self.state = 'recovering'
  if self and self.parent then self.parent.state = 'normal' end
  if self then self.dead = true end
end

function Summon:draw()
  if self.hidden then return end

  if self.state == 'charging' then
    graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
      -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
      graphics.circle(self.x, self.y, self.attack_sensor.rs * math.min(self.currentTime / 3, 1) , purple_transparent)
      graphics.circle(self.x, self.y, self.attack_sensor.rs, purple[0], 1)
    graphics.pop()
  end

end



Vanish = Object:extend()
Vanish:implement(GameObject)
Vanish:implement(Physics)
function Vanish:init(args)
  self:init_game_object(args)
  self.currentTime = 0

  self.state = "charging"

  self.parent.state = 'frozen'

  self.invulnTime = 0.25
  self.vanishTime = 0.5
  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.t:after(self.invulnTime, function() self.parent.invulnerable = true end)
  self.t:after(self.vanishTime, function() self:teleport() end)

end

function Vanish:update(dt)
  if self.parent and self.parent.dead then self.dead = true; return end
  self:update_game_object(dt)
  self.x = self.parent.x
  self.y = self.parent.y
  self.currentTime = self.currentTime + dt
  self.parent.alpha = 1 - math.max(self.currentTime / self.vanishTime, 1)
end

function Vanish:teleport()
  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.state = "over"
  self.parent.state = 'normal'
  self.parent.invulnerable = false
  self.parent.alpha = 1
  self.parent:set_position(self.target.x - 5, self.target.y)
  self.parent:set_velocity(0, 0)
  
  self.t:after(1.5, function() self.dead = true end)
end

function Vanish:draw()
  if self.state == 'charging' then
    graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
      -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
      graphics.circle(self.x, self.y, math.min((self.currentTime / self.vanishTime), 1) * (self.parent.shape.w / 2 ), white_transparent)
    graphics.pop()

  elseif self.state == 'over' then
  end

  
end


RallyEffect = Object:extend()
RallyEffect:implement(GameObject)
function RallyEffect:init(args)
  self:init_game_object(args)

  self.max_rs = 4
  self.duration = 0.15
  self.currentTime = 0

end

function RallyEffect:update(dt)
  self:update_game_object(dt)
  self.currentTime = self.currentTime + dt
  if self.currentTime > self.duration then
    self.dead = true
  end

end

function RallyEffect:draw()
  graphics.push(self.x, self.y)
  graphics.circle(self.x, self.y, math.min((self.currentTime / self.duration), 1) * self.max_rs, yellow[0], 1)
  graphics.pop()
end

RallyCircle = Object:extend()
RallyCircle:implement(GameObject)
function RallyCircle:init(args)
  self:init_game_object(args)
  self.rs = 2

end

function RallyCircle:update(dt)
  self:update_game_object(dt)
  local mx, my = self.camera:get_mouse_position()
  self.x = mx
  self.y = my
end

function RallyCircle:draw()
  if not self.hidden then
    graphics.push(self.x, self.y)
    graphics.circle(self.x, self.y, self.rs, yellow[0])
    graphics.pop()
  end
  self.hidden = true
end


Volcano = Object:extend()
Volcano:implement(GameObject)
Volcano:implement(Physics)
function Volcano:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:set_as_rectangle(9, 9, 'static', 'player')
  self:set_restitution(0.5)
  self.hfx:add('hit', 1)
  self.color = orange[0]
  self.attack_sensor = Circle(self.x, self.y, 256)

  self.vr = 0
  self.dvr = random:float(-math.pi/4, math.pi/4)

  self.color = fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.rs = 0
  self.hidden = false
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function() self.spring:pull(0.15) end)
  self.t:after(0.2, function() self.color = args.color end)

  camera:shake(6, 1)
  earth1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  fire1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.t:every(self.level == 3 and 0.5 or 1, function()
    camera:shake(4, 0.5)
    _G[random:table{'earth1', 'earth2', 'earth3'}]:play{pitch = random:float(0.95, 1.05), volume = 0.25}
    _G[random:table{'fire1', 'fire2', 'fire3'}]:play{pitch = random:float(0.95, 1.05), volume = 0.25}
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*72, r = random:float(0, 2*math.pi), color = self.color, dmg = (self.parent.area_dmg_m or 1)*self.parent.dmg,
      character = self.parent.character, level = self.parent.level, parent = self, void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  end, self.level == 3 and 8 or 4)

  self.t:after(4, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end


function Volcano:update(dt)
  self:update_game_object(dt)
  if self.dvr then self.vr = self.vr + self.dvr*dt end
end


function Volcano:draw()
  if self.hidden then return end
  if not self.hfx.hit then return end

  graphics.push(self.x, self.y, -math.pi/2, self.spring.x, self.spring.x)
    graphics.triangle_equilateral(self.x, self.y, 1.5*self.shape.w, self.hfx.hit.f and fg[0] or self.color, 3)
  graphics.pop()

  graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
    -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
    graphics.circle(self.x, self.y, 24, self.color_transparent)
    local lw = 2
    for i = 1, 4 do graphics.arc('open', self.x, self.y, 24, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
  graphics.pop()
end




Sentry = Object:extend()
Sentry:implement(GameObject)
Sentry:implement(Physics)
function Sentry:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(6, 6, 'static', 'player')
  self:set_restitution(0.5)
  self.hfx:add('hit', 1)

  self.t:after(15*(self.parent.conjurer_buff_m or 1), function()
    local n = n or random:int(3, 4)
    for i = 1, n do HitParticle{group = main.current.effects, x = self.x, y = self.y, r = random:float(0, 2*math.pi), color = self.color} end
    HitCircle{group = main.current.effects, x = self.x, y = self.y}:scale_down()
    self.dead = true

    if self.parent.construct_instability then
      camera:shake(2, 0.5)
      local n = (self.parent.construct_instability == 1 and 1) or (self.parent.construct_instability == 2 and 1.5) or (self.parent.construct_instability == 3 and 2) or 1
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*48, color = self.color, dmg = n*self.parent.dmg*self.parent.area_dmg_m, parent = self.parent}
      _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    end
  end)

  self.t:every({2.75, 3.5}, function()
    self.hfx:use('hit', 0.25, 200, 10)
    local r = self.r
    local n = random:bool((main.current.ranger_level == 2 and 16) or (main.current.ranger_level == 1 and 8) or 0) and 4 or 1
    for j = 1, n do
      self.t:after((j-1)*0.1, function()
        for i = 1, 4 do
          archer1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
          HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
          local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 200, r = r, color = self.color,
          dmg = self.parent.dmg*(self.parent.conjurer_buff_m or 1), character = 'sentry', parent = self.parent, ricochet = self.parent.level == 3 and 2 or 0}
          Projectile(table.merge(t, mods or {}))
          r = r + math.pi/2
        end
      end)
    end

    if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
      local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
      if #enemies > 0 then
        for _, enemy in ipairs(enemies) do
          enemy.taunted = self
          enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
        end
      end
    end

    if self.parent.rearm then
      self.t:after(0.25, function()
        self.hfx:use('hit', 0.25, 200, 10)
        local r = self.r
        for i = 1, 4 do
          archer1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
          HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
          local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 200, r = r, color = self.color,
          dmg = self.parent.dmg*(self.parent.conjurer_buff_m or 1), character = 'sentry', parent = self.parent, ricochet = self.parent.level == 3 and 2 or 0}
          Projectile(table.merge(t, mods or {}))
          r = r + math.pi/2
        end

        if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
          local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
          if #enemies > 0 then
            for _, enemy in ipairs(enemies) do
              enemy.taunted = self
              enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
            end
          end
        end
      end)
    end
  end, nil, nil, 'attack')
end


function Sentry:update(dt)
  self:update_game_object(dt)
  self.r = self.r + math.pi*dt
  self:set_angle(self.r)
  self.t:set_every_multiplier('attack', self.parent.level == 3 and 0.75 or 1)
end


function Sentry:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
    graphics.rectangle(self.x, self.y, 2*self.shape.w, 4, 2, 2, self.hfx.hit.f and fg[0] or self.color)
    graphics.rectangle(self.x, self.y, 4, 2*self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end




Turret = Object:extend()
Turret:implement(GameObject)
Turret:implement(Physics)
function Turret:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(14, 6, 'static', 'player')
  self:set_restitution(0.5)
  self.hfx:add('hit', 1)
  self.color = orange[0]
  self.attack_sensor = Circle(self.x, self.y, 256)
  turret_deploy:play{pitch = 1.2, volume = 0.2}
  
  self.t:every({2.75, 3.5}, function()
    self.t:every({0.1, 0.2}, function()
      self.hfx:use('hit', 0.25, 200, 10)
      HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(self.r), y = self.y + 0.8*self.shape.w*math.sin(self.r), rs = 6}
      local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(self.r), y = self.y + 1.6*self.shape.w*math.sin(self.r), v = 200, r = self.r, color = self.color,
      dmg = self.parent.dmg*(self.parent.conjurer_buff_m or 1)*self.upgrade_dmg_m, character = self.parent.character, parent = self.parent}
      Projectile(table.merge(t, mods or {}))
      turret1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
      turret2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    end, 3)

    if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
      local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
      if #enemies > 0 then
        for _, enemy in ipairs(enemies) do
          enemy.taunted = self
          enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
        end
      end
    end

    if self.parent.rearm then
      self.t:after(1, function()
        self.t:every({0.1, 0.2}, function()
          self.hfx:use('hit', 0.25, 200, 10)
          HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(self.r), y = self.y + 0.8*self.shape.w*math.sin(self.r), rs = 6}
          local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(self.r), y = self.y + 1.6*self.shape.w*math.sin(self.r), v = 200, r = self.r, color = self.color,
          dmg = self.parent.dmg*(self.parent.conjurer_buff_m or 1)*self.upgrade_dmg_m, character = self.parent.character, parent = self.parent}
          Projectile(table.merge(t, mods or {}))
          turret1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
          turret2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
        end, 3)

        if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
          local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
          if #enemies > 0 then
            for _, enemy in ipairs(enemies) do
              enemy.taunted = self
              enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
            end
          end
        end
      end)
    end
  end, nil, nil, 'shoot')

  self.t:after(24*(self.parent.conjurer_buff_m or 1), function()
    local n = n or random:int(3, 4)
    for i = 1, n do HitParticle{group = main.current.effects, x = self.x, y = self.y, r = random:float(0, 2*math.pi), color = self.color} end
    HitCircle{group = main.current.effects, x = self.x, y = self.y}:scale_down()
    self.dead = true

    if self.parent.construct_instability then
      camera:shake(2, 0.5)
      local n = (self.parent.construct_instability == 1 and 1) or (self.parent.construct_instability == 2 and 1.5) or (self.parent.construct_instability == 3 and 2) or 1
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*48, color = self.color, dmg = n*self.parent.dmg*self.parent.area_dmg_m, parent = self.parent}
      _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    end
  end)
  
  self.upgrade_dmg_m = 1
  self.upgrade_aspd_m = 1
end


function Turret:update(dt)
  self:update_game_object(dt)

  self.t:set_every_multiplier('shoot', 1/self.upgrade_aspd_m)

  local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
  if closest_enemy then
    self:rotate_towards_object(closest_enemy, 0.2)
    self.r = self:get_angle()
  end
end


function Turret:draw()
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end


function Turret:upgrade()
  self.upgrade_dmg_m = self.upgrade_dmg_m + 0.5
  self.upgrade_aspd_m = self.upgrade_aspd_m + 0.5
  for i = 1, 6 do HitParticle{group = main.current.effects, x = self.x, y = self.y, r = random:float(0, 2*math.pi), color = self.color} end
  HitCircle{group = main.current.effects, x = self.x, y = self.y}:scale_down()
end




Pet = Object:extend()
Pet:implement(GameObject)
Pet:implement(Physics)
function Pet:init(args)
  self:init_game_object(args)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:set_as_rectangle(8, 8, 'dynamic', 'projectile')
  self:set_restitution(0.5)
  self.hfx:add('hit', 1)
  self.color = character_colors.hunter
  self.pierce = 6
  pet1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
  self.ricochet = 1
end


function Pet:update(dt)
  self:update_game_object(dt)

  self:set_angle(self.r)
  self:move_along_angle(self.v, self.r)
end


function Pet:draw()
  if not self.hfx.hit then return end
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end


function Pet:on_collision_enter(other, contact)
  local x, y = contact:getPositions()
  local nx, ny = contact:getNormal()
  local r = 0
  if nx == 0 and ny == -1 then r = -math.pi/2
  elseif nx == 0 and ny == 1 then r = math.pi/2
  elseif nx == -1 and ny == 0 then r = math.pi
  else r = 0 end

  if other:is(Wall) then
    local n = n or random:int(3, 4)
    for i = 1, n do HitParticle{group = main.current.effects, x = x, y = y, r = random:float(0, 2*math.pi), color = self.color} end
    HitCircle{group = main.current.effects, x = x, y = y}:scale_down()
    hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}

    if self.parent.level == 3 and self.ricochet > 0 then
      local r = Unit.bounce(self, nx, ny)
      self.r = r
      self.ricochet = self.ricochet - 1
    else
      self.dead = true

      if self.parent.construct_instability then
        camera:shake(2, 0.5)
        local n = (self.parent.construct_instability == 1 and 1) or (self.parent.construct_instability == 2 and 1.5) or (self.parent.construct_instability == 3 and 2) or 1
        Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*48, color = self.color, dmg = n*self.parent.dmg*self.parent.area_dmg_m, parent = self.parent}
        _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      end
    end
  end
end


function Pet:on_trigger_enter(other)
  if table.any(main.current.enemies, function(v) return other:is(v) end) then
    if self.pierce <= 0 then
      camera:shake(2, 0.5)
      other:hit(self.parent.dmg*(self.conjurer_buff_m or 1))
      other:push(35*(self.knockback_m or 1), self:angle_to_object(other))
      self.dead = true
      local n = random:int(3, 4)
      for i = 1, n do HitParticle{group = main.current.effects, x = x, y = y, r = random:float(0, 2*math.pi), color = self.color} end
      HitCircle{group = main.current.effects, x = x, y = y}:scale_down()
    else
      camera:shake(2, 0.5)
      other:hit(self.parent.dmg*(self.conjurer_buff_m or 1))
      other:push(35*(self.knockback_m or 1), self:angle_to_object(other))
      self.pierce = self.pierce - 1
    end
    hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    elseif self.character == 'blade' then
    self.hfx:use('hit', 0.25)
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = fg[0], duration = 0.1}
    HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color}
    HitParticle{group = main.current.effects, x = self.x, y = self.y, color = other.color}
  end
end



Bomb = Object:extend()
Bomb:implement(GameObject)
Bomb:implement(Physics)
function Bomb:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(8, 8, 'static', 'player')
  self:set_restitution(0.5)
  self.hfx:add('hit', 1)
  
  mine1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.color = orange[0]
  self.dmg = 2*get_character_stat('bomber', self.level, 'dmg')
  self.t:after(8, function() self:explode() end)
end


function Bomb:update(dt)
  self:update_game_object(dt)
end


function Bomb:draw()
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end


function Bomb:explode()
  camera:shake(4, 0.5)
  local t = {group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*64*(self.level == 3 and 2 or 1), color = self.color, 
    dmg = self.parent.area_dmg_m*self.dmg*(self.parent.conjurer_buff_m or 1)*(self.level == 3 and 2 or 1), character = self.character, parent = self.parent}
  Area(table.merge(t, mods or {}))
  if not self.parent.construct_instability and not self.parent.rearm then self.dead = true end
  _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  _G[random:table{'saboteur_hit1', 'saboteur_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  explosion1:play{pitch = random:float(0.95, 1.05), volume = 0.5}

  self.t:after(0.25, function()
    if self.parent.construct_instability then
      camera:shake(2, 0.5)
      local n = (self.parent.construct_instability == 1 and 1) or (self.parent.construct_instability == 2 and 1.5) or (self.parent.construct_instability == 3 and 2) or 1
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r + random:float(-math.pi/16, math.pi/16), w = self.parent.area_size_m*48*(self.level == 3 and 2 or 1), color = self.color, 
        dmg = n*self.parent.dmg*self.parent.area_dmg_m*(self.level == 3 and 2 or 1), parent = self.parent}
      _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      self.dead = true
    end

    if self.parent.rearm then
      camera:shake(2, 0.5)
      local n = (self.parent.construct_instability == 1 and 1) or (self.parent.construct_instability == 2 and 1.5) or (self.parent.construct_instability == 3 and 2) or 1
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r + random:float(-math.pi/16, math.pi/16), w = self.parent.area_size_m*48*(self.level == 3 and 2 or 1), color = self.color,
        dmg = n*self.parent.dmg*self.parent.area_dmg_m*(self.level == 3 and 2 or 1), parent = self.parent}
      _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      self.dead = true
    end
  end)
end


function Bomb:on_collision_enter(other, contact)
  if table.any(main.current.enemies, function(v) return other:is(v) end) then
    self:explode()
  end
end




Saboteur = Object:extend()
Saboteur:implement(GameObject)
Saboteur:implement(Physics)
Saboteur:implement(Unit)
function Saboteur:init(args)
  self:init_game_object(args)
  self:init_unit()
  self:set_as_rectangle(8, 8, 'dynamic', 'player')
  self:set_restitution(0.5)
  
  self.color = character_colors.saboteur
  self.character = 'saboteur'
  self.class = character_types.saboteur
  self:calculate_stats(true)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)

  _G[random:table{'saboteur1', 'saboteur2', 'saboteur3'}]:play{pitch = random:float(0.8, 1.2), volume = 0.2}
  self.target = random:table(self.group:get_objects_by_classes(main.current.enemies))

  self.actual_dmg = 2*get_character_stat('saboteur', self.level, 'dmg')
end


function Saboteur:update(dt)
  self:update_game_object(dt)

  self.buff_area_size_m = self.parent.buff_area_size_m
  self.buff_area_dmg_m = self.parent.buff_area_dmg_m
  self:calculate_stats()

  if not self.target then self.target = random:table(self.group:get_objects_by_classes(main.current.enemies)) end
  if self.target and self.target.dead then self.target = random:table(self.group:get_objects_by_classes(main.current.enemies)) end
  if not self.target then
    self:seek_point(gw/2, gh/2)
    self:rotate_towards_velocity(0.5)
    self.r = self:get_angle()
  else
    self:seek_point(self.target.x, self.target.y)
    self:rotate_towards_velocity(0.5)
    self.r = self:get_angle()
  end
end


function Saboteur:draw()
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end


function Saboteur:on_collision_enter(other, contact)
  if table.any(main.current.enemies, function(v) return other:is(v) end) then
    camera:shake(4, 0.5)
    local t = {group = main.current.effects, x = self.x, y = self.y, r = self.r, w = (self.crit and 1.5 or 1)*self.area_size_m*64, color = self.color, 
      dmg = (self.crit and 2 or 1)*self.area_dmg_m*self.actual_dmg*(self.conjurer_buff_m or 1), character = self.character, parent = self.parent}
    Area(table.merge(t, mods or {}))

    if self.parent.construct_instability then
      self.t:after(0.25, function()
        camera:shake(2, 0.5)
        local n = (self.parent.construct_instability == 1 and 1) or (self.parent.construct_instability == 2 and 1.5) or (self.parent.construct_instability == 3 and 2) or 1
        Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*48, color = self.color, dmg = n*self.parent.dmg*self.parent.area_dmg_m, parent = self.parent}
        _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        self.dead = true
      end)
    else
      self.dead = true
    end
  end
end


Troop = Object:extend()
Troop:implement(GameObject)
Troop:implement(Physics)
Troop:implement(Unit)
function Troop:init(args)
  self.target_rally = nil
  self.castTime = 0.3
  self.backswing = 0.2
  --buff examples...
  --self.buffs[1] = {name = buff_types['dmg'], amount = 0.2, color = red_transparent_weak}
  --self.buffs[2] = {name = buff_types['aspd'], amount = 0.2, color = green_transparent_weak}
  self.beingHealed = false
  self:init_game_object(args)
  self:init_unit()
  local level = self.level or 1
  local scaleMod = 1 + ((level - 1) / 3)
  local size = unit_size['medium'] * scaleMod
  self:set_as_rectangle(size, size,'dynamic', 'troop')
  self:set_restitution(0.5)

  self.color = character_colors[self.character]
  self.class = 'troop'
  self.type = character_types[self.character]
  self:calculate_stats(true)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)

  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 40)
  self.aggro_sensor = self.aggro_sensor or Circle(self.x, self.y, 60)
  self:set_character()

  self.state = unit_states['normal']
end

function Troop:update(dt)
  self:update_game_object(dt)
  self:update_buffs(dt)
  if self.slowed then 
    self.buff_mvspd_m = self.slowed
  else
    self.buff_mvspd_m = 1 
  end
  self:calculate_stats()

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
    if main.current and main.current.rallyEffect then
      main.current.rallyEffect.hidden = false
    end
    self.state = unit_states['following']

    self.target = nil
    self.target_pos = nil
  elseif (input["m2"].pressed and main.selectedCharacter == self.character) and (self.state == unit_states['normal'] or self.state == unit_states['stopped'] or self.state == unit_states['rallying'] or self.state == unit_states['following']) then
    self.state = unit_states['rallying']
    local mx, my = self.group.camera:get_mouse_position()
    RallyEffect{group = main.current.effects, x = mx, y = my}

    self:seek_mouse()
    self:wander(15,50,5)
    self:rotate_towards_velocity(1)

    self.target = nil
    local tx, ty = self.group.camera:get_mouse_position()
    self.target_pos = {x = tx, y = ty}
  end

  --cancel follow if no longer pressing button
  if self.state == unit_states['following'] then
    if not self:should_follow() then
      self.state = unit_states['normal']
    end
  end

  -- then do movement if rally/following
  if self.state == unit_states['following'] then
    self:seek_mouse()
    --self:steering_separate(16, {Troop})
    self:wander(15,50,5)
    self:rotate_towards_velocity(1)

  elseif self.state == unit_states['rallying'] then
    if self:distance_to_point(self.target_pos.x, self.target_pos.y) < 20 then
      self.target_pos = nil
      self.state = unit_states['normal']
    else
      self:seek_point(self.target_pos.x, self.target_pos.y)
      self:wander(15,50,5)
      self:rotate_towards_velocity(1)
    end

  --then find target if not already moving
  elseif self.state == unit_states['normal'] then
    --find target
    if self.target and self.target.dead then self.target = nil end
    if self.character == "cleric" or self.character == "paladin" or self.character == "priest" then 
      if self.target and self.target.beingHealed then self.target = nil end
    end
    if self.character == "cleric" then
      if self.target and self.target.hp == self.target.max_hp then self.target = nil end
      if not self.target then self.target = self:get_hurt_ally(self.aggro_sensor) end
    elseif self.character == "paladin" then
      if self.target and self.target.bubbled then self.target = nil end
      if self.target and (self.target.hp == self.target.max_hp) then self.target = nil end
      if not self.target then self.target = self:get_most_hurt_ally(self.aggro_sensor) end
    elseif self.character == "priest" then
      if self.target and (self.target.bubbled or self.target.shielded) then self.target = nil end
      if self.target and self.target.hp == self.target.max_hp then self.target = nil end
      if not self.target then self.target = self:get_hurt_ally_without_shield(self.aggro_sensor) end
    elseif self.character == 'druid' then
      if self.target and self.target.buffs['druid_hot'] then self.target = nil end
      if self.target and self.target.hp == self.target.max_hp then self.target = nil end
      if not self.target then self.target = self:get_most_hurt_ally(self.aggro_sensor) end
    elseif self.character == "necromancer" then
      if not self.target then self.target = self:get_closest_object_in_shape(self.aggro_sensor, {Corpse}) end
    else
      if not self.target then self.target = self:get_closest_object_in_shape(self.aggro_sensor, main.current.enemies) end
    end
    --if target not in attack range, close in
    if self.target and not self:in_range()() and self.state == unit_states['normal'] then
      self:seek_point(self.target.x, self.target.y)
      self:wander(7, 30, 5)
      --self:steering_separate(16, {Troop})
      self:rotate_towards_velocity(1)
    --otherwise target is in attack range or doesn't exist, stay still
    else
      self:set_velocity(0,0)
      self:steering_separate(8, {Troop})
    end
  else
    self:set_velocity(0,0)
  end
  
  self.r = self:get_angle()

  self.attack_sensor:move_to(self.x, self.y)
  self.aggro_sensor:move_to(self.x, self.y)
end


function Troop:draw()
  --graphics.circle(self.x, self.y, self.attack_sensor.rs, orange[0], 1)
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
  local i = 1
  for _ , buff in pairs(self.buffs) do
    graphics.circle(self.x, self.y, ((self.shape.w * 0.66) / 2) + (i), buff.color, 1)
    i = i + 1
  end
  graphics.rectangle(self.x, self.y, self.shape.w*.66, self.shape.h*.66, 3, 3, self.hfx.hit.f and fg[0] or self.color)
  if self.casting then
    self:draw_cast_timer()
  end
  if self.bubbled then 
    graphics.circle(self.x, self.y, self.shape.w, yellow_transparent_weak)
  end
  if self.shielded then
    graphics.circle(self.x, self.y, self.shape.w*0.8, white_transparent_weak)
  end
  graphics.pop()
end

function Troop:draw_cast_timer()
  local currentTime = love.timer.getTime()
  local time = currentTime - self.startedCastingAt
  local pct = time / self.castTime
  local bodySize = self.shape.rs or self.shape.w/2 or 5
  local rs = pct * bodySize
  if pct < 1 then
    graphics.circle(self.x, self.y, rs, white_transparent)
  end
end

function Troop:slow(amount, duration)
  self.slowed = amount
  self.t:after(duration, function() self.slowed = false end, 'slow')
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
  mods = mods or {}
  local t = {group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(area or 64), color = self.color, dmg = self.area_dmg_m*self.dmg,
    character = self.character, level = self.level, parent = self}
  Area(table.merge(t, mods))

  if self.character == 'swordsman'then
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  end

  if self.character == 'juggernaut' then
    elementor1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
  end

end

function Troop:bubble(duration)
  self.bubbled = true
  self.shielded = false
  self.t:after(duration, function() self.bubbled = false end)
end

function Troop:shield(amount, duration)
  self.shielded = amount
  self.t:after(duration, function() self.shielded = false end)
end

function Troop:onDeath()
  Corpse{group = main.current.main, x = self.x, y = self.y}
end



function Troop:set_character()
  if self.character == 'swordsman' then
    self.dmg = self.dmg;
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['melee'])
    self.t:cooldown(attack_speeds['fast'], self:in_range(), function()
      if self.target then
        self:attack(10, {x = self.target.x, y = self.target.y})
      end
    end, nil, nil, 'attack')

  elseif self.character == 'archer' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium'])
    self.t:cooldown(attack_speeds['ultra-fast'], self:in_range(), function()
      if self.target then
        self:shootAnimation(self:angle_to_object(self.target))
      end
    end, nil, nil, 'shoot')
  
  elseif self.character == 'laser' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium-long'])
    self.t:cooldown(attack_speeds['medium'], self:in_range(), function()
      if self.target then
        sniper_load:play{volume=0.9}
        Helper.Spell.Laser.create(Helper.Color.blue, 1, false, false, 20, self, 0, 0)
      end
    end, nil, nil, 'shoot')


  --spell tests
  --elseif self.character == 'archer' then
    --self.attack_sensor = Circle(self.x, self.y, attack_ranges['ultra-long'])
    --self.t:cooldown(3, self:in_range(), function()
      --if self.target then
        -- shoot1:play{volume=0.9}
        -- Helper.Spell.Missile.create(Helper.Color.blue, 10, false, 50, false, 20, self.x, self.y, Helper.Geometry.random_in_radius(self.target.x, self.target.y, 25))

        -- sniper_load:play{volume=0.9}
        -- Helper.Spell.SpreadMissile.create(Helper.Color.green, 20, false, 100, 30, self)

        --sniper_load:play{volume=0.9}
        --Helper.Spell.Laser.create(Helper.Color.blue, 1, false, false, 100, self, 0, 0)

        -- sniper_load:play{volume=0.9}
        -- Helper.Spell.SpreadLaser.create(Helper.Color.red, 5, false, 300, self)
      --end
    --end, nil, nil, 'shoot')

  elseif self.character == 'cannon' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['long'])
    self.t:cooldown(attack_speeds['slow'], self:in_range(), function()
      if self.target then
        self:shootAnimation(self:angle_to_object(self.target))
      end
    end, nil, nil, 'shoot')

  elseif self.character == 'sniper' then
    self.attack_sensor = Circle(self.x, self.y, attack_ranges['ultra-long'])
    self.dmg = self.dmg * 4
    self.castTime = 1
    self.backswing = 0.25
    self.t:cooldown(attack_speeds['slow'], self:in_range(), function()
      if self.target then
        Snipe{group = main.current.main, team = 'player', parent = self, target = self.target, dmg = self.dmg}
      end
    end, nil, nil, 'shoot')

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

  self.aggro_sensor = Circle(self.x, self.y, math.max(1000, 60))
end

function Troop:hit(damage, from_undead)
  if self.bubbled then return end
  if self.dead then return end
  if self.magician_invulnerable then return end
  if self.undead and not from_undead then return end

  self.hfx:use('hit', 0.25, 200, 10)
  self:show_hp()

  if self.shielded then
    if self.shielded > damage then 
      self.shielded = self.shielded - damage
      damage = 0
    else
      damage = damage - self.shielded
      self.shielded = false
    end
  end

  local actual_damage = math.max(self:calculate_damage(damage), 0)
  self.hp = self.hp - actual_damage

  camera:shake(2, 0.5)

  if self.hp > 0 then
    _G[random:table{'player_hit1', 'player_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  else
    hit4:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    for i = 1, random:int(4, 6) do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 12}:scale_down(0.3):change_color(0.5, self.color)

    self.dead = true
    if main.current:all_troops_dead() then
      main.current:die()
    end

    if self.dot_area then self.dot_area.dead = true; self.dot_area = nil end
  end
end

function Troop:on_collision_enter(other, contact)
  local x, y = contact:getPositions()

  if other:is(Wall) then
      self:bounce(contact:getNormal())
      local r = random:float(0.9, 1.1)
      player_hit_wall1:play{pitch = r, volume = 0.1}
      pop1:play{pitch = r, volume = 0.2}

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
    self.t:after(backswing, function() self.state = unit_states['normal'] end, 'castAnimationEnd')
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
      self.state = unit_states['stopped']
      self:cast()
      self.t:after(backswing, function() self.state = unit_states['normal'] end, 'castAnimationEnd')
    end, 'castAnimation')
end

function Troop:cast()
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
  local allies = self:get_objects_in_shape(sensor, {Troop})
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




Automaton = Object:extend()
Automaton:implement(GameObject)
Automaton:implement(Physics)
Automaton:implement(Unit)
function Automaton:init(args)
  self:init_game_object(args)
  self:init_unit()
  self:set_as_rectangle(8, 8, 'dynamic', 'player')
  self:set_restitution(0.5)
  
  self.color = character_colors.artificer
  self.character = 'artificer'
  self.class = 'sorcerer'
  self:calculate_stats(true)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)

  self.attack_sensor = Circle(self.x, self.y, 96)
  self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
    if closest_enemy then
      turret1:play{pitch = random:float(0.95, 1.05), volume = 0.10}
      turret2:play{pitch = random:float(0.95, 1.05), volume = 0.10}
      wizard1:play{pitch = random:float(0.95, 1.05), volume = 0.10}
      local r = self:angle_to_object(closest_enemy)
      HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
      local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 250, r = r, color = self.parent.color, dmg = self.parent.dmg, character = 'artificer',
      parent = self.parent, level = self.parent.level}
      Projectile(table.merge(t, mods or {}))
    end

    if self.parent.rearm then
      self.t:after(0.25, function()
        local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
        if closest_enemy then
          turret1:play{pitch = random:float(0.95, 1.05), volume = 0.10}
          turret2:play{pitch = random:float(0.95, 1.05), volume = 0.10}
          wizard1:play{pitch = random:float(0.95, 1.05), volume = 0.10}
          local r = self:angle_to_object(closest_enemy)
          HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
          local t = {group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), v = 250, r = r, color = self.parent.color, dmg = self.parent.dmg, character = 'artificer',
          parent = self.parent, level = self.parent.level}
          Projectile(table.merge(t, mods or {}))
        end
      end)
    end

    if self.parent.taunt and random:bool((self.parent.taunt == 1 and 10) or (self.parent.taunt == 2 and 20) or (self.parent.taunt == 3 and 30)) then
      local enemies = self:get_objects_in_shape(Circle(self.x, self.y, 96), main.current.enemies)
      if #enemies > 0 then
        for _, enemy in ipairs(enemies) do
          enemy.taunted = self
          enemy.t:after(4, function() enemy.taunted = false end, 'taunt')
        end
      end
    end
  end, nil, nil, 'shoot')

  self.t:after(18*(self.parent.conjurer_buff_m or 1), function()
    local n = n or random:int(3, 4)
    for i = 1, n do HitParticle{group = main.current.effects, x = self.x, y = self.y, r = random:float(0, 2*math.pi), color = self.color} end
    HitCircle{group = main.current.effects, x = self.x, y = self.y}:scale_down()
    self.dead = true

    if self.parent.level == 3 then
      shoot1:play{pitch = random:float(0.95, 1.05), volume = 0.2}
      for i = 1, 12 do
        Projectile{group = main.current.main, x = self.x, y = self.y, color = self.color, r = (i-1)*math.pi/6, v = 200, dmg = self.parent.dmg, character = 'artificer_death',
          parent = self.parent, level = self.parent.level, pierce = 1, ricochet = 1}
      end
    end

    if self.parent.construct_instability then
      camera:shake(2, 0.5)
      local n = (self.parent.construct_instability == 1 and 1) or (self.parent.construct_instability == 2 and 1.5) or (self.parent.construct_instability == 3 and 2) or 1
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*48, color = self.color, dmg = n*self.parent.dmg*self.parent.area_dmg_m, parent = self.parent}
      _G[random:table{'cannoneer1', 'cannoneer2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    end
  end)
end


function Automaton:update(dt)
  self:update_game_object(dt)

  self:calculate_stats()

  if not self.target then self.target = random:table(self.group:get_objects_by_classes(main.current.enemies)) end
  if self.target and self.target.dead then self.target = random:table(self.group:get_objects_by_classes(main.current.enemies)) end
  if not self.seek_f then return end
  if not self.target then
    self:seek_point(gw/2, gh/2)
    self:wander(50, 200, 50)
    self:rotate_towards_velocity(1)
    self:steering_separate(32, {Enemy})
  else
    self:seek_point(self.target.x, self.target.y)
    self:wander(50, 200, 50)
    self:rotate_towards_velocity(1)
    self:steering_separate(32, {Enemy})
  end
  self.r = self:get_angle()

  self.t:set_every_multiplier('shoot', self.parent.level == 3 and 0.75 or 1)
  self.attack_sensor:move_to(self.x, self.y)
end


function Automaton:draw()
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end


Gold = Object:extend()
Gold:implement(GameObject)
Gold:implement(Physics)
function Gold:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  if #self.group:get_objects_by_class(Gold) > 30 then self.dead = true; return end
  self:set_as_rectangle(3, 3, 'dynamic', 'ghost')
  self:set_restitution(0.5)
  local r = random:float(0, 2*math.pi)
  local f = random:float(2, 4)
  self:apply_impulse(f*math.cos(r), f*math.sin(r))
  self:apply_angular_impulse(random:table{random:float(-6*math.pi, -2*math.pi), random:float(2*math.pi, 6*math.pi)})
  self:set_damping(2.5)
  self:set_angular_damping(5)
  self.color = yellow2[0]
  self.hfx:add('hit', 1)
  self.cant_be_picked_up = true
  self.t:after(0.5, function() self.cant_be_picked_up = false end)
  gold1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.weak_magnet_sensor = Circle(self.x, self.y, 16)
  self.magnet_sensor = Circle(self.x, self.y, 56)
end


function Gold:update(dt)
  self:update_game_object(dt)
  self.r = self:get_angle()
  if not self.magnet_sensor then return end
  if not self.weak_magnet_sensor then return end

  local players = self:get_objects_in_shape(main.current.player.magnetism and self.magnet_sensor or self.weak_magnet_sensor, {Player})
  if players and #players > 0 then
    local x, y = 0, 0
    for _, p in ipairs(players) do
      x = x + p.x
      y = y + p.y
    end
    x = x/#players
    y = y/#players
    local r = self:point_to_angle(x, y)
    self:apply_force(20*math.cos(r), 20*math.sin(r))
  end
  if self.magnet_sensor then self.magnet_sensor:move_to(self.x, self.y) end
  if self.weak_magnet_sensor then self.weak_magnet_sensor:move_to(self.x, self.y) end
end


function Gold:draw()
  if not self.hfx.hit then return end
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 1, 1, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end


function Gold:on_trigger_enter(other, contact)
  if self.cant_be_picked_up then return end

  if other:is(Player) then
    main.current.gold_picked_up = main.current.gold_picked_up + 1
    self.dead = true
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 4, color = fg[0], duration = 0.1}
    for i = 1, 2 do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
    _G[random:table{'gold2', 'coins1', 'coins2', 'coins3'}]:play{pitch = random:float(0.9, 1.1), volume = 0.3}

    local units = other:get_all_units()
    local th
    for _, unit in ipairs(units) do
      if unit.character == 'miner' then
        th = unit
      end
    end
    if th then
      if th.level == 3 then
        trigger:after(0.01, function()
          if not main.current.main.world then return end
          _G[random:table{'scout1', 'scout2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.35}
          HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6}
          local r = random:float(0, 2*math.pi)
          for i = 1, 8 do
            local t = {group = main.current.main, x = self.x + 8*math.cos(r), y = self.y + 8*math.sin(r), v = 250, r = r, color = yellow2[0], dmg = th.dmg, character = th.character, parent = th, level = th.level}
            Projectile(table.merge(t, mods or {}))
            r = r + math.pi/4
          end
        end)
      else
        trigger:after(0.01, function()
          if not main.current.main.world then return end
          _G[random:table{'scout1', 'scout2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.35}
          HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6}
          local r = random:float(0, 2*math.pi)
          for i = 1, 4 do
            local t = {group = main.current.main, x = self.x + 8*math.cos(r), y = self.y + 8*math.sin(r), v = 250, r = r, color = yellow2[0], dmg = th.dmg, character = th.character, parent = th, level = th.level}
            Projectile(table.merge(t, mods or {}))
            r = r + 2*math.pi/4
          end
        end)
      end
    end
  end
end




HealingOrb = Object:extend()
HealingOrb:implement(GameObject)
HealingOrb:implement(Physics)
function HealingOrb:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  if #self.group:get_objects_by_class(HealingOrb) > 30 then self.dead = true; return end
  self:set_as_rectangle(4, 4, 'dynamic', 'ghost')
  self:set_restitution(0.5)
  local r = random:float(0, 2*math.pi)
  local f = random:float(2, 4)
  self:apply_impulse(f*math.cos(r), f*math.sin(r))
  self:apply_angular_impulse(random:table{random:float(-6*math.pi, -2*math.pi), random:float(2*math.pi, 6*math.pi)})
  self:set_damping(2.5)
  self:set_angular_damping(5)
  self.color = yellow2[0]
  self.hfx:add('hit', 1)
  self.cant_be_picked_up = true
  self.t:after(0.5, function() self.cant_be_picked_up = false end)
  illusion1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.weak_magnet_sensor = Circle(self.x, self.y, 16)
  self.magnet_sensor = Circle(self.x, self.y, 56)

  if main.current.healer_level > 0 and not self.healer_effect_orb then
    if random:bool((main.current.healer_level == 1 and 15) or (main.current.healer_level == 2 and 30)) then
      SpawnEffect{group = main.current.effects, x = self.x, y = self.y, color = green[0], action = function(x, y)
        HealingOrb{group = main.current.main, x = x, y = y, healer_effect_orb = true}
      end}
    end
  end
end


function HealingOrb:update(dt)
  self:update_game_object(dt)
  self.r = self:get_angle()
  if not self.magnet_sensor then return end
  if not self.weak_magnet_sensor then return end

  local players = self:get_objects_in_shape(main.current.player.magnetism and self.magnet_sensor or self.weak_magnet_sensor, {Player})
  if players and #players > 0 then
    local x, y = 0, 0
    for _, p in ipairs(players) do
      x = x + p.x
      y = y + p.y
    end
    x = x/#players
    y = y/#players
    local r = self:point_to_angle(x, y)
    self:apply_force(20*math.cos(r), 20*math.sin(r))
  end
  if self.magnet_sensor then self.magnet_sensor:move_to(self.x, self.y) end
  if self.weak_magnet_sensor then self.weak_magnet_sensor:move_to(self.x, self.y) end
end


function HealingOrb:draw()
  if not self.hfx.hit then return end
  local sr = random:float(-0.1, 0.1)
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x + sr, self.hfx.hit.x + sr)
    graphics.circle(self.x, self.y, 1.2*self.shape.w, self.hfx.hit.f and fg[0] or green_transparent_weak)
    graphics.circle(self.x, self.y, 0.5*self.shape.w, self.hfx.hit.f and fg[0] or green[0])
  graphics.pop()
end


function HealingOrb:on_trigger_enter(other, contact)
  if self.cant_be_picked_up then return end

  if other:is(Player) then
    self.dead = true
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 4, color = fg[0], duration = 0.1}
    for i = 1, 2 do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = green[0]} end
    orb1:play{pitch = random:float(0.95, 1.05), volume = 1}
    heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}

    local units = other:get_all_units()
    local lowest_hp = 10
    local lowest_unit
    for _, unit in ipairs(units) do
      local r = unit.hp/unit.max_hp
      if r < lowest_hp then
        lowest_hp = r
        lowest_unit = unit
      end
    end
    if lowest_unit then
      lowest_unit:heal(0.2*lowest_unit.max_hp*(lowest_unit.heal_effect_m or 1))
    end

    if main.current.player.haste then
      local units = other:get_all_units()
      for _, unit in ipairs(units) do
        unit.hasted = love.timer.getTime()
        unit.t:after(4, function() unit.hasted = false end, 'haste')
      end
    end

    if main.current.player.divine_barrage and random:bool((main.current.player.divine_barrage == 1 and 20) or (main.current.player.divine_barrage == 2 and 40) or (main.current.player.divine_barrage == 3 and 60)) then
      trigger:after(0.01, function()
        if not main.current.main.world then return end
        main.current.player:barrage(main.current.player.r, 5, nil, 3)
      end)
    end
  end
end

Corpse = Object:extend()
Corpse:implement(GameObject)
Corpse:implement(Physics)
function Corpse:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(1,1, "static", "ghost")
  self:set_restitution(0.5)
  self.dug_up = false

  self.t:after(30, function() self.dead = true end)
end

function Corpse:kill()
  self.dug_up = true
  self.dead = true
end

function Corpse:update(dt)
  self:update_game_object(dt)
end

function Corpse:draw()
  graphics.push(self.x, self.y, self.r)
    graphics.rectangle(self.x, self.y, 4, 4, nil, nil, black[0])
  graphics.pop()
end



Critter = Object:extend()
Critter:implement(GameObject)
Critter:implement(Physics)
Critter:implement(Unit)
function Critter:init(args)
  self:init_game_object(args)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:init_unit()
  self:set_as_rectangle(7, 4, 'dynamic', 'player')
  self:set_restitution(0.5)

  self.aggro_sensor = Circle(self.x, self.y, 125)
  self.attack_sensor = Circle(self.x, self.y, 25)
  self.slowed = false

  self.class = 'enemy_critter'
  self.color = args.color or white[0]
  self:calculate_stats(true)
  self:set_as_steerable(self.v, 400, math.pi, 1)
  --self:push(args.v, args.r)
  self.invulnerable = true
  self.t:after(0.5, function() self.invulnerable = false end)

  self.t:cooldown(attack_speeds['medium'], function() return self.target and self:distance_to_object(self.target) < self.attack_sensor.rs end, 
  function() self:attack() end, nil, nil, "attack")

end

function Critter:update(dt)
  self:update_game_object(dt)

  if self.slowed then
    self.slow_mvspd_m = self.slowed
  end

  if self.being_pushed then
    local v = math.length(self:get_velocity())
    if v < 50 then
      self.being_pushed = false
      self.steering_enabled = true
      self:set_damping(0)
      self:set_angular_damping(0)
    end
  else
    if not self.target then self.target = random:table(self.group:get_objects_by_classes(main.current.enemies)) end
    if self.target and self.target.dead then self.target = random:table(self.group:get_objects_by_classes(main.current.enemies)) end
    if not self.target or self:distance_to_object(self.target) < self.attack_sensor.rs then
      self:set_velocity(0,0)
      self:rotate_towards_velocity(1)
      self:steering_separate(8, {Critter})
    elseif self.target then
      self:seek_point(self.target.x, self.target.y)
      self:rotate_towards_velocity(1)
      self:steering_separate(8, {Critter})
    end
  end
  self.r = self:get_angle()

  self.aggro_sensor:move_to(self.x, self.y)
  self.attack_sensor:move_to(self.x, self.y)
end


function Critter:draw()
  if not self.hfx.hit then return end
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end

function Critter:attack()
  if self.target and not self.target.dead then
    swordsman1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    self.target:hit(self.dmg)
  end
end


function Critter:hit(damage)
  if self.dead or self.invulnerable then return end
  self.hfx:use('hit', 0.25, 200, 10)
  self.hp = self.hp - damage
  self:show_hp()
  if self.hp <= 0 then self:die() end
end

function Critter:slow(amount, duration)
  self.slowed = amount
  self.t:after(duration, function() self.slowed = false end, 'slow')
end


function Critter:push(f, r)
  self.push_force = f
  self.being_pushed = true
  self.steering_enabled = false
  self:apply_impulse(f*math.cos(r), f*math.sin(r))
  self:apply_angular_impulse(random:table{random:float(-12*math.pi, -4*math.pi), random:float(4*math.pi, 12*math.pi)})
  self:set_damping(1.5)
  self:set_angular_damping(1.5)
end


function Critter:die(x, y, r, n)
  if self.parent and self.parent.summons then
    self.parent.summons = self.parent.summons - 1 end
  if self.dead then return end
  x = x or self.x
  y = y or self.y
  n = n or random:int(2, 3)
  for i = 1, n do HitParticle{group = main.current.effects, x = x, y = y, r = random:float(0, 2*math.pi), color = self.color} end
  HitCircle{group = main.current.effects, x = x, y = y}:scale_down()
  self.dead = true
  _G[random:table{'enemy_die1', 'enemy_die2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.5}
  critter2:play{pitch = random:float(0.95, 1.05), volume = 0.2}
end


function Critter:on_collision_enter(other, contact)
  local x, y = contact:getPositions()
  local nx, ny = contact:getNormal()
  local r = 0
  if nx == 0 and ny == -1 then r = -math.pi/2
  elseif nx == 0 and ny == 1 then r = math.pi/2
  elseif nx == -1 and ny == 0 then r = math.pi
  else r = 0 end

  if other:is(Wall) then
    self.hfx:use('hit', 0.15, 200, 10, 0.1)
    self:bounce(contact:getNormal())
  end
end


function Critter:on_trigger_enter(other, contact)
  --[[if other:is(Enemy) then
    critter2:play{pitch = random:float(0.65, 0.85), volume = 0.1}
    self:hit(1)
    other:hit(self.dmg, self)
  end]]--
end

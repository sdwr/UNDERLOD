Player = Unit:extend()
Player:implement(GameObject)
Player:implement(Physics)
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
    -- Removed push effect
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
  self.hfx:use('hit', 0.25, 200, 10)
  self:show_hp()

  local actual_damage = math.max(self:calculate_damage(damage), 0)
  self.hp = self.hp - actual_damage
  _G[random:table{'player_hit1', 'player_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  camera:shake(4, 0.5)
  main.current.damage_taken = main.current.damage_taken + actual_damage

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
end



function Player:attack(area, mods)

end


function Player:dot_attack(area, mods)

end

function Player:die()
  Player.super.die(self)
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
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*24, color = self.color, dmg = self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  elseif self.character == 'cannon' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*32, color = self.color, dmg = self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  elseif self.character == 'blade' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*64, color = self.color, dmg = self.dmg, character = self.character, level = self.level, parent = self,
      void_rift = self.parent.void_rift, echo_barrage = self.parent.echo_barrage}
  elseif self.character == 'cannoneer' then
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*96, color = self.color, dmg = self.dmg, character = self.character, level = self.level, parent = self,
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
          self.v = self.v*1.25
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
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*32, color = self.color, dmg = self.dmg, character = self.character, parent = self,
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
        DotArea{group = main.current.effects, x = self.x, y = self.y, rs = self.parent.area_size_m*24, color = self.color, dmg = self.dmg*(self.parent.dot_dmg_m or 1), void_rift = true, duration = 1}
      end
    end
  end
end




Area = Object:extend()
Area:implement(GameObject)
function Area:init(args)
  self:init_game_object(args)
  
  if self.areatype == 'target' then
    if self.target then
      self.x, self.y = self.target.x, self.target.y
    end
  end
  if self.pick_shape == 'circle' then
    local w = 1.5*self.r
    self.shape = Circle(self.x, self.y, w)
  else
    local w = 1.5*self.w
    local h = self.h and 1.5*self.h or 1.5*w
    self.shape = Rectangle(self.x, self.y, w, h, self.r)
  end

  self.dmg = self.dmg
  self.flashFactor = self.dmg / 30
  if self.flashFactor == 0 then self.flashFactor = 0.5 end

  self.color = self.color or fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)

  self.w = 0
  self.hidden = false

  self.is_troop = args.is_troop or false

  self.duration = args.duration or 0.2
  self.current_time = 0

  self.damage_ticks = args.damage_ticks or false
  self.tick_rate = args.tick_rate or 0.1

  if self.tick_immediately then
    self.current_time = self.tick_rate
  end
  
  self.active = true

  if not self.damage_ticks then
    self:damage()
  end

  --self.t:tween(0.05, self, {w = args.w}, math.cubic_in_out, function() self.spring:pull(0.15 * self.flashFactor) end)
  self.t:after(self.duration, function()
    self.color = args.color
    self.active = false
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end

function Area:damage()

  local targets = {}
  if self.is_troop then
    targets = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
  else
    targets = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  end

  --healing area
  if self.heal then
    for _, target in ipairs(targets) do
      target:heal(self.heal)
    end

  --root targets
  elseif self.rootDuration then
    for _, target in ipairs(targets) do
      if self:can_hit_with_effect(target, 'rooted') then
        target:root(self.rootDuration, self.unit)
        target:hit(self.dmg, self.unit)
        self:apply_hit_effect(target)
      end
    end

  elseif self.shockDuration then
    for _, target in ipairs(targets) do
      if self:can_hit_with_effect(target, 'shocked') then
        target:shock(self.shockDuration, self.unit)
        target:hit(self.dmg, self.unit)
        self:apply_hit_effect(target)
      end
    end

  elseif self.stunDuration then
    local stun_chance = self.stunChance or 1
    for _, target in ipairs(targets) do

      if self:can_hit_with_effect(target, 'stunned') then
        if math.random() < stun_chance then
          target:stun(self.stunDuration, self.unit)
          target:hit(self.dmg, self.unit)
          self:apply_hit_effect(target)
        end
      end
    end

  elseif self.chillAmount then
    for _, target in ipairs(targets) do
      if self:can_hit_with_effect(target, 'chilled') then
        target:chill(self.chillAmount, self.chillDuration, self.unit)
        target:hit(self.dmg, self.unit)
        self:apply_hit_effect(target)
      end
    end

  elseif self.burnDps then
    for _, target in ipairs(targets) do
      target:burn(self.burnDps, self.burnDuration, self.unit)
    end
  
  elseif self.knockback_force then
    for _, target in ipairs(targets) do
      if self:can_hit_with_knockback(target) then
        target:hit(self.dmg, self.unit)
        target:push(self.knockback_force, self.unit:angle_to_object(target), nil, self.knockback_duration)
        self:apply_hit_effect(target)
      end
    end
  elseif self.dmg > 0 then
    for _, target in ipairs(targets) do
      target:hit(self.dmg, self.unit)
      self:apply_hit_effect(target)
    end
  end
end

function Area:apply_hit_effect(target)
  HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
  for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
  for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
  hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
end

function Area:can_hit_with_effect(target, effectName)
  if self.only_multi_hit_after_effect_ends then
    if not target:has_buff(effectName) then
      return true
    else
      return false
    end
  else
    return true
  end
end

function Area:can_hit_with_knockback(target)
  if self.only_multi_hit_after_effect_ends then
    if not target.state == unit_states['knockback'] then
      return true
    else
      return false
    end
  else
    return true
  end
end

function Area:update(dt)
  self:update_game_object(dt)
  if self.damage_ticks and self.active then
    self:update_ticks(dt)
  end
  if self.unit and self.unit.dead ~= true and self.follow_unit then
    self.x, self.y = self.unit.x, self.unit.y
  end
end

function Area:update_ticks(dt)
  self.current_time = self.current_time + dt
  if self.current_time >= self.tick_rate and self.active 
    and self.dmg > 0 then
    self:damage()
    self.current_time = 0
  end
end


function Area:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

  local w = self.w/2
  local w10 = self.w/10
  local x1, y1 = self.x - w, self.y - w
  local x2, y2 = self.x + w, self.y + w
  local lw = math.remap(w, 32, 256, 2, 4)
  if self.pick_shape == 'circle' then
    graphics.circle(self.x, self.y, self.r, self.color_transparent)
    graphics.circle(self.x, self.y, self.r, self.color, 1 * self.flashFactor)
  else
    graphics.polyline(self.color, lw, x1, y1 + w10, x1, y1, x1 + w10, y1)
    graphics.polyline(self.color, lw, x2 - w10, y1, x2, y1, x2, y1 + w10)
    graphics.polyline(self.color, lw, x2 - w10, y2, x2, y2, x2, y2 - w10)
    graphics.polyline(self.color, lw, x1, y2 - w10, x1, y2, x1 + w10, y2)
    graphics.rectangle((x1+x2)/2, (y1+y2)/2, x2-x1, y2-y1, nil, nil, self.color_transparent)
    graphics.rectangle((x1+x2)/2, (y1+y2)/2, x2-x1, y2-y1, nil, nil, self.color, 1 * self.flashFactor)
  end
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
        target:hit(self.dmg/5)
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
      end
    end, nil, nil, 'dot')
  
  elseif self.character == 'wizard' then
    self.t:every(0.2, function()
    local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
    if #enemies > 0 then self.spring:pull(0.05, 200, 10) end
    for _, enemy in ipairs(enemies) do
      enemy:hit(self.dmg/5, self.parent)
      enemy:slow(0.8, 1, nil)
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
  self.color.a = math.min(self.currentTime, 1)

  self.state = "charging"
  Helper.Unit.start_casting(self.parent)
  sniper_load:play({volume = 0.5})
  self.t:after(self.parent.castTime, function() self:fire() end, 'shoot')

end

function Snipe:cancel()
  self.dead = true
  Helper.Unit:unclaim_target(self.parent)

end

function Snipe:update(dt)
  self:update_game_object(dt)
  if self.parent and self.parent.dead == true then self:cancel() return end
  if not self.target or self.target.dead == true then self:cancel() return end
  self.currentTime = self.currentTime + dt

  self.color.a = math.min(self.currentTime / self.parent.castTime, 1)

end

function Snipe:fire()
  dual_gunner2:play({pitch = random:float(0.9, 1.1), volume = 0.7})
  if self.target then self.target:hit(self.dmg, self.parent) end
  Helper.Unit:finish_casting(self.parent)
  self:cancel()
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


Charge = Object:extend()
Charge:implement(GameObject)
Charge:implement(Physics)
function Charge:init(args)
  self:init_game_object(args)
  self.currentTime = 0

  self.state = "charging"

  self.parent.state = 'frozen'

  orb1:play({volume = 0.9})

  self.chargeDamage = self.damage or 20
  self.chargeDistance = self.chargeDistance or 100
  self.chargeSpeed = self.chargeSpeed or 200

  self.chargeTime = self.chargeTime or 1
  self.chargeDuration = self.chargeDuration or 0.5
  self.recoveryTime = self.recoveryTime or 1.5

  self.color = self.color or red[0]
  self.transparency = self.transparency or 0.2
  self.lineWidth = self.lineWidth or 8

  self.destX = self.x
  self.destY = self.y
end

function Charge:update(dt)
  if self.parent and self.parent.dead then self.dead = true; return end
  self:update_game_object(dt)
  self.currentTime = self.currentTime + dt

  if self.state == 'charging' and self.currentTime > self.chargeTime then
    self:charge()
  elseif self.state == 'mid_charge' then
    local timeRemaining = self.chargeTime - self.currentTime
    self.parent:move_towards_point(self.destX, self.destY, self.chargeSpeed, timeRemaining)
    if timeRemaining < 0 then
      self:recover()
    end
  elseif self.state == 'recovering' and self.currentTime > self.recoveryTime then
    if self.parent and self.parent.state == 'frozen' then self.parent.state = 'normal' end
    self.dead = true
  end
end

function Charge:charge()
  self.currentTime = 0
  self.state = "mid_charge"
  usurer1:play{pitch = random:float(0.95, 1.05), volume = 1.7}
  

  --try seek_point or move_towrads_point
  --need to launch the unit forward here
  --don't really know how collisions work with this
  --can maybe set the unit to a kinematic body and then apply a force to it
end

function Charge:recover()
  self.currentTime = 0
  self.state = "recovering"
end

function Charge:draw()
  --just targets whichever direction the unit is facing
  if self.state == 'charging' then
    local lengthPerc = math.min(self.currentTime / self.chargeTime, 1)
    local length = self.chargeDistance * lengthPerc
    self.destX = self.x + length * math.cos(self.parent.r)
    self.destY = self.y + length * math.sin(self.parent.r)
    local color = self.color:clone()
    color.a = self.transparency
    graphics.line(self.x, self.y, self.destX, self.destY, self.color, self.lineWidth)
  end
end

Stomp = Object:extend()
Stomp:implement(GameObject)
Stomp:implement(Physics)
function Stomp:init(args)
  self:init_game_object(args)
  self.attack_sensor = Circle(self.x, self.y, self.rs)
  self.currentTime = 0
  self.knockback = self.knockback or false

  self.state = "charging"

  orb1:play({volume = 0.5})

  self.color = self.color or red[0]
  self.color_transparent = self.color:clone()
  self.color_transparent.a = 0.2

  self.recoveryTime = self.chargeTime or 1
  self.recoveryTime = self.recoveryTime + 0.25
  

  self.t:after(self.chargeTime or 1, function() self:stomp() end)
  self.t:after(self.recoveryTime, function() self:recover() end)

end

function Stomp:update(dt)
  if self.unit and self.unit.dead then self.dead = true; return end
  self:update_game_object(dt)
  self.attack_sensor:move_to(self.x, self.y)
  self.currentTime = self.currentTime + dt
end

function Stomp:stomp()
  if self then self.state = "recovering" else return end

  usurer1:play{pitch = random:float(0.95, 1.05), volume = 1.6}

  local targets = {}
  if self.team == 'enemy' then
    targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.friendlies)
  else
    targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies)
  end
  if #targets > 0 then self.spring:pull(0.05, 200, 10) end
  for _, target in ipairs(targets) do
    if self.knockback then
      -- Reverse the angle by adding math.pi
      local angle = target:angle_to_object(self) + math.pi
      target:push(LAUNCH_PUSH_FORCE_BOSS, angle)
    else
      target:slow(0.3, 1, nil)
    end
    target:hit(self.dmg, self.unit)
    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}


    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
  end
end

function Stomp:recover()
  if self then self.dead = true else return end
  if self.parent and self.parent.state == 'frozen' then self.parent.state = 'normal' end
end

function Stomp:draw()
  if self.hidden then return end

  if self.state == 'charging' then
    graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
      -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
      graphics.circle(self.x, self.y, self.attack_sensor.rs * math.min(self.currentTime / (self.chargeTime or 1), 1) , self.color_transparent)
      graphics.circle(self.x, self.y, self.attack_sensor.rs, self.color, 1)
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
  Stomp{group = main.current.main, unit = self.unit, team = self.team, x = self.target.x + math.random(-10, 10), y = self.target.y + math.random(-10, 10), rs = self.rs, color = self.color, dmg = self.dmg, level = self.level, parent = self}
end

function Mortar:recover()
  if self then self.dead = true else return end
  if self.parent then self.parent.state = 'normal' end
end

function Mortar:draw()
end



Laser = Object:extend()
Laser:implement(GameObject)
function Laser:init(args)
  self:init_game_object(args)
  self.damage_troops = args.damage_troops or true
  self.pre_color = args.pre_color or red[0]
  self.color = blue[0]
  self.w = 4
  self.initial_rotation = args.initial_rotation or 0

  self.x = self.parent.x or args.x or 0
  self.y = self.parent.y or args.y or 0

  self.shape = Rectangle(self.x, self.y, self.w, 500, self:get_rotation())

  self.dps = args.dps or 10
  self.tick = args.tick or 0.1

  self.startup_duration = args.startup_duration or 0.1
  self.pre_duration = args.pre_duration or 0.5
  self.duration = args.duration or 1

  self.charge_sound = nil
  self.fire_sound = nil

  self.t:after(self.startup_duration, function() self:startup() end)
  self.t:after(self.startup_duration + self.pre_duration, function() self:fire() end)
  self.t:after(self.startup_duration + self.pre_duration + self.duration, function() self:die() end)
end

function Laser:get_rotation()
  return self.parent.r + self.initial_rotation
end

function Laser:startup()
  self.state = 'pre'
  -- play warmup sound
  self.charge_sound = laser_charging:play{pitch = random:float(0.8, 1.2), volume = 0.5}
end

function Laser:fire()
  self.state = 'firing'
  self:stopSound()
  self.fire_sound = shoot1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.t:every(self.tick, function() self:damage() end)
end

function Laser:stopSound()
  if self.charge_sound then self.charge_sound:stop() end
  if self.fire_sound then self.fire_sound:stop() end
end

function Laser:damage()
  local target_classes = self.damage_troops and main.current.friendlies or main.current.enemies
  local targets = main.current.main:get_objects_in_shape(self.shape, target_classes)
  for _, target in ipairs(targets) do
    target:hit(self.dps * self.tick, self.parent)
  end

end

function Laser:update(dt)
  self:update_game_object(dt)
  if not self.parent or self.parent.dead then self:die(); return end
  --location follows the parent
  self.x = self.parent.x
  self.y = self.parent.y
  self.r = self:get_rotation()
end

function Laser:draw()
  graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
  if self.state == 'pre' then
    graphics.rectangle(0, 0, self.shape.w, self.shape.h, 2, 2, self.pre_color)
  elseif self.state == 'firing' then
    graphics.rectangle(0, 0, 1.5*self.shape.w, self.shape.h, 2, 2, self.color)
  end
  graphics.pop()
end

function Laser:die()
  self:stopSound()
  self.dead = true
  self.t:destroy()
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

TimedCircle = Object:extend()
TimedCircle:implement(GameObject)
function TimedCircle:init(args)
  self:init_game_object(args)
  self.duration = args.duration or 1
  self.rs = args.rs or 16

  self.time_started = Helper.Time.time
end

function TimedCircle:update(dt)
  self:update_game_object(dt)
  if self.unit and self.unit.x and self.unit.y then
    self.x = self.unit.x
    self.y = self.unit.y
  end
  if Helper.Time.time - self.time_started > self.duration then self.dead = true end
end

function TimedCircle:draw()
  graphics.push(self.x, self.y)
  graphics.circle(self.x, self.y, self.rs, self.color, nil)
  graphics.pop()
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
  
  self.rs = 8
  self.speed = 0.5

  
  self.duration = RALLY_DURATION
  self.current_duration = 0
  
  self.time_started = Helper.Time.time
  self.color = self.color or yellow[0]
end

function RallyCircle:update(dt)
  self:update_game_object(dt)
  self.current_duration = Helper.Time.time - self.time_started
  if self.current_duration > self.duration then 
    --only clear unit state if the rally expires naturally
    --if something else kills this object, they will have to clear the state themselves
    if self.team then
      self.team:clear_rally_point()
    else
      self:die() 
    end
  end
  self.current_rs = self.current_duration * self.speed
end

function RallyCircle:draw()
  if not self.hidden then
    graphics.push(self.x, self.y)
    local radii = self:findRadiuses()
    for _, radius in ipairs(radii) do
      graphics.circle(self.x, self.y, radius, self.color, 1)
    end
    
    graphics.pop()
  end
end

--draw 2 circles with sizes based on current_rs, which will move over time
function RallyCircle:findRadiuses()
  local initial_size = self.rs
  local final_size = 1
  local size_diff = initial_size - final_size
  
  local radii = {}
  for i = 1, 2 do
    local starting_size = i * (initial_size / 2)
    local circle_size = starting_size - (self.current_duration * size_diff * self.speed)
    while circle_size < 1 do
      circle_size = circle_size + (initial_size - 1)
    end
    table.insert(radii, circle_size)
  end

  return radii
end

function RallyCircle:die()
  self.dead = true
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
    Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*72, r = random:float(0, 2*math.pi), color = self.color, dmg = self.parent.dmg,
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
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*48, color = self.color, dmg = n*self.parent.dmg, parent = self.parent}
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
    dmg = self.dmg*(self.parent.conjurer_buff_m or 1)*(self.level == 3 and 2 or 1), character = self.character, parent = self.parent}
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
        dmg = n*self.parent.dmg*(self.level == 3 and 2 or 1), parent = self.parent}
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
      dmg = (self.crit and 2 or 1)*self.actual_dmg*(self.conjurer_buff_m or 1), character = self.character, parent = self.parent}
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
      Area{group = main.current.effects, x = self.x, y = self.y, r = self.r, w = self.parent.area_size_m*48, color = self.color, dmg = n*self.parent.dmg, parent = self.parent}
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



Critter = Unit:extend()
Critter:implement(GameObject)
Critter:implement(Physics)
function Critter:init(args)
  self.class = 'enemy_critter'
  self:init_game_object(args)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:init_unit()
  Helper.Unit:add_custom_variables_to_unit(self)
  Set_Enemy_Shape(self, 'critter')
  self:set_restitution(0.5)

  self.aggro_sensor = Circle(self.x, self.y, 125)
  self.attack_sensor = Circle(self.x, self.y, 25)

  self.color = args.color or white[0]
  self:calculate_stats(true)
  self:set_as_steerable(self.v, 400, math.pi, 1)

  self.t:cooldown(attack_speeds['fast'], function() return self.target and self:distance_to_object(self.target) < self.attack_sensor.rs end, 
  function() self:attack() end, nil, nil, "attack")

end

function Critter:update(dt)
  self:update_game_object(dt)

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


function Critter:hit(damage, from, damageType, makesSound, cannotProcOnHit)
  
  if makesSound == nil then makesSound = true end
  if cannotProcOnHit == nil then cannotProcOnHit = false end

  if self.dead or self.invulnerable then return end

  if makesSound then
    self.hfx:use('hit', 0.25, 200, 10)
  end

  self.hp = self.hp - damage

  --on hit callbacks
  if from and from.onHitCallbacks and not cannotProcOnHit then
    from:onHitCallbacks(self, damage, damageType)
  end
  self:onGotHitCallbacks(from, damage, damageType)

  self:show_hp()
  if self.hp <= 0 then
    
    if from and from.onKillCallbacks then
      from:onKillCallbacks(self)
    end
    self:onDeathCallbacks(from)
    self:die()
  end
end

function Critter:push(f, r, push_invulnerable, duration)
  --only push if not already pushing
  if self.state == unit_states['knockback'] then
    return
  end

  self.push_invulnerable = push_invulnerable or false
  duration = duration or KNOCKBACK_DURATION_ENEMY

  self.state = unit_states['knockback']

  -- Cancel any existing during trigger for push
  if self.cancel_trigger_tag then
    self.t:cancel(self.cancel_trigger_tag)
  end

  --reset state after duration
  self.cancel_trigger_tag = self.t:after(duration, function()
    if self.state == unit_states['knockback'] then
      self.state = unit_states['normal']
    end
  end)

  self.push_force = f
  self.being_pushed = true
  self.steering_enabled = false
  self:apply_impulse(f*math.cos(r), f*math.sin(r))
  self:apply_angular_impulse(random:table{random:float(-12*math.pi, -4*math.pi), random:float(4*math.pi, 12*math.pi)})
  self:set_damping(1.5)
  self:set_angular_damping(1.5)
end


function Critter:die(x, y, r, n)
  Critter.super.die(self)
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

  if other:is(Wall) then
    self.hfx:use('hit', 0.15, 200, 10, 0.1)
    self:bounce(contact:getNormal())
  elseif table.any(main.current.enemies, function(v) return other:is(v) end) then
    
    player_hit1:play{pitch = random:float(0.95, 1.05), volume = 1.3}
    
    local push_force_reduction = 0.13
    local duration = KNOCKBACK_DURATION_ENEMY
    local push_force = LAUNCH_PUSH_FORCE_ENEMY * push_force_reduction
    local dmg = 10
    if other:is(Boss) then  
      duration = KNOCKBACK_DURATION_BOSS
      push_force = LAUNCH_PUSH_FORCE_BOSS * push_force_reduction
      dmg = 20
    end
    self:push(push_force, self:angle_to_object(other) + math.pi, nil, duration)
    self:hit(dmg, other, nil, false)
  end
end


function Critter:on_trigger_enter(other, contact)
  --[[if other:is(Enemy) then
    critter2:play{pitch = random:float(0.65, 0.85), volume = 0.1}
    self:hit(1)
    other:hit(self.dmg, self)
  end]]--
end

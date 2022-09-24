OldEnemy = Object:extend()
OldEnemy:implement(GameObject)
OldEnemy:implement(Physics)
OldEnemy:implement(Unit)
function OldEnemy:init(args)
  self:init_game_object(args)
  self:init_unit()

  if self.type == 'boss' then
    if self.name == 'stompy' then
      self:set_as_rectangle(60, 60, 'dynamic', 'enemy')
      self.color = grey[0]
      self:set_restitution(0.1)
      self.class = 'boss'
      self:calculate_stats(true)
      self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
    elseif self.name == 'dragon' then
      self:set_as_rectangle(70, 70, 'dynamic', 'enemy')
      self.color = red[-2]
      self:set_restitution(0.1)
      self.class = 'boss'
      self:calculate_stats(true)
      self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
    elseif self.name == 'heigan' then 
      self:set_as_rectangle(40, 60, 'dynamic', 'enemy')
      self.color = orange[-2]
      self:set_restitution(0.1)
      self.class = 'boss'
      self:calculate_stats(true)
      self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
    else
      error("boss name " .. self.name .. " not found")
    end
  else
    if self.type == 'stomper' then
      self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
      self:set_restitution(0.5)
      self.color = red[0]:clone()
      self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
      
    elseif self.type == 'mortar' then
      self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
      self:set_restitution(0.5)
      self.color = orange[0]:clone()
      self:set_as_steerable(self.v, 2000, 4*math.pi, 4)

    elseif self.type == 'summoner' then
      self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
      self:set_restitution(0.5)
      self.color = purple[0]:clone()
      self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
    elseif self.type == 'rager' then
      self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
      self:set_restitution(0.5)
      self.color = red[0]:clone()
      self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
    elseif self.type == 'assassin' then
      self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
      self:set_restitution(0.5)
      self.color = black[0]:clone()
      self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
    else
      self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
      self:set_restitution(0.5)
      self.color = grey[0]:clone()
      self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
    end
    self.class = 'seeker'
    self:calculate_stats(true)
  end
  
  self.state = 'normal'
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 20 + self.shape.w / 2)
  self.aggro_sensor = self.aggro_sensor or Circle(self.x, self.y, 1000)
  if self.type == 'stomper' then
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_closest_target(self.attack_sensor, main.current.friendlies); return target end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        self:stomp(30)
      end
    end, nil, nil, 'attack')
    
  elseif self.type == 'shooter' then
    self.attack_sensor = Circle(self.x, self.y, 100)
    self.t:cooldown(attack_speeds['medium'], function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end, function ()
      local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies)
      if target then
        self:rotate_towards_object(target, 1)
        self:shoot(self:angle_to_object(target))
      end
    end, nil, nil, 'shoot')
  elseif self.type == 'mortar' then
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target end, function ()
      local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
      if target then
        self:rotate_towards_object(target, 1)
        self:mortar(target)
      end
    end, nil, nil, 'shoot')
  elseif self.type == 'summoner' then
    self.summons = 0
    self.t:cooldown(attack_speeds['slow'], function() return self.state == 'normal' and self.summons < 4 end, function()
      self:summon()
    end, nil, nil, 'cast')
  elseif self.type == 'rager' then
    self.t:cooldown(attack_speeds['fast'], function() local targets = self:get_objects_in_shape(self.attack_sensor, main.current.friendlies); return targets and #targets > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        self:rotate_towards_object(closest_enemy, 1)
        self:attack(10, {x = closest_enemy.x, y = closest_enemy.y})
      end
    end, nil, nil, 'attack')
  elseif self.type == 'assassin' then
    self.spawn_pos = {x = self.x, y = self.y}
    self.t:cooldown(attack_speeds['ultra-slow'], function() local targets = self:get_objects_in_shape(self.aggro_sensor, main.current.friendlies); return targets and #targets > 0 end, function()
      local furthest_enemy = self:get_furthest_object_to_point(self.aggro_sensor, main.current.friendlies, {x = self.x, y = self.y})
      if furthest_enemy then
        self:vanish(furthest_enemy)
      end
    end, nil, nil, 'vanish')

    self.t:cooldown(attack_speeds['ultra-fast'], function() local targets = self:get_objects_in_shape(self.attack_sensor, main.current.friendlies); return targets and #targets > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        self:rotate_towards_object(closest_enemy, 1)
        self:attack(10, {x = closest_enemy.x, y = closest_enemy.y}, yellow[0])
      end
    end, nil, nil, 'attack')
  elseif self.type == 'boss' then
    if self.name == "stompy" then
      self.t:cooldown(attack_speeds['ultra-slow'], function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target and self.state == unit_states['normal'] end, function ()
        local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
        if target then
          self:rotate_towards_object(target, 1)
          self:mortar(target)
        end
      end, nil, nil, 'shoot')
      self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target and self.state == unit_states['normal'] end, function()
        self:stomp(self.attack_sensor.rs)
      end, nil, nil, 'stomp')
      self.t:cooldown(attack_speeds['fast'], function() local targets = self:get_objects_in_shape(self.aggro_sensor, main.current.friendlies); return targets and #targets > 0 and self.state == unit_states['normal'] end, function()
        local closest_enemy = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
        self.target = closest_enemy

        if self:in_range()() then
          self:rotate_towards_object(closest_enemy, 1)
          self:attack(20, {x = closest_enemy.x, y = closest_enemy.y})
        end
      end, nil, nil, 'attack')
    elseif self.name == "dragon" then
      self.attack_sensor.rs = self.attack_sensor.rs + 20
      self.summons = 0
      self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end, function()
        local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies);
        self.target = target

        if self:in_range()() then
          self:breathe_fire(2, self.attack_sensor.rs + 5)
        end
      end, nil, nil, 'channel')
      self.t:cooldown(attack_speeds["ultra-slow"], function() return true end, function()
        self:spawn_whelps(self, math.min(10 - self.summons, 4))
      end, nil, nil, 'summon')
    elseif self.name == "heigan" then
      self.cycle_index = 0
      self.t:cooldown(attack_speeds['slow'], function() return true end, function()
        self:safety_dance()
      end, nil, nil, 'cast')
    end

  else
    self.t:cooldown(attack_speeds['fast'], function() local targets = self:get_objects_in_shape(self.attack_sensor, main.current.friendlies); return targets and #targets > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        self:rotate_towards_object(closest_enemy, 1)
        self:attack(30, {x = closest_enemy.x, y = closest_enemy.y})
      end
    end, nil, nil, 'attack')

  end

  if self.speed_booster then
    self.color = green[0]:clone()
    self.area_sensor = Circle(self.x, self.y, 128)
    self.t:after({16, 24}, function() self:hit(10000) end)
  elseif self.exploder then
    self.color = blue[0]:clone()
    self.t:after({16, 24}, function() self:hit(10000) end)
  elseif self.headbutter then
    self.color = orange[0]:clone()
    self.last_headbutt_time = 0
    local n = math.remap(current_new_game_plus, 0, 5, 1, 0.5)
   --[[ self.t:every(function() return math.distance(self.x, self.y, main.current.player.x, main.current.player.y) < 76 and love.timer.getTime() - self.last_headbutt_time > 10*n end, function()
      if self.silenced or self.barbarian_stunned then return end
      if self.headbutt_charging or self.headbutting then return end
      self.headbutt_charging = true
      self.t:tween(2, self.color, {r = fg[0].r, b = fg[0].b, g = fg[0].g}, math.cubic_in_out, function()
        if self.silenced or self.barbarian_stunned then return end
        self.t:tween(0.25, self.color, {r = orange[0].r, b = orange[0].b, g = orange[0].g}, math.linear)
        self.headbutt_charging = false
        headbutt1:play{pitch = random:float(0.95, 1.05), volume = 0.2}
        self.headbutting = true
        self.last_headbutt_time = love.timer.getTime()
        self:set_damping(0)
        self:apply_steering_impulse(300, self:angle_to_object(main.current.player), 0.75)
        self.t:after(0.75, function()
          self.headbutting = false
        end)
      end)
    end)
  ]]--
  elseif self.tank then
    self.color = yellow[0]:clone()
    self.buff_hp_m = 1.25 + (0.1*self.level) + (0.4*current_new_game_plus)
    self:calculate_stats()
    self.hp = self.max_hp
    local n = math.remap(current_new_game_plus, 0, 5, 1, 0.75)
    self.t:every({3*n, 5*n}, function()
      if self.silenced or self.barbarian_stunned then return end
      local enemy = self:get_closest_object_in_shape(Circle(self.x, self.y, 64), main.current.enemies)
      if enemy then
        wizard1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = yellow[0], duration = 0.1}
        LightningLine{group = main.current.effects, src = self, dst = enemy, color = yellow[0]}
        enemy:push(random:float(30, 50), enemy:angle_to_object(main.current.player), true)
      end
    end)
  elseif self.shooter then
    self.color = fg[0]:clone()
    local n = math.remap(current_new_game_plus, 0, 5, 1, 0.5)
    self.t:after({2*n, 4*n}, function()
      self.shooting = true
      self.t:every({4, 6}, function()
        if self.silenced or self.barbarian_stunned then return end
        for i = 1, 3 do
          self.t:after(math.max(1 - self.level*0.01, 0.25)*0.15*(i-1), function()
            shoot1:play{pitch = random:float(0.95, 1.05), volume = 0.1}
            self.hfx:use('hit', 0.25, 200, 10, 0.1)
            local r = self.r
            HitCircle{group = main.current.effects, x = self.x + 0.8*self.shape.w*math.cos(r), y = self.y + 0.8*self.shape.w*math.sin(r), rs = 6}
            EnemyProjectile{group = main.current.main, x = self.x + 1.6*self.shape.w*math.cos(r), y = self.y + 1.6*self.shape.w*math.sin(r), color = fg[0], r = r, v = math.min(140 + 3.5*self.level + 2*current_new_game_plus, 300),
              dmg = (current_new_game_plus*0.05 + 1)*self.dmg, source = 'shooter'}
          end)
        end
      end, nil, nil, 'shooter')
    end)
  elseif self.spawner then
    self.color = purple[0]:clone()
  end

  local player = main.current.player
  if player and player.intimidation and not self.boss and not self.tank then
    self.buff_hp_m = (player.intimidation == 1 and 0.9) or (player.intimidation == 2 and 0.8) or (player.intimidation == 3 and 0.7)
    self:calculate_stats()
    self.hp = self.max_hp
  end

  if player and player.vulnerability then
    self.vulnerable = (player.vulnerability == 1 and 1.1) or (player.vulnerability == 2 and 1.2) or (player.vulnerability == 3 and 1.3)
  end

  if player and player.temporal_chains then
    self.temporal_chains_mvspd_m = (player.temporal_chains and 0.9) or (player.temporal_chains and 0.8) or (player.temporal_chains and 0.7)
  end

  self.usurer_count = 0
  self.curses = {}
end


function OldEnemy:update(dt)
  self:update_game_object(dt)


  if self.slowed then self.slow_mvspd_m = self.slowed
  else self.slow_mvspd_m = 1 end

  self.buff_mvspd_m = (self.speed_boosting_mvspd_m or 1)*(self.slow_mvspd_m or 1)*(self.temporal_chains_mvspd_m or 1)*(self.tank and 0.35 or 1)*(self.deceleration_mvspd_m or 1)
  self.buff_def_m = (self.seeping_def_m or 1)

  self:calculate_stats()

  self.stun_dmg_m = (self.barbarian_stunned and 2 or 1)

  --get target / rotate to target
  if self.target and self.target.dead then self.target = nil end
  if self.state == unit_states['normal'] then
    if not self:in_range()() then
      self.target = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
    end
    if self.target and self.target.dead then self.target = nil end
    if self.target then
      self:rotate_towards_object(self.target, 0.5)
    end
  elseif self.state == unit_states['stopped'] or self.state == unit_states['channeling'] then
    if self.target and not self.target.dead then
      self:rotate_towards_object(self.target, 1)
    end
  end

  if not self.headbutting then
    if self.state == 'normal' then
      if self:in_range()() then
        -- dont need to move
      elseif self.target then
        self:seek_point(self.target.x, self.target.y)
        self:rotate_towards_velocity(0.5)
      else
        -- dont need to move
      end
    else
      self:set_velocity(0,0)
    end
    
  end
  self.r = self:get_angle()


  self.attack_sensor:move_to(self.x, self.y)
  self.aggro_sensor:move_to(self.x, self.y)

  if self.area_sensor then self.area_sensor:move_to(self.x, self.y) end
end

function OldEnemy:attack(area, mods, color)
  mods = mods or {}
  local t = {team = "enemy", group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(area or 64), color = color or self.color, dmg = self.area_dmg_m*self.dmg,
    character = self.character, level = self.level, parent = self}

  self.state = unit_states['frozen']

  self.t:after(0.3, function() 
    self.state = unit_states['stopped']
    Area(table.merge(t, mods))
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  end, 'stopped')
  self.t:after(0.4 + .4, function() self.state = unit_states['normal'] end, 'normal')

end

function OldEnemy:stomp(area, mods)
  Stomp{group = main.current.main, team = "enemy", x = self.x, y = self.y, rs = area or 25, color = red[0], dmg = 50, level = self.level, parent = self}
end

function OldEnemy:mortar(target)
  Mortar{group = main.current.main, team = "enemy", target = target, rs = 25, color = red[0], dmg = 30, level = self.level, parent = self}
end

function OldEnemy:breathe_fire(duration, rs)
  BreatheFire{origin_offset = true, follows_caster = true, area_type = 'triangle',
    group = main.current.main, team = "enemy", x = self.x, y = self.y, rs = rs, color = red[3], dmg = 20, duration = duration, level = self.level, parent = self}
end

function OldEnemy:summon()
  Summon{group = main.current.main, team = "enemy", x = self.x, y = self.y, rs = 25, color = purple[0], level = self.level, parent = self}
end

function OldEnemy:spawn_whelps(parent, amount)
  main.current:spawn_critters(parent, amount)
end

function OldEnemy:vanish(target)
  Vanish{group = main.current.main, team = "enemy", x = self.x, y = self.y, target = target, level = self.level, parent = self}
end

function OldEnemy:shoot(r, mods)
  mods = mods or {}
  local t = {group = main.current.main, x = self.x, y = self.y, v = 175, r = r, color = self.color, dmg = self.dmg}
  self.hfx:use('shoot', 0.25)
  self.state = unit_states['frozen']

  self.t:after(0.4, function()
    self.state = unit_states['stopped']
    HitCircle{group = main.current.effects, x = self.x , y = self.y, rs = 6, duration = 0.1}
    EnemyProjectile(table.merge(t, mods or {}))
    
    end, 'stopped')
  self.t:after(0.4 + .4, function() self.state = unit_states['normal'] end, 'normal')

end


function OldEnemy:draw()
  graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    if self.type == 'boss' then
      if self.name == 'stompy' or self.name == 'heigan' then
        graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 10, 10, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
      elseif self.name == 'dragon' then
        local points = self:make_regular_polygon(3, self.shape.w / 2, self:get_angle())
        graphics.polygon(points, self.color)
        --debug
        --local facing = self:angle_to_point(self:get_angle(), 50)
        --graphics.line(self.x, self.y, facing.x, facing.y, green[0], 5)
        --graphics.polygon(self.shape.vertices, self.color, 1)
      else
        error("boss name " .. self.name .. " not found")
      end
    else
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    end
  graphics.pop()

  if self.boss then
    local t, c = self.t:get_timer_and_delay('boss_attack')
    local n = t/c
    graphics.line(self.x - self.shape.w/2, self.y + 8, self.x + self.shape.w/2, self.y + 8, bg[-3], 2)
    graphics.line(self.x - self.shape.w/2, self.y + 8, self.x - self.shape.w/2 + self.shape.w*n, self.y + 8, self.color, 2)
  end

  if self.px and self.py then
    if self.phidden then return end
    graphics.push(self.px, self.py, self.vr, self.spring.x, self.spring.x)
      graphics.circle(self.px, self.py, self.prs + random:float(-1, 1), yellow[0])
      graphics.circle(self.px, self.py, self.pull_sensor.rs, self.color_transparent)
      local lw = math.remap(self.pull_sensor.rs, 32, 256, 2, 4)
      for i = 1, 4 do graphics.arc('open', self.px, self.py, self.pull_sensor.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, yellow[0], lw) end
    graphics.pop()
  end
end

function OldEnemy:on_collision_enter(other, contact)
  local x, y = contact:getPositions()

  if other:is(Wall) then
    self.hfx:use('hit', 0.15, 200, 10, 0.1)
    self:bounce(contact:getNormal())
    if self.juggernaut_push then
      self:hit(self.juggernaut_push)
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    end

    if self.launcher_push then
      self:hit(self.launcher_push)
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    end

    if self.headbutter and self.headbutting then
      self.headbutting = false
    end

  elseif table.any(main.current.enemies, function(v) return other:is(v) end) then
    if self.being_pushed and math.length(self:get_velocity()) > 60 then
      other:hit(math.floor(self.push_force/4), nil, nil, true)
      self:hit(math.floor(self.push_force/2), nil, nil, true)
      other:push(math.floor(self.push_force/2), other:angle_to_object(self))
      HitCircle{group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1}
      for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = self.color} end
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}

    elseif self.headbutting then
      other:push(math.length(self:get_velocity())/4, other:angle_to_object(self))
      HitCircle{group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1}
      for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = self.color} end
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
      if other:is(OldEnemy) or other:is(Player) then self.headbutting = false end
    end
  
  elseif other:is(Turret) then
    self.headbutting = false
    _G[random:table{'player_hit1', 'player_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    self:hit(0, nil, nil, true)
    self:push(random:float(2.5, 7), other:angle_to_object(self))
  end
end


function OldEnemy:hit(damage, projectile, dot, from_enemy)
  if self.invulnerable then return end
  local pyrod = self.pyrod
  self.pyrod = false
  if self.dead then return end
  if self.type == 'boss' then
    self.hfx:use('hit', 0.005, 200, 20)
  else
    self.hfx:use('hit', 0.25, 200, 10)
  end
  if self.push_invulnerable then return end
  self:show_hp()

  local actual_damage = math.max(self:calculate_damage(damage)*(self.stun_dmg_m or 1), 0)
  if self.vulnerable then actual_damage = actual_damage*self.vulnerable end
  self.hp = self.hp - actual_damage
  if self.hp > self.max_hp then self.hp = self.max_hp end
  main.current.damage_dealt = main.current.damage_dealt + actual_damage


  if dot then
    self.seeping_def_m = 1
    self.t:after(1, function()
      self.seeping_def_m = 1
    end, 'seeping')

    self.deceleration_mvspd_m =  1
    self.t:after(1, function()
      self.deceleration_mvspd_m = 1
    end, 'deceleration')
  end

  if projectile and projectile.spawn_critters_on_hit then
    critter1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    trigger:after(0.01, function()
      for i = 1, projectile.spawn_critters_on_hit do
        Critter{group = main.current.main, x = self.x, y = self.y, color = orange[0], r = random:float(0, 2*math.pi), v = 10, dmg = projectile.parent.dmg, parent = projectile.parent}
      end
    end)
  end


  if self.hp <= 0 then
    self:die()
    self.dead = true
    for i = 1, random:int(4, 6) do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 12}:scale_down(0.3):change_color(0.5, self.color)
    _G[random:table{'enemy_die1', 'enemy_die2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.5}

    --[[
    if main.current.healer_level > 0 then
      if random:bool((main.current.healer_level == 2 and 16) or (main.current.healer_level == 1 and 8) or 0) then
        trigger:after(0.01, function()
          HealingOrb{group = main.current.main, x = self.x, y = self.y}
        end)
      end
    end
    ]]--

    if self.type == 'boss' then
      slow(0.25, 1)
      magic_die1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    end

    if self.speed_booster then
      if self.silenced or self.barbarian_stunned then return end
      local enemies = self:get_objects_in_shape(self.area_sensor, main.current.enemies)
      if #enemies > 0 then
        buff1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = green[0], duration = 0.1}
        for _, enemy in ipairs(enemies) do
          LightningLine{group = main.current.effects, src = self, dst = enemy, color = green[0]}
          enemy:speed_boost(3)
        end
      end
    end

    if self.exploder then
      if self.silenced or self.barbarian_stunned then return end
      mine1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      trigger:after(0.01, function()
        ExploderMine{group = main.current.main, x = self.x, y = self.y, color = blue[0], parent = self}
      end)
    end

    if self.spawner then
      if self.silenced or self.barbarian_stunned then return end
      critter1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
      trigger:after(0.01, function()
        if not main.current.main.world then return end
        for i = 1, random:int(5, 8) do
          EnemyCritter{group = main.current.main, x = self.x, y = self.y, color = purple[0], r = random:float(0, 2*math.pi), v = 10 + 0.1*self.level, dmg = 2*self.dmg, projectile = projectile}
        end
      end)
    end

    if pyrod then
      trigger:after(0.01, function()
        if not main.current.main.world then return end
        Area{group = main.current.main, x = self.x, y = self.y, color = red[0], w = 32*pyrod.parent.area_size_m, r = random:float(0, 2*math.pi), dmg = pyrod.parent.area_dmg_m*pyrod.dmg,
          character = pyrod.character, level = pyrod.level, parent = pyrod.parent}
      end)
    end

    if projectile and projectile.spawn_critters_on_kill then
      trigger:after(0.01, function()
        critter1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        for i = 1, projectile.spawn_critters_on_kill do
          Critter{group = main.current.main, x = self.x, y = self.y, color = orange[0], r = random:float(0, 2*math.pi), v = 5, dmg = projectile.parent.dmg, parent = projectile.parent}
        end
      end)
    end

    if self.infested then
      critter1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      trigger:after(0.01, function()
        if type(self.infested) == 'number' then
          for i = 1, self.infested do
            Critter{group = main.current.main, x = self.x, y = self.y, color = orange[0], r = random:float(0, 2*math.pi), v = 10, dmg = self.infested_dmg, parent = self.infested_ref}
          end
        end
      end)
    end

    if self.jester_cursed then
      trigger:after(0.01, function()
        if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then return end
        _G[random:table{'scout1', 'scout2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.35}
        HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6}
        local r = random:float(0, 2*math.pi)
        for i = 1, 4 do
          local t = {group = main.current.main, x = self.x + 8*math.cos(r), y = self.y + 8*math.sin(r), v = 250, r = r, color = red[0], dmg = self.jester_ref.dmg,
            pierce = self.jester_lvl3 and 2 or 0, homing = self.jester_lvl3, character = self.jester_ref.character, parent = self.jester_ref}
          Projectile(table.merge(t, mods or {}))
          r = r + math.pi/2
        end
      end)
    end

    if self.bane_cursed then
      trigger:after(0.01, function()
        DotArea{group = main.current.effects, x = self.x, y = self.y, rs = (self.bane_ref.level == 3 and 2 or 1)*self.bane_ref.area_size_m*27, color = purple[0],
          dmg = self.bane_ref.area_dmg_m*self.bane_ref.dmg*(self.bane_ref.dot_dmg_m or 1), void_rift = true, duration = 1}
      end)
    end
  end
end

function OldEnemy:die()
  if self.parent and self.parent.summons and self.parent.summons > 0 then
    self.parent.summons = self.parent.summons - 1
  end
end


function OldEnemy:push(f, r, push_invulnerable)
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


function OldEnemy:speed_boost(duration)
  self.speed_boosting = love.timer.getTime()
  self.t:after(duration, function() self.speed_boosting = false end, 'speed_boost')
end


function OldEnemy:slow(amount, duration)
  self.slowed = amount
  self.t:after(duration, function() self.slowed = false end, 'slow')
end

function OldEnemy:onDeath()
  Corpse{group = main.current.main, x = self.x, y = self.y}
end


function OldEnemy:curse(curse, duration, arg1, arg2, arg3)
  buff1:play{pitch = random:float(0.65, 0.75), volume = 0.25}
  if curse == 'launcher' then
    self.t:after(duration, function()
      self.launcher_push = arg1
      self.launcher = arg2
      self:push(random:float(50, 75)*self.launcher.knockback_m, random:table{0, math.pi, math.pi/2, -math.pi/2})
    end, 'launcher_curse')
  elseif curse == 'jester' then
    self.jester_cursed = true
    self.jester_lvl3 = arg1
    self.jester_ref = arg2
    self.t:after(duration, function() self.jester_cursed = false end, 'jester_curse')
  elseif curse == 'bane' then
    self.bane_cursed = true
    self.bane_lvl3 = arg1
    self.bane_ref = arg2
    self.t:after(duration, function() self.bane_cursed = false end, 'bane_curse')
  elseif curse == 'infestor' then
    self.infested = arg1
    self.infested_dmg = arg2
    self.infested_ref = arg3
    self.t:after(duration, function() self.infested = false end, 'infestor_curse')
  elseif curse == 'silencer' then
    self.silenced = true
    self.t:after(duration, function() self.silenced = false end, 'silencer_curse')
  elseif curse == 'usurer' then
    if arg1 then
      self.usurer_count = self.usurer_count + 1
      if self.usurer_count == 3 then
        usurer1:play{pitch = random:float(0.95, 1.05), volume = 1}
        rogue_crit1:play{pitch = random:float(0.95, 1.05), volume = 1}
        camera:shake(4, 0.4)
        self.usurer_count = 0
        self:hit(50*arg2.dmg)
      end
    end
  end

  if main.current.player.whispers_of_doom then
    if not self.doom then self.doom = 0 end
    self.doom = self.doom + 1
    if self.doom == ((main.current.player.whispers_of_doom == 1 and 4) or (main.current.player.whispers_of_doom == 2 and 3) or (main.current.player.whispers_of_doom == 3 and 2)) then
      self.doom = 0
      self:hit((main.current.player.whispers_of_doom == 1 and 100) or (main.current.player.whispers_of_doom == 2 and 150) or (main.current.player.whispers_of_doom == 3 and 200))
      buff1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    end
  end

  if main.current.player.hextouch then
    local p = main.current.player
    local dmg = (p.hextouch == 1 and 10) or (p.hextouch == 2 and 15) or (p.hextouch == 3 and 20)
    self:apply_dot(dmg*(p.dot_dmg_m or 1)*(main.current.chronomancer_dot or 1), 3)
  end
end


function OldEnemy:apply_dot(dmg, duration, color)
  self.t:every(0.25, function()
    hit2:play{pitch = random:float(0.8, 1.2), volume = 0.2}
    self:hit(dmg/4, nil, true)
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = fg[0], duration = 0.1}
    for i = 1, 1 do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
    for i = 1, 1 do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = color or purple[0]} end
  end, math.floor(duration/0.2))
end


ExploderMine = Object:extend()
ExploderMine:implement(GameObject)
function ExploderMine:init(args)
  self:init_game_object(args)
  self.hfx:add('hit', 1)
  self.vr = 0
  self.dvr = random:float(-math.pi/4, math.pi/4)
  self.rs = 0
  self.t:tween(0.05, self, {rs = args.rs}, math.cubic_in_out, function()
    self.spring:pull(0.15)
    self.t:every(0.8 - current_new_game_plus*0.1, function()
      mine1:play{pitch = 1 + self.t:get_every_iteration'mine_count'*0.1, volume = 0.5}
      self.spring:pull(0.5, 200, 10)
      self.hfx:use('hit', 0.5, 200, 10, 0.2)
    end, 3, function()
      shoot1:play{pitch = random:float(0.95, 1.05), volume = 0.4}
      cannoneer1:play{pitch = random:float(0.95, 1.05), volume = 0.4}
      for i = 1, 4 do HitParticle{group = main.current.effects, x = self.x, y = self.y, r = random:float(0, 2*math.pi), color = self.color} end
      HitCircle{group = main.current.effects, x = self.x, y = self.y}
      local n = math.floor(8 + current_new_game_plus*1.5)
      if main.current.main.world then
        for i = 1, n do
          EnemyProjectile{group = main.current.main, x = self.x, y = self.y, color = blue[0], r = (i-1)*math.pi/(n/2), v = 120 + math.min(5*self.parent.level, 300), dmg = 1.3*self.parent.dmg}
        end
      end
      self.dead = true
    end, 'mine_count')
  end)
end


function ExploderMine:update(dt)
  self:update_game_object(dt)
  self.vr = self.vr + self.dvr*dt
end


function ExploderMine:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, 2.5, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end




EnemyCritter = Object:extend()
EnemyCritter:implement(GameObject)
EnemyCritter:implement(Physics)
EnemyCritter:implement(Unit)
function EnemyCritter:init(args)
  self:init_game_object(args)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:init_unit()
  self:set_as_rectangle(7, 4, 'dynamic', 'enemy')
  self:set_restitution(0.5)

  self.aggro_sensor = Circle(self.x, self.y, 1000)
  self.attack_sensor = Circle(self.x, self.y, 25)
  self.slowed = false

  self.class = 'enemy_critter'
  self.color = args.color or grey[0]
  self:calculate_stats(true)
  self:set_as_steerable(self.v, 400, math.pi, 1)
  --self:push(args.v, args.r) 
  self.t:cooldown(attack_speeds['medium'], function() return self.target and self:distance_to_object(self.target) < self.attack_sensor.rs end, 
  function() self:attack() end, nil, nil, "attack")
end


function EnemyCritter:update(dt)
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
    if not self.target then self.target = random:table(self.group:get_objects_by_classes(main.current.friendlies)) end
    if self.target and self.target.dead then self.target = random:table(self.group:get_objects_by_classes(main.current.friendlies)) end
    if not self.target or self:distance_to_object(self.target) < self.attack_sensor.rs then
      self:set_velocity(0,0)
      self:rotate_towards_velocity(1)
      self:steering_separate(8, {EnemyCritter})
    elseif self.target then
      self:seek_point(self.target.x, self.target.y)
      self:rotate_towards_velocity(1)
      self:steering_separate(8, {EnemyCritter})
    end
  end
  self.r = self:get_angle()

  self.aggro_sensor:move_to(self.x, self.y)
  self.attack_sensor:move_to(self.x, self.y)
end


function EnemyCritter:draw()
  if not self.hfx.hit then return end
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end

function EnemyCritter:attack()
  if self.target and not self.target.dead then
    swordsman1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    self.target:hit(self.dmg)
  end
end

function EnemyCritter:hit(damage, projectile)
  if self.dead or self.invulnerable then return end
  self.hfx:use('hit', 0.25, 200, 10)
  self.hp = self.hp - damage
  self:show_hp()
  if self.hp <= 0 then self:die() end
end

function EnemyCritter:slow(amount, duration)
  self.slowed = amount
  self.t:after(duration, function() self.slowed = false end, 'slow')
end



function EnemyCritter:push(f, r)
  self.push_force = f
  self.being_pushed = true
  self.steering_enabled = false
  self:apply_impulse(f*math.cos(r), f*math.sin(r))
  self:apply_angular_impulse(random:table{random:float(-12*math.pi, -4*math.pi), random:float(4*math.pi, 12*math.pi)})
  self:set_damping(1.5)
  self:set_angular_damping(1.5)
end


function EnemyCritter:die(x, y, r, n)
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


function EnemyCritter:on_collision_enter(other, contact)
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


function EnemyCritter:on_trigger_enter(other, contact)
  --[[if other:is(Player) then
    self:die(self.x, self.y, nil, random:int(2, 3))
    other:hit(self.dmg, nil, nil, true)
  end]]--
end


EnemyProjectile = Object:extend()
EnemyProjectile:implement(GameObject)
EnemyProjectile:implement(Physics)
function EnemyProjectile:init(args)
  self:init_game_object(args)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:set_as_rectangle(10, 4, 'dynamic', 'enemy_projectile')
end


function EnemyProjectile:update(dt)
  self:update_game_object(dt)

  self:set_angle(self.r)
  self:move_along_angle(self.v, self.r)
end


function EnemyProjectile:draw()
  graphics.push(self.x, self.y, self.r)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.color)
  graphics.pop()
end


function EnemyProjectile:die(x, y, r, n)
  if self.dead then return end
  x = x or self.x
  y = y or self.y
  n = n or random:int(3, 4)
  for i = 1, n do HitParticle{group = main.current.effects, x = x, y = y, r = random:float(0, 2*math.pi), color = self.color} end
  HitCircle{group = main.current.effects, x = x, y = y}:scale_down()
  self.dead = true
  proj_hit_wall1:play{pitch = random:float(0.9, 1.1), volume = 0.05}
end


function EnemyProjectile:on_collision_enter(other, contact)
  local x, y = contact:getPositions()
  local nx, ny = contact:getNormal()
  local r = 0
  if nx == 0 and ny == -1 then r = -math.pi/2
  elseif nx == 0 and ny == 1 then r = math.pi/2
  elseif nx == -1 and ny == 0 then r = math.pi
  else r = 0 end

  if other:is(Wall) then
    self:die(x, y, r, random:int(2, 3))
  end
end


function EnemyProjectile:on_trigger_enter(other, contact)
  if other:is(Player) or other:is(Troop) then
    self:die(self.x, self.y, nil, random:int(2, 3))
    other:hit(self.dmg)

  elseif other:is(Critter) then
    self:die(self.x, self.y, nil, random:int(2, 3))
    other:hit(self.dmg)

  elseif other:is(OldEnemy) or other:is(EnemyCritter) then
    if self.source == 'shooter' then
      self:die(self.x, self.y, nil, random:int(2, 3))
      other:hit(0.5*self.dmg, nil, nil, true)
    end
  end
end

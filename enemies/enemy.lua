
enemy_to_class = {}

Enemy = Object:extend()
Enemy:implement(GameObject)
Enemy:implement(Physics)
Enemy:implement(Unit)
function Enemy:init(args)
  self:init_game_object(args)

  self:init_unit()
  self:setExtraFunctions()

  self.init_enemy(self)
  self:calculate_stats(true)
  
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 20 + self.shape.w / 2)
  self.aggro_sensor = self.aggro_sensor or Circle(self.x, self.y, 1000)
  self.state = 'normal'
end

--load enemy type specific functions from global table
function Enemy:setExtraFunctions()
  local t = enemy_to_class[self.type]
  for k, v in pairs(t) do
    self[k] = v
  end
end

function Enemy:update(dt)
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


    --move
    if self.state == unit_states['normal'] then
        if self:in_range()() then
            -- dont need to move
        elseif self.target then
            self:seek_point(self.target.x, self.target.y)
            self:rotate_towards_velocity(0.5)
        else
            -- dont need to move
        end
    elseif self.state == unit_states['frozen'] or unit_states['channeling'] then
      self:set_velocity(0,0)
    end

    self.r = self:get_angle()
  
  
    self.attack_sensor:move_to(self.x, self.y)
    self.aggro_sensor:move_to(self.x, self.y)
  
    if self.area_sensor then self.area_sensor:move_to(self.x, self.y) end
end

function Enemy:draw()
  self.draw_enemy(self)
end

function Enemy:on_collision_enter(other, contact)
    local x, y = contact:getPositions()
    
    if other:is(Wall) then
        self.hfx:use('hit', 0.15, 200, 10, 0.1)
        self:bounce(contact:getNormal())
    
    elseif table.any(main.current.enemies, function(v) return other:is(v) end) then
        if self.being_pushed and math.length(self:get_velocity()) > 60 then
            other:hit(math.floor(self.push_force/4), nil, nil, true)
            self:hit(math.floor(self.push_force/2), nil, nil, true)
            other:push(math.floor(self.push_force/2), other:angle_to_object(self))
            HitCircle{group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1}
            for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = self.color} end
            hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
        end
    end
end

function Enemy:hit(damage)
    if self.invulnerable then return end
    if self.dead then return end
    if self.isBoss then
      self.hfx:use('hit', 0.005, 200, 20)
    else
      self.hfx:use('hit', 0.25, 200, 10)
    end
    if self.push_invulnerable then return end
    self:show_hp()
  
    local actual_damage = math.max(self:calculate_damage(damage)*(self.stun_dmg_m or 1), 0)
    self.hp = self.hp - actual_damage
    if self.hp > self.max_hp then self.hp = self.max_hp end
    main.current.damage_dealt = main.current.damage_dealt + actual_damage
  
  
    if self.hp <= 0 then
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
  Corpse{group = main.current.main, x = self.x, y = self.y}
end

function Enemy:die()
    self.dead = true
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

function Enemy:slow(amount, duration)
  self.slowed = amount
  self.t:after(duration, function() self.slowed = false end, 'slow')
end

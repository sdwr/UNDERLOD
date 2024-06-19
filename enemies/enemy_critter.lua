
EnemyCritter = Unit:extend()
EnemyCritter:implement(GameObject)
EnemyCritter:implement(Physics)
function EnemyCritter:init(args)
  self:init_game_object(args)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:init_unit()
  Set_Enemy_Shape(self, 'critter')
  self:set_restitution(0.5)

  self.aggro_sensor = Circle(self.x, self.y, 1000)
  self.attack_sensor = Circle(self.x, self.y, 25)

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
    self.target:hit(self.dmg, self)
  end
end

function EnemyCritter:hit(damage, from, damageType)
  if self.dead or self.invulnerable then return end
  self.hfx:use('hit', 0.25, 200, 10)

  self.hp = self.hp - damage
  self:show_damage_number(damage, damageType)

  if from and from.onHitCallbacks then
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
  EnemyCritter.super.die(self)
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

function EnemyCritter:onDeath()
    if self.parent and self.parent.summons then
      self.parent.summons = self.parent.summons - 1
    end
    self.death_function()
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

Summon = Object:extend()
Summon:implement(GameObject)
Summon:implement(Physics)
function Summon:init(args)
  self:init_game_object(args)
  self.attack_sensor = Circle(self.x, self.y, self.rs)
  self.currentTime = 0

  self.state = "charging"

  self.parent.state = 'frozen'
  
  self.color_transparent = self.color:clone()
  self.color_transparent.a = 0.4

  self.summonTime = self.castTime or 3
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
  if self.parent.summons and self.parent.maxSummons and self.parent.summons < self.parent.maxSummons then
    if self.type == 'enemy_critter' then
      for i = 1, self.amount do
        local offset = SpawnGlobals.spawn_offsets[i % #SpawnGlobals.spawn_offsets]
        local x, y = self.x + offset.x, self.y + offset.y
        if Can_Spawn(2, {x = x, y = y}) then
            self.parent.summons = self.parent.summons + 1
            EnemyCritter{group = main.current.main, x = x, y = y, color = grey[0], r = random:float(0, 2*math.pi), 
            v = 10, parent = self.parent}
        end
      end
    else
      for i = 1, self.amount do
        local offset = SpawnGlobals.spawn_offsets[i % #SpawnGlobals.spawn_offsets]
        local x, y = self.x + offset.x, self.y + offset.y
        if Can_Spawn(6, {x = x, y = y}) then
            self.parent.summons = self.parent.summons + 1
            Enemy{type = self.type, group = main.current.main, x = self.x + offset.x, y = self.y + offset.y, level = self.level, parent = self.parent}
        end
      end
    end
  end
  self:recover()
end

function Summon:recover()
  self.state = 'recovering'
  if self and self.parent then self.parent.state = 'normal' end
  if self.suicide and self.parent then
    self.parent:die()
    self.dead = true
  end
  if self then self.dead = true end
end

function Summon:draw()
  if self.hidden then return end

  if self.state == 'charging' then
    graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
      -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
      graphics.circle(self.x, self.y, self.attack_sensor.rs * math.min(self.currentTime / self.summonTime, 1) , self.color_transparent)
      graphics.circle(self.x, self.y, self.attack_sensor.rs, self.color, 1)
    graphics.pop()
  end

end
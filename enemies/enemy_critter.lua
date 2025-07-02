
EnemyCritter = Unit:extend()
EnemyCritter:implement(GameObject)
EnemyCritter:implement(Physics)
function EnemyCritter:init(args)
  self.class = 'enemy_critter'
  self.faction = 'enemy'

  self:init_game_object(args)
  Helper.Unit:add_custom_variables_to_unit(self)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:init_unit()
  Set_Enemy_Shape(self, 'critter')
  self:set_restitution(0.5)

  self.aggro_sensor = Circle(self.x, self.y, 1000)
  self.attack_sensor = Circle(self.x, self.y, 25)

  self.color = args.color or grey[0]
  self:calculate_stats(true)
  --self:push(args.v, args.r) 
  self.t:cooldown(attack_speeds['medium'], function() return self.target and self:distance_to_object(self.target) < self.attack_sensor.rs end, 
  function() self:attack() end, nil, nil, "attack")
end

function EnemyCritter:update(dt)
  self:update_game_object(dt)

  if self.dead then return end

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
    self.target:hit(self.dmg, self, nil, true, false)
  end
end

function EnemyCritter:hit(damage, from, damageType, makesSound, cannotProcOnHit)
  if self.dead or self.invulnerable then return end
  if makesSound == nil then makesSound = true end
  if cannotProcOnHit == nil then cannotProcOnHit = false end

  if makesSound then
    self.hfx:use('hit', 0.25, 200, 10)
  end

  self.hp = self.hp - damage
  self:show_damage_number(damage, damageType)
  
  -- Track damage dealt by the attacker
  if from and from.total_damage_dealt then
    from.total_damage_dealt = from.total_damage_dealt + damage
  end

  if from and from.onHitCallbacks and not cannotProcOnHit then
    from:onHitCallbacks(self, damage, damageType)
  end
  self:onGotHitCallbacks(from, damage, damageType)

  if self.hp <= 0 then
    local overkill = - self.hp
    if from and from.onKillCallbacks then
      from:onKillCallbacks(self, overkill)
    end
    self:onDeathCallbacks(from)
    
    -- Track kill for the attacker
    if from and from.kills then
      from.kills = from.kills + 1
    end
    
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
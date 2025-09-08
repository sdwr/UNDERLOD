Area = Object:extend()
Area.__class_name = 'Area'
Area:implement(GameObject)
function Area:init(args)
  self:init_game_object(args)

  self.damage = get_dmg_value(self.damage)

  self.unit = args.unit
  self.r = args.r or 32
  self.r = Helper.Unit:apply_area_size_multiplier(self.unit, self.r)

  if self.areatype == 'target' then
    if self.target then
      self.x, self.y = self.target.x, self.target.y
    end
  end
  if self.pick_shape == 'circle' then
    local w = 1.2*self.r
    self.shape = Circle(self.x, self.y, w)
  else
    local w = 1.5*self.w
    local h = self.h and 1.5*self.h or 1.5*w
    self.shape = Rectangle(self.x, self.y, w, h, self.r)
  end

  self.damage = get_dmg_value(self.damage)
  self.damage_type = self.damage_type or DAMAGE_TYPE_PHYSICAL
  self.flashFactor = self.damage / 30
  if self.flashFactor == 0 then self.flashFactor = 0.5 end

  self.color = self.color or fg[0]
  self.color_transparent = Color(args.color.r, args.color.g, args.color.b, 0.08)
  self.fill_whole_area = args.fill_whole_area or false

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
    self:try_damage()
  end

  --self.t:tween(0.05, self, {w = args.w}, math.cubic_in_out, function() self.spring:pull(0.15 * self.flashFactor) end)
  self.t:after(self.duration, function()
    self.color = args.color
    self.active = false
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end

function Area:try_damage()

  local targets = {}
  if self.is_troop then
    targets = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
  else
    -- Enemy areas only check player cursor
    local cursor = main.current.current_arena and main.current.current_arena.player_cursor
    if cursor and not cursor.dead then
      -- Check collision based on shape type
      local hit = false
      if self.pick_shape == 'circle' then
        -- Circle to circle collision
        local dist = math.distance(self.x, self.y, cursor.x, cursor.y)
        hit = dist <= self.shape.rs + (cursor.cursor_radius or 4)
      else
        -- Rectangle to circle collision
        local cursor_circle = Circle(cursor.x, cursor.y, cursor.cursor_radius or 4)
        hit = self.shape:collides_with_circle(cursor_circle)
      end
      
      if hit then
        targets = {cursor}
      else
        targets = {}
      end
    else
      targets = {}
    end
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
        target:hit(self.damage, self.unit, self.damage_type, true, true)
        self:apply_hit_effect(target)
      end
    end

  elseif self.shockDuration then
    for _, target in ipairs(targets) do
      if self:can_hit_with_effect(target, 'shocked') then
        target:shock(self.unit)
        target:hit(self.damage, self.unit, self.damage_type, true, true)
        self:apply_hit_effect(target)
      end
    end

  --changed stun to flat duration based on enemy type
  elseif self.stunsTargets then
    local stun_chance = self.stunChance or 1
    for _, target in ipairs(targets) do

      if self:can_hit_with_effect(target, 'stunned') then
        if math.random() < stun_chance then
          target:stun()
          target:hit(self.damage, self.unit, self.damage_type, true, true)
          self:apply_hit_effect(target)
        end
      end
    end

  elseif self.chillAmount then
    for _, target in ipairs(targets) do
      if self:can_hit_with_effect(target, 'chilled') then
        target:chill(self.damage, self.unit)
        target:hit(self.damage, self.unit, self.damage_type, true, true)
        self:apply_hit_effect(target)
      end
    end

  elseif self.burnDps then
    for _, target in ipairs(targets) do
      target:burn(self.burnDps, BURN_DURATION, self.unit)
    end
  
  elseif self.knockback_force then
    for _, target in ipairs(targets) do
      local angle = target:angle_from_object(self.unit or self)
      if self:can_hit_with_knockback(target) then
        target:hit(self.damage, self.unit, self.damage_type, true, true)
        target:push(self.knockback_force, angle, nil, self.knockback_duration)
        self:apply_hit_effect(target)
      end
    end
  elseif self.debuff then
    for _, target in ipairs(targets) do
      target:add_buff(self.debuff)
    end
  elseif self.damage > 0 then
    for _, target in ipairs(targets) do
      target:hit(self.damage, self.unit, self.damage_type, true, true)
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
  -- Knockback is now handled as damage impulse, so always allow
  return true
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
    and self.damage > 0 then
    self:try_damage()
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
    if self.fill_whole_area then
      graphics.circle(self.x, self.y, self.r, self.color)
    else
      graphics.circle(self.x, self.y, self.r, self.color_transparent)
      graphics.circle(self.x, self.y, self.r, self.color, 1 * self.flashFactor)
    end
  else
    graphics.polyline(self.color, lw, x1, y1 + w10, x1, y1, x1 + w10, y1)
    graphics.polyline(self.color, lw, x2 - w10, y1, x2, y1, x2, y1 + w10)
    graphics.polyline(self.color, lw, x2 - w10, y2, x2, y2, x2, y2 - w10)
    graphics.polyline(self.color, lw, x1, y2 - w10, x1, y2, x1 + w10, y2)
    if self.fill_whole_area then
      graphics.rectangle((x1+x2)/2, (y1+y2)/2, x2-x1, y2-y1, nil, nil, self.color)
    else
      graphics.rectangle((x1+x2)/2, (y1+y2)/2, x2-x1, y2-y1, nil, nil, self.color_transparent)
      graphics.rectangle((x1+x2)/2, (y1+y2)/2, x2-x1, y2-y1, nil, nil, self.color, 1 * self.flashFactor)
    end
  end
  graphics.pop()
end


DotArea = Object:extend()
DotArea.__class_name = 'DotArea'
DotArea:implement(GameObject)
DotArea:implement(Physics)
function DotArea:init(args)
  self:init_game_object(args)
  self:make_shape()

  self.damage = get_dmg_value(self.damage)

  self.closest_sensor = Circle(self.x, self.y, 128)

  if not self.character or self.character == 'base' then
    self.t:every(0.2, function()
      local targets = {}
      if self.team == 'enemy' then
        -- Enemy DoT only checks player cursor
        local cursor = main.current.current_arena and main.current.current_arena.player_cursor
        if cursor and not cursor.dead then
          -- Check if cursor is in shape
          local cursor_circle = Circle(cursor.x, cursor.y, cursor.cursor_radius or 4)
          if main.current.main:get_objects_in_shape(self.shape, {cursor})[1] then
            targets = {cursor}
          else
            targets = {}
          end
        else
          targets = {}
        end
      else
        targets = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
      end
      for _, target in ipairs(targets) do
        target:hit(self.damage/5, self.parent, self.damage_type, true, true)
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
      end
    end, nil, nil, 'dot')
  
  elseif self.character == 'wizard' then
    self.t:every(0.2, function()
    local enemies = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
    if #enemies > 0 then self.spring:pull(0.05, 200, 10) end
    for _, enemy in ipairs(enemies) do
      enemy:hit(self.damage/5, self.parent, self.damage_type, true, true)
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



--leave as reference for future items
ForceArea = Object:extend()
ForceArea.__class_name = 'ForceArea'
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
          enemy:hit(4*self.parent.dmg, self.parent, self.damage_type, true, true)
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

--leave as reference for future items
ForceField = Object:extend()
ForceField.__class_name = 'ForceField'
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

BreatheFire = Object:extend()
BreatheFire.__class_name = 'BreatheFire'
BreatheFire:implement(GameObject)
BreatheFire:implement(Physics)
function BreatheFire:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end

  self.damage = get_dmg_value(self.damage)


  self.currentTime = 0
  self.dot_area = DotArea{follows_caster = true, area_type = 'triangle', team = self.team,
    group = main.current.effects, x = self.x, y = self.y, rs = self.rs, caster = self.parent, parent = self, damage = self.damage, duration = self.duration,
    color = self.color}
  Helper.Unit:set_state(self.parent, unit_states['channeling'])
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
  Helper.Unit:set_state(self.parent, unit_states['idle'])
  self.dead = true
end

function BreatheFire:draw()
  --happens in dotArea
end


Charge = Object:extend()
Charge.__class_name = 'Charge'
Charge:implement(GameObject)
Charge:implement(Physics)
function Charge:init(args)
  self:init_game_object(args)
  self.currentTime = 0

  self.state = "charging"

  Helper.Unit:set_state(self.parent, unit_states['frozen'])

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
Stomp.__class_name = 'Stomp'
Stomp:implement(GameObject)
Stomp:implement(Physics)

function Stomp:init(args)
    self:init_game_object(args)
    self.attack_sensor = Circle(self.x, self.y, self.rs)
    self.currentTime = 0
    self.knockback = self.knockback or false
    self.draw_under_units = true
    self.damage = get_dmg_value(self.damage)
    self.cancel_on_death = self.cancel_on_death

    self.state = "charging"
    self.visual_phase = "charging" -- charging, impact

    if self.target then
      self.x = self.target.x + math.random(-self.target_offset or 0, self.target_offset or 0)
      self.y = self.target.y + math.random(-self.target_offset or 0, self.target_offset or 0)
    end

    self.sound_volume = self.sound_volume or 0.5
    orb1:play({volume = self.sound_volume})

    -- Main effect colors
    self.color = (self.color or red[0]):clone()
    self.color.a = 0.5
    self.white_color = fg[0]:clone()
    self.white_color.a = 0.8
    self.impact_color = yellow[0]:clone()
    self.impact_color.a = 0.5

    -- Properties for the charging animation
    self.current_color = self.color:clone()
    self.circle_thickness = 4
    self.inner_radius = 0 -- Starts as a filled circle
    self.outer_radius = self.attack_sensor.rs

    -- Property for the impact animation
    self.impact_radius = 0

    self.recoveryTime = (self.chargeTime or 1) + 0.25
    local total_time = self.chargeTime or 1

    -- Timing for each phase of the charging animation
    local phase1_end = total_time * 0.2  -- Time to transition from filled to open circle
    local phase2_end = total_time * 0.6  -- Time to transition to white and thick
    local phase3_end = total_time * 1.0  -- Time to transition back to original color

    self.show_inner_circle = true

    -- ===================================================================
    -- REVISED Animation Sequence using Tweens
    -- ===================================================================

    -- Constants for the ring thickness
    local NORMAL_THICKNESS = 2
    local THICKENED_THICKNESS = 4
    -- Calculate the radius change needed for even thickening
    local THICKNESS_CHANGE_HALF = (THICKENED_THICKNESS - NORMAL_THICKNESS) / 2

    -- 1. Starts as a filled circle. Tween to an open circle with NORMAL_THICKNESS.
    self.t:tween(phase1_end, self, {inner_radius = self.attack_sensor.rs - NORMAL_THICKNESS}, math.linear)

    -- 2. After the first phase, tween to THICKENED_THICKNESS and white color.
    -- To thicken evenly, expand the outer radius and shrink the inner radius.
    self.t:after(phase1_end, function()
        self.t:tween(phase2_end - phase1_end, self, {outer_radius = self.attack_sensor.rs + THICKNESS_CHANGE_HALF, inner_radius = self.attack_sensor.rs - NORMAL_THICKNESS - THICKNESS_CHANGE_HALF}, math.linear)
        -- Also tween the color to white.
        self.t:tween(phase2_end - phase1_end, self.current_color, {r = self.white_color.r, g = self.white_color.g, b = self.white_color.b}, math.linear)
    end)

    -- 3. After the second phase, tween back to NORMAL_THICKNESS and the original color.
    self.t:after(phase2_end, function()
        self.t:tween(phase3_end - phase2_end, self, {outer_radius = self.attack_sensor.rs, inner_radius = self.attack_sensor.rs - NORMAL_THICKNESS}, math.linear)
        self.t:tween(phase3_end - phase2_end, self.current_color, {r = self.color.r, g = self.color.g, b = self.color.b}, math.linear)
    end)

    -- Schedule the main actions
    self.t:after(total_time, function() self:stomp() end)
    self.t:after(self.recoveryTime, function() self:recover() end)
end

function Stomp:update(dt)
    if self.unit and self.unit.dead and self.cancel_on_death then self.dead = true; return end
    self:update_game_object(dt)
    self.attack_sensor:move_to(self.x, self.y)
    self.currentTime = self.currentTime + dt
end

function Stomp:stomp()
    if not self or self.dead then return end
    self.state = "recovering"
    self.visual_phase = "impact"

    self.current_color = self.color:clone()
    self.current_color.a = 0.3

    earth2:play{pitch = random:float(0.95, 1.05), volume = self.sound_volume}
    
    -- 5. On impact, start the expanding yellow circle animation.
    self.t:tween(0.2, self, {impact_radius = self.attack_sensor.rs}, math.linear)

    local targets = {}
    if self.team == 'enemy' then
        -- Enemy mortars only check player cursor
        local cursor = main.current.current_arena and main.current.current_arena.player_cursor
        if cursor and not cursor.dead then
            local cursor_circle = Circle(cursor.x, cursor.y, cursor.cursor_radius or 4)
            if self.attack_sensor:is_colliding_with_circle(cursor_circle) then
                targets = {cursor}
            end
        end
    else
        targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies)
    end

    if #targets > 0 then self.spring:pull(0.05, 200, 10) end
    for _, target in ipairs(targets) do
        if self.knockback then
            local angle = target:angle_to_object(self) + math.pi
            target:push(LAUNCH_PUSH_FORCE_BOSS, angle)
        else
            target:slow(0.3, 1, nil)
        end
        target:hit(self.damage, self.unit, self.damage_type, true, false)
        HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
    end
end

function Stomp:recover()
    if self then self.dead = true end
    if self.parent and self.parent.state == 'frozen' then self.parent.state = 'normal' end
end

-- ===================================================================
-- REFACTORED DRAW FUNCTION
-- ===================================================================
function Stomp:draw()
    if self.hidden then return end

    graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)

    if self.visual_phase == "charging" then
        -- Draw the outer circle (the main effect)
        local outer_circle = function() 
            graphics.circle(self.x, self.y, self.outer_radius, self.current_color) 
        end
        
        -- Draw an inner circle with the background color to create the "hollow" effect.
        -- This is a simple masking technique.
        local inner_circle = function() 
            graphics.circle(self.x, self.y, self.inner_radius, self.current_color) 
        end
        
        -- Draw the outline on top.
        if self.show_inner_circle then
            graphics.draw_with_mask(outer_circle, inner_circle, true)
        else
            graphics.circle(self.x, self.y, self.outer_radius, self.current_color, self.circle_thickness)
        end

    elseif self.visual_phase == "impact" then
        -- 5. Draw the expanding yellow impact circle.
        if self.knockback then
            graphics.circle(self.x, self.y, self.impact_radius, self.impact_color, 4)
        else
            graphics.circle(self.x, self.y, self.attack_sensor.rs, self.current_color)
        end
    end
    
    -- Reset graphics state to avoid affecting other objects
    graphics.pop()
end



Mortar = Object:extend()
Mortar.__class_name = 'Mortar'
Mortar:implement(GameObject)
Mortar:implement(Physics)
function Mortar:init(args)
  self:init_game_object(args)

  self.damage = get_dmg_value(self.damage)

  self.state = "charging"

  Helper.Unit:set_state(self.parent, unit_states['frozen'])

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
  Stomp{group = main.current.main, unit = self.unit, team = self.team, x = self.target.x + math.random(-10, 10), y = self.target.y + math.random(-10, 10), rs = self.rs, color = self.color, damage = self.damage, level = self.level, parent = self}
end

function Mortar:recover()
  if self then self.dead = true else return end
  if self.parent then self.parent.state = 'normal' end
end

function Mortar:draw()
end


--might keep if new laser is too tricky
Laser = Object:extend()
Laser.__class_name = 'Laser'
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
  self.t:every(self.tick, function() self:try_damage() end)
end

function Laser:stopSound()
  if self.charge_sound then self.charge_sound:stop() end
  if self.fire_sound then self.fire_sound:stop() end
end

function Laser:try_damage()
  local targets = {}
  if self.damage_troops then
    -- Enemy lasers only check player cursor
    local cursor = main.current.current_arena and main.current.current_arena.player_cursor
    if cursor and not cursor.dead then
      -- Check if cursor is in the laser shape
      if main.current.main:get_objects_in_shape(self.shape, {cursor})[1] then
        targets = {cursor}
      end
    end
  else
    targets = main.current.main:get_objects_in_shape(self.shape, main.current.enemies)
  end
  for _, target in ipairs(targets) do
    target:hit(self.dps * self.tick, self.parent, self.damage_type, true, true)
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
Vanish.__class_name = 'Vanish'
Vanish:implement(GameObject)
Vanish:implement(Physics)
function Vanish:init(args)
  self:init_game_object(args)
  self.currentTime = 0

  self.state = "charging"

  Helper.Unit:set_state(self.parent, unit_states['frozen'])

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
  Helper.Unit:set_state(self.parent, unit_states['idle'])
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

TroopDeathAnimation = Object:extend()
TroopDeathAnimation.__class_name = 'TroopDeathAnimation'
TroopDeathAnimation:implement(GameObject)

function TroopDeathAnimation:init(args)
  self:init_game_object(args)
  
  -- Animation properties
  self.duration = 0.5
  self.elapsed = 0
  
  -- Beam properties
  self.max_width = 20  -- Maximum width of the wider beam
  self.inner_width_ratio = 0.4  -- Inner beam is 40% of outer beam width
  self.height = 120  -- Height of the beam
  
  -- Colors (white semi-transparent)
  self.outer_color = white[0]:clone()
  self.outer_color.a = 0.3
  self.inner_color = white[0]:clone()
  self.inner_color.a = 0.6
  
  -- Position (centered on the troop's death location)
  self.x = args.x or 0
  self.y = args.y or 0
end

function TroopDeathAnimation:update(dt)
  self:update_game_object(dt)
  
  self.elapsed = self.elapsed + dt
  
  -- Die when animation is complete
  if self.elapsed >= self.duration then
    self.dead = true
  end
end

function TroopDeathAnimation:draw()
  -- Calculate current width based on elapsed time
  local progress = self.elapsed / self.duration
  local current_width = self.max_width * progress
  local current_inner_width = current_width * self.inner_width_ratio
  
  -- Calculate alpha fade out in the last 0.2 seconds
  local alpha_multiplier = 1.0
  if progress > 0.8 then
    alpha_multiplier = 1.0 - ((progress - 0.8) / 0.2)
  end

  local outer_color = self.outer_color:clone()
  outer_color.a = outer_color.a * alpha_multiplier
  local inner_color = self.inner_color:clone()
  inner_color.a = inner_color.a * alpha_multiplier
  
  -- Draw outer beam (wider, more transparent)
  graphics.rectangle(self.x, self.y - self.height/2, current_width, self.height, nil, nil, outer_color)
  graphics.rectangle(self.x, self.y - self.height/2, current_inner_width, self.height, nil, nil, inner_color)
end

EnemyDeathAnimation = Object:extend()
EnemyDeathAnimation.__class_name = 'EnemyDeathAnimation'
EnemyDeathAnimation:implement(GameObject)

function EnemyDeathAnimation:init(args)
  self:init_game_object(args)
  
  -- Store reference to the enemy unit
  self.enemy = args.enemy

  -- Animation propertie
  self.duration = 1.5
  if self.enemy.class == 'boss' then
    self.duration = 2.5
  elseif self.enemy.class == 'miniboss' then
    self.duration = 2.0
  elseif self.enemy.class == 'special_enemy' then
    self.duration = 1.5
  elseif self.enemy.class == 'normal_enemy' then
    self.duration = 1.0
  else
    self.duration = 1.0
  end

  self.elapsed = 0
  
  
  -- Create a specific death animation instance
  self.death_animation = DrawAnimations.create_normalized_animation(self.enemy, 'death', self.duration)
  self.death_anim_set = self.enemy.spritesheet and self.enemy.spritesheet['death']
  
  -- Calculate and store the base scale (works even if enemy is GCed)
  self.base_scale_x, self.base_scale_y = DrawAnimations.calculate_enemy_scale(self.enemy)
  
  -- Position where the enemy died
  self.x = args.x or 0
  self.y = args.y or 0
  
  -- Death animation specific properties
  self.fade_start_time = 0.8  -- Start fading at 80% of duration
  
  -- Particle effects
  self.particle_timer = 0
  self.particle_interval = 0.1
end

function EnemyDeathAnimation:update(dt)
  self:update_game_object(dt)
  
  self.elapsed = self.elapsed + dt
  
  -- Update the death animation if it exists
  if self.death_animation then
    self.death_animation:update(dt)
  end
  
  -- Spawn particles in the first 30% of the animation
  if self.elapsed <= self.duration * 0.3 then
    self.particle_timer = self.particle_timer + dt
    if self.particle_timer >= self.particle_interval then
      self.particle_timer = 0
      -- Spawn small particles around the animation
      for i = 1, random:int(1, 3) do
        local angle = random:float(0, math.pi * 2)
        local distance = random:float(5, 15)
        local px = self.x + math.cos(angle) * distance
        local py = self.y + math.sin(angle) * distance
        HitParticle{group = main.current.effects, x = px, y = py, color = self.enemy.color or fg[0]}
      end
    end
  end
  
  -- Die when animation is complete
  if self.elapsed >= self.duration then
    self.dead = true
  end
end

function EnemyDeathAnimation:draw()
  -- Calculate alpha fade from 1.0 to 0.3 over the entire duration
  local fade_progress = self.elapsed / self.duration
  local alpha = 1.0 - (fade_progress * 0.7)  -- Goes from 1.0 to 0.3
  
  -- Try to draw the death animation using the helper function
  if self.death_animation and self.death_anim_set then
    -- Create a temporary anim_set with the normalized animation
    local temp_anim_set = {self.death_animation, self.death_anim_set[2]}
    
    local animation_success = DrawAnimations.draw_death_animation(
      self.enemy,
      temp_anim_set,
      self.x, 
      self.y, 
      0,  -- rotation
      1.0, -- scale (no additional scaling)
      alpha
    )
    
    if animation_success then
      return
    end
  end
  
  -- -- Fallback to simple colored circle if no spritesheet available
  -- local color = self.enemy.color or fg[0]
  -- local fallback_color = color:clone()
  -- fallback_color.a = alpha
  
  -- graphics.push(self.x, self.y, 0, 1, 1)
  --   graphics.circle(self.x, self.y, self.enemy.shape.w / 2, fallback_color)
  -- graphics.pop()
end

RallyCircle = Object:extend()
RallyCircle.__class_name = 'RallyCircle'
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

-- ====================================================================
-- CustomCursor Class
-- A custom cursor effect that changes when the left mouse button is held down.
-- ====================================================================

-- ====================================================================
-- CustomCursor Class
-- A custom cursor effect that changes when the left mouse button is held down.
-- Version 2: Uses a pointer/arrow shape instead of a circle.
-- ====================================================================

-- ====================================================================
-- CustomCursor Class
-- A custom cursor effect that changes when the left mouse button is held down.
-- Version 3: Corrected to draw all elements at absolute positions.
-- ====================================================================

CustomCursor = Object:extend()
CustomCursor.__class_name = 'CustomCursor'
CustomCursor:implement(GameObject)

function CustomCursor:init(args)
    args.group = main.cursorGroup
    self:init_game_object(args)
    
    -- Define cursor mode: 'simple' for menus/buy screen, 'animated' for arena
    self.mode = args.mode or 'simple'
    
    -- Define the cursor's appearance and animations
    self.idle_pulse_radius = 3
    self.pull_pulse_radius = 5
    
    self.idle_pulse_speed = 1.5
    self.pull_pulse_speed = 4
    
    self.ring_spin_speed = 3

    self.pointer_scale = 0.5
    
    -- Colors (assuming yellow[0] is your base yellow color)
    self.base_color = yellow[0]:clone()
    self.pulse_color = yellow[0]:clone()
    self.ring_color = yellow[0]:clone()

    self.outline_color = black[0]:clone()
    self.outline_color.a = 0.9

    -- Timers for animations, driven by the game clock for smoothness
    self.pulse_timer = 0
    self.ring_angle = 0
end

function CustomCursor:update(dt)
    self:update_game_object(dt)

    -- Update cursor position to follow the mouse
    local mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = mouse_x / sx
    mouse_y = mouse_y / sx
    self.x = mouse_x
    self.y = mouse_y
    
    -- Update animation timers
    self.pulse_timer = self.pulse_timer + dt
    self.ring_angle = (self.ring_angle + dt * self.ring_spin_speed) % (2 * math.pi)

    -- The cursor is always active and doesn't die
    self.dead = false
end

function CustomCursor:draw()
    if self.mode == 'simple' then
        self:draw_simple_mode()
    elseif self.mode == 'animated' then
        -- Check if the left mouse button is being held down OR space is held
        self:draw_animated_mode()
    elseif self.mode == 'arena' then
        self:draw_arena_mode()
    else
        self:draw_simple_mode()
    end
end

function CustomCursor:draw_animated_mode()
  if input['m1'].down then
    self:draw_pull_state()
  else
    self:draw_idle_state()
  end
end

function CustomCursor:draw_arena_mode()
  graphics.circle(self.x, self.y, 2, self.base_color, 1)
end

function CustomCursor:draw_pointer_shape(x, y, scale)
  scale = scale or 1
  local angle = -math.pi / 4 -- -45 degrees for a standard top-left pointing cursor

  -- Define shape dimensions based on scale
  local head_height = 14 * scale
  local head_width = 14 * scale
  local tail_width = 4 * scale
  local tail_height = 10 * scale

  -- Use push/translate/rotate to handle all transformations
  graphics.push(x, y)
      graphics.translate(x, y)
      graphics.rotate(angle)
      
      -- We draw all shapes relative to the new (0,0) origin.

      -- Draw Outline first (slightly larger shapes in black)
      -- Outline for head (triangle)
      local outline_triangle_points = {0, -head_height/2, -head_width/2, head_height/2, head_width/2, head_height/2}
      graphics.polygon(outline_triangle_points, self.outline_color)
      -- Outline for tail (rectangle)
      graphics.rectangle(0, head_height/2 + tail_height/2, tail_width + 2, tail_height + 2, 0, 0,self.outline_color)

      -- Draw Fill on top
      -- Fill for head (triangle)
      local inner_triangle_points = {0, (-head_height/2)+1, (-head_width/2)+1, (head_height/2)-1, (head_width/2)-1, (head_height/2)-1}
      graphics.polygon(inner_triangle_points, self.base_color)
      -- Fill for tail (rectangle)
      graphics.rectangle(0, head_height/2 + tail_height/2, tail_width, tail_height, 0, 0, self.base_color)

  graphics.pop()
end

function CustomCursor:draw_simple_mode()
    -- Simple pointer cursor for menus
    self:draw_pointer_shape(self.x, self.y, self.pointer_scale)
end

function CustomCursor:draw_idle_state()
    -- --- Idle Pulse Effect ---
    --scales between 0 and 0.25
    local pulse_alpha_effect = (math.sin(self.pulse_timer * self.idle_pulse_speed) + 1) / 8
    local pulse_radius_offset = pulse_alpha_effect * 6
    self.pulse_color.a = 0.6 + pulse_alpha_effect
    graphics.circle(self.x, self.y, self.idle_pulse_radius + pulse_radius_offset, self.pulse_color)

    -- --- Main Idle Cursor ---
    --self:draw_pointer_shape(self.x, self.y, self.pointer_scale)
end

function CustomCursor:draw_pull_state()
    -- --- Pulling Pulse Effect ---
    local pulse_alpha = (math.sin(self.pulse_timer * self.pull_pulse_speed) + 1) / 2
    local pulse_radius_offset = pulse_alpha * 4
    self.pulse_color.a = (1 - pulse_alpha) * 0.7
    graphics.circle(self.x, self.y, self.pull_pulse_radius + pulse_radius_offset, self.pulse_color)
    
    -- --- Spinning Vortex Ring ---
    local ring_radius = self.pull_pulse_radius * 1.6
    self.ring_color.a = 0.8
    
    -- Use a standard push/translate/rotate/pop block for the spinning effect
    graphics.push(self.x, self.y)
        -- Move the coordinate system's origin to the cursor's position
        graphics.translate(self.x, self.y)
        -- Rotate the entire coordinate system
        graphics.rotate(self.ring_angle)
        -- Draw the arcs at the new origin (0,0)
        graphics.arc('open', 0, 0, ring_radius, 0, 2.09, self.ring_color, 2)
        graphics.arc('open', 0, 0, ring_radius, math.pi, math.pi + 2.09, self.ring_color, 2)
    graphics.pop()

    -- --- Main Pulling Cursor ---
    -- Draw the pointer shape slightly larger to indicate power
    --self:draw_pointer_shape(self.x, self.y, self.pointer_scale)
end

function CustomCursor:die()
    self.dead = true
end




Corpse = Object:extend()
Corpse.__class_name = 'Corpse'
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

-- Create a debug line object that can be added to effects group
DebugLine = Object:extend()
DebugLine.__class_name = 'DebugLine'
DebugLine:implement(GameObject)

function DebugLine:init(args)
  self:init_game_object(args)
  self.x1 = args.x1 or self.x
  self.y1 = args.y1 or self.y
  self.x2 = args.x2 or self.x
  self.y2 = args.y2 or self.y
  self.color = args.color or yellow[0]
  self.line_width = args.line_width or 2
  self.duration = args.duration or 1 -- How long the line should last
  
  -- Auto-remove after duration
  if self.duration > 0 then
    self.t:after(self.duration, function() self.dead = true end)
  end
end

function DebugLine:update(dt)
  self:update_game_object(dt)
  -- Update line positions if needed
  if self.update_func then
    self:update_func(dt)
  end
end

function DebugLine:draw()
  graphics.push(self.x1, self.y1, 0, 1, 1)
    graphics.line(self.x1, self.y1, self.x2, self.y2, self.color, self.line_width)
  graphics.pop()
end


Critter = Unit:extend()
Critter:implement(GameObject)
Critter:implement(Physics)
function Critter:init(args)
  self.faction = 'friendly'
  self.class = 'enemy_critter'
  
  self:init_game_object(args)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:init_unit()
  Helper.Unit:add_custom_variables_to_unit(self)
  Set_Enemy_Shape(self, 'critter')
  self:set_restitution(0.5)

  self.attack_sensor = Circle(self.x, self.y, 25)

  self.color = args.color or white[0]
  self:calculate_stats(true)
  self:set_as_steerable(self.v, 400, math.pi, 1)

  self.dmg_type = args.dmg_type or DAMAGE_TYPE_PHYSICAL

  self.t:cooldown(attack_speeds['fast'], function() return self.target and self:distance_to_object(self.target) < self.attack_sensor.rs end, 
  function() self:attack() end, nil, nil, "attack")

end

function Critter:update(dt)
  Critter.super.update(self, dt)

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
    self.target:hit(self.dmg, self, self.dmg_type, true, false)
  end
end


function Critter:hit(damage, from, damageType, playHitEffects, cannotProcOnHit)
  -- Use the indirect hit function (current behavior)
  Helper.Damage:indirect_hit(self, damage, from, damageType, playHitEffects)
end

function Critter:push(f, r, push_invulnerable, duration)
  -- Apply damage impulse instead of state change
  Helper.Unit:apply_knockback(self, f, r)
  
  self.push_force = f
  self.being_pushed = true
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
    --delay the damage to avoid box2d lock
    self.t:after(0, function()
      if self and not self.dead then
        self:hit(dmg, other, nil, true, false)
      end
    end)
  end
end


function Critter:on_trigger_enter(other, contact)
  --[[if other:is(Enemy) then
    critter2:play{pitch = random:float(0.65, 0.85), volume = 0.1}
    self:hit(1)
    other:hit(self.dmg, self)
  end]]--
end


DebugCircle = Object:extend()
DebugCircle.__class_name = 'DebugCircle'
DebugCircle:implement(GameObject)
function DebugCircle:init(args)
  self:init_game_object(args)
  
  self.radius = args.radius or 10
  self.color = args.color or white[0]
  self.line_width = args.line_width or 1
  self.duration = args.duration or 1
  self.start_time = love.timer.getTime()
end

function DebugCircle:update(dt)
  self:update_game_object(dt)
  
  local elapsed = love.timer.getTime() - self.start_time
  if elapsed > self.duration then
    self.dead = true
  end
end

function DebugCircle:draw()
  local elapsed = love.timer.getTime() - self.start_time
  local alpha = math.max(0, 1 - (elapsed / self.duration))
  
  local color = self.color:clone()
  color.a = alpha * 0.5
  
  graphics.circle(self.x, self.y, self.radius, color, self.line_width)
end


DebugOval = Object:extend()
DebugOval.__class_name = 'DebugOval'
DebugOval:implement(GameObject)
function DebugOval:init(args)
  self:init_game_object(args)
  
  self.rx = args.rx or args.radius_x or 30  -- horizontal radius
  self.ry = args.ry or args.radius_y or 15  -- vertical radius
  self.color = args.color or white[0]
  self.line_width = args.line_width or 1
  self.duration = args.duration or 1
  self.segments = args.segments or 32
  self.start_time = love.timer.getTime()
end

function DebugOval:update(dt)
  self:update_game_object(dt)
  
  local elapsed = love.timer.getTime() - self.start_time
  if elapsed > self.duration then
    self.dead = true
  end
end

function DebugOval:draw()
  local elapsed = love.timer.getTime() - self.start_time
  local alpha = math.max(0, 1 - (elapsed / self.duration))
  
  local color = self.color:clone()
  color.a = alpha * 0.5
  
  -- Draw ellipse as a series of lines
  local points = {}
  for i = 0, self.segments do
    local angle = (i / self.segments) * 2 * math.pi
    local px = self.x + self.rx * math.cos(angle)
    local py = self.y + self.ry * math.sin(angle)
    table.insert(points, px)
    table.insert(points, py)
  end
  
  -- Close the loop
  table.insert(points, points[1])
  table.insert(points, points[2])
  
  love.graphics.setLineWidth(self.line_width)
  love.graphics.setColor(color.r, color.g, color.b, color.a)
  love.graphics.line(points)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setLineWidth(1)
end


OrbDangerLine = Object:extend()
OrbDangerLine.__class_name = 'OrbDangerLine'
OrbDangerLine:implement(GameObject)
function OrbDangerLine:init(args)
  self:init_game_object(args)
  
  self.parent = args.parent
  self.orb = args.orb
  
  -- Line endpoints
  self.x1 = self.parent.x
  self.y1 = self.parent.y
  self.x2 = self.orb.x
  self.y2 = self.orb.y
  
  -- Visual properties
  self.width = 2
  self.base_alpha = 0.15
  self.pulse_speed = 3
  self.pulse_amplitude = 0.1
  
  -- Floor effect properties
  self.floor_effect = 'orb_danger_targeting'
  self.pick_shape = 'line'
  self.color = args.color or red[5]
  self.color_transparent = Color(self.color.r, self.color.g, self.color.b, self.base_alpha)
  
  self.timer = 0
end

function OrbDangerLine:update(dt)
  self:update_game_object(dt)
  
  -- Check if parent or orb is dead
  if not self.parent or self.parent.dead or not self.orb or self.orb.dead then
    self.dead = true
    return
  end
  
  -- Update line endpoints to follow parent and orb
  self.x1 = self.parent.x
  self.y1 = self.parent.y
  self.x2 = self.orb.x
  self.y2 = self.orb.y
  
  -- Animate alpha with pulsing effect
  self.timer = self.timer + dt
  local pulse = math.sin(self.timer * self.pulse_speed) * self.pulse_amplitude
  local current_alpha = math.max(0.05, self.base_alpha + pulse)
  self.color_transparent = Color(self.color.r, self.color.g, self.color.b, current_alpha)
end

function OrbDangerLine:draw()
  -- Floor effects handle the actual drawing through the stencil system
  -- No need to draw here as it's handled by the floor_effect system
end

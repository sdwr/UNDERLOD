-- Weapon-owned effects use the main group for lifecycle and its ground pass
-- for telegraphs. They have no Box2D bodies and never create effects in a
-- collision callback. Damage is a weapon hit (can crit), not a recursive proc.
WeaponEffect = Object:extend()
WeaponEffect.__class_name = 'WeaponEffect'
WeaponEffect:implement(GameObject)

function WeaponEffect:init(args)
  self:init_game_object(args)
  self.x, self.y = self.unit.x, self.unit.y
  self.start_x, self.start_y = self.x, self.y
  self.target_x = self.target and self.target.x or self.x
  self.target_y = self.target and self.target.y or self.y
  self.color = get_weapon_effect_color(self.kind)
  self.elapsed, self.impact_age = 0, nil
  self.damage = self.weapon.damage * self.damage_multi
  self.radius = (self.weapon.def.radius or self.weapon.range) * (self.unit.area_size_m or 1)
  self.angle = math.atan2(self.target_y - self.y, self.target_x - self.x)
  self.hit_cooldowns = {{}, {}}
  self.orbit_angle = 0
  self.zap_timer = 0
  if self.kind == 'cannon' then
    self.flight_time = math.max(0.12, math.distance(self.x, self.y, self.target_x, self.target_y) / 220)
  elseif self.kind == 'meteor' then
    self.flight_time = 0.65
  elseif self.kind == 'radiance' then
    -- Aura range already includes both Reach and Area in update_weapon_stats.
    self.radius = self.weapon.range
    self:impact(self.x, self.y, true)
  end
end

function WeaponEffect:owns_weapon()
  if not self.unit or self.unit.dead then return false end
  for _, weapon in ipairs(self.unit.weapons or {}) do
    if weapon == self.weapon then return true end
  end
  return false
end

function WeaponEffect:hit(target, damage)
  if not target or target.dead then return end
  Helper.Damage:indirect_hit(target, damage, self.unit, DAMAGE_TYPE_PHYSICAL, true,
    {canCrit = true, noRicochet = true})
end

function WeaponEffect:impact(x, y, ignite)
  self.x, self.y, self.impact_age = x, y, 0
  local targets = main.current.main:get_objects_in_shape(Circle(x, y, self.radius), main.current.enemies)
  for _, target in ipairs(targets) do
    self:hit(target, self.damage)
    if ignite and not target.dead and target.burn then target:burn(self.damage * 0.4, self.unit) end
  end
  if self.kind ~= 'radiance' then
    earth1:play{volume = 0.25, pitch = self.kind == 'meteor' and 0.8 or 1.2}
  end
end

function WeaponEffect:orb_position(index)
  local angle = self.orbit_angle + (index - 1) * math.pi
  local radius = self.weapon.range
  return self.unit.x + math.cos(angle) * radius, self.unit.y + math.sin(angle) * radius
end

function WeaponEffect:update_orbit(dt)
  self.orbit_angle = self.orbit_angle + 2.5 * dt
  self.x, self.y = self.unit.x, self.unit.y
  self.radius = self.weapon.def.radius * (self.unit.area_size_m or 1)
  for index = 1, 2 do
    local cooldowns = self.hit_cooldowns[index]
    for target, time in pairs(cooldowns) do
      local remaining = time - dt
      cooldowns[target] = not target.dead and remaining > 0 and remaining or nil
    end
    if self.weapon.can_fire then
      local x, y = self:orb_position(index)
      local targets = main.current.main:get_objects_in_shape(Circle(x, y, self.radius), main.current.enemies)
      for _, target in ipairs(targets) do
        if not cooldowns[target] and not target.dead then
          self:hit(target, self.weapon.damage * self.damage_multi)
          cooldowns[target] = math.max(0.05, self.weapon.cooldown * (Helper.Unit.closest_enemy_distance_multiplier or 1))
        end
      end
    end
  end
end

function WeaponEffect:zap()
  local targets = main.current.main:get_objects_in_shape(Circle(self.x, self.y, self.radius), main.current.enemies)
  table.sort(targets, function(a, b)
    return math.distance(self.x, self.y, a.x, a.y) < math.distance(self.x, self.y, b.x, b.y)
  end)
  local count = 0
  for _, target in ipairs(targets) do
    if not target.dead then
      self:hit(target, self.damage)
      if not target.dead and target.shock then target:shock(self.unit) end
      LightningLine{group = main.current.effects, src = self, dst = target,
        color = self.color, generations = 3, max_offset = 7}
      count = count + 1
      if count == 3 then break end
    end
  end
  if count > 0 then spark2:play{volume = 0.15} end
end

function WeaponEffect:update(dt)
  self:update_game_object(dt)
  if self.dead then return end
  if not self:owns_weapon() then self.dead = true; return end
  self.elapsed = self.elapsed + dt
  if self.kind == 'orbit' then
    self:update_orbit(dt)
  elseif self.kind == 'lightning' then
    if self.elapsed >= 1.8 then self.dead = true; return end
    self.x = self.x + math.cos(self.angle) * 35 * dt
    self.y = self.y + math.sin(self.angle) * 35 * dt
    self.zap_timer = self.zap_timer - dt
    if self.zap_timer <= 0 then self:zap(); self.zap_timer = 0.45 end
  elseif self.impact_age then
    self.impact_age = self.impact_age + dt
    if self.kind == 'radiance' then self.x, self.y = self.unit.x, self.unit.y end
    if self.impact_age >= 0.3 then self.dead = true end
  elseif self.elapsed >= self.flight_time then
    self:impact(self.target_x, self.target_y, false)
  elseif self.kind == 'cannon' then
    local t = self.elapsed / self.flight_time
    self.x = self.start_x + (self.target_x - self.start_x) * t
    self.y = self.start_y + (self.target_y - self.start_y) * t
  end
end

function WeaponEffect:draw_ground()
  if self.dead or not self:owns_weapon() then return end
  local inner, outer = self.color:clone(), self.color:clone()
  outer.a = 0
  if self.impact_age then
    local fade = 1 - self.impact_age / 0.3
    inner.a = 0.22 * fade
    graphics.gradient_circle(self.x, self.y, self.radius, inner, outer)
    inner.a = 0.45 * fade
    graphics.circle(self.x, self.y, self.radius * (0.65 + 0.35 * (1 - fade)), inner, 1)
  elseif self.kind == 'meteor' then
    inner.a = 0.1
    graphics.gradient_circle(self.target_x, self.target_y, self.radius, inner, outer)
    inner.a = 0.35
    graphics.circle(self.target_x, self.target_y, self.radius * math.min(1, self.elapsed / self.flight_time), inner, 1)
  end
end

function WeaponEffect:draw()
  if self.dead or not self:owns_weapon() or self.impact_age then return end
  if self.kind == 'orbit' then
    for index = 1, 2 do
      local x, y = self:orb_position(index)
      local glow = self.color:clone(); glow.a = 0.15
      local edge = self.color:clone(); edge.a = 0
      graphics.gradient_circle(x, y, self.radius * 1.8, glow, edge)
      graphics.circle(x, y, self.radius, self.color)
      graphics.circle(x - self.radius * 0.2, y - self.radius * 0.2, self.radius * 0.35, fg[0])
    end
  elseif self.kind == 'lightning' then
    local radius = 4 * (self.unit.area_size_m or 1)
    for index = 1, 4 do
      local angle = self.elapsed * 8 + index * math.pi / 2
      graphics.line(self.x, self.y, self.x + math.cos(angle) * radius * 2,
        self.y + math.sin(angle) * radius * 2, self.color, 1)
    end
    graphics.circle(self.x, self.y, radius, fg[0])
  elseif self.kind == 'cannon' then
    local lift = math.sin(math.pi * self.elapsed / self.flight_time) * 12
    graphics.circle(self.x, self.y - lift, 4, self.color)
    graphics.circle(self.x - 1, self.y - lift - 1, 1.5, fg[0])
  elseif self.kind == 'meteor' then
    local progress = math.min(1, self.elapsed / self.flight_time)
    local x, y = self.target_x + 24 * (1 - progress), self.target_y - 80 * (1 - progress)
    local tail = self.color:clone(); tail.a = 0.4
    graphics.line(x, y, x + 9, y - 26, tail, 5)
    graphics.circle(x, y, 6, self.color)
    graphics.circle(x - 1, y - 1, 3, yellow[0])
  end
end

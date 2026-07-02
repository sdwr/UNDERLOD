
Stomp_Spell = Spell:extend()
function Stomp_Spell:init(args)
  Stomp_Spell.super.init(self, args)

  self.attack_sensor = Circle(self.x, self.y, self.rs)

  orb1:play({volume = 0.5})

  self.damage = get_dmg_value(self.damage)
  self.knockback = self.knockback or false

  self.color = self.color or red[0]
  self.color_transparent = self.color:clone()
  self.color_transparent.a = 0.2

  -- Ground gradient colors (see Stomp in miscellaneous_objects.lua).
  self.pool_inner = self.color:clone(); self.pool_inner.a = 0.22
  self.pool_outer = self.color:clone(); self.pool_outer.a = 0.03
  self.fill_inner = self.color:clone(); self.fill_inner.a = 0.12
  self.fill_outer = self.color:clone(); self.fill_outer.a = 0.34
end

function Stomp_Spell:update(dt)
  Stomp_Spell.super.update(self, dt)
  self.attack_sensor:move_to(self.x, self.y)
end

-- Ground layer: drawn by the arena's ground-effect pass so the telegraph sits
-- under units.
function Stomp_Spell:draw_ground()
  graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
    local rs = self.attack_sensor.rs
    local pulse = 1 + 0.03*math.sin(8*self.elapsedTime)
    graphics.gradient_circle(self.x, self.y, rs*pulse, self.pool_inner, self.pool_outer)

    -- Edge-weighted fill growing with charge progress so the expanding
    -- boundary reads as a countdown.
    local progress = math.min(self.elapsedTime / (self.spell_duration or 1), 1)
    graphics.gradient_circle(self.x, self.y, rs*progress, self.fill_inner, self.fill_outer)

    -- Rim: subtle glow halo brightening with the charge, crisp core ring, and
    -- slow rotating dashes for a hint of motion.
    local glow_w = 4 + 2*progress
    local glow_edge = self.color:clone(); glow_edge.a = 0
    local glow_peak = self.color:clone(); glow_peak.a = 0.08 + 0.14*progress
    graphics.gradient_annulus(self.x, self.y, math.max(rs - glow_w, 0), rs, glow_edge, glow_peak)
    graphics.gradient_annulus(self.x, self.y, rs, rs + glow_w, glow_peak, glow_edge)

    graphics.circle(self.x, self.y, rs, self.color, 1)

    local spin = self.elapsedTime*(0.8 + 1.0*progress)
    local dash_color = fg[0]:clone()
    dash_color.a = 0.15 + 0.2*progress
    for i = 0, 2 do
      local a0 = spin + i*(2*math.pi/3)
      graphics.arc('open', self.x, self.y, rs, a0, a0 + 0.45, dash_color, 2)
    end
  graphics.pop()
end

function Stomp_Spell:draw()
  Stomp_Spell.super.draw(self)
end


-- Cancel (e.g. caster died) must not detonate the stomp: base cancel routes
-- through die(), so flag it and skip the impact.
function Stomp_Spell:cancel()
  self.cancelled = true
  Stomp_Spell.super.cancel(self)
end

function Stomp_Spell:die()
  if self.cancelled then
    Stomp_Spell.super.die(self)
    return
  end

  usurer1:play{pitch = random:float(0.95, 1.05), volume = 1.6}

  -- The spell object dies on impact, so leave a one-shot flash behind for the
  -- actual hit moment.
  GroundFlash{
    group = main.current.main,
    x = self.x, y = self.y,
    rs = self.attack_sensor.rs,
    duration = 0.35,
    impact_ring = self.knockback,
  }

  local targets = {}
  if self.team == 'enemy' then
    targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.friendlies)
  else
    targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies)
  end
  if #targets > 0 then self.spring:pull(0.05, 200, 10) end
  for _, target in ipairs(targets) do
    target:hit(self.damage, self.unit, nil, true, false)
    if self.knockback then
      target:push(LAUNCH_PUSH_FORCE_BOSS, self.unit:angle_to_object(target))
    else
      target:slow(0.3, 1, nil)
    end
    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end

    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
  end

  Stomp_Spell.super.die(self)
end
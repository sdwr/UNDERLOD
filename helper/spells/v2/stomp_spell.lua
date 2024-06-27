
Stomp_Spell = Spell:extend()
function Stomp_Spell:init(args)
  Stomp_Spell.super.init(self, args)

  self.attack_sensor = Circle(self.x, self.y, self.rs)

  orb1:play({volume = 0.5})

  self.color = self.color or red[0]
  self.color_transparent = self.color:clone()
  self.color_transparent.a = 0.2
end

function Stomp_Spell:update(dt)
  Stomp_Spell.super.update(self, dt)
  self.attack_sensor:move_to(self.x, self.y)
end

function Stomp_Spell:draw()

  graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
    -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
    graphics.circle(self.x, self.y, self.attack_sensor.rs * math.min(self.elapsedTime / (self.spell_duration or 1), 1) , self.color_transparent)
    graphics.circle(self.x, self.y, self.attack_sensor.rs, self.color, 1)
  graphics.pop()
  
end


function Stomp_Spell:die()
  usurer1:play{pitch = random:float(0.95, 1.05), volume = 1.6}

  local targets = {}
  if self.team == 'enemy' then
    targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.friendlies)
  else
    targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies)
  end
  if #targets > 0 then self.spring:pull(0.05, 200, 10) end
  for _, target in ipairs(targets) do
    target:hit(self.dmg, self.unit)
    target:slow(0.3, 1, nil)
    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = self.color} end
    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
  end

  Stomp_Spell.super.die(self)
end
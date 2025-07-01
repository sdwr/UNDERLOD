
Summon_Spell = Spell:extend()
function Summon_Spell:init(args)
  Summon_Spell.super.init(self, args)

  self.attack_sensor = Circle(self.x, self.y, self.rs)

  self.summonType = self.summonType or 'enemy_critter'
  self.summonAmount = self.summonAmount or 4

  pop2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.color = self.color or purple[0]

end

function Summon_Spell:update(dt)
  Summon_Spell.super.update(self, dt)
  self.attack_sensor:move_to(self.x, self.y)
end

function Summon_Spell:draw()
  graphics.push(self.x, self.y, self.r + (self.vr or 0), self.spring.x, self.spring.x)
    -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
    graphics.circle(self.x, self.y, self.attack_sensor.rs * math.min(self.elapsedTime / (self.spell_duration or 1), 1) , self.color_transparent)
    graphics.circle(self.x, self.y, self.attack_sensor.rs, self.color, 1)
  graphics.pop()
end

function Summon_Spell:spawn()
  if not self.unit or self.unit.dead or not self.unit.state == unit_states['channeling'] then return end

  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  spawn1:play{pitch = random:float(0.8, 1.2), volume = 0.15}
  if self.summonType == 'enemy_critter' then
    for i = 1, self.summonAmount do
      local offset = SpawnGlobals.spawn_offsets[i % #SpawnGlobals.spawn_offsets]
      local x, y = self.x + offset.x, self.y + offset.y
      if Can_Spawn(2, {x = x, y = y}) then
          local enemy = EnemyCritter{group = main.current.main, x = x, y = y, color = grey[0], r = random:float(0, 2*math.pi), 
          v = 10, parent = self.unit}
          Spawn_Enemy_Effect(main.current, enemy)
      end
    end
  else
    for i = 1, self.summonAmount do
      local offset = SpawnGlobals.spawn_offsets[i % #SpawnGlobals.spawn_offsets]
      local x, y = self.x + offset.x, self.y + offset.y
      if Can_Spawn(6, {x = x, y = y}) then
          local enemy = Enemy{type = self.type, group = main.current.main, x = self.x + x, y = self.y + y, level = self.level, parent = self.unit}
          Spawn_Enemy_Effect(main.current, enemy)
      end
    end
  end
end

function Summon_Spell:die()
  self:spawn()

  Summon_Spell.super.die(self)
  if self.unit_dies_at_end and self.unit then
    self.unit:die()
  end
end

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
  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  spawn1:play{pitch = random:float(0.8, 1.2), volume = 0.15}
  if self.summonType == 'enemy_critter' then
    for i = 1, self.amount do
      local offset = SpawnGlobals.spawn_offsets[i % #SpawnGlobals.spawn_offsets]
      local x, y = self.x + offset.x, self.y + offset.y
      if Can_Spawn(2, {x = x, y = y}) then
          EnemyCritter{group = main.current.main, x = x, y = y, color = grey[0], r = random:float(0, 2*math.pi), 
          v = 10, parent = self.unit}
      end
    end
  else
    for i = 1, self.amount do
      local offset = SpawnGlobals.spawn_offsets[i % #SpawnGlobals.spawn_offsets]
      local x, y = self.x + offset.x, self.y + offset.y
      if Can_Spawn(6, {x = x, y = y}) then
          Enemy{type = self.type, group = main.current.main, x = self.x + offset.x, y = self.y + offset.y, level = self.level, parent = self.unit}
      end
    end
  end
end

function Summon_Spell:finish_cast()
  self:spawn()

  Summon_Spell.super.finish_cast(self)
end

Mortar_Spell = Spell:extend()
function Mortar_Spell:init(args)
  Mortar_Spell.super.init(self, args)

  self.color = self.color or red[0]
  turret_hit_wall2:play{volume = 0.9}

  self.num_shots = self.num_shots or 3
  self.shot_interval = self.shot_interval or 0.7

  self.dmg = self.dmg or 30
  self.rs = self.rs or 25

  --memory
  self.next_shot = 0.2
  self.shots_left = self.num_shots
end

function Mortar_Spell:update(dt)
  Mortar_Spell.super.update(self, dt)
  self.next_shot = self.next_shot - dt
  if self.next_shot <= 0 then
    self.next_shot = self.shot_interval
    self:fire()
  end
end

function Mortar_Spell:draw()
  Mortar_Spell.super.draw(self)
end

function Mortar_Spell:fire()

  local target = self.unit:my_target()
  if not target then return end
  cannoneer1:play{pitch = random:float(0.95, 1.05), volume = 0.9}

  Stomp{
    group = main.current.main,
    unit = self.unit,
    team = "enemy",
    x = target.x + math.random(-10, 10),
    y = target.y + math.random(-10, 10),
    target = target,
    rs = self.rs,
    color = self.color,
    dmg = self.dmg,
    level = self.level,
  }

  self.shots_left = self.shots_left - 1
  if self.shots_left <= 0 then self:finish_cast() end
end

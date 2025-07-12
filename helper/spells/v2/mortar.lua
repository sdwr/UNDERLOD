Mortar_Spell = Spell:extend()
function Mortar_Spell:init(args)
  Mortar_Spell.super.init(self, args)

  self.color = self.color or red[0]
  turret_hit_wall2:play{volume = 0.9}

  self.knockback = self.knockback or false

  self.num_shots = self.num_shots or 3
  self.shot_interval = self.shot_interval or 0.7

  self.damage = get_dmg_value(self.damage)
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

  self.shots_left = self.shots_left - 1
  if self.shots_left <= 0 then self:die() end

  local target = self.target
  if not target then return end
  cannoneer1:play{pitch = random:float(0.95, 1.05), volume = 0.9}

  Stomp{
    group = main.current.main,
    unit = self.unit,
    team = "enemy",
    target_offset = 10,
    target = target,
    rs = self.rs,
    chargeTime = 1.5,
    knockback = self.knockback,
    color = self.color,
    damage = self.damage,
    level = self.level,
  }

end

-- ===================================================================
-- LINE MORTAR SPELL
-- Fires a line of mortars over time in a specific direction
-- ===================================================================
LineMortar_Spell = Spell:extend()
function LineMortar_Spell:init(args)
  LineMortar_Spell.super.init(self, args)

  self.color = self.color or red[0]
  turret_hit_wall2:play{volume = 0.9}

  self.knockback = self.knockback or false

  self.num_shots = self.num_shots or 5
  self.shot_interval = self.shot_interval or 0.5
  self.line_length = self.line_length or 200  -- Total length of the line

  self.damage = get_dmg_value(self.damage)
  self.rs = self.rs or 20

  if self.target then
    self.line_angle = math.atan2(self.target.y - self.y, self.target.x - self.x)
  else
    self.line_angle = random:float(0, 2 * math.pi)
  end

  --memory
  self.next_shot = 0.2
  self.shots_left = self.num_shots
  self.shots_fired = 0
end

function LineMortar_Spell:update(dt)
  LineMortar_Spell.super.update(self, dt)
  self.next_shot = self.next_shot - dt
  if self.next_shot <= 0 then
    self.next_shot = self.shot_interval
    self:fire()
  end
end

function LineMortar_Spell:draw()
  LineMortar_Spell.super.draw(self)
end

function LineMortar_Spell:fire()
  self.shots_left = self.shots_left - 1
  self.shots_fired = self.shots_fired + 1
  if self.shots_left <= 0 then self:die() end

  cannoneer1:play{pitch = random:float(0.95, 1.05), volume = 0.2}

  -- Calculate position along the line
  local progress = self.shots_fired / self.num_shots
  local distance_along_line = progress * self.line_length
  
  -- Calculate target position
  local target_x = self.unit.x + math.cos(self.line_angle) * distance_along_line
  local target_y = self.unit.y + math.sin(self.line_angle) * distance_along_line

  Stomp{
    group = main.current.main,
    unit = self.unit,
    team = "enemy",
    target_offset = 10,
    x = target_x,
    y = target_y,
    rs = self.rs,
    chargeTime = 1.0,
    knockback = self.knockback,
    sound_volume = 0.2,
    color = self.color,
    damage = self.damage,
    level = self.level,
  }
end
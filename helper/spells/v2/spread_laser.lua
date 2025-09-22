

Spread_Laser = Spell:extend()
function Spread_Laser:init(args)
  Spread_Laser.super.init(self, args)

  self.color = self.color or red[0]
  self.laser_aim_widths = self.laser_aim_width or 6
  self.damage = get_dmg_value(self.damage)
  self.damage_troops = self.damage_troops or true

  self.num_shots = self.num_shots or 3
  self.shot_interval = self.shot_interval or 0.2
  self.rotation_direction = self.rotation_direction or 1
  self.total_rotation = self.total_rotation  -- Total arc to cover (in radians)
  self.both_directions = self.both_directions or false  -- Fire in both directions at once
  self.starting_r = self.starting_r  -- Optional starting rotation

  self.charge_duration = self.charge_duration or 1
  self.fire_duration = self.fire_duration or 0.2

  self.spell_duration = (self.num_shots * self.shot_interval) + self.charge_duration + 0.2
  --memory
  self.laser_beams = {}
  self.elapsed_time = 0
  self.next_shot = 0.2
  self.shots_left = self.num_shots
  self.r = 0
  self.r_offset = 0
  self.shot_index = 0  -- Track which shot we're on

  self:initCoords()
end

function Spread_Laser:initCoords()
  if self.starting_r then
    self.r = self.starting_r
  elseif self.spread_type == 'target' then
    self.target = self.unit:my_target()
    if not self.target then return end
    self.target_x = self.target.x
    self.target_y = self.target.y
    self.r = math.atan2(self.target_y - self.unit.y, self.target_x - self.unit.x)
  elseif self.spread_type == 'scatter' then
    self.r = math.random(0, 2 * math.pi)
  elseif self.spread_type == 'forward' then
    self.r = self.unit:get_angle()
  end
end

function Spread_Laser:update(dt)
  Spread_Laser.super.update(self, dt)
  self.next_shot = self.next_shot - dt
  if self.next_shot <= 0 and self.shots_left > 0 then
    self.next_shot = self.shot_interval
    self.shots_left = self.shots_left - 1
    local r_offset = self:get_next_rotation()
    if self.both_directions then
      self:shoot_laser(self.r + r_offset)
      self:shoot_laser(self.r - r_offset)
    else
      self:shoot_laser(self.r + r_offset)

    end
  end
end

function Spread_Laser:draw()

end

function Spread_Laser:get_next_rotation()
  local i = self.num_shots - self.shots_left

  if self.spread_type == 'scatter' then
    local offset = (math.pi * 2) / self.num_shots * self.rotation_direction
    self.r_offset = self.r_offset + offset
  elseif self.spread_type == 'forward' then
    if self.both_directions or self.total_rotation then
      -- First shot is forward, then alternate outward in both directions
        local step = self.total_rotation / (self.num_shots - 1) * 2  -- Spread step
        self.r_offset = step * i
    else
      -- Default circular spread
      local offset = (math.pi * 2) / self.num_shots * self.rotation_direction
      self.r_offset = self.r_offset + offset
    end
  elseif self.spread_type == 'target' then
    --oscillate outwards from the target, first shot is dead center
    local direction = (i % 2 == 0) and -1 or 1

    --i goes from 1 to num_shots
    local multi = 0
    if i == 1 then
      multi = 0
    else
      multi = math.floor(i/2)
    end

    local offset = self.spread_width * multi * direction
    self.r_offset = offset
  end

  return self.r_offset
end

-- have to set x/y/target/unit manually, because its not a cast
--note: each laser shot still has a charge time
--spell ends when all lasers are cast + charge time
function Spread_Laser:shoot_laser(rotation)

  local function create_laser(rotation)
    local spelldata = {
      group = self.group,
      unit = self.unit,
      target = self.target,
      x = self.x,
      y = self.y,
      lasermode = 'fixed',
      rotation_lock = true,
      rotation_offset = rotation,
      charge_duration = self.charge_duration,
      fire_duration = self.fire_duration,
      spell_duration = self.spell_duration,
      color = self.color,
      damage = self.damage,
      reduce_pierce_damage = self.reduce_pierce_damage,
      laser_aim_width = self.laser_aim_width,
      damage_troops = self.damage_troops,
      damage_once = self.damage_once,
      end_spell_on_fire = false,
      fire_follows_unit = false,
      fade_fire_draw = true,
      fade_in_aim_draw = true,
    }
    local laser = Laser_Spell(spelldata)
    table.insert(self.laser_beams, laser)
  end

  create_laser(rotation)
end

function Spread_Laser:die()
  Spread_Laser.super.die(self)
  for i, laser_beam in ipairs(self.laser_beams) do
    --only kill if it's charging
    if laser_beam.is_charging then
      laser_beam:die()
    end
  end
  self.laser_beams = {}
end
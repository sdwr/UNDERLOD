-- A close/mid-range scatter unit. Fires a fan of straight, non-homing pellets
-- toward the target each swing. Damage per pellet is low; the upside is
-- landing several at close range.

Shotgun_Troop = Troop:extend()

SHOTGUN_PELLET_COUNT = 5
SHOTGUN_HALF_SPREAD = math.pi / 8 -- 22.5°, ~45° total cone

function Shotgun_Troop:init(data)
  self.base_attack_range = TROOP_SHOTGUN_RANGE or 250
  Shotgun_Troop.super.init(self, data)

  self.backswing = 0.1
  self.num_pellets = SHOTGUN_PELLET_COUNT
  self.half_spread = SHOTGUN_HALF_SPREAD
end

function Shotgun_Troop:update(dt)
  Shotgun_Troop.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function Shotgun_Troop:draw()
  Shotgun_Troop.super.draw(self)
end

function Shotgun_Troop:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
  self:set_state_functions()
end

function Shotgun_Troop:create_spelldata()
  return {
    group = main.current.main,
    on_attack_callbacks = true,
    spell_duration = 1.5,
    bullet_size = 2,
    pierce = false,
    homing = false,
    speed = 320,
    is_troop = true,
    color = orange[0],
    damage = function() return self.dmg end,
    max_distance = self.attack_range or self.base_attack_range,
  }
end

function Shotgun_Troop:setup_cast(cast_target)
  local data = {
    name = 'shotgun',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function()
      self:stretch_on_attack()
      self:fire_side_pellets(cast_target)
    end,
    unit = self,
    target = cast_target,
    backswing = self.backswing,
    instantspell = true,
    spellclass = ArrowProjectile,
    spelldata = self:create_spelldata(),
  }
  self.castObject = Cast(data)
end

-- The Cast handles the center pellet (fired toward cast_target). This fires
-- the remaining pellets fanned symmetrically around that aim line.
function Shotgun_Troop:fire_side_pellets(cast_target)
  if not cast_target or cast_target.dead then return end

  local angle_to_target = math.atan2(cast_target.y - self.y, cast_target.x - self.x)
  local side_count = self.num_pellets - 1
  if side_count <= 0 then return end

  local half = math.floor(side_count / 2)
  for i = 1, half do
    local offset = self.half_spread * (i / half)
    self:fire_pellet_at_angle(angle_to_target + offset)
    self:fire_pellet_at_angle(angle_to_target - offset)
  end

  -- Odd extra pellet (when num_pellets is even): fire it along center too.
  if side_count % 2 == 1 then
    self:fire_pellet_at_angle(angle_to_target)
  end
end

function Shotgun_Troop:fire_pellet_at_angle(angle)
  local spelldata = self:create_spelldata()
  spelldata.on_attack_callbacks = false
  spelldata.unit = self
  spelldata.angle = angle
  ArrowProjectile(spelldata)
end

function Shotgun_Troop:instant_attack(cast_target)
  local spelldata = self:create_spelldata()
  spelldata.on_attack_callbacks = false
  spelldata.unit = self
  spelldata.target = cast_target
  ArrowProjectile(spelldata)
  self:fire_side_pellets(cast_target)
end

function Shotgun_Troop:set_state_functions()
  self.state_always_run_functions['always_run'] = function(self) end
  self.state_change_functions['death'] = function(self)
    self:cancel_cast()
    Helper.Unit:unclaim_target(self)
  end
end

-- A close/mid-range scatter unit. Fires a fan of straight, non-homing pellets
-- toward the target each swing. Damage per pellet is low; the upside is
-- landing several at close range.

Shotgun_Troop = Troop:extend()

SHOTGUN_PELLET_COUNT = 5
-- Tightened from math.pi/8 -> math.pi/16 (~11.25° half, ~22.5° total cone).
SHOTGUN_HALF_SPREAD = math.pi / 16

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

SHOTGUN_PELLET_MAX_DISTANCE_MULT = 1.3

function Shotgun_Troop:create_spelldata()
  local range = self.attack_range or self.base_attack_range
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
    -- Pellets disappear at engage range * 1.3, giving a thin ribbon of
    -- "stray hit" past the targeting range.
    max_distance = range * SHOTGUN_PELLET_MAX_DISTANCE_MULT,
    -- 5 pellets per swing all play the arrow release sound. Drop each pellet
    -- to a fraction of the default (2) so the combined burst is roughly one
    -- normal arrow rather than five.
    volume = 0.4,
  }
end

function Shotgun_Troop:setup_cast(cast_target)
  local data = {
    name = 'shotgun',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function(cast)
      self:stretch_on_attack()
      if not cast_target or cast_target.dead then return end
      local angle_to_target = math.atan2(cast_target.y - self.y, cast_target.x - self.x)

      -- The Cast's main spell would normally fire on-target. Strip its target
      -- and replace with a random angle inside the cone so every pellet,
      -- including this one, scatters.
      cast.spelldata.target = nil
      cast.spelldata.angle = angle_to_target + random:float(-self.half_spread, self.half_spread)

      -- Fire the remaining pellets (num_pellets - 1) at independent random
      -- angles within the same cone.
      for _ = 1, (self.num_pellets - 1) do
        local angle = angle_to_target + random:float(-self.half_spread, self.half_spread)
        self:fire_pellet_at_angle(angle)
      end
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

function Shotgun_Troop:fire_pellet_at_angle(angle)
  local spelldata = self:create_spelldata()
  spelldata.on_attack_callbacks = false
  spelldata.unit = self
  spelldata.angle = angle
  ArrowProjectile(spelldata)
end

function Shotgun_Troop:instant_attack(cast_target)
  if not cast_target or cast_target.dead then return end
  local angle_to_target = math.atan2(cast_target.y - self.y, cast_target.x - self.x)
  for _ = 1, self.num_pellets do
    local angle = angle_to_target + random:float(-self.half_spread, self.half_spread)
    self:fire_pellet_at_angle(angle)
  end
end

function Shotgun_Troop:set_state_functions()
  self.state_always_run_functions['always_run'] = function(self) end
  self.state_change_functions['death'] = function(self)
    self:cancel_cast()
    Helper.Unit:unclaim_target(self)
  end
end

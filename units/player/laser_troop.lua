Laser_Troop = Troop:extend()
function Laser_Troop:init(data)
  self.base_attack_range = TROOP_RANGE
  Laser_Troop.super.init(self, data)
end

-- can remove this, no need to override
function Laser_Troop:update(dt)
  Laser_Troop.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function Laser_Troop:draw()
  Laser_Troop.super.draw(self)
end

function Laser_Troop:draw_cast_timer()
  Laser_Troop.super.draw_cast_timer(self)
end


--conditions to attack should be:
--1. state is 'normal' (includes has assigned_target)
--2. target is in range
--3. cooldown is ready

-- so these should be managed by:
--1. state can be set by spell/helper
--2. target is set by RMB click, and if not set there is auto-targetted by spell/helper
--3. cooldown should be in unit
function Laser_Troop:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)

  self.infinite_range = true

  self:set_state_functions()
  -- Cast/cooldown values are set in calculate_stats() first run
end

function Laser_Troop:setup_cast(cast_target)
  --calculate distance multiplier
  Laser_Troop.super.setup_cast(self, cast_target)

  local data = {
    name = 'laser',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
    end,
    backswing = 0.1,
    target = cast_target,
    cast_distance_multiplier = self.cast_distance_multiplier,
    spellclass = Laser_Spell,
    spelldata = {
      group = main.current.main,
      spell_duration = 10,
      color = blue[0],
      on_attack_callbacks = true,
      damage = function() return self.dmg end,
      reduce_pierce_damage = true,
      lasermode = 'target',
      laser_aim_width = 1,
      laser_width = 8,
      charge_duration = 0.5,
      damage_troops = false,
      damage_once = true,
      end_spell_on_fire = false,
      fire_follows_unit = false,
      fade_fire_draw = true,
      fade_in_aim_draw = true,
    }
  }
  self:cast(data)
end

function Laser_Troop:instant_attack(cast_target)
  Laser_Spell{
    group = main.current.effects,
    target = cast_target,
    on_attack_callbacks = false,
    unit = self,
    spell_duration = 10,
    color = blue[0],
    damage = function() return self.dmg end,
    reduce_pierce_damage = true,
    lasermode = 'target',
    laser_aim_width = 1,
    laser_width = 8,
    charge_duration = 0.5,
    damage_troops = false,
    damage_once = true,
    end_spell_on_fire = false,
    fire_follows_unit = true,
    fade_fire_draw = true,
    fade_in_aim_draw = true,
  }
end

-- NOTE: Laser hits are currently left as indirect hits for now.
-- TODO: Implement primary hit for the exact target only, with chained hits for other targets hit by the beam.
-- This requires modifying the Laser_Spell to distinguish between the intended target and other targets.

function Laser_Troop:set_state_functions()

  
    --cancel on death
    self.state_change_functions['death'] = function(self)
      self:cancel_cast()
      Helper.Unit:unclaim_target(self)
    end

  end

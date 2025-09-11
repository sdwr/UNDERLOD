LaserWeapon = Weapon:extend()

function LaserWeapon:init(data)
  self.weapon_name = 'laser'
  self.base_attack_range = 120
  LaserWeapon.super.init(self, data)
  
  self.backswing = data.backswing or 0.1
  self.laser_charge_duration = 0.35
  self.laser_fire_duration = 0.2
end

function LaserWeapon:create_spelldata()
  return {
    group = main.current.effects,
    unit = self,
    target = self.target,
    x = self.x,
    y = self.y,
    damage = function() return self.dmg end,
    color = blue[5],
    aim_color = red[-5],
    laser_width = 5,
    laser_aim_width = 2,
    length = 300,
    charge_duration = self.laser_charge_duration,
    fire_duration = self.laser_fire_duration,
    lasermode = 'target',  -- Changed from 'rotate' to 'target' to follow target
    fire_follows_unit = true,
    end_spell_on_fire = false,
    damage_troops = false,
    damage_once = true,
    draw_spawn_circle = true,
    fade_fire_draw = true,
    fade_in_aim_draw = true,
    is_weapon = true,
    is_troop = true,
  }
end

function LaserWeapon:setup_cast(cast_target)
  LaserWeapon.super.setup_cast(self, cast_target)
  
  local data = {
    name = 'laser',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
    end,
    unit = self,
    target = cast_target,
    backswing = self.backswing,
    instantspell = true,
    spellclass = Laser_Spell,
    spelldata = self:create_spelldata()
  }
  self.castObject = Cast(data)
end

function LaserWeapon:update(dt)
  LaserWeapon.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function LaserWeapon:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
end

function LaserWeapon:get_angle()
  -- Return angle towards target if we have one
  if self.target and not self.target.dead then
    return math.atan2(self.target.y - self.y, self.target.x - self.x)
  end
  -- Default to 0 if no target
  return self.r or 0
end
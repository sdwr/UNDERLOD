MachineGunWeapon = Weapon:extend()

function MachineGunWeapon:init(data)
  self.weapon_name = 'machine_gun'
  self.base_attack_range = 80
  MachineGunWeapon.super.init(self, data)
  
  self.backswing = data.backswing or 0.05
  -- Cast/cooldown values are set in calculate_stats()
end

function MachineGunWeapon:create_spelldata()
  return {
    group = main.current.main,
    on_attack_callbacks = true,
    volume = 0.5,
    spell_duration = 10,
    bullet_size = 2,
    pierce = false,
    speed = 400,
    is_weapon = true,
    is_troop = true,
    color = yellow[0],
    damage = function() return self.dmg end,
  }
end

function MachineGunWeapon:setup_cast(cast_target)
  MachineGunWeapon.super.setup_cast(self, cast_target)
  
  local data = {
    name = 'bullet',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
    end,
    unit = self,
    target = cast_target,
    backswing = self.backswing,
    instantspell = true,
    spellclass = ArrowProjectile,  -- Reuse arrow projectile for bullets
    spelldata = self:create_spelldata()
  }
  self.castObject = Cast(data)
end

function MachineGunWeapon:update(dt)
  MachineGunWeapon.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function MachineGunWeapon:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
  -- Cast/cooldown values are set in calculate_stats()
end
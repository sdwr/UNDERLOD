CannonWeapon = Weapon:extend()

function CannonWeapon:init(data)
  self.weapon_name = 'cannon'
  self.base_attack_range = 60
  CannonWeapon.super.init(self, data)
  
  self.backswing = data.backswing or 0.2
  -- Cast/cooldown values are set in calculate_stats()
end

function CannonWeapon:create_spelldata()
  return {
    group = main.current.main,
    on_attack_callbacks = true,
    volume = 0.7,
    spell_duration = 10,
    bullet_size = 8,  -- Large cannonball
    bullet_shape = 'circle',  -- Round cannonball
    pierce = false,
    speed = 250,  -- Slower than bullets
    is_weapon = true,
    is_troop = true,
    color = orange[0],
    damage = function() return self.dmg end,
  }
end

function CannonWeapon:setup_cast(cast_target)
  CannonWeapon.super.setup_cast(self, cast_target)
  
  local data = {
    name = 'cannonball',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
      -- Cannon fire sound
      if explosion1 then
        explosion1:play{pitch = random:float(0.7, 0.9), volume = 0.3}
      end
    end,
    unit = self,
    target = cast_target,
    backswing = self.backswing,
    instantspell = true,
    spellclass = ArrowProjectile,
    spelldata = self:create_spelldata()
  }
  self.castObject = Cast(data)
end

function CannonWeapon:update(dt)
  CannonWeapon.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function CannonWeapon:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
  -- Cast/cooldown values are set in calculate_stats()
end
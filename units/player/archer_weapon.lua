ArcherWeapon = Weapon:extend()

function ArcherWeapon:init(data)
  self.weapon_name = 'archer'
  self.base_attack_range = TROOP_RANGE
  ArcherWeapon.super.init(self, data)
  
  self.backswing = data.backswing or 0.1
  -- Cast/cooldown values are set in calculate_stats()
end

function ArcherWeapon:create_spelldata()
  return {
    group = main.current.main,
    on_attack_callbacks = true,
    volume = 1,
    spell_duration = 10,
    bullet_size = 3,
    pierce = false,
    speed = 350,
    is_weapon = true,
    color = blue[0],
    damage = function() return self.dmg end,
  }
end

function ArcherWeapon:setup_cast(cast_target)
  ArcherWeapon.super.setup_cast(self, cast_target)
  
  local data = {
    name = 'arrow',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
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

function ArcherWeapon:instant_attack(cast_target)
  local spelldata = self:create_spelldata()
  spelldata.on_attack_callbacks = false
  spelldata.unit = self
  spelldata.target = cast_target
  ArrowProjectile(spelldata)
end
  
function ArcherWeapon:instant_attack_at_angle(angle, damage_multi)
  local spelldata = self:create_spelldata()
  spelldata.on_attack_callbacks = false
  spelldata.unit = self
  spelldata.angle = angle
  spelldata.damage = function() return self.dmg * damage_multi end
  ArrowProjectile(spelldata)
end

function ArcherWeapon:multishot(angle)
  local angle1 = angle + MULTISHOT_ANGLE_OFFSET
  local angle2 = angle - MULTISHOT_ANGLE_OFFSET

  local proc = Get_Static_Proc(self, 'multishot')
  local damage_multi = proc:get_damage_multi()

  self:instant_attack_at_angle(angle1, damage_multi)
  self:instant_attack_at_angle(angle2, damage_multi)
  
  if Get_Static_Proc(self, 'extraMultishot') then
    local angle3 = angle + MULTISHOT_ANGLE_OFFSET / 2
    local angle4 = angle - MULTISHOT_ANGLE_OFFSET / 2

    self:instant_attack_at_angle(angle3, damage_multi)
    self:instant_attack_at_angle(angle4, damage_multi)
  end
end

function ArcherWeapon:update(dt)
  ArcherWeapon.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function ArcherWeapon:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
  -- Cast/cooldown values are set in calculate_stats()
end
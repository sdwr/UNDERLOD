FrostAoeWeapon = Weapon:extend()

function FrostAoeWeapon:init(data)
  self.weapon_name = 'frost_aoe'
  self.base_attack_range = 50  -- Detection radius for enemies
  FrostAoeWeapon.super.init(self, data)
  
  self.backswing = data.backswing or 0.1
  self.aoe_radius = 50  -- Damage radius
  -- Cast/cooldown values are set in calculate_stats()
end

function FrostAoeWeapon:create_spelldata()
  return {
    group = main.current.effects,
    unit = self,
    is_troop = true,
    x = self.x, 
    y = self.y,
    pick_shape = 'circle',
    damage = function() return self.dmg end,
    damage_type = DAMAGE_TYPE_COLD,
    r = self.aoe_radius,
    duration = 0.2,
    color = blue[0],
    is_weapon = true,
    floor_effect = 'frostnova',
  }
end

function FrostAoeWeapon:setup_cast(cast_target)
  FrostAoeWeapon.super.setup_cast(self, cast_target)
  
  local data = {
    name = 'frost_explosion',
    viable = function() return math.distance(self.x, self.y, cast_target.x, cast_target.y) <= self.aoe_radius end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
    end,
    unit = self,
    target = cast_target,
    backswing = self.backswing,
    instantspell = true,
    spellclass = Area_Spell,
    spelldata = self:create_spelldata(),
    cast_sound = glass_shatter,
    cast_volume = 0.3,
  }
  self.castObject = Cast(data)
end

function FrostAoeWeapon:update(dt)
  FrostAoeWeapon.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function FrostAoeWeapon:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
  -- Cast/cooldown values are set in calculate_stats()
end
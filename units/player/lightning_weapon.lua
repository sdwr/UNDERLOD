LightningWeapon = Weapon:extend()

function LightningWeapon:init(data)
  self.weapon_name = 'lightning'
  self.base_attack_range = 70
  LightningWeapon.super.init(self, data)
  
  self.backswing = data.backswing or 0.1
  self.chain_count = 2  -- Chains to 2 additional enemies
  -- Cast/cooldown values are set in calculate_stats()
end

function LightningWeapon:create_spelldata()
  return {
    group = main.current.main,
    parent = self,
    source = self,
    target = self.target,
    damage = self.dmg or 12,
    damageType = DAMAGE_TYPE_LIGHTNING,
    range = 50,  -- Chain range
    max_chains = self.chain_count,
    damage_reduction_per_chain = 0.3,
    is_troop = true,
    is_weapon = true,
    color = yellow[5],
    skip_first_bounce = false,  -- Draw line from weapon to first target
  }
end

function LightningWeapon:setup_cast(cast_target)
  LightningWeapon.super.setup_cast(self, cast_target)
  
  local data = {
    name = 'lightning_chain',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
      -- Apply initial shock to target
      if cast_target and not cast_target.dead then
        cast_target:shock(self)
      end
    end,
    unit = self,
    target = cast_target,
    backswing = self.backswing,
    instantspell = true,
    spellclass = ChainLightning,
    spelldata = self:create_spelldata()
  }
  self.castObject = Cast(data)
end

function LightningWeapon:update(dt)
  LightningWeapon.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function LightningWeapon:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
  -- Cast/cooldown values are set in calculate_stats()
end
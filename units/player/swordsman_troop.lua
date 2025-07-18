Swordsman_Troop = Troop:extend()
function Swordsman_Troop:init(data)
  self.base_attack_range = TROOP_SWORDSMAN_RANGE
  Swordsman_Troop.super.init(self, data)

  self.baseCooldown = TROOP_SWORDSMAN_BASE_COOLDOWN
  self.cooldownTime = self.baseCooldown
  self.baseCast = attack_speeds['short-cast']
  self.castTime = self.baseCast
  self.backswing = 0.1
  self:reset_castcooldown(math.random() * (self.base_castcooldown or self.baseCast))

  self.base_attack_area = 20

end

function Swordsman_Troop:update(dt)
  Swordsman_Troop.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function Swordsman_Troop:draw()
  Swordsman_Troop.super.draw(self)
end

function Swordsman_Troop:play_attack_sound()
  _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
end

function Swordsman_Troop:set_character()

  --the size of this is updated in objects.lua, and re-set in :update
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)

  --cooldowns
  self.baseCooldown = TROOP_SWORDSMAN_BASE_COOLDOWN
  self.cooldownTime = self.baseCooldown
  self.baseCast = 0
  self.castTime = self.baseCast
  self.backswing = 0.2
  self:reset_castcooldown(math.random() * (self.base_castcooldown or self.baseCast))

  self:set_state_functions()
end

function Swordsman_Troop:setup_cast(cast_target)
  local cast_data = {
    name = 'attack',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
    end,
    unit = self,
    target = cast_target,
    castcooldown = self.cooldownTime,
    cast_length = self.castTime,
    backswing = self.backswing,
    instantspell = true,
    
    -- This is the data for the actual spell that gets created.
    spellclass = Area_Spell,
    spelldata = {
      group = main.current.effects,
      sound = self.play_attack_sound,
      -- Core spell properties matching the new Area_v2 convention
      damage = function() return self.dmg end,
      radius = self.base_attack_area,
      duration = 0.2, -- How long the visual effect lasts on screen.
      damage_ticks = false,
      color = orange[0],
      opacity = 0.3,

      area_type = 'target',
      apply_primary_hit_to_target = true,
              
      -- The Area spell needs to know its caster and what team it's on.
      unit = self,
      is_troop = true,
      
      }
    }

    self.castObject = Cast(cast_data)
end

function Swordsman_Troop:set_state_functions()
  self.state_always_run_functions['always_run'] = function(self)
  end

end
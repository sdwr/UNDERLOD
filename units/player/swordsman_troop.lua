Swordsman_Troop = Troop:extend()
function Swordsman_Troop:init(data)
  self.base_attack_range = attack_ranges['melee']
  Swordsman_Troop.super.init(self, data)

  self.baseCooldown = attack_speeds['ultra-fast']
  self.cooldownTime = self.baseCooldown
  self.baseCast = attack_speeds['short-cast']
  self.castTime = self.baseCast
  self.backswing = 0.1
  self.castcooldown = math.random() * (self.base_castcooldown or self.baseCast)

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
  self.baseCooldown = attack_speeds['medium-fast']
  self.cooldownTime = self.baseCooldown

  self:set_state_functions()
end

function Swordsman_Troop:setup_cast()
  if self.onAttackCallbacks then
    self:onAttackCallbacks(self.target)
  end
  local data = {
    name = 'attack',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, true) end,
    oncast = function() end,
    oncastfinish = function() self:play_attack_sound() end,
    unit = self,
    target = self.target,
    castcooldown = self.cooldownTime,
    cast_length = self.castTime,
    backswing = self.backswing,
    instantspell = true,
    spellclass = Area,
    spelldata = {
      group = main.current.effects,
      spell_duration = 0.1,
      color = red[0],
      areatype = 'target',
      r = self.r,
      w = 8 * self.area_size_m,
      dmg = self.dmg,
      area = self.area,
      mods = self.mods,
      is_troop = true,
    },
  }
  self:cast(data)
end

function Swordsman_Troop:set_state_functions()
  self.state_always_run_functions['always_run'] = function()
    if Helper.Unit:can_cast(self) then
      if self:my_target() then
        self:setup_cast()
      end
    end
  end

end
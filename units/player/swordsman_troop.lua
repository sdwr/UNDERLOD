Swordsman_Troop = Troop:extend()
function Swordsman_Troop:init(data)
  self.base_attack_range = attack_ranges['melee']
  Swordsman_Troop.super.init(self, data)
end

function Swordsman_Troop:update(dt)
  Swordsman_Troop.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function Swordsman_Troop:draw()
  Swordsman_Troop.super.draw(self)
end

function Swordsman_Troop:attack(area, mods)
  print('swordsman attacking')
  Swordsman_Troop.super.attack(self, area, mods)
  _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
end

function Swordsman_Troop:set_character()
  --the size of this is updated in objects.lua, and re-set in :update
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)

  --cooldowns
  self.baseCooldown = attack_speeds['medium-fast']
  self.cooldownTime = self.baseCooldown

  self.state_always_run_functions['always_run'] = function()
    if Helper.Unit:can_cast(self) then
      if self:my_target() then
        self:attack(self.dmg, {x = self:my_target().x, y = self:my_target().y})
        self.last_attack_finished = Helper.Time.time
      end
    end
  end

  self.t:cooldown(attack_speeds['medium-fast'], self:in_range(), function()
    if self.target then
      self:attack(10, {x = self.target.x, y = self.target.y})
    end
  end, nil, nil, 'attack')
end
require 'procs/proc'
-- Desc: procs are objects that do things when certain conditions are met
-- base proc class is at the bottom

--proc craggy
Proc_Craggy = Proc:extend()
function Proc_Craggy:init(data)
  --super call to enable debugging
  Proc_Craggy.super.init(self, data)
  
  --define what triggers the proc has
  self.triggers = {PROC_ON_GOT_HIT}

  --define the proc's vars
  self.canProc = true
  self.cooldown = data.cooldown or 1
  self.chance = data.chance or 0.1
  self.damage = data.damage or 15
  self.stunDuration = data.stunDuration or 1.5

end
function Proc_Craggy:onGotHit(unit, from)
  Proc_Craggy.super.onGotHit(self, unit, from)
  if self.canProc and math.random() < self.chance then
    self.canProc = false
    trigger:after(self.cooldown, function() self.canProc = true end)
    from:stun(self.stunDuration)
    from:hit(self.damage, unit)
  end
end

--proc bash
Proc_Bash = Proc:extend()
function Proc_Bash:init(data)
  --super call to enable debugging
  Proc_Bash.super.init(self, data)
  
  --define what triggers the proc has
  self.triggers = {PROC_ON_HIT}

  --define the proc's vars
  self.canProc = true
  self.cooldown = data.cooldown or 2
  self.chance = data.chance or 0.2
  self.damage = data.damage or 10
  self.stunDuration = data.stunDuration or 1
end
function Proc_Bash:onHit(unit, target)
  Proc_Bash.super.onHit(self, unit, target)
  if self.canProc and math.random() < self.chance then
    self.canProc = false
    trigger:after(self.cooldown, function() self.canProc = true end)
    target:stun(self.stunDuration)
    target:hit(self.damage, unit)
  end
end

--proc heal
Proc_Heal = Proc:extend()
function Proc_Heal:init(data)
  Proc_Heal.super.init(self, data)
  
  --define what triggers the proc has
  self.triggers = {}

  --define the proc's vars
  self.every_time = data.every_time or 5
  self.healAmount = data.healAmount or 10
  trigger:every(self.every_time, function() self.unit:heal(self.healAmount) end)
end

--proc overkill
Proc_Overkill = Proc:extend()
function Proc_Overkill:init(data)
  Proc_Overkill.super.init(self, data)
  
  --define what triggers the proc has
  self.triggers = {PROC_ON_KILL}

  --define the proc's vars
  self.overkillMulti = data.overkillMulti or 2
  self.radius = data.sizeMulti or 3
end
function Proc_Overkill:onKill(unit, target)
  Proc_Overkill.super.onKill(self, unit, target)
  if target.health <= 0 then
    local damage_troops = not self:is(Troop)
    local damage = math.abs(target.health) * self.overkillMulti
    local radius = target.shape.w * self.radius
    Helper.Spell.DamageCircle:create(self, black[0], damage_troops, damage,
      radius, target.x, target.y)
  end
end

Proc_Berserk = Proc:extend()
function Proc_Berserk:init(data)
  Proc_Berserk.super.init(self, data)
  
  --define what triggers the proc has
  self.triggers = {}

  --define the proc's vars
  self.buff = data.buff or 'berserk'
end




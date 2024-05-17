require 'procs/proc'
-- Desc: procs are objects that do things when certain conditions are met
-- base proc class is at the bottom

--need to pass unit into proc, some procs need to know who they are on (without callbacks)

--proc craggy
Proc_Craggy = Proc:extend()
function Proc_Craggy:init(args)
  self.triggers = {PROC_ON_GOT_HIT}

  
  Proc_Craggy.super.init(self, args)
  
  

  --define the proc's vars
  self.canProc = true
  self.cooldown = self.data.cooldown or 1
  self.chance = self.data.chance or 0.1
  self.damage = self.data.damage or 15
  self.stunDuration = self.data.stunDuration or 1.5

end
function Proc_Craggy:onGotHit(from, damage)
  Proc_Craggy.super.onGotHit(self, from)
  if self.canProc and math.random() < self.chance then
    self.canProc = false
    trigger:after(self.cooldown, function() self.canProc = true end)

    arrow_hit_wall2:play{pitch = random:float(0.8, 1.2), volume = 0.9}
    
    from:stun(self.stunDuration)
    from:hit(self.damage, self.unit)
  end
end

--proc bash
Proc_Bash = Proc:extend()
function Proc_Bash:init(args)
  self.triggers = {PROC_ON_HIT}

  
  Proc_Bash.super.init(self, args)
  
  

  --define the proc's vars
  self.canProc = true
  self.cooldown = self.data.cooldown or 2
  self.chance = self.data.chance or 0.2
  self.damage = self.data.damage or 10
  self.stunDuration = self.data.stunDuration or 1
end
function Proc_Bash:onHit(target, damage)
  Proc_Bash.super.onHit(self, target, damage)
  if self.canProc and math.random() < self.chance then
    self.canProc = false
    trigger:after(self.cooldown, function() self.canProc = true end)

    arrow_hit_wall2:play{pitch = random:float(0.8, 1.2), volume = 0.9}

    target:stun(self.stunDuration)
    target:hit(self.damage, self.unit)
  end
end

--proc berserk
Proc_Berserk = Proc:extend()
function Proc_Berserk:init(args)
  self.triggers = {PROC_ON_GOT_HIT}

  Proc_Berserk.super.init(self, args)
  
  

  --can only proc once
  self.canProc = true

  --define the proc's vars
  self.buffname = 'berserk'
  self.buffDuration = self.data.buffDuration or 5
  self.buffdata = {name = 'berserk', color = red[2], duration = self.buffDuration,
  stats = {dmg = 0.5, attack_speed = 0.3, move_speed = 0.3}
  }
end

function Proc_Berserk:onGotHit(from, damage)
  Proc_Berserk.super.onGotHit(self, from, damage)

  if self.canProc and self.hp / self.max_hp < 0.3 then
    self.canProc = false
    self.unit:add_buff(self.buffdata)
  end
end

--proc heal
Proc_Heal = Proc:extend()
function Proc_Heal:init(args)
  self.triggers = {}

  Proc_Heal.super.init(self, args)
  
  

  --define the proc's vars
  self.every_time = self.data.every_time or 5
  self.healAmount = self.data.healAmount or 10
  trigger:every(self.every_time, function() self:heal() end)
end

-- :heal() is on troop, but should be on unit instead
function Proc_Heal:heal()
  heal1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.unit:heal(self.healAmount)
end

--proc overkill
Proc_Overkill = Proc:extend()
function Proc_Overkill:init(args)
  self.triggers = {PROC_ON_KILL}

  Proc_Overkill.super.init(self, args)
  
  

  --define the proc's vars
  self.overkillMulti = self.data.overkillMulti or 2
  self.radius = self.data.sizeMulti or 2
end
function Proc_Overkill:onKill(target)
  Proc_Overkill.super.onKill(self, target)
  if target.hp <= 0 then
    local damage_troops = not self.is_troop
    local damage = math.abs(target.hp) * self.overkillMulti
    local radius = target.shape.w * self.radius

    cannoneer2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
    Helper.Spell.DamageCircle:create(self, black[0], damage_troops, damage,
      radius, target.x, target.y)
  end
end

Proc_Bloodlust = Proc:extend()
function Proc_Bloodlust:init(args)
  self.triggers = {}

  Proc_Bloodlust.super.init(self, args)
  
  

  --define the proc's vars
  --same buff as berserk
  self.buffname = 'berserk'
  self.buffDuration = self.data.buffDuration or 5
  self.buffdata = {name = 'berserk', color = red[2], duration = self.buffDuration,
  stats = {dmg = 0.5, attack_speed = 0.3, move_speed = 0.3}
  }

  trigger:after(TIME_TO_ROUND_START, function() self.unit:add_buff(self.buffdata) end)
end


--proc lightning
--needs 2 procs, so that the attack counter only counts down on 1 hit per attack
Proc_Lightning = Proc:extend()
function Proc_Lightning:init(args)
  self.triggers = {PROC_ON_ATTACK, PROC_ON_HIT}

  Proc_Lightning.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 10
  self.damageType = 'lightning'
  self.chain = self.data.chain or 4
  self.every_attacks = self.data.every_attacks or 4
  self.radius = self.data.radius or 50
  self.color = self.data.color or blue[0]

  --define the procs memory
  self.has_attacked = false
  self.attacks_left = math.random(1, self.every_attacks)
end

function Proc_Lightning:onAttack(target)
  Proc_Lightning.super.onAttack(self, target)
  if self.attacks_left > 0 then
    self.has_attacked = true
  end
end

function Proc_Lightning:onHit(target, damage)
  Proc_Lightning.super.onHit(self, target, damage)
  if self.has_attacked then
    self.has_attacked = false
    self.attacks_left = self.attacks_left - 1
    if self.attacks_left == 0 then
      self.attacks_left = self.every_attacks

      spark3:play{pitch = random:float(0.8, 1.2), volume = 0.7}
      --remove level from spell
      ChainLightning{
        group = main.current.main, 
        target = target, rs = self.radius, 
        dmg = self.damage, color = self.color, 
        parent = self.unit, 
        level = 1}

    end
  end
end

--proc static
Proc_Static = Proc:extend()
function Proc_Static:init(args)
  self.triggers = {PROC_ON_MOVE, PROC_ON_HIT}

  Proc_Static.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 10
  self.damageType = 'lightning'
  self.chain = self.data.chain or 8
  self.every_moves = self.data.every_moves or 100
  self.radius = self.data.radius or 100
  self.color = self.data.color or blue[0]

  --define the procs memory
  self.moves_left = self.every_moves
end

function Proc_Static:onMove(distance)
  Proc_Static.super.onMove(self, distance)
  if self.moves_left == 0 then return end

  self.moves_left = math.max(0, self.moves_left - distance)
  if self.moves_left == 0 then
    --play sound
    pop2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  end
end

function Proc_Static:onHit(target, damage)
  Proc_Static.super.onHit(self, target, damage)
  if self.moves_left == 0 then
    self.moves_left = self.every_moves
    ChainLightning{
      group = main.current.main, 
      target = target, rs = self.radius, 
      dmg = self.damage, color = self.color, 
      parent = self.unit, 
      level = 1}
  end
end

--proc radianceburn
--need to add an aura to the unit that follows it around
-- maybe put it on just one, to save processing power
Proc_RadianceBurn = Proc:extend()
function Proc_RadianceBurn:init(args)
  self.triggers = {}

  Proc_RadianceBurn.super.init(self, args)
  
  

  --define the proc's vars
  self.buff = 'radiance'
  self.damageType = 'fire'
  --need constant for buff duration = infinity
  self.buffDuration = self.data.buffDuration or 9999

  trigger:after(TIME_TO_ROUND_START, function() self.unit:add_buff(self.buff, self.buffDuration) end)
end

Proc_Shield = Proc:extend()
function Proc_Shield:init(args)
  self.triggers = {}

  Proc_Shield.super.init(self, args)
  
  

  --define the proc's vars
  self.buff = 'shield'
  self.shield_amount = self.data.shield_amount or 10
  self.time_between = self.data.time_between or 1
  self.buff_duration = self.data.buff_duration or 5

  --need to have shield amount in buff
  trigger:every(self.time_between, function() self.unit:add_buff(self.buff, self.buff_duration) end)
end

--need a new gameObject group that collides with walls but not units
--to make phasing work
Proc_Phasing = Proc:extend()
function Proc_Phasing:init(args)
  self.triggers = {}

  Proc_Phasing.super.init(self, args)
  
  

  --define the proc's vars
  self.buff = 'phasing'
  self.buff_duration = self.data.buff_duration or 9999
  self.buffdata = {name = 'phasing', color = pink[5], duration = self.buff_duration,
    toggles = {phasing = 1}
  }

  trigger:after(TIME_TO_ROUND_START, function() self.unit:add_buff(self.buffdata) end)
end

Proc_Fire = Proc:extend()
function Proc_Fire:init(args)
  self.triggers = {PROC_ON_HIT}

  Proc_Fire.super.init(self, args)
  
  
  --define the proc's vars
  self.damageType = 'fire'
  self.burnDuration = self.data.burnDuration or 3
  self.burnDps = self.data.burnDamage or 5
end

function Proc_Fire:onHit(target, damage)
  Proc_Fire.super.onHit(self, target, damage)
  --need to add a burn debuff to the target
  target:burn(self.burnDps, self.burnDuration)
end

Proc_Blazin = Proc:extend()
function Proc_Blazin:init(args)
  self.triggers = {PROC_ON_TICK}

  Proc_Blazin.super.init(self, args)
  
  

  --define the proc's vars
  self.buff = 'blazin'
  self.buff_duration = self.data.buff_duration or 1
  self.aspd_per_enemy = self.data.aspd_per_enemy or 0.05
  self.max_aspd = self.data.max_aspd or 0.5

  self.buffdata = {name = 'blazin', color = red[5], duration = self.buff_duration,
    stats = {aspd = 0}
  }

end

function Proc_Blazin:onTick(dt)
  Proc_Blazin.super.onTick(self, dt)

  --find how many enemies are burning
  local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
  local count = 0
  for i, enemy in ipairs(enemies) do
    if enemy:has_buff('burn') then
      count = count + 1
    end
  end

  --change stats based on # of enemies burning
  self.buffdata.stats.aspd = math.min(count * self.aspd_per_enemy, self.max_aspd)
  
  --remove buff before reapplying (otherwise will not change stats)
  self.unit:remove_buff(self.buff)
  self.unit:add_buff(self.buffdata)
end

Proc_Redshield = Proc:extend()
function Proc_Redshield:init(args)
  self.triggers = {PROC_ON_GOT_HIT}

  Proc_Redshield.super.init(self, args)

  --define the proc's vars
  self.buff = 'redshield'
  self.armor_per_stack = self.data.armor_per_stack or 1
  self.max_stacks = self.data.max_stacks or 10

  self.stacks = 0

  --starting to get complicated, might hurt perforamnce to add things
  --that scale with # of enemies
  --change to stacks per hit taken, have stacks fall off over time or on hit
end

function Proc_Redshield:onGotHit(from, damage)
  Proc_Redshield.super.onGotHit(self, from, damage)


  --change stats based on # of stacks
  --do in objects or here?
  -- in objects, we need seperate logic for stackable buffs
  -- here, we need to remove and reapply the buff manually
  --starting to think buffs should be a class as well L(0_0L)

  self.unit:add_buff(self.buff)
end

function Proc_Redshield:onTick(dt)
  Proc_Redshield.super.onTick(self, dt)

  --stacks decrement over time
end

Proc_Frost = Proc:extend()
function Proc_Frost:init(args)
  self.triggers = {PROC_ON_HIT}

  Proc_Frost.super.init(self, args)

  --define the proc's vars
  self.slow_amount = self.data.slow_amount or 0.3
  self.slow_duration = self.data.slow_duration or 2
end

function Proc_Frost:onHit(target, damage)
  Proc_Frost.super.onHit(self, target, damage)

  target:slow(self.slow_amount, self.slow_duration)
end

Proc_Frostfield = Proc:extend()
function Proc_Frostfield:init(args)
  self.triggers = {PROC_ON_ATTACK, PROC_ON_HIT}

  Proc_Frostfield.super.init(self, args)

  --define the proc's vars
  self.slow_amount = self.data.slow_amount or 0.3
  self.slow_duration = self.data.slow_duration or 2
  self.radius = self.data.radius or 20

  self.every_attacks = self.data.every_attacks or 4

  --define the procs memory
  self.has_attacked = false
  self.attacks_left = math.random(1, self.every_attacks)
end

function Proc_Frostfield:onAttack(target)
  Proc_Frostfield.super.onAttack(self, target)
  if self.attacks_left > 0 then
    self.has_attacked = true
  end
end

function Proc_Frostfield:onHit(target, damage)
  Proc_Frostfield.super.onHit(self, target, damage)
  if self.has_attacked then
    self.has_attacked = false
    self.attacks_left = self.attacks_left - 1
    if self.attacks_left == 0 then
      self.attacks_left = self.every_attacks

      --remove level from spell
      Helper.Spell.Frostfield:create(self.unit, blue[0], false, 5, self.radius, 2, target.x, target.y)
    end
  end
end

--have to define how to stack slows
-- just the amount is a little tricky, need to multiplicatively stack towards 0
-- could use stacks, but it would be nice to use any source of slow
-- ideal is multiplicative stacking, and remove slow over time
-- which i guess is a stack
-- also keep track of which unit applied the slow? or just make it a global effect
Proc_Slowstack = Proc:extend()
function Proc_Slowstack:init(args)
  self.triggers = {PROC_ON_HIT}

  Proc_Slowstack.super.init(self, args)

  --define the proc's vars
  self.slow_amount = self.data.slow_amount or 0.1
  self.slow_duration = self.data.slow_duration or 2
  self.max_slow = self.data.max_slow or 0.5

  self.slow = 0
end



proc_name_to_class = {
  ['craggy'] = Proc_Craggy,
  ['bash'] = Proc_Bash,
  ['heal'] = Proc_Heal,
  ['overkill'] = Proc_Overkill,
  ['berserk'] = Proc_Berserk,
  ['bloodlust'] = Proc_Bloodlust,
  ['lightning'] = Proc_Lightning,
  ['static'] = Proc_Static,
  ['radianceburn'] = Proc_RadianceBurn,
  ['shield'] = Proc_Shield,
  ['phasing'] = Proc_Phasing,
  ['fire'] = Proc_Fire,
  ['redshield'] = Proc_Redshield,
  ['blazin'] = Proc_Blazin,
  ['frostfield'] = Proc_Frostfield,
  ['slowstack'] = Proc_Slowstack,
}



require 'procs/proc'
-- Desc: procs are objects that do things when certain conditions are met
-- base proc class is at the bottom

--need to pass unit into proc, some procs need to know who they are on (without callbacks)

function Create_Proc(name, unit)
  if not proc_name_to_class[name] then
    print('proc not found')
    print(name)
    return nil
  end

  return proc_name_to_class[name]({unit = unit, data = {name = name}})
end


--proc reroll
Proc_Reroll = Proc:extend()
function Proc_Reroll:init(args)
  self.triggers = {}

  Proc_Reroll.super.init(self, args)
  
end

--when sold in the shop, reroll the upcoming levels
--make sure this doesn't trigger at the end of rounds, when the unit is removed
function Proc_Reroll:die()
  Proc_Reroll.super.die(self)
  --should only trigger in buy_screen
  if main.current and main.current.roll_levels then
    main.current:roll_levels()
  end
end


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
  if self.unit and self.unit.heal then
    heal1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
    self.unit:heal(self.healAmount)
  end
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

--proc berserk
Proc_Berserk = Proc:extend()
function Proc_Berserk:init(args)
  self.triggers = {}

  Proc_Berserk.super.init(self, args)
  
  

  --define the proc's vars
  self.buff = 'berserk'
  self.buffDuration = self.data.buffDuration or 5
  self.buffdata = {name = 'berserk', color = purple[5], duration = 5, maxDuration = 5,
    stats = {attack_speed = 0.1, move_speed = 0.1}
  }

  trigger:after(TIME_TO_ROUND_START, function() self.unit:add_buff(self.buffdata) end)
end

Proc_Bloodlust = Proc:extend()
function Proc_Bloodlust:init(args)
  self.triggers = {PROC_ON_KILL}

  Proc_Bloodlust.super.init(self, args)
  
  

  --define the proc's vars
  --buff defined in objects.lua (unit) :berserk()
  self.buffname = 'bloodlust'
  self.buffDuration = self.data.buffDuration or 5
end

function Proc_Bloodlust:onKill(target)
  Proc_Bloodlust.super.onKill(self, target)
  self.unit:berserk(self.buffDuration)
end


--proc lightning
--needs 2 procs, so that the attack counter only counts down on 1 hit per attack
Proc_Lightning = Proc:extend()
function Proc_Lightning:init(args)
  self.triggers = {PROC_ON_ATTACK, PROC_ON_HIT}

  Proc_Lightning.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
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

--proc radiance
--need to add an aura to the unit that follows it around
--but only applies once to each enemy, no matter how many units have the aura
--best to do with a debuff that is applied to the enemy
--the radiance debuff should work differently than other debuffs
--last for a second, reapplied all the time, but only ticks once
Proc_Radiance = Proc:extend()
function Proc_Radiance:init(args)
  self.triggers = {PROC_ON_TICK}

  Proc_Radiance.super.init(self, args)
  
  

  --define the proc's vars
  self.radius = self.data.radius or 50
  self.damage = self.data.damage or 10
  self.damageType = 'fire'
end

function Proc_Radiance:onTick(dt)
  Proc_Radiance.super.onTick(self, dt)
  local enemies = main.current.main:get_objects_by_classes(enemy_classes)
  for i, enemy in ipairs(enemies) do
    if Helper.Spell:is_in_range(self.unit, enemy, self.radius, false) then
      --backwards from how it 'should' work, but easier to implement
      if not enemy:has_buff('radianceburn') then
        enemy:add_buff({name = 'radianceburn', damage = self.damage, duration = 1})
        
        --Helper.Sound:play_radiance()
        enemy:hit(self.damage, self.unit, self.damageType)
      end
    end
  end
end

Proc_Shield = Proc:extend()
function Proc_Shield:init(args)
  self.triggers = {}

  Proc_Shield.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'shield'
  self.color = grey[5]
  self.shield_amount = self.data.shield_amount or 10
  self.time_between = self.data.time_between or 5
  self.buff_duration = self.data.buff_duration or 4

  self.buffdata = {name = self.buffname, color = self.color, duration = self.buff_duration,
    stats = {shield = self.shield_amount}
  }

  --need to have shield amount in buff
  --no way to cancel the trigger once the unit is dead :( 
  self.manual_trigger = trigger:every(self.time_between, function() self.unit:add_buff(self.buffdata) end)
end

function Proc_Shield:die()
  Proc_Shield.super.die(self)
  trigger:cancel(self.manual_trigger)
end

--need a new gameObject group that collides with walls but not units
--to make phasing work
--looks like 'ghost' tag doesn't work, or can't be set mid-game
Proc_Phasing = Proc:extend()
function Proc_Phasing:init(args)
  self.triggers = {}

  Proc_Phasing.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'phasing'
  self.buff_duration = self.data.buff_duration or 9999
  self.buffdata = {name = self.buffname, color = purple[5], duration = self.buff_duration,
    toggles = {phasing = 1}
  }

  self.unit:add_buff(self.buffdata)
end

Proc_Fire = Proc:extend()
function Proc_Fire:init(args)
  self.triggers = {PROC_ON_HIT}

  Proc_Fire.super.init(self, args)
  
  
  --define the proc's vars
  self.damageType = 'fire'
  self.burnDuration = self.data.burnDuration or 3
  self.burnDps = self.data.burnDamage or 15
end

function Proc_Fire:onHit(target, damage)
  Proc_Fire.super.onHit(self, target, damage)
  --need to add a burn debuff to the target
  target:burn(self.burnDps, self.burnDuration, self.unit)
end

Proc_Firestack = Proc:extend()
function Proc_Firestack:init(args)
  self.triggers = {}

  Proc_Firestack.super.init(self, args)

  self.buffdata = {name = 'firestack', duration = 9999,
    toggles = {firestack = 1}
  }
  --add ability to stack firedmg on hit to unit
  self.unit:add_buff(self.buffdata)
end


ProcChainExplode = Proc:extend()
function ProcChainExplode:init(args)
  self.triggers = {PROC_ON_KILL}

  ProcChainExplode.super.init(self, args)
  
  

  --define the proc's vars
  self.radius = self.data.radius or 25
  self.color = self.data.color or red[0]
end

function ProcChainExplode:onKill(target)
  ProcChainExplode.super.onKill(self, target)
  if target:has_buff('burn') then
    local damage_troops = not self.is_troop
    local damage = (target.max_hp or 100) / 10
    local radius = self.radius

    cannoneer2:play{pitch = random:float(0.8, 1.2), volume = 1.2}
    Helper.Spell.DamageCircle:create(self, self.color, damage_troops, damage,
      radius, target.x, target.y)
  end
end

Proc_Blazin = Proc:extend()
function Proc_Blazin:init(args)
  self.triggers = {PROC_ON_TICK}

  Proc_Blazin.super.init(self, args)
  
  

  --define the proc's vars
  self.buff = 'blazin'
  self.buff_duration = self.data.buff_duration or 1
  self.aspd_per_enemy = self.data.aspd_per_enemy or 0.1
  self.max_aspd = self.data.max_aspd or 1

  --dont use stacks, because we don't want it to decay over time
  self.buffdata = {name = 'blazin', color = red[5], duration = self.buff_duration,
    stats = {aspd = 0}
  }

end

function Proc_Blazin:onTick(dt)
  Proc_Blazin.super.onTick(self, dt)

  --find how many enemies are burning
  local enemies = main.current.main:get_objects_by_classes(enemy_classes)
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
  -- proc stats, 
  self.buffdata = {name = 'redshield', color = grey[5], duration = 5, maxDuration = 5, stacks = 1}

end

function Proc_Redshield:onGotHit(from, damage)
  Proc_Redshield.super.onGotHit(self, from, damage)

  self.unit:redshield(self.buffdata.duration)
end

Proc_Redsword = Proc:extend()
function Proc_Redsword:init(args)
  self.triggers = {}

  Proc_Redsword.super.init(self, args)

  --define the proc's vars
  -- gain damage based on your bonus defense
  self.buffdata = {
    name = 'redsword',
    duration = 9999,
    stats = {dmg_per_def = 2}
  }
  self.unit:add_buff(self.buffdata)
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

  target:slow(self.slow_amount, self.slow_duration, self.unit)
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

Proc_Icenova = Proc:extend()
function Proc_Icenova:init(args)
  self.triggers = {PROC_ON_TICK}

  Proc_Icenova.super.init(self, args)

  --define the proc's vars
  self.damage = self.data.damage or 10
  self.radius = self.data.radius or 30
  self.duration = self.data.duration or 0.1
  self.slowAmount = self.data.slowAmount or 0.5
  self.slowDuration = self.data.slowDuration or 3
  self.color = self.data.color or blue[0]

  --define the procs memory
  self.canProc = true
  self.cooldown = self.data.cooldown or 5
  self.procDelay = self.data.procDelay or 0.8
end

function Proc_Icenova:onTick(dt)
  Proc_Icenova.super.onTick(self, dt)

  if self.canProc then
    --check for nearby enemies
    if Helper.Spell:there_is_target_in_range(self.unit, self.radius, nil) then
      self.canProc = false
      trigger:after(self.cooldown + self.procDelay, function() self.canProc = true end)
      trigger:after(self.procDelay, function() self:cast() end) 
    end
  end
end

function Proc_Icenova:cast()
  --play sound
  pop2:play{pitch = random:float(0.8, 1.2), volume = 0.9}

  --cast here, note that the spell has duration, but we only want it to trigger once
  Helper.Spell.Frostfield:create(self.unit, self.color, false, self.damage, self.radius, self.duration, self.unit.x, self.unit.y)
end


--have to define how to stack slows
-- just the amount is a little tricky, need to multiplicatively stack towards 0
-- could use stacks, but it would be nice to use any source of slow
-- ideal is multiplicative stacking, and remove slow over time
-- which i guess is a stack
-- also keep track of which unit applied the slow? or just make it a global effect
Proc_Slowstack = Proc:extend()
function Proc_Slowstack:init(args)
  self.triggers = {}

  Proc_Slowstack.super.init(self, args)

  --define the proc's vars
  self.buffdata = {name = 'slowstack', duration = 9999,
    toggles = {slowstack = 1}
  }

  self.unit:add_buff(self.buffdata)
end

--need to assign an owner to burn debuff for this to work
--consider snapshotting the owner's ele multiplier
-- and keepign it when the buff gets reapplied
Proc_Eledmg = Proc:extend()
function Proc_Eledmg:init(args)
  self.triggers = {}

  Proc_Eledmg.super.init(self, args)

  self.buffdata = {name = 'eledmg', duration = 9999,
    stats = {eledmg = 0.5}
  }

  self.unit:add_buff(self.buffdata)
end

--need to assign an owner to burn debuff for this to work
--and pass unit in to :slow()
--and see where the cold damage is coming from for frostfield
--also think about sharing vamp between the units in the troop
Proc_Elevamp = Proc:extend()
function Proc_Elevamp:init(args)
  self.triggers = {}

  Proc_Elevamp.super.init(self, args)

  self.buffdata = {name = 'elevamp', duration = 9999,
    stats = {elevamp = 0.5}
  }

  self.unit:add_buff(self.buffdata)
end



proc_name_to_class = {
  ['reroll'] = Proc_Reroll,

  ['craggy'] = Proc_Craggy,
  ['bash'] = Proc_Bash,
  ['heal'] = Proc_Heal,
  ['overkill'] = Proc_Overkill,
  ['berserk'] = Proc_Berserk,
  ['bloodlust'] = Proc_Bloodlust,
  ['lightning'] = Proc_Lightning,
  ['static'] = Proc_Static,
  ['radiance'] = Proc_Radiance,
  ['shield'] = Proc_Shield,
  ['phasing'] = Proc_Phasing,
  --red procs
  ['fire'] = Proc_Fire,
  ['firestack'] = Proc_Firestack,
  ['redshield'] = Proc_Redshield,
  ['redsword'] = Proc_Redsword,
  ['chainexplode'] = ProcChainExplode,
  ['blazin'] = Proc_Blazin,
  --blue procs
  ['frost'] = Proc_Frost,
  ['frostfield'] = Proc_Frostfield,
  ['icenova'] = Proc_Icenova,
  ['slowstack'] = Proc_Slowstack,

  -- elemental procs
  ['eledmg'] = Proc_Eledmg,
  ['elevamp'] = Proc_Elevamp
}



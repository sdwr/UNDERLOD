require 'procs/proc'
-- Desc: procs are objects that do things when certain conditions are met
-- base proc class is at the bottom

--need to pass unit into proc, some procs need to know who they are on (without callbacks)

--need a type of proc that exists on for the whole unit, not just per troop
--bloodlust (otherwise they get out of sync)
--frostfield (otherwise they get out of sync)


--either unit or team will be nil (or both!)
--need to make sure the procs will not crash when they are created on the wrong object
--move the proc startup to an 'activate' function? and only call if the unit/team exists
function Create_Proc(name, team, unit)
  if not proc_name_to_class[name] then
    print('proc not found')
    print(name)
    return nil
  end

  local procObj = proc_name_to_class[name]({team = team, unit = unit, data = {name = name}})
  return procObj
end


--proc reroll
Proc_Reroll = Proc:extend()
function Proc_Reroll:init(args)
  self.triggers = {PROC_ON_SELL}
  self.scope = 'global'

  Proc_Reroll.super.init(self, args)
  
end

--when sold in the shop, reroll the upcoming levels
--make sure this doesn't trigger at the end of rounds, when the unit is removed
function Proc_Reroll:onSell()
  --should only trigger in buy_screen
  if main.current and main.current.roll_levels then
    main.current:roll_levels()
  end
end

--proc reroll
Proc_Reset = Proc:extend()
function Proc_Reset:init(args)
  self.triggers = {PROC_ON_SELL}
  self.scope = 'global'

  Proc_Reroll.super.init(self, args)
  
end

--when sold in the shop, resets the reroll cost
function Proc_Reset:onSell()
  --should only trigger in buy_screen
  if main.current and main.current.reset_reroll_cost then
    main.current:reset_reroll_cost()
  end
end


Proc_DamagePotion = Proc:extend()
function Proc_DamagePotion:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'troop'

  Proc_DamagePotion.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'damagepotion'
  self.buffDuration = self.data.buffDuration or 9999
  self.dmgMulti = self.data.dmgMulti or 0.5
  self.buff = {name = self.buffname, color = red[5], duration = self.buffDuration,
    stats = {dmg = self.dmgMulti}
  }
end

function Proc_DamagePotion:onRoundStart()
  Proc_DamagePotion.super.onRoundStart(self)
  if not self.unit then return end
  self.unit:add_buff(self.buff)
end

Proc_ShieldPotion = Proc:extend()
function Proc_ShieldPotion:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'troop'

  Proc_ShieldPotion.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'shieldpotion'
  self.buffDuration = self.data.buffDuration or 9999
  self.shieldAmount = self.data.shieldAmount or 100
end

function Proc_ShieldPotion:onRoundStart()
  Proc_ShieldPotion.super.onRoundStart(self)
  if not self.unit then return end
  self.unit:shield(self.shieldAmount, self.buffDuration)
end

--need to make the sell trigger onroundstart
--and add the onroundstart to the unit somehow
--because the unit doesn't exist until the round starts
Proc_BerserkPotion = Proc:extend()
function Proc_BerserkPotion:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'troop'

  Proc_BerserkPotion.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'berserkpotion'
  self.buffDuration = self.data.buffDuration or 9999
  self.aspdMulti = self.data.aspdMulti or 0.5
  self.mvspdMulti = self.data.mvspdMulti or 0.2
  self.buff = {name = self.buffname, color = red[5], duration = self.buffDuration,
    stats = {aspd = self.aspdMulti, mvspd = self.mspdMulti}
  }
end

function Proc_BerserkPotion:onRoundStart()
  Proc_BerserkPotion.super.onRoundStart(self)
  if not self.unit then return end
  self.unit:add_buff(self.buff)
end

Proc_AreaPotion = Proc:extend()
function Proc_AreaPotion:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'troop'

  Proc_AreaPotion.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'areapotion'
  self.areaMulti = self.data.areaMulti or 0.3
  self.buffDuration = self.data.buffDuration or 9999
  self.buff = {name = self.buffname, color = red[5], duration = self.buffDuration,
    stats = {area_size = self.areaMulti}
  }
end

function Proc_AreaPotion:onRoundStart()
  Proc_AreaPotion.super.onRoundStart(self)
  if not self.unit then return end
  self.unit:add_buff(self.buff)
end

--proc craggy
Proc_Craggy = Proc:extend()
function Proc_Craggy:init(args)
  self.triggers = {PROC_ON_GOT_HIT}
  self.scope = 'troop'

  
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
    
    if from and from.hp and from.hp > 0 then
      from:stun(self.stunDuration)
      from:hit(self.damage, self.unit)
    end
  end
end

Proc_SackOfCash = Proc:extend()
function Proc_SackOfCash:init(args)
  self.triggers = {PROC_ON_DEATH}
  self.scope = 'global'

  Proc_SackOfCash.super.init(self, args)
  
  

  --define the proc's vars
  self.goldChance = self.data.goldChance or 0.2
end

function Proc_SackOfCash:onDeath(from)
  Proc_SackOfCash.super.onDeath(self, from)

  if not self.globalUnit then return end
  if self.globalUnit.is_troop then return end
  if self.globalUnit.class ~= 'special_enemy' then return end

  if math.random() < self.goldChance then
    gold1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
    local x_offset = random:float(-10, 10)
    local y_offset = random:float(-10, 10)
    GoldItem{group = main.current.main, x = self.globalUnit.x + x_offset, y = self.globalUnit.y + y_offset, amount = 1}
  end

end

Proc_SpikedCollar = Proc:extend()
function Proc_SpikedCollar:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_SpikedCollar.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.tick_interval = self.data.tick_interval or 3
  self.damageType = self.data.damageType or DAMAGE_TYPE_PHYSICAL

  self.radius = self.data.radius or 50

  --proc internal memory
  self.tick_timer = 0
end

function Proc_SpikedCollar:onTick(dt, from)
  Proc_SpikedCollar.super.onTick(self, dt)

  if not self.team then
    print('error: no team for proc', self.name)
    return
  end

  --only tick once per tick
  if not self.team:is_first_alive_troop(from) then return end

  self.tick_timer = self.tick_timer + dt
  if self.tick_timer < self.tick_interval then return end
  self.tick_timer = 0


  local enemies = self.team:get_enemies_in_range(self.radius)
  if not enemies or #enemies == 0 then return end

  rogue_crit1:play{pitch = random:float(0.8, 1.2), volume = 0.3}
  for i, enemy in ipairs(enemies) do
      enemy:hit(self.damage, self.unit, self.damageType)
  end
end

--proc bash
Proc_Bash = Proc:extend()
function Proc_Bash:init(args)
  self.triggers = {PROC_ON_HIT}
  self.scope = 'troop'
  
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

--works the same way as shield
Proc_Heal = Proc:extend()
function Proc_Heal:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'troop'

  Proc_Heal.super.init(self, args)
  
  

  --define the proc's vars
  self.time_between = self.data.time_between or 5
  self.healAmount = self.data.healAmount or 10
end

function Proc_Heal:onRoundStart()
  Proc_Heal.super.onRoundStart(self)
  if not self.unit then return end
  self.manual_trigger = trigger:every(self.time_between, function()
    self:heal()
  end)
end

function Proc_Heal:heal()
  if self.unit and self.unit.heal then
    heal1:play{pitch = random:float(0.8, 1.2), volume = 0.1}
    self.unit:heal(self.healAmount)
  end
end

function Proc_Heal:die()
  Proc_Heal.super.die(self)
  if not self.manual_trigger then return end
  trigger:cancel(self.manual_trigger)
end

Proc_SacrificialClam = Proc:extend()
function Proc_SacrificialClam:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_SacrificialClam.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'sacrificialclam'
  self.buffDuration = self.data.duration or 4
  self.buffAspd = self.data.buffAspd or 0.4
  self.tick_interval = self.buffDuration

  self.buffdata = {name = self.buffname, duration = self.buffDuration,
    stats = {aspd = self.buffAspd}, color = green[3]
  }

  self.selfDamage = self.data.selfDamage or 15
  
  self.radius = self.data.radius or 50

  --proc internal memory
  self.tick_timer = self.buffDuration / 2
end

function Proc_SacrificialClam:onTick(dt, from)
  Proc_SacrificialClam.super.onTick(self, dt)

  if not self.team then
    print('error: no team for proc', self.name)
    return
  end

  --only tick once per tick
  if not self.team:is_first_alive_troop(from) then return end

  self.tick_timer = self.tick_timer + dt
  if self.tick_timer < self.tick_interval then return end
  self.tick_timer = 0


  local allies = self.team:get_allies_in_range(self.radius)
  self.team:damage_all_troops(self.selfDamage, nil, DAMAGE_TYPE_PHYSICAL)
  
  pop2:play{pitch = random:float(0.8, 1.2), volume = 1.2}
  
  if not allies or #allies == 0 then return end
  for i, ally in ipairs(allies) do
    ally:add_buff(self.buffdata)
  end
end

Proc_HealingWave = Proc:extend()
function Proc_HealingWave:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_HealingWave.super.init(self, args)
  
  

  --define the proc's vars
  self.tick_interval = self.data.tick_interval or 5

  self.healAmount = self.data.healAmount or 25
  self.radius = self.data.radius or 75
  self.color = self.data.color or green[0]

  --proc memory
  self.tick_timer = 0
end

function Proc_HealingWave:onTick(dt, from)
  Proc_HealingWave.super.onTick(self, dt)

  if not self.team then
    print('error: no team for proc', self.name)
    return
  end

  --only tick once per tick
  if not self.team:is_first_alive_troop(from) then return end

  self.tick_timer = self.tick_timer + dt
  if self.tick_timer < self.tick_interval then return end


  self:cast(from)
end

function Proc_HealingWave:cast(from)

  heal1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.tick_timer = 0

  local randomx = random:float(-10, 10)
  local randomy = random:float(-10, 10)

  Area{
    group = main.current.effects, 
    x = from.x + randomx, y = from.y + randomy,
    pick_shape = 'circle',
    dmg = 0, r = self.radius, duration = 0.2, color = self.color,
    is_troop = from.is_troop,
    heal = self.healAmount
  }

end



Proc_Curse = Proc:extend()
function Proc_Curse:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_Curse.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'curse'
  self.buffDuration = self.data.buffDuration or 3
  self.seek_radius = 100
  self.radius = self.data.radius or 50
  self.color = self.data.color or purple[0]
  self.buffdata = {name = self.buffname, duration = self.buffDuration, color = self.color,
    stats = {percent_def = -0.4}
  }

  self.tick_interval = self.data.tick_interval or 5 
  --proc memory
  self.tick_timer = math.random() * self.tick_interval
end

function Proc_Curse:onTick(dt, from)
  Proc_Curse.super.onTick(self, dt)

  if not self.team then
    print('error: no team for proc', self.name)
    return
  end

  --only tick once per tick
  if not self.team:is_first_alive_troop(from) then return end

  self.tick_timer = self.tick_timer + dt
  if self.tick_timer < self.tick_interval then return end

  local enemy = Helper.Spell:get_random_target_in_range_from_point(from.x, from.y, self.seek_radius, from.is_troop)
  if not enemy or enemy == -1 then return end

  self.tick_timer = math.random() * self.tick_interval
  self:curse(enemy, from)
end

function Proc_Curse:curse(target, from)
  if not target then return end
  glass_shatter:play{pitch = random:float(0.8, 1.2), volume = 0.5}

  local randomx = random:float(-10, 10)
  local randomy = random:float(-10, 10)

  Area{
    group = main.current.effects, 
    x = target.x + randomx, y = target.y + randomy,
    pick_shape = 'circle',
    dmg = 0, r = self.radius, duration = 0.2, color = self.color,
    is_troop = from.is_troop,
    debuff = self.buffdata
  
  }
end

Proc_Root = Proc:extend()
function Proc_Root:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_Root.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'root'
  self.rootDuration = self.data.rootDuration or 3
  self.seek_radius = 100
  self.radius = self.data.radius or 50
  self.color = self.data.color or green[0]

  self.tick_interval = self.data.tick_interval or 5 
  --proc memory
  self.tick_timer = math.random() * self.tick_interval
end

function Proc_Root:onTick(dt, from)
  Proc_Root.super.onTick(self, dt)

  if not self.team then
    print('error: no team for proc', self.name)
    return
  end

  --only tick once per tick
  if not self.team:is_first_alive_troop(from) then return end

  self.tick_timer = self.tick_timer + dt
  if self.tick_timer < self.tick_interval then return end

  local enemy = Helper.Spell:get_random_target_in_range_from_point(from.x, from.y, self.seek_radius, from.is_troop)
  if not enemy or enemy == -1 then return end

  self:root(enemy, from)
end

function Proc_Root:root(target, from)
  if not target then return end

  glass_shatter:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.tick_timer = 0

  local randomx = random:float(-10, 10)
  local randomy = random:float(-10, 10)

  Area{
    group = main.current.effects, 
    x = target.x + randomx, y = target.y + randomy,
    pick_shape = 'circle',
    dmg = 0, r = self.radius, duration = 0.2, color = self.color,
    is_troop = from.is_troop,
    rootDuration = self.rootDuration
  
  }
end



--proc overkill
Proc_Overkill = Proc:extend()
function Proc_Overkill:init(args)
  self.triggers = {PROC_ON_KILL}
  self.scope = 'troop'

  Proc_Overkill.super.init(self, args)
  
  

  --define the proc's vars
  self.overkillMulti = self.data.overkillMulti or 0.2
  self.radius = self.data.sizeMulti or 2
  self.is_troop = (self.unit and self.unit.is_troop) or false
end
function Proc_Overkill:onKill(target)
  Proc_Overkill.super.onKill(self, target)
  local damage = target.max_hp * self.overkillMulti
  local radius = target.shape.w * self.radius

  cannoneer2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  Area{
    group = main.current.effects, 
    x = target.x, y = target.y,
    pick_shape = 'circle',
    dmg = damage,
    r = radius, duration = 0.2, color = black[0],
    is_troop = self.is_troop,
  }
end

Proc_Bloodlust = Proc:extend()
function Proc_Bloodlust:init(args)
  self.triggers = {PROC_ON_KILL}
  self.scope = 'team'

  Proc_Bloodlust.super.init(self, args)
  
  

  --define the proc's vars
  --buff defined in objects.lua (unit) :berserk()
  self.buffname = 'bloodlust'
  self.buffDuration = self.data.buffDuration or 5
end

function Proc_Bloodlust:onKill(target)
  Proc_Bloodlust.super.onKill(self, target)
  local units = self.team.troops
  for i, unit in ipairs(units) do
    unit:bloodlust(self.buffDuration)
  end
end


--proc lightning
--needs 2 procs, so that the attack counter only counts down on 1 hit per attack
Proc_Lightning = Proc:extend()
function Proc_Lightning:init(args)
  self.triggers = {PROC_ON_ATTACK, PROC_ON_HIT}
  self.scope = 'troop'

  Proc_Lightning.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.damageType = DAMAGE_TYPE_LIGHTNING
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
  self.scope = 'team'

  Proc_Static.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.damageType = DAMAGE_TYPE_LIGHTNING
  self.chain = self.data.chain or 6
  self.every_moves = self.data.every_moves or 500
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
    pop2:play{pitch = random:float(0.8, 1.2), volume = 1.2}
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
      chain = self.chain,
      level = 1}
  end
end

Proc_Shock = Proc:extend()
function Proc_Shock:init(args)
  self.triggers = {PROC_ON_HIT}
  self.scope = 'troop'

  Proc_Shock.super.init(self, args)
  
  

  --define the proc's vars
  self.color = self.data.color or yellow[0]
  self.duration = 5
end

function Proc_Shock:onHit(target, damage, damageType)
  Proc_Shock.super.onHit(self, target, damage, damageType)
  
  if damageType == DAMAGE_TYPE_LIGHTNING then
    target:shock(self.duration)
  end
end

Proc_Overcharge = Proc:extend()
function Proc_Overcharge:init(args)
  self.triggers = {PROC_ON_ATTACK}
  self.scope = 'team'

  Proc_Overcharge.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'overcharge'
  self.buffDuration = self.data.buffDuration or 9999
  self.aspdMulti = self.data.aspdMulti or 0.1
  self.maxStacks = self.data.maxStacks or 10

  self.buff = {name = self.buffname, color = yellow[5], duration = self.buffDuration,
    stats = {aspd = self.aspdMulti}, stacks = 1
  }

  --memory
  self.targets = {}
  self.hitCount = 0

end

function Proc_Overcharge:onAttack(target, unit)
  Proc_Overcharge.super.onAttack(self, target)

  --only apply the buff when the first unit attacks
  --but drop the buff when any unit attacks a different target
  --keep track of each unit's target separately
  local troopIndex = self.team:get_troop_index(unit)
  if troopIndex == -1 then return end

  if not self.targets[troopIndex] then
    self.targets[troopIndex] = target
  elseif self.targets[troopIndex] ~= target then
      self.team:remove_buff(self.buffname)
      self:resetStacks()
  else
    --the same target, add a stack
    self:addHit()
  end

end

function Proc_Overcharge:addHit()
  self.hitCount = self.hitCount + 1
  if self.hitCount >= self.team:get_alive_troop_count() then
    self.buff.stacks = math.min(self.buff.stacks + 1, self.maxStacks)
    self.team:add_buff(self.buff)
    self.hitCount = 0
  end
end

function Proc_Overcharge:resetStacks()
  self.buff.stacks = 1
  self.targets = {}
end

Proc_Powercharge = Proc:extend()
function Proc_Powercharge:init(args)
  self.triggers = {PROC_ON_ATTACK}
  self.scope = 'team'

  Proc_Powercharge.super.init(self, args)

  --define the proc's vars
  self.buffname = 'powercharge'
  self.buffDuration = self.data.buffDuration or 9999
  self.dmgMulti = self.data.dmgMulti or 0.1
  self.maxStacks = self.data.maxStacks or 10

  self.buff = {name = self.buffname, color = red[5], duration = self.buffDuration,
    stats = {dmg = self.dmgMulti}, stacks = 1
  }

  --memory
  self.targets = {}
  self.hitCount = 0

end

function Proc_Powercharge:onAttack(target, unit)
  Proc_Powercharge.super.onAttack(self, target)

  --only apply the buff when the first unit attacks
  --but drop the buff when any unit attacks a different target
  --keep track of each unit's target separately
  local troopIndex = self.team:get_troop_index(unit)
  if troopIndex == -1 then return end

  if not self.targets[troopIndex] then
    self.targets[troopIndex] = target
  elseif self.targets[troopIndex] ~= target then
      self.team:remove_buff(self.buffname)
      self:resetStacks()
  else
    --the same target, add a stack
    self:addHit()
  end

end

function Proc_Powercharge:addHit()
  self.hitCount = self.hitCount + 1
  if self.hitCount >= self.team:get_alive_troop_count() then
    self.buff.stacks = math.min(self.buff.stacks + 1, self.maxStacks)
    self.team:add_buff(self.buff)
    self.hitCount = 0
  end
end

function Proc_Powercharge:resetStacks()
  self.buff.stacks = 1
  self.targets = {}
end

Proc_Vulncharge = Proc:extend()
function Proc_Vulncharge:init(args)
  self.triggers = {PROC_ON_ATTACK}
  self.scope = 'team'

  Proc_Vulncharge.super.init(self, args)

  --define the proc's vars
  self.buffname = 'vulncharge'
  self.buffDuration = self.data.buffDuration or 5
  self.dmgMulti = self.data.dmgMulti or 0.1
  self.maxStacks = self.data.maxStacks or 10

  self.buff = {name = self.buffname, color = purple[5], duration = self.buffDuration,
    stats = {percent_def = -0.1}, stacks = 1, stacks_expire_together = true
  }

  --memory
  self.target = nil
  self.hitCount = 0

end

function Proc_Vulncharge:onAttack(target, unit)
  Proc_Vulncharge.super.onAttack(self, target)

  --only apply to one target ( all troops must attack the same target)
  local troopIndex = self.team:get_troop_index(unit)
  if troopIndex == -1 then return end

  if not self.target then
    self.target = target
  elseif self.target ~= target then
    self:removeVuln()
    self:resetStacks()
    self.target = target
  else
    --the same target, add a stack
    self:addHit()
  end

end

function Proc_Vulncharge:addHit()
  self.hitCount = self.hitCount + 1
  if self.hitCount >= self.team:get_alive_troop_count() then
    self.buff.stacks = math.min(self.buff.stacks + 1, self.maxStacks)
    self:applyVuln()
    self.hitCount = 0
  end
end

function Proc_Vulncharge:applyVuln()
  if not self.target then return end
  self.target:add_buff(self.buff)
end

function Proc_Vulncharge:removeVuln()
  if not self.target then return end
  self.target:remove_buff(self.buffname)
end

function Proc_Vulncharge:resetStacks()
  self.buff.stacks = 1
  self.targets = {}
end

--talismans that grant global buffs
Proc_StrengthTalisman = Proc:extend()
function Proc_StrengthTalisman:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'global'

  Proc_StrengthTalisman.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'strengthtalisman'
  self.buffDuration = self.data.buffDuration or 9999
  self.dmgMulti = self.data.dmgMulti or 0.25
  self.buff = {name = self.buffname, color = red[5], duration = self.buffDuration,
    stats = {dmg = self.dmgMulti}
  }
end

function Proc_StrengthTalisman:onRoundStart()
  Proc_StrengthTalisman.super.onRoundStart(self)

  spawn_mark2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  local troops = Helper.Unit:get_list(true)
  for i, troop in ipairs(troops) do
    troop:add_buff(self.buff)
  end
end

Proc_AgilityTalisman = Proc:extend()
function Proc_AgilityTalisman:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'global'

  Proc_AgilityTalisman.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'agilitytalisman'
  self.buffDuration = self.data.buffDuration or 9999
  self.aspdMulti = self.data.aspdMulti or 0.25
  self.mvspdMulti = self.data.mvspdMulti or 0.25
  self.buff = {name = self.buffname, color = yellow[5], duration = self.buffDuration,
    stats = {aspd = self.aspdMulti, mvspd = self.mvspdMulti}
  }
end

function Proc_AgilityTalisman:onRoundStart()
  Proc_AgilityTalisman.super.onRoundStart(self)

  spawn_mark2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  local troops = Helper.Unit:get_list(true)
  for i, troop in ipairs(troops) do
    troop:add_buff(self.buff)
  end
end

--CDR ON STATS NOT IMPLEMENTED
Proc_WisdomTalisman = Proc:extend()
function Proc_WisdomTalisman:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'global'

  Proc_WisdomTalisman.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'wisdomtalisman'
  self.buffDuration = self.data.buffDuration or 9999
  self.range = self.data.range or 0.25
  self.cdrMulti = self.data.cdr or 0.1
  self.buff = {name = self.buffname, color = blue[5], duration = self.buffDuration,
    stats = {range = self.range, cdr = self.cdrMulti}
  }
end

function Proc_WisdomTalisman:onRoundStart()
  Proc_WisdomTalisman.super.onRoundStart(self)

  spawn_mark2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  local troops = Helper.Unit:get_list(true)
  for i, troop in ipairs(troops) do
    troop:add_buff(self.buff)
  end
end

Proc_VitalityTalisman = Proc:extend()
function Proc_VitalityTalisman:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'global'

  Proc_VitalityTalisman.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'vitalitytalisman'
  self.buffDuration = self.data.buffDuration or 9999
  self.hpMulti = self.data.hpMulti or 0.25
  self.defMulti = self.data.defMulti or 0.25
  self.buff = {name = self.buffname, color = green[5], duration = self.buffDuration,
    stats = {hp = self.hpMulti, percent_def = self.defMulti}
  }
end

function Proc_VitalityTalisman:onRoundStart()
  Proc_VitalityTalisman.super.onRoundStart(self)

  spawn_mark2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  local troops = Helper.Unit:get_list(true)
  for i, troop in ipairs(troops) do
    troop:add_buff(self.buff)
  end
end

--triggers on all enemy deaths
Proc_Firebomb = Proc:extend()
function Proc_Firebomb:init(args)
  self.triggers = {PROC_ON_DEATH}
  self.scope = 'global'

  Proc_Firebomb.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.radius = self.data.radius or 30
  self.color = self.data.color or red[0]

  self.chance_to_proc = self.data.chance_to_proc or 0.2

  self.is_troop = true
end

function Proc_Firebomb:onDeath(from)
  Proc_Firebomb.super.onDeath(self, from)
  
  
  if not self.globalUnit then return end
  if self.globalUnit.is_troop == self.is_troop then return end
  
  if not self.globalUnit:has_buff('burn') then return end

  if math.random() < self.chance_to_proc then
    self:explode(from)
  end
end

function Proc_Firebomb:explode(from)
  explosion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  Area{
    group = main.current.effects,
    x = self.globalUnit.x, y = self.globalUnit.y,
    pick_shape = 'circle',
    dmg = self.damage, r = self.radius, duration = 0.2, color = self.color,
    is_troop = self.is_troop
  }

  self.globalUnit = nil
end

Proc_WaterElemental = Proc:extend()
function Proc_WaterElemental:init(args)
  self.triggers = {PROC_ON_DEATH}
  self.scope = 'global'

  Proc_WaterElemental.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.radius = self.data.radius or 30
  self.color = self.data.color or blue[0]

  self.chance_to_proc = self.data.chance_to_proc or 0.2

  self.is_troop = true

  --proc memory
  self.maxSummons = self.data.maxSummons or 3
  self.summoned = 0
  self.summons = {}
end

function Proc_WaterElemental:onDeath(from)
  Proc_WaterElemental.super.onDeath(self, from)
  
  if not self.globalUnit then return end
  if self.globalUnit.is_troop == self.is_troop then return end

  if not self.globalUnit:has_buff('slowed') then return end

  self:checkSummons()

  if math.random() < self.chance_to_proc and self.summoned < self.maxSummons then
    self:summon(from)
  end

  self.globalUnit = nil
end

function Proc_WaterElemental:summon(from)
  local myLocation = {x = self.globalUnit.x, y = self.globalUnit.y}
  local location = Get_Spawn_Point(6, myLocation)
  if not location then return end
  local summon = Critter{group = main.current.main,
    x = location.x, y = location.y, color = self.color, r = random:float(0, 2*math.pi)
  }

  self.summoned = self.summoned + 1
  table.insert(self.summons, summon)
end

function Proc_WaterElemental:checkSummons()
  for i, summon in ipairs(self.summons) do
    if not summon or summon.dead then
      table.remove(self.summons, i)
      self.summoned = self.summoned - 1
    end
  end
end

function Proc_WaterElemental:clearSummonList()
  for i, summon in ipairs(self.summons) do
    if summon then
      summon:die()
    end
  end
end

function Proc_WaterElemental:die()
  Proc_WaterElemental.super.die(self)
  self:clearSummonList()
end

Proc_Shockwave = Proc:extend()
function Proc_Shockwave:init(args)
  self.triggers = {PROC_ON_DEATH}
  self.scope = 'global'

  Proc_Shockwave.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.radius = self.data.radius or 30
  self.color = self.data.color or yellow[0]

  self.chance_to_proc = self.data.chance_to_proc or 0.2

  self.is_troop = true
end

function Proc_Shockwave:onDeath(from)
  Proc_Shockwave.super.onDeath(self, from)
  
  if not self.globalUnit then return end
  if self.globalUnit.is_troop == self.is_troop then return end

  if not self.globalUnit:has_buff('shock') then return end

  if math.random() < self.chance_to_proc then
    self:shockwave(from)
  end
end

function Proc_Shockwave:shockwave(from)
  explosion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  Area{
    group = main.current.effects,
    x = self.globalUnit.x, y = self.globalUnit.y,
    pick_shape = 'circle',
    dmg = self.damage, r = self.radius, duration = 0.2, color = self.color,
    is_troop = self.is_troop,
    shockDuration = 5,
  }

  self.globalUnit = nil
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
  self.scope = 'troop'

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
        enemy:hit(self.damage, nil, self.damageType)
      end
    end
  end
end

--can only have 1 shield at a time, no stack for now
--any new shield will overwrite the old one
Proc_Shield = Proc:extend()
function Proc_Shield:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'troop'

  Proc_Shield.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'shield'
  self.shield_amount = self.data.shield_amount or 10
  self.time_between = self.data.time_between or 5
  self.buff_duration = self.data.buff_duration or 4

end

function Proc_Shield:onRoundStart()
  Proc_Shield.super.onRoundStart(self)
  if not self.unit then return end
  self.manual_trigger = trigger:every_immediate(self.time_between, function()
    self.unit:shield(self.shield_amount, self.buff_duration)
  end)
end

--should cancel the trigger when the unit dies
function Proc_Shield:die()
  Proc_Shield.super.die(self)
  if not self.manual_trigger then return end
  trigger:cancel(self.manual_trigger)
end

Proc_Fire = Proc:extend()
function Proc_Fire:init(args)
  self.triggers = {PROC_ON_HIT}
  self.scope = 'troop'

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

Proc_Lavapool = Proc:extend()
function Proc_Lavapool:init(args)
  self.triggers = {PROC_ON_ATTACK, PROC_ON_HIT}
  self.scope = 'troop'

  Proc_Lavapool.super.init(self, args)
  

  --define the proc's vars
  self.duration = self.data.duration or 3
  self.color = self.data.color or red[0]
  self.damage = self.data.damage or 10
  self.tick_rate = self.data.tick_rate or 1
  self.radius = self.data.radius or 25
  self.every_attacks = self.data.every_attacks or 4

  --define the procs memory
  self.has_attacked = false
  self.attacks_left = math.random(1, self.every_attacks)
end

function Proc_Lavapool:onAttack(target)
  Proc_Lavapool.super.onAttack(self, target)
  if self.attacks_left > 0 then
    self.has_attacked = true
  end
end

function Proc_Lavapool:onHit(target, damage)
  Proc_Lavapool.super.onHit(self, target, damage)
  if self.has_attacked then
    self.has_attacked = false
    self.attacks_left = self.attacks_left - 1
    if self.attacks_left == 0 then
      self.attacks_left = self.every_attacks

      --remove level from spell
      Area{
        group = main.current.floor,
        unit = self.unit,
        x= target.x, y = target.y,
        pick_shape = 'circle',
        damage_ticks = true,
        tick_rate = self.tick_rate,
        tick_immediately = true,
        dmg = self.damage,
        r = self.radius, duration = self.duration, color = self.color,
        is_troop = self.unit.is_troop,
        burnDps = 10,
        burnDuration = 2
      }
    end
  end
end

Proc_Firestack = Proc:extend()
function Proc_Firestack:init(args)
  self.triggers = {}
  self.scope = 'troop'

  Proc_Firestack.super.init(self, args)

  self.buffdata = {name = 'firestack', duration = 9999,
    toggles = {firestack = 1}
  }
  --add ability to stack firedmg on hit to unit
  if not self.unit then return end
  self.unit:add_buff(self.buffdata)
end

Proc_Lavaman = Proc:extend()
function Proc_Lavaman:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_Lavaman.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'lavaman'
  self.tick_interval = 5
  self.color = self.data.color or red[0]

  --proc memory
  self.tick_timer = math.random() * self.tick_interval
end

function Proc_Lavaman:onTick(dt, from)
  Proc_Lavaman.super.onTick(self, dt)

  if not self.team then
    print('error: no team for proc', self.name)
    return
  end

  --only tick once per tick
  if not self.team:is_first_alive_troop(from) then return end
  --should cancel when all troops in the team are dead

  self.tick_timer = self.tick_timer + dt
  if self.tick_timer < self.tick_interval then return end

  self:try_spawn(from)
end

function Proc_Lavaman:try_spawn(from)

  -- find a random free spot in the team
  self:find_free_spot(from)
  
  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.tick_timer = 0
end

function Proc_Lavaman:find_free_spot(from)
  local tries = 10
  for i = 1, tries do
    local offset = SpawnGlobals.spawn_offsets[i % #SpawnGlobals.spawn_offsets]
    local coords = {x = from.x + offset.x, y = from.y + offset.y}
    if Can_Spawn(2, coords) then
      self:spawn(coords)
      return
    end
  end
end

function Proc_Lavaman:spawn(coords)
  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.tick_timer = 0
  Critter{group = main.current.main,
    x = coords.x, y = coords.y, color = self.color, r = random:float(0, 2*math.pi)
  }
end


--should be global instead of per troop?
Proc_FireExplode = Proc:extend()
function Proc_FireExplode:init(args)
  self.triggers = {}
  self.scope = 'troop'

  Proc_FireExplode.super.init(self, args)

  self.buffdata = {name = 'fireexplode', duration = 9999,
  toggles = {fireexplode = 1}, onExplode = function(target) self.explode(self, target) end
  }

  if not self.unit then return end
  self.unit:add_buff(self.buffdata)

  --define the proc's vars
  self.radius = self.data.radius or 25
  self.color = self.data.color or red[0]
  self.dmgMulti = self.data.dmgMulti or 0.2
  self.sizeMulti = self.data.sizeMulti or 2

  self.is_troop = (self.unit and self.unit.is_troop) or false

end

function Proc_FireExplode:explode(target)
  local damage = (target.max_hp * self.dmgMulti)
  local radius = target.shape.w * self.sizeMulti

  target:remove_buff('burn')

  cannoneer1:play{pitch = random:float(0.8, 1.2), volume = 1.2}
  Area{
    group = main.current.effects, 
    x = target.x, y = target.y,
    pick_shape = 'circle',
    dmg = damage,
    r = radius, duration = 0.2, color = self.color,
    is_troop = self.is_troop,
  }
end

Proc_Blazin = Proc:extend()
function Proc_Blazin:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'troop'

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
  if not self.unit then return end
  self.unit:remove_buff(self.buff)
  self.unit:add_buff(self.buffdata)
end

Proc_Frost = Proc:extend()
function Proc_Frost:init(args)
  self.triggers = {PROC_ON_HIT}
  self.scope = 'troop'

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
  self.scope = 'troop'

  Proc_Frostfield.super.init(self, args)

  --define the proc's vars
  self.duration = self.data.duration or 3
  self.color = self.data.color or blue[0]

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
      Area{
        group = main.current.floor,
        unit = self.unit,
        x= target.x, y = target.y,
        pick_shape = 'circle',
        damage_ticks = true,
        dmg = 0,
        r = self.radius, duration = self.duration, color = self.color,
        is_troop = self.unit.is_troop,
        slowAmount = self.slow_amount,
        slowDuration = self.slow_duration
      }
    end
  end
end

Proc_Holduground = Proc:extend()
function Proc_Holduground:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'troop'

  Proc_Holduground.super.init(self, args)

  --define the proc's vars
  self.buffname = 'holduground'
  self.aspd_per_second = self.data.aspd_per_second or 0.2
  self.max_aspd = self.data.max_aspd or 1

  --define the procs memory
  self.time_elapsed = 0
end

--could be a buff, but lets do everything in the proc
--think about adding 'per second' procs instead of onTick
--not sure what performance is like, but we could save some calculations
function Proc_Holduground:onTick(dt)
  Proc_Holduground.super.onTick(self, dt)
  if not self.unit then return end
  if self.unit:isMoving() then
    self.time_elapsed = 0
    self.unit:remove_buff(self.buffname)
  else
    self.time_elapsed = self.time_elapsed + dt
    local aspd = math.min(self.time_elapsed * self.aspd_per_second, self.max_aspd)
    local buffdata = {name = 'holduground', color = blue[5], duration = 1,
      stats = {aspd = aspd}
    }
    self.unit:remove_buff(self.buffname)
    self.unit:add_buff(buffdata)
  end
end

--only lasts a second so not really necessary to remove (and no timer involved)
function Proc_Holduground:die()
  Proc_Holduground.super.die(self)
  if not self.unit then return end
  self.unit:remove_buff(self.buffname)
end

Proc_Icenova = Proc:extend()
function Proc_Icenova:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'troop'

  Proc_Icenova.super.init(self, args)

  --define the proc's vars
  self.damageMulti = self.data.damageMulti or 1
  self.radius = self.data.radius or 30
  self.duration = self.data.duration or 0.2
  self.slowAmount = self.data.slowAmount or 0.5
  self.slowDuration = self.data.slowDuration or 3
  self.color = self.data.color or blue[0]

  --define the procs memory
  self.canProc = true
  self.cooldown = self.data.cooldown or 5
  self.procDelay = self.data.procDelay or 0.4

  self:reset_tryProc()
end

function Proc_Icenova:onTick(dt)
  Proc_Icenova.super.onTick(self, dt)
  

  if self.canProc then
    --check for nearby enemies
    if Helper.Spell:there_is_target_in_range(self.unit, self.radius - 8, nil) then
      self.canProc = false
      self:start_proc_delay()
    end
  elseif self.tryProc then
    self.active_procDelay = self.active_procDelay - dt
    if self.active_procDelay <= 0 then
      self:try_proc()
    end
  
  end
end

--wait a bit before casting, to see if the unit is still in range
function Proc_Icenova:start_proc_delay()
  alert1:play{pitch = random:float(0.8, 1.2), volume = 0.6}
  self.canProc = false
  self.tryProc = true
  self.active_procDelay = self.procDelay
end

function Proc_Icenova:try_proc()
  if Helper.Spell:there_is_target_in_range(self.unit, self.radius - 8, nil) then
    self:cast()
    trigger:after(self.cooldown, function() self.canProc = true end)
    self:reset_tryProc()
  else
    --reset the proc
    self.canProc = true
    self:reset_tryProc()
  end
end

function Proc_Icenova:reset_tryProc()
  self.tryProc = false
  self.active_procDelay = 0
end

function Proc_Icenova:cast()
  --play sound
  glass_shatter:play{pitch = random:float(0.8, 1.2), volume = 0.8}

  local damage = self.unit.dmg * self.damageMulti
  --cast here, note that the spell has duration, but we only want it to trigger once
  Area{
    group = main.current.effects,
    unit = self.unit,
    x = self.unit.x, y = self.unit.y,
    pick_shape = 'circle',
    dmg = damage,
    r = self.radius + 3, duration = self.duration, color = self.color,
    is_troop = self.unit.is_troop,
    slowAmount = self.slowAmount,
    slowDuration = self.slowDuration
  }
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
  self.scope = 'troop'

  Proc_Slowstack.super.init(self, args)

  --define the proc's vars
  self.buffdata = {name = 'slowstack', duration = 9999,
    toggles = {slowstack = 1}
  }

  if not self.unit then return end
  self.unit:add_buff(self.buffdata)
end

--need to assign an owner to burn debuff for this to work
--consider snapshotting the owner's ele multiplier
-- and keepign it when the buff gets reapplied
Proc_Eledmg = Proc:extend()
function Proc_Eledmg:init(args)
  self.triggers = {}
  self.scope = 'troop'

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
  self.scope = 'troop'

  Proc_Elevamp.super.init(self, args)

  self.buffdata = {name = 'elevamp', duration = 9999,
    stats = {elevamp = 0.5}
  }

  self.unit:add_buff(self.buffdata)
end



proc_name_to_class = {
  ['reroll'] = Proc_Reroll,
  ['reset'] = Proc_Reset,
  ['damagepotion'] = Proc_DamagePotion,
  ['shieldpotion'] = Proc_ShieldPotion,
  ['berserkpotion'] = Proc_BerserkPotion,
  ['areapotion'] = Proc_AreaPotion,
  
  ['sackofcash'] = Proc_SackOfCash,

  ['craggy'] = Proc_Craggy,
  ['spikedcollar'] = Proc_SpikedCollar,
  ['bash'] = Proc_Bash,
  ['overkill'] = Proc_Overkill,
  ['bloodlust'] = Proc_Bloodlust,

  --yellow procs
  ['lightning'] = Proc_Lightning,
  ['static'] = Proc_Static,
  ['radiance'] = Proc_Radiance,
  ['shield'] = Proc_Shield,
  ['shock'] = Proc_Shock,
  --red procs
  ['fire'] = Proc_Fire,
  ['lavapool'] = Proc_Lavapool,
  ['lavaman'] = Proc_Lavaman,
  ['firestack'] = Proc_Firestack,
  ['fireexplode'] = Proc_FireExplode,
  ['blazin'] = Proc_Blazin,
  --blue procs
  ['frost'] = Proc_Frost,
  ['frostfield'] = Proc_Frostfield,
  ['holduground'] = Proc_Holduground,
  ['icenova'] = Proc_Icenova,
  ['slowstack'] = Proc_Slowstack,
  --green procs
  ['heal'] = Proc_Heal,
  ['sacrificialclam'] = Proc_SacrificialClam,
  ['healingwave'] = Proc_HealingWave,
  ['curse'] = Proc_Curse,
  ['root'] = Proc_Root,
  
  --stack on attack
  ['overcharge'] = Proc_Overcharge,
  ['powercharge'] = Proc_Powercharge,
  ['vulncharge'] = Proc_Vulncharge,


  --global talismans
  ['strengthtalisman'] = Proc_StrengthTalisman,
  ['wisdomtalisman'] = Proc_WisdomTalisman,
  ['agilitytalisman'] = Proc_AgilityTalisman,
  ['vitalitytalisman'] = Proc_VitalityTalisman,

  --elemental on death
  ['firebomb'] = Proc_Firebomb,
  ['waterelemental'] = Proc_WaterElemental,
  ['shockwave'] = Proc_Shockwave,

  -- elemental procs
  ['eledmg'] = Proc_Eledmg,
  ['elevamp'] = Proc_Elevamp
}



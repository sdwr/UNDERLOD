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
  self.baseCooldown = 1
  self.adjustedCooldown = Helper.Unit:apply_cooldown_reduction(self, self.baseCooldown)
  self.chance = self.data.chance or 0.1
  self.damage = self.data.damage or 15

end
function Proc_Craggy:onGotHit(from, damage)
  Proc_Craggy.super.onGotHit(self, from)
  if self.canProc and math.random() < self.chance then
    self.canProc = false
    trigger:after(self.adjustedCooldown, function() self.canProc = true end)

    arrow_hit_wall2:play{pitch = random:float(0.8, 1.2), volume = 0.9}
    
    if from and from.hp and from.hp > 0 then
      from:stun()
      from:hit(self.damage, self.unit, DAMAGE_TYPE_PHYSICAL, true, false)
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
  self.triggers = {PROC_ON_GOT_HIT}
  self.scope = 'troop'

  Proc_SpikedCollar.super.init(self, args)
  
  
  --define the proc's vars
  
  self.damage = self.data.damage or 20
  self.tick_interval = self.data.tick_interval or 2
  self.damageType = self.data.damageType or DAMAGE_TYPE_PHYSICAL
  self.stunChance = self.data.stunChance or 0.2
  self.stunDuration = self.data.stunDuration or 1
  
  self.radius = self.data.radius or 35
  self.color = self.data.color or brown[0]

  self.baseCooldown = 2
  self.adjustedCooldown = Helper.Unit:apply_cooldown_reduction(self, self.baseCooldown)
  self.proc_chance = self.data.proc_chance or 0.2
  
  --proc internal memory
  self.cooldown_timer = 0
end

function Proc_SpikedCollar:onTick(dt, from)
  Proc_SpikedCollar.super.onTick(self, dt, from)

  if self.cooldown_timer > 0 then
    self.cooldown_timer = self.cooldown_timer - dt
    if self.cooldown_timer < 0 then
      self.cooldown_timer = 0
    end
  end
end

function Proc_SpikedCollar:onGotHit(from, damage)
  if not self.unit or self.cooldown_timer > 0 then return end

  Proc_SpikedCollar.super.onGotHit(self, from, damage)

  if math.random() < self.proc_chance then
    rogue_crit1:play{pitch = random:float(0.8, 1.2), volume = 0.6}

    self:create_area()

    self.cooldown_timer = self.adjustedCooldown
  end
end

function Proc_SpikedCollar:create_area()
  if not self.unit then return end

  self.display_area = Area{
    group = main.current.effects,
    x = self.unit.x, y = self.unit.y,
    pick_shape = 'circle',
    damage = self.damage, r = self.radius, duration = 0.2, color = self.color,
    is_troop = self.unit.is_troop,
    damage_ticks = false,
    stunDuration = self.stunDuration,
    unit = self.unit,
  }
end

function Proc_SpikedCollar:die()
  Proc_SpikedCollar.super.die(self)
end

--works the same way as shield
Proc_Heal = Proc:extend()
function Proc_Heal:init(args)
  self.triggers = {PROC_ON_ROUND_START}
  self.scope = 'troop'

  Proc_Heal.super.init(self, args)
  
  

  --define the proc's vars
  self.baseTimeBetween = 5
  self.adjustedTimeBetween = Helper.Unit:apply_cooldown_reduction(self, self.baseTimeBetween)
  self.healAmount = self.data.healAmount or 10
end

function Proc_Heal:onRoundStart()
  Proc_Heal.super.onRoundStart(self)
  if not self.unit then return end
  self.manual_trigger = trigger:every(self.adjustedTimeBetween, function()
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
  self.baseTickInterval = self.buffDuration
  self.adjustedTickInterval = Helper.Unit:apply_cooldown_reduction(self, self.baseTickInterval)

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
  if self.tick_timer < self.adjustedTickInterval then return end
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
  self.baseTickInterval = 5
  self.adjustedTickInterval = Helper.Unit:apply_cooldown_reduction(self, self.baseTickInterval)

  self.heal_percent = self.data.heal_percent or 0.2
  --overwritten in proc
  self.healAmount = self.data.healAmount or 25
  self.radius = self.data.radius or 75
  self.color = self.data.color or green[0]
  self.max_chains = self.data.max_chains or 4

  --proc memory
  --random 0-1, not full range
  self.tick_timer = math.random()
end

function Proc_HealingWave:onTick(dt, from)
  Proc_HealingWave.super.onTick(self, dt)

  if not self.team then
    print('error: no team for proc', self.name)
    return
  end

  --only tick once per team per tick
  if not self.team:is_first_alive_troop(from) then return end

  --only cast once per tick_interval (to prevent casting at first instance of damage in round)
  self.tick_timer = self.tick_timer + dt
  if self.tick_timer < self.adjustedTickInterval then return end
  self.tick_timer = 0

  local hurtTroop = self.team:get_random_hurt_troop()
  if not hurtTroop then return end

  self.healAmount = hurtTroop.max_hp * self.heal_percent
  self:cast(hurtTroop)

end

function Proc_HealingWave:cast(from)

  self.tick_timer = 0

  ChainHeal{
    group = main.current.main,
    is_troop = from.is_troop,
    parent = from,
    target = from,
    heal_amount = self.healAmount,
    max_chains = self.max_chains,
    range = self.radius,
    color = self.color,

  }

end



Proc_Curse = Proc:extend()
function Proc_Curse:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_Curse.super.init(self, args)
  
  --define the proc's vars
  self.seek_radius = 100
  self.baseTickInterval = 5
  self.adjustedTickInterval = Helper.Unit:apply_cooldown_reduction(self, self.baseTickInterval)
  self.radius = self.data.radius or 50
  self.color = self.data.color or purple[-3]

  --proc memory
  self.tick_timer = math.random() * self.baseTickInterval
  self.proc_timer = 0
  self.proc_delay = 1 -- Delay before first proc to avoid triggering on first enemy in wave
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
  if self.tick_timer < self.adjustedTickInterval then return end

  local enemy = Helper.Spell:get_random_target_in_range_from_point(from.x, from.y, self.seek_radius, from.is_troop)
  if not enemy or enemy == -1 then return end

  -- Apply proc delay to avoid triggering on first enemy in wave
  self.proc_timer = self.proc_timer + dt
  if self.proc_timer < self.proc_delay then return end

  self:curse(enemy, from)
end

function Proc_Curse:curse(target, from)
  earth1:play{pitch = random:float(0.8, 1.2), volume = 0.9}
  
  self.tick_timer = 0
  self.proc_timer = 0

  -- Use Area_Spell to find targets, then curse each one
  Area_Spell{
    group = main.current.effects,
    x = target.x, y = target.y,
    radius = self.radius,
    pick_shape = 'circle',
    duration = 0.6,
    color = purple[-3],
    is_troop = from.is_troop,
    damage = 0, -- No damage, just visual
    unit = from, -- Pass the caster unit for stat scaling
    on_hit_callback = function(spell, hit_target, unit)
      hit_target:start_curse(from)
    end
  }
end

Proc_CurseHeal = Proc:extend()
function Proc_CurseHeal:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'team'

  Proc_CurseHeal.super.init(self, args)
end

Proc_CurseDamageLink = Proc:extend()
function Proc_CurseDamageLink:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'team'

  Proc_CurseDamageLink.super.init(self, args)
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

  self.baseTickInterval = 5
  self.adjustedTickInterval = Helper.Unit:apply_cooldown_reduction(self, self.baseTickInterval)
  --proc memory
  self.tick_timer = math.random() * self.baseTickInterval
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
  if self.tick_timer < self.adjustedTickInterval then return end

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
    damage = 0, r = self.radius, duration = 0.2, color = self.color,
    is_troop = from.is_troop,
    rootDuration = self.rootDuration,
    unit = from,
  }
end

Proc_Retaliate = Proc:extend()
function Proc_Retaliate:init(args)
  self.triggers = {PROC_ON_GOT_HIT, PROC_ON_TICK}
  self.scope = 'troop'

  Proc_Retaliate.super.init(self, args)
  
  --define the proc's vars
  self.baseCooldown = self.data.cooldown or 2
  self.cooldown = 0

  --proc memory
end

function Proc_Retaliate:onTick(dt, from)
  Proc_Retaliate.super.onTick(self, dt)
  if self.cooldown < 0 then return end
  self.cooldown = self.cooldown - dt
end

function Proc_Retaliate:onGotHit(from, damage)
  Proc_Retaliate.super.onGotHit(self, from, damage)
  if not self.unit then return end
  if self.cooldown > 0 then return end

  self.cooldown = self.baseCooldown
  if self.unit.instant_attack then
    self.unit:instant_attack(from)
  else
    print('no instant attack', self.unit.character)
  end

  --try retaliatenearby
  if Has_Static_Proc(self.unit, 'retaliateNearby') then
    self:retaliateNearby(from)
  end
end

function Proc_Retaliate:retaliateNearby(from)
  local nearbyProc = Get_Static_Proc(self.unit, 'retaliateNearby')
  if not nearbyProc then return end
  if not self.unit then return end
  if not self.unit.instant_attack then
    print('no instant attack', self.unit.character)
    return
  end

  local max_targets = nearbyProc.max_targets
  local radius = nearbyProc.radius

  local attack_sensor = Circle(self.unit.x, self.unit.y, radius)
  local enemies = self.unit:get_objects_in_shape(attack_sensor, enemy_classes)
  if not enemies or #enemies == 0 then return end

  if #enemies > max_targets then
    enemies = table.slice(enemies, 1, max_targets)
  end

  for i, enemy in ipairs(enemies) do
    self.unit:instant_attack(enemy)
  end
end

Proc_RetaliateNearby = Proc:extend()
function Proc_RetaliateNearby:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'troop'

  Proc_RetaliateNearby.super.init(self, args)

  self.max_targets = 5
  self.radius = 100
end

Proc_ElementalRetaliate = Proc:extend()
function Proc_ElementalRetaliate:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'troop'

  Proc_ElementalRetaliate.super.init(self, args)
end


Proc_Battlefury = Proc:extend()
function Proc_Battlefury:init(args)
  self.triggers = {PROC_ON_ATTACK}
  self.scope = 'troop'

  Proc_Battlefury.super.init(self, args)

  --define the proc's vars
  self.radius = self.data.radius or 30
  self.color = self.data.color or brown[0]
  self.duration = self.data.duration or 0.15
  
end

function Proc_Battlefury:onAttack(target, unit)
  Proc_Battlefury.super.onAttack(self, target, unit)
  if not target then return end
  if not unit then return end
  
  Area_Spell{
    group = main.current.effects,
    x = unit.x, y = unit.y,
    pick_shape = 'circle',
    radius = self.radius,
    duration = self.duration,
    damage = unit.dmg or 10,
    color = self.color,
    is_troop = unit.is_troop,
    unit = unit,
  }
end

Proc_Splash = Proc:extend()
function Proc_Splash:init(args)
  self.triggers = {PROC_ON_PRIMARY_HIT}
  self.scope = 'troop'

  self.radius = args.radius or 15
  self.color = args.color or brown[0]
  self.duration = args.duration or 0.15

  self.damageMulti = args.damageMulti or 0.4

  Proc_Splash.super.init(self, args)
end

function Proc_Splash:onPrimaryHit(target, damage, damageType)
  Proc_Splash.super.onPrimaryHit(self, target, damage, damageType)
  if not target then return end
  if not self.unit then return end

  local radiusMulti = 1
  if Has_Static_Proc(self.unit, 'splashSizeBoost') then
    local proc = Get_Static_Proc(self.unit, 'splashSizeBoost')
    radiusMulti = radiusMulti * proc.radiusMulti
  elseif Has_Static_Proc(self.unit, 'splashSizeBoost2') then
    local proc = Get_Static_Proc(self.unit, 'splashSizeBoost2')
    radiusMulti = radiusMulti * proc.radiusMulti
  end
  
  Area_Spell{
    group = main.current.effects,
    x = target.x, y = target.y,
    pick_shape = 'circle',
    radius = self.radius * radiusMulti,
    duration = self.duration,
    damage = damage * self.damageMulti,
    color = self.color,
    is_troop = self.unit.is_troop,
    unit = self.unit,
    targets_to_exclude = {[target.id] = true}
  }
end

Proc_SplashSizeBoost = Proc:extend()
function Proc_SplashSizeBoost:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'troop'

  Proc_SplashSizeBoost.super.init(self, args)

  self.radiusMulti = 1.5
end

Proc_SplashSizeBoost2 = Proc:extend()
function Proc_SplashSizeBoost2:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'troop'

  Proc_SplashSizeBoost2.super.init(self, args)

  self.radiusMulti = 1.5
end

--proc overkill
Proc_Overkill = Proc:extend()
function Proc_Overkill:init(args)
  self.triggers = {PROC_ON_KILL}
  self.scope = 'troop'

  Proc_Overkill.super.init(self, args)
  
  

  --define the proc's vars
  self.overkillMulti = self.data.overkillMulti or 2
  self.radius = self.data.radius or 30
  self.is_troop = (self.unit and self.unit.is_troop) or false
  self.color = self.data.color or black[0]
  self.color_transparent = Color(self.color.r, self.color.g, self.color.b, 0.15)
  self.duration = self.data.duration or 0.15
  self.knockback_force = self.data.knockback_force or LAUNCH_PUSH_FORCE_ENEMY
  self.knockback_duration = self.data.knockback_duration or KNOCKBACK_DURATION_ENEMY
end
function Proc_Overkill:onKill(target, overkill)
  Proc_Overkill.super.onKill(self, target, overkill)
  local damage = overkill * self.overkillMulti
  local radius = self.radius

  cannoneer2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  Area{
    group = main.current.effects, 
    x = target.x, y = target.y,
    pick_shape = 'circle',
    damage = damage, 
    r = radius, duration = self.duration, color = self.color_transparent,
    fill_whole_area = true,
    is_troop = self.is_troop,
    knockback_force = self.knockback_force,
    knockback_duration = self.knockback_duration,
    unit = self.unit,
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

Proc_BloodlustSpeedBoost = Proc:extend()
function Proc_BloodlustSpeedBoost:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'team'

  Proc_BloodlustSpeedBoost.super.init(self, args)
end


Proc_Shieldslam = Proc:extend()
function Proc_Shieldslam:init(args)
  self.triggers = {PROC_ON_PRIMARY_HIT}
  self.scope = 'troop'

  Proc_Shieldslam.super.init(self, args)
  
  --define the proc's vars
  self.knockback_force = LAUNCH_PUSH_FORCE_ENEMY
  self.knockback_duration = KNOCKBACK_DURATION_ENEMY
end

function Proc_Shieldslam:onPrimaryHit(target, damage, damageType)
  Proc_Shieldslam.super.onPrimaryHit(self, target, damage, damageType)
  if not target then return end
  if not self.unit then return end
  
  local r = self.unit:angle_to_object(target)
  -- Apply damage impulse
  target:push(self.knockback_force, r, false, self.knockback_duration)
end

Proc_Rebuke = Proc:extend()
function Proc_Rebuke:init(args)
  self.triggers = {PROC_ON_GOT_HIT}
  self.scope = 'troop'

  Proc_Rebuke.super.init(self, args)
end

function Proc_Rebuke:onGotHit(target, damage)
  Proc_Rebuke.super.onGotHit(self, target, damage)
  if not target then return end
  if not unit then return end
  --pass for now, add knockback area here
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
  self.triggers = {PROC_ON_KILL}
  self.scope = 'troop'

  Proc_Firebomb.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.radius = self.data.radius or 30
  self.color = self.data.color or red[0]

  self.chance_to_proc = self.data.chance_to_proc or 0.2

  self.is_troop = true
end

function Proc_Firebomb:onKill(target)
  Proc_Firebomb.super.onKill(self, target)
  
  
  if not self.unit then return end
  
  if not target or not target:has_buff('burn') then return end

  if math.random() < self.chance_to_proc then
    self:explode(target)
  end
end

function Proc_Firebomb:explode(target)
  explosion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  Area{
    group = main.current.effects,
    x = target.x, y = target.y,
    pick_shape = 'circle',
    damage = self.damage, r = self.radius, duration = 0.2, color = self.color,
    is_troop = self.is_troop
  }

  self.globalUnit = nil
end

Proc_WaterElemental = Proc:extend()
function Proc_WaterElemental:init(args)
  self.triggers = {PROC_ON_KILL}
  self.scope = 'troop'

  Proc_WaterElemental.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.radius = self.data.radius or 30
  self.color = self.data.color or blue[0]

  self.chance_to_proc = self.data.chance_to_proc or 0.3

  self.is_troop = true

  --proc memory
  self.maxSummons = self.data.maxSummons or 3
  self.summoned = 0
  self.summons = {}

end

function Proc_WaterElemental:onKill(target)
  Proc_WaterElemental.super.onKill(self, target)
  
  print('water elemental proc', self.target, self.unit)
  if not self.unit then return end

  if not target or not target:has_buff('chill') then return end

  self:checkSummons()

  print('summoning water elemental', self.chance_to_proc, self.summoned, self.maxSummons)
  if math.random() < self.chance_to_proc and self.summoned < self.maxSummons then
    self:summon(target)
  end

  self.globalUnit = nil
end

function Proc_WaterElemental:summon(target)
  local myLocation = {x = target.x, y = target.y}
  local location = Get_Spawn_Point(6, myLocation)
  if not location then return end
  local summon = Critter{group = main.current.main,
    dmg_type = DAMAGE_TYPE_COLD,
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
  if not self.summons then return end
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
  self.triggers = {PROC_ON_KILL}
  self.scope = 'troop'

  Proc_Shockwave.super.init(self, args)
  
  

  --define the proc's vars
  self.damage = self.data.damage or 20
  self.radius = self.data.radius or 30
  self.color = self.data.color or yellow[0]

  self.chance_to_proc = self.data.chance_to_proc or 0.2

  self.is_troop = true
end

function Proc_Shockwave:onKill(target)
  Proc_Shockwave.super.onKill(self, target)
  
  if not self.unit then return end

  if not target or not target:has_buff('shock') then return end

  if math.random() < self.chance_to_proc then
    self:shockwave(target)
  end
end

function Proc_Shockwave:shockwave(target)
  explosion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  Area{
    group = main.current.effects,
    x = target.x, y = target.y,
    pick_shape = 'circle',
    damage = self.damage, r = self.radius, duration = 0.2, color = self.color,
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
  self.triggers = {PROC_ON_DEATH}
  self.scope = 'troop'

  Proc_Radiance.super.init(self, args)
  
  

  --define the proc's vars
  self.color = self.data.color or red[0]
  self.radius = self.data.radius or 60
  self.damage = self.data.damage or 8
  self.damageType = DAMAGE_TYPE_FIRE

  if self.unit then
    self.damage_aura = self:create_damage_aura()
  end
end

function Proc_Radiance:onDeath(unit)
  Proc_Radiance.super.onDeath(self, unit)
  self:delete_aura()
  self:die()
end

function Proc_Radiance:create_damage_aura()

  local on_hit_callback = function(area_spell, target, unit)
    if not target:has_buff('radianceburn') then
      target:add_buff({name = 'radianceburn', damage = self.damage, duration = 1})
      target:hit(self.damage, unit, self.damageType, false, true)
    end
  end
  local aura = Area_Spell{
    group = main.current.effects,
    unit = self.unit,
    follow_unit = true,
    x = self.unit.x, y = self.unit.y,
    pick_shape = 'circle',
    damage = 0,
    damage_ticks = true,
    hit_only_once = false,
    r = self.radius, 
    duration = 1000, 
    color = self.color,
    opacity = 0.08,
    line_width = 0,
    tick_rate = 0.5,
    is_troop = self.unit.is_troop,
    on_hit_callback = on_hit_callback,
  }
  return aura
end

function Proc_Radiance:delete_aura()
  if self.damage_aura then
    self.damage_aura:die()
    self.damage_aura = nil
  end
end

function Proc_Radiance:die()
  Proc_Radiance.super.die(self)
  self:delete_aura()
end

--can only have 1 shield at a time, no stack for now
--any new shield will overwrite the old one
Proc_Shield = Proc:extend()
function Proc_Shield:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'troop'

  Proc_Shield.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'shield'
  self.shield_amount = self.data.shield_amount or 25
  self.baseTimeBetween = 5
  self.adjustedTimeBetween = Helper.Unit:apply_cooldown_reduction(self, self.baseTimeBetween)
  self.buff_duration = self.data.buff_duration or 4

  --proc memory
  self.shield_timer = math.random() * (self.adjustedTimeBetween / 2)

end

function Proc_Shield:onTick(dt)
  Proc_Shield.super.onTick(self, dt)
  if not self.unit then return end
  self.shield_timer = self.shield_timer + dt

  if self.shield_timer < self.adjustedTimeBetween then return end

  heal1:play{pitch = random:float(0.8, 1.2), volume = 0.15}
  self.unit:shield(self.shield_amount, self.buff_duration)
  self.shield_timer = 0
end

Proc_ShieldExplode = Proc:extend()
function Proc_ShieldExplode:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'troop'

  Proc_ShieldExplode.super.init(self, args)
end

Proc_LightningBall = Proc:extend()
function Proc_LightningBall:init(args)
  self.triggers = {PROC_ON_PRIMARY_HIT}
  self.scope = 'troop'

  Proc_LightningBall.super.init(self, args)

  --define the proc's vars
  self.chance_to_proc = self.data.chance_to_proc or 0.2
  self.damage = self.data.damage or 10
  self.color = self.data.color or yellow[0]
end

function Proc_LightningBall:onPrimaryHit(target, damage, damageType)
  Proc_LightningBall.super.onPrimaryHit(self, target, damage, damageType)

  if not self.unit then return end

  if not target then return end

  if math.random() < self.chance_to_proc then
    self:create_lightning_ball(target)
  end
  
end

function Proc_LightningBall:create_lightning_ball(target)
  if not self.unit then return end

  local spawn_distance_factor = 0.35

  -- Calculate the spawn location as a weighted average
  local spawn_location = {
      x = self.unit.x + (target.x - self.unit.x) * spawn_distance_factor,
      y = self.unit.y + (target.y - self.unit.y) * spawn_distance_factor
  }
  
  -- The rest of the code remains the same
  local travel_direction = {x = target.x - spawn_location.x, y = target.y - spawn_location.y}
  local travel_direction_length = math.sqrt(travel_direction.x^2 + travel_direction.y^2)
  local travel_direction_normalized = {x = travel_direction.x / travel_direction_length, y = travel_direction.y / travel_direction_length}
  local travel_direction_angle = math.atan2(travel_direction_normalized.y, travel_direction_normalized.x)

  new_spark:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  LightningBall{
    group = main.current.main,
    x = spawn_location.x, y = spawn_location.y,
    r = travel_direction_angle,
    is_troop = self.unit.is_troop,
    duration = 4,
    damage = self.damage,
    num_targets = 3,
    tick_rate = 1,
  }
end

Proc_Shock = Proc:extend()
function Proc_Shock:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'global'

  Proc_Shock.super.init(self, args)
  
end

Proc_BurnExplode = Proc:extend()
function Proc_BurnExplode:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'global'

  Proc_BurnExplode.super.init(self, args)

  --define the proc's vars
  self.radius = self.data.radius or 35
  self.color = self.data.color or red[0]
end


Proc_Volcano = Proc:extend()
function Proc_Volcano:init(args)
  self.triggers = {PROC_ON_DEATH}
  self.scope = 'global'

  Proc_Volcano.super.init(self, args)
  

  --define the proc's vars
  self.duration = self.data.duration or 3
  self.color = self.data.color or red[0]
  self.damage = self.data.damage or 10
  self.tick_rate = self.data.tick_rate or 1
  self.radius = self.data.radius or 35

  --define the procs memory
end

function Proc_Volcano:onDeath()
  Proc_Volcano.super.onDeath(self)

  if not self.globalUnit then return end
  
  if self.globalUnit:has_buff('burn') then
    self:create_lava_pool(self.globalUnit)
  end
end

function Proc_Volcano:create_lava_pool(target)
      --remove level from spell
      Area{
        group = main.current.floor,
        x= target.x, y = target.y,
        pick_shape = 'circle',
        damage_ticks = true,
        tick_rate = self.tick_rate,
        tick_immediately = true,
        damage = self.damage,
        r = self.radius, duration = self.duration, color = self.color,
        is_troop = true,
      }
end

Proc_Meteor = Proc:extend()
function Proc_Meteor:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_Meteor.super.init(self, args)

  --define the proc's vars
  self.attack_radius = self.data.attack_radius or 150
  self.target_offset = self.data.target_offset or 8
  self.radius = self.data.radius or 18
  self.color = self.data.color or red[0]
  self.damage = self.data.damage or 30

  self.charge_time = self.data.charge_time or 0.25

  self.attack_sensor = Circle(0, 0, self.attack_radius)

  self.baseTickInterval = 5
  self.adjustedTickInterval = Helper.Unit:apply_cooldown_reduction(self, self.baseTickInterval)

  --proc memory
  self.tick_timer = math.random() * (self.adjustedTickInterval / 2)
end

function Proc_Meteor:onTick(dt, from)
  Proc_Meteor.super.onTick(self, dt)

  if not self.team then
    print('error: no team for proc', self.name)
    return
  end

  --only tick once per tick
  if not self.team:is_first_alive_troop(from) then return end

  self.tick_timer = self.tick_timer + dt
  if self.tick_timer < self.adjustedTickInterval then return end

  self.attack_sensor.x = from.x
  self.attack_sensor.y = from.y
  self:summon_meteor(from)
  self.tick_timer = 0
end

function Proc_Meteor:summon_meteor(from)
  --have to differentiate from enemy mortars somehow
  local target = from:get_random_target(self.attack_sensor, enemy_classes)
  if not target then return end

  local radius = self.radius

  if Has_Static_Proc(from, 'meteorSizeBoost') then
    radius = radius * 1.4
  end

  local damage = self.damage
  if Has_Static_Proc(from, 'meteorDamageBoost') then
    damage = damage * 2
  end

  Stomp{
    group = main.current.main,
    chargeTime = self.charge_time,
    knockback = true,
    target = target,
    target_offset = self.target_offset,
    team = 'troop',
    damage = damage,
    rs = radius,
    color = self.color,
    unit = from,
  }
end

Proc_MeteorSizeBoost = Proc:extend()
function Proc_MeteorSizeBoost:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'team' 

  Proc_MeteorSizeBoost.super.init(self, args)
end

Proc_MeteorDamageBoost = Proc:extend()
function Proc_MeteorDamageBoost:init(args)
  self.triggers = {PROC_STATIC}
  self.scope = 'team'
  
  Proc_MeteorDamageBoost.super.init(self, args)
end


Proc_Lavaman = Proc:extend()
function Proc_Lavaman:init(args)
  self.triggers = {PROC_ON_TICK}
  self.scope = 'team'

  Proc_Lavaman.super.init(self, args)
  
  

  --define the proc's vars
  self.buffname = 'lavaman'
  self.baseTickInterval = 5
  self.adjustedTickInterval = Helper.Unit:apply_cooldown_reduction(self, self.baseTickInterval)
  self.color = self.data.color or red[0]

  --proc memory
  -- randomize timer between 1/2 and 3/4 of the interval
  self.tick_timer = self.baseTickInterval - (self.baseTickInterval / 4 ) - ((math.random() / 4) * self.baseTickInterval)
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
  if self.tick_timer < self.adjustedTickInterval then return end

  self:try_spawn(from)
end

function Proc_Lavaman:try_spawn(from)

  -- find a random free spot in the team
  self:find_free_spot(from)
  
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
  critter2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  self.tick_timer = 0
  Critter{group = main.current.main,
    dmg_type = DAMAGE_TYPE_FIRE,
    x = coords.x, y = coords.y, color = self.color, r = random:float(0, 2*math.pi)
  }
end


-- --should be global instead of per troop?
-- Proc_FireExplode = Proc:extend()
-- function Proc_FireExplode:init(args)
--   self.triggers = {PROC_ON_HIT}
--   self.scope = 'troop'

--   Proc_FireExplode.super.init(self, args)


--   if not self.unit then return end

--   --define the proc's vars
--   self.radius = self.data.radius or 25
--   self.color = self.data.color or red[0]
--   self.dmgMulti = self.data.dmgMulti or 0.2
--   self.sizeMulti = self.data.sizeMulti or 2

--   self.proc_chance = self.data.proc_chance or 0.2

--   self.is_troop = (self.unit and self.unit.is_troop) or false

-- end

-- function Proc_FireExplode:onHit(target, damage)
--   Proc_FireExplode.super.onHit(self, target, damage)
--   if math.random() < self.proc_chance then
--     self:explode(target)
--   end
-- end

-- function Proc_FireExplode:explode(target)
--   local damage = (target.max_hp * self.dmgMulti)
--   local radius = target.shape.w * self.sizeMulti

--   target:remove_buff('burn')

--   cannoneer1:play{pitch = random:float(0.8, 1.2), volume = 1.2}
--   Area{
--     group = main.current.effects, 
--     x = target.x, y = target.y,
--     pick_shape = 'circle',
--     dmg = damage,
--     r = radius, duration = 0.2, color = self.color,
--     is_troop = self.is_troop,
--   }
-- end

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
Proc_Phoenix = Proc:extend()
function Proc_Phoenix:init(args)
  self.triggers = {PROC_ON_DEATH}
  self.scope = 'troop'

  Proc_Phoenix.super.init(self, args)
  
  self.color = self.data.color or white[0]
  self.invulnerable_duration = self.data.invulnerable_duration or 2.5
  
  --define the proc's vars
  self.team_index = nil
  self.death_location_x = nil
  self.death_location_y = nil
  
  self.has_been_revived = false
end

function Proc_Phoenix:onDeath()
  Proc_Phoenix.super.onDeath(self)
  
  if self.has_been_revived then return end

  self.team_index = self.unit.team
  self.has_been_revived = true
  self.death_location_x = self.unit.x
  self.death_location_y = self.unit.y

  local team = Helper.Unit:get_team_by_index(self.team_index)


  trigger:after(1, function()
    if team then
      local location = team:get_center()
      Helper.Unit:resurrect_troop(team, self.unit, location, self.invulnerable_duration, self.color)
    end
  end)
  
end

Proc_Frostfield = Proc:extend()
function Proc_Frostfield:init(args)
  self.triggers = {PROC_ON_FREEZE}
  self.scope = 'global'

  Proc_Frostfield.super.init(self, args)

  --define the proc's vars
  self.duration = self.data.duration or 3
  self.tick_rate = self.data.tick_rate or 0.5
  self.color = self.data.color or blue[0]

  self.radius = self.data.radius or 35

  self.every_attacks = self.data.every_attacks or 4

  --define the procs memory
  self.has_attacked = false
  self.attacks_left = math.random(1, self.every_attacks)
end

function Proc_Frostfield:onFreeze(unit, target)
  Proc_Frostfield.super.onFreeze(self, target)
  Area{
    group = main.current.floor,
    unit = unit,
    x= target.x, y = target.y,
    pick_shape = 'circle',
    damage_ticks = true,
    tick_rate = self.tick_rate,
    damage = 5,
    r = self.radius, duration = self.duration, color = self.color,
    is_troop = not target.is_troop,
    damage_type = DAMAGE_TYPE_COLD,
  }
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

Proc_Frostnova = Proc:extend()
function Proc_Frostnova:init(args)
    self.triggers = {PROC_ON_TICK}
    self.scope = 'troop'
    Proc_Frostnova.super.init(self, args)

    -- Define the proc's properties from data
    self.damage = (self.data.damage or 10) * (self.data.damageMulti or 1)
    self.damageType = self.data.damageType or DAMAGE_TYPE_COLD
    self.radius_boost = self.data.radius_boost or 3
    self.radius = self.data.radius or 45
    self.duration = self.data.duration or 0.2
    self.chillAmount = self.data.chillAmount or 0.5
    self.chillDuration = self.data.chillDuration or 3
    self.color = self.data.color or blue[0]

    -- Cooldown and wind-up values
    self.baseCooldown = 5
    self.adjustedCooldown = Helper.Unit:apply_cooldown_reduction(self, self.baseCooldown)
    self.cancel_cooldown = self.data.cancel_cooldown or 0.3
    self.procDelay = self.data.procDelay or 0.75 -- This is the wind-up duration

    -- State machine setup
    self.state = 'ready'       -- Possible states: 'ready', 'winding_up', 'on_cooldown'
    self.windup_timer = 0
    self.cooldown_timer = 0
    
    -- This will hold the visual effect object
    self.proc_display_area = nil 
    self.attack_sensor = Circle(0, 0, self.radius)
end

-- ===================================================================
-- ON TICK: The State Machine
-- This is the heart of the proc, handling all logic every frame.
-- ===================================================================
function Proc_Frostnova:onTick(dt)
    Proc_Frostnova.super.onTick(self, dt)
    if not self.unit or self.unit.dead then return end

    self.attack_sensor:move_to(self.unit.x, self.unit.y)

    -- STATE: ON COOLDOWN
    if self.state == 'on_cooldown' then
        self.cooldown_timer = self.cooldown_timer - dt
        if self.cooldown_timer <= 0 then
            self.state = 'ready'
        end

    -- STATE: READY
    elseif self.state == 'ready' then
        if #main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies, nil) > 0 then
            -- Enemy found! Transition to the winding_up state.
            self.state = 'winding_up'
            self.windup_timer = self.procDelay
            alert1:play{pitch = random:float(0.8, 1.2), volume = 0.6}
            
            -- Create a new visual effect for this wind-up.
            self:create_proc_display_area()
        end

    -- STATE: WINDING UP
    elseif self.state == 'winding_up' then
        -- 1. Check for cancellation (no enemies left in range)
        if #main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies, nil) == 0 then
            self.state = 'on_cooldown'
            self.cooldown_timer = self.cancel_cooldown
            self:destroy_proc_display_area() -- Destroy the visual effect
            return
        end

        -- 2. If not cancelled, update the wind-up timer and visual.
        self.windup_timer = self.windup_timer - dt
        self:update_proc_display()

        -- 3. Check for successful cast.
        if self.windup_timer <= 0 then
            self:cast()
            self.state = 'on_cooldown'
            self.cooldown_timer = self.adjustedCooldown
            self:destroy_proc_display_area() -- Destroy the visual effect
        end
    end
end

-- ===================================================================
-- VISUAL EFFECT HELPERS
-- ===================================================================

function Proc_Frostnova:create_proc_display_area()
    -- If an old one somehow exists, destroy it first.
    self:destroy_proc_display_area()

    self.proc_display_area = Area{
        group = main.current.effects,
        x = self.unit.x, y = self.unit.y,
        pick_shape = 'circle',
        r = 0, -- Start with a radius of 0
        duration = self.procDelay, -- Give it a lifetime just longer than the wind-up
        color = self.color,
        damage = 0,
    }
end

function Proc_Frostnova:update_proc_display()
    if self.proc_display_area and not self.proc_display_area.dead then
        local progress = 1 - (self.windup_timer / self.procDelay) -- Progress from 0 to 1
        progress = math.max(0, math.min(1, progress)) -- Clamp progress to prevent errors
        
        self.proc_display_area.r = (self.radius + self.radius_boost) * progress
        self.proc_display_area.x = self.unit.x
        self.proc_display_area.y = self.unit.y
    end
end

function Proc_Frostnova:destroy_proc_display_area()
    if self.proc_display_area then
        self.proc_display_area.dead = true
        self.proc_display_area = nil
    end
end

-- ===================================================================
-- CAST ACTION
-- ===================================================================

function Proc_Frostnova:cast()
    self:destroy_proc_display_area()
    glass_shatter:play{pitch = random:float(0.8, 1.2), volume = 0.8}

    Area{
        group = main.current.effects,
        unit = self.unit,
        x = self.unit.x, y = self.unit.y,
        pick_shape = 'circle',
        damage = self.damage,
        damage_type = self.damageType,
        r = self.radius + self.radius_boost, 
        duration = self.duration, 
        color = self.color,
        is_troop = self.unit.is_troop,
    }
end

Proc_Firenova = Proc:extend()
function Proc_Firenova:init(args)
  self.triggers = {PROC_ON_ATTACK, PROC_ON_HIT}
  self.scope = 'troop'

  Proc_Firenova.super.init(self, args)

  self.damage = self.data.damage or 10
  self.damageType = DAMAGE_TYPE_FIRE
  self.radius = self.data.radius or 30
  self.knockback_force = self.data.knockback_force or LAUNCH_PUSH_FORCE_ENEMY
  self.knockback_duration = self.data.knockback_duration or 1

  self.color = self.data.color or red[0]
  self.proc_chance = self.data.proc_chance or 0.2

end

function Proc_Firenova:onAttack(target)
  Proc_Firenova.super.onAttack(self, target)
  if target and target:has_buff('burn') and math.random() < self.proc_chance then
    self:explode(target, self.damage)
  end
end

function Proc_Firenova:explode(target, damage)
  fire1:play{pitch = random:float(0.8, 1.2), volume = 0.8}
  Area{
    group = main.current.effects,
    unit = self.unit,
    x = target.x, y = target.y,
    pick_shape = 'circle',
    damage = self.damage,
    r = self.radius, duration = self.duration, color = self.color,
    is_troop = self.unit.is_troop,
    knockback_force = self.knockback_force,
    knockback_duration = self.knockback_duration
  }
end

Proc_Glaciate = Proc:extend()
function Proc_Glaciate:init(args)
  self.triggers = {PROC_ON_ATTACK, PROC_ON_TICK}
  self.scope = 'troop'

  Proc_Glaciate.super.init(self, args)

  self.damage = self.data.damage or 10
  self.damageType = DAMAGE_TYPE_COLD
  self.duration = self.data.duration or 1
  self.color = self.data.color or blue[0]

  --define the procs memory
  self.baseHitCooldown = 2
  self.adjustedHitCooldown = Helper.Unit:apply_cooldown_reduction(self, self.baseHitCooldown)
  self.hit_cooldown_timer = 0
end

function Proc_Glaciate:onTick(dt)
  Proc_Glaciate.super.onTick(self, dt)
  if self.hit_cooldown_timer > 0 then
    self.hit_cooldown_timer = self.hit_cooldown_timer - dt
  end
end

function Proc_Glaciate:onAttack(target)
  Proc_Glaciate.super.onAttack(self, target)
  if self.hit_cooldown_timer <= 0 then
    if target:has_buff('slowed') and not target:has_buff('frozen') then
      self.hit_cooldown_timer = self.adjustedHitCooldown
      target:freeze(self.duration, self.unit)
    end
  end
end

Proc_Shatterlance = Proc:extend()
function Proc_Shatterlance:init(args)
  self.triggers = {PROC_ON_PRIMARY_HIT}
  self.scope = 'troop'
  
  Proc_Shatterlance.super.init(self, args)

  self.damageType = DAMAGE_TYPE_COLD
  self.fallback_damage = self.data.fallback_damage or 20
  self.radius = self.data.radius or 35
  self.color = self.data.color or blue[0]
end

function Proc_Shatterlance:onPrimaryHit(target, damage, damageType)
  Proc_Shatterlance.super.onPrimaryHit(self, target, damage, damageType)
  if target:has_buff('freeze') then
    self:explode(target, damage)
  end
end

function Proc_Shatterlance:explode(target, damage)
  print('explode', target, damage)
  Area{
    group = main.current.effects,
    x = target.x, y = target.y,
    pick_shape = 'circle',
    damage = damage,
    r = self.radius, color = self.color,
    is_troop = self.unit.is_troop,
    damage_type = self.damageType,
    unit = self.unit,
  }
end

Proc_Glacialprison = Proc:extend()
function Proc_Glacialprison:init(args)
  self.triggers = {PROC_ON_KILL}
  self.scope = 'troop'

  Proc_Glacialprison.super.init(self, args)

  self.damage = self.data.damage or 10
  self.damageType = DAMAGE_TYPE_COLD
  self.radius = self.data.radius or 35
  self.chillAmount = self.data.chillAmount or 0.5
  self.duration = self.data.duration or 3
  self.chillDuration = self.data.chillDuration or 1.5
  self.color = self.data.color or blue[0]
  self.tick_rate = self.data.tick_rate or 0.1
end

function Proc_Glacialprison:onKill(target)
  Proc_Glacialprison.super.onKill(self, target)
  if target:has_buff('frozen') then
    
    glass_shatter:play{pitch = random:float(0.8, 1.2), volume = 0.5}

    Area{
      group = main.current.effects,
      x = target.x, y = target.y,
      unit = self.unit,
      pick_shape = 'circle',  
      damage = self.damage,
      r = self.radius, duration = self.duration, color = self.color,
      damage_ticks = true,
      tick_rate = self.tick_rate,
      is_troop = self.unit.is_troop,
      chillAmount = self.chillAmount,
      chillDuration = self.chillDuration,
      only_multi_hit_after_effect_ends = true,
    }
  end
end

Proc_Rimeheart = Proc:extend()
function Proc_Rimeheart:init(args)
  --todo
  Proc_Rimeheart.super.init(self, args)

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

Proc_Triforce = Proc:extend()
function Proc_Triforce:init(args)
  self.triggers = {}
  self.scope = 'troop'
  
  
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
  ['overkill'] = Proc_Overkill,
  ['bloodlust'] = Proc_Bloodlust,
  ['bloodlustSpeedBoost'] = Proc_BloodlustSpeedBoost,

  ['shieldslam'] = Proc_Shieldslam,
  ['rebuke'] = Proc_Rebuke,
  ['battlefury'] = Proc_Battlefury,

  ['splash'] = Proc_Splash,
  ['splashSizeBoost'] = Proc_SplashSizeBoost,
  ['splashSizeBoost2'] = Proc_SplashSizeBoost2,

  --yellow procs
  ['radiance'] = Proc_Radiance,
  ['shield'] = Proc_Shield,
  ['shieldexplode'] = Proc_ShieldExplode,
  ['lightningball'] = Proc_LightningBall,
  ['shock'] = Proc_Shock,
  --red procs
  ['burnexplode'] = Proc_BurnExplode,
  ['volcano'] = Proc_Volcano,
  ['meteor'] = Proc_Meteor,
  ['meteorSizeBoost'] = Proc_MeteorSizeBoost,
  ['meteorDamageBoost'] = Proc_MeteorDamageBoost,
  ['firenova'] = Proc_Firenova,
  ['lavaman'] = Proc_Lavaman,
  -- ['fireexplode'] = Proc_FireExplode,
  ['blazin'] = Proc_Blazin,
  ['phoenix'] = Proc_Phoenix,
  --blue procs
  ['frostfield'] = Proc_Frostfield,
  ['holduground'] = Proc_Holduground,
  ['frostnova'] = Proc_Frostnova,
  ['glaciate'] = Proc_Glaciate,
  ['shatterlance'] = Proc_Shatterlance,
  ['glacialprison'] = Proc_Glacialprison,
  ['rimeheart'] = Proc_Rimeheart,
  --green procs
  ['heal'] = Proc_Heal,
  ['sacrificialclam'] = Proc_SacrificialClam,
  ['healingwave'] = Proc_HealingWave,
  ['root'] = Proc_Root,

  ['retaliate'] = Proc_Retaliate,
  ['elementalRetaliate'] = Proc_ElementalRetaliate,
  ['retaliateNearby'] = Proc_RetaliateNearby,

  ['curse'] = Proc_Curse,
  ['curseHeal'] = Proc_CurseHeal,
  ['curseDamageLink'] = Proc_CurseDamageLink,

  --stack on attack
  ['overcharge'] = Proc_Overcharge,
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
  ['triforce'] = Proc_Triforce,
  ['eledmg'] = Proc_Eledmg,
  ['elevamp'] = Proc_Elevamp
}



--procs are objects that do things when certain conditions are met
--they live on items, and are added to units when the arena is entered
--they are checked in objects.lua
--they can have multiple triggers, that are called when the trigger is met
-- ex. 'on_hit', 'on_got_hit', 'on_attack', 'on_move', 'on_death'
-- and the triggers can interact with each other in the proc
-- procs should have timers as well, so they can only trigger every so often

--format of the proc:init is:
-- super call to enable debugging
-- define what triggers the proc has (so the unit can call them)
-- define the proc's vars (and bring stats in from data)
-- define the proc's timers

PROC_ON_TICK = 'onTickProcs'
PROC_ON_HIT = 'onHitProcs'
PROC_ON_GOT_HIT = 'onGotHitProcs'
PROC_ON_ATTACK = 'onAttackProcs'
PROC_ON_PRIMARY_HIT = 'onPrimaryHitProcs'
PROC_ON_MOVE = 'onMoveProcs'
PROC_ON_DEATH = 'onDeathProcs'
PROC_ON_KILL = 'onKillProcs'

PROC_ON_FREEZE = 'onFreezeProcs'
PROC_ON_BURN = 'onBurnProcs'
PROC_ON_SHOCK = 'onShockProcs'

PROC_ON_ROUND_START = 'onRoundStartProcs'
PROC_ON_SELL = 'onSellProcs'
PROC_STATIC = 'staticProcs'

--does not include onSell, as that doesn't go in the unit's callback lists
LIST_OF_PROC_TYPES = {
  PROC_ON_TICK,
  PROC_ON_HIT,
  PROC_ON_GOT_HIT,
  PROC_ON_ATTACK,
  PROC_ON_PRIMARY_HIT,
  PROC_ON_MOVE,
  PROC_ON_DEATH,
  PROC_ON_KILL,
  PROC_ON_FREEZE,
  PROC_ON_BURN,
  PROC_ON_SHOCK,
  PROC_ON_ROUND_START,
  PROC_STATIC,
}

--these need to have unit passed in, because they will be called on global procs
--or set self.globalUnit on the proc to avoid changing the signature?? sounds terrible :>(
CALL_PROC_MAP = {
  [PROC_ON_TICK] = function(proc, dt) return proc:onTick(dt) end,
  [PROC_ON_HIT] = function(proc, target, damage, damageType) return proc:onHit(target, damage, damageType) end,
  [PROC_ON_GOT_HIT] = function(proc, from, damage, damageType) return proc:onGotHit(from, damage, damageType) end,
  [PROC_ON_ATTACK] = function(proc, target) return proc:onAttack(target) end,
  [PROC_ON_PRIMARY_HIT] = function(proc, target, damage, damageType) return proc:onPrimaryHit(target, damage, damageType) end,
  [PROC_ON_MOVE] = function(proc, distance) return proc:onMove(distance) end,
  [PROC_ON_DEATH] = function(proc) return proc:onDeath() end,
  [PROC_ON_KILL] = function(proc, target) return proc:onKill(target) end,
  [PROC_ON_FREEZE] = function(proc, target) return proc:onFreeze(target) end,
  [PROC_ON_BURN] = function(proc, target) return proc:onBurn(target) end,
  [PROC_ON_SHOCK] = function(proc, target) return proc:onShock(target) end,
  [PROC_ON_ROUND_START] = function(proc) return proc:onRoundStart() end,
  [PROC_STATIC] = function(proc) end,
}

PROC_TYPE_TO_DISPLAY = {
  [PROC_ON_TICK] = {text = 'onTick', color = 'white'},
  [PROC_ON_HIT] = {text = 'onHit', color = 'red'},
  [PROC_ON_GOT_HIT] = {text = 'onGotHit', color = 'red'},
  [PROC_ON_ATTACK] = {text = 'onAttack', color = 'blue'},
  [PROC_ON_PRIMARY_HIT] = {text = 'onPrimaryHit', color = 'purple'},
  [PROC_ON_MOVE] = {text = 'onMove', color = 'green'},
  [PROC_ON_DEATH] = {text = 'onDeath', color = 'black'},
  [PROC_ON_KILL] = {text = 'onKill', color = 'black'},
  [PROC_ON_FREEZE] = {text = 'onFreeze', color = 'blue'},
  [PROC_ON_BURN] = {text = 'onBurn', color = 'red'},
  [PROC_ON_SHOCK] = {text = 'onShock', color = 'yellow'},
  [PROC_ON_ROUND_START] = {text = 'onStart', color = 'black'},
  [PROC_ON_SELL] = {text = 'onSell', color = 'black'},
  [PROC_STATIC] = {text = 'static', color = 'black'},

  [DAMAGE_TYPE_COLD] = {text = 'cold', color = 'blue'},
  [DAMAGE_TYPE_FIRE] = {text = 'fire', color = 'red'},
  [DAMAGE_TYPE_LIGHTNING] = {text = 'lightning', color = 'yellow'},
  [DAMAGE_TYPE_POISON] = {text = 'poison', color = 'green'},
  [DAMAGE_TYPE_PHYSICAL] = {text = 'physical', color = 'brown'},
}

--this is the list of procs that are global, and not tied to a unit
-- the var is global, but is initialized/reset in the arena
-- all units try to call the procs in this list when their "onXCallback" functions are called

GLOBAL_PROC_LIST = {}

Call_Global_Procs = function(triggerName, args)
  if not GLOBAL_PROC_LIST[triggerName] then
    return
  end

  for i, proc in ipairs(GLOBAL_PROC_LIST[triggerName]) do
    if not proc.dead then
      proc[triggerName](proc, args)
    end
  end
end

Reset_Global_Proc_List = function()
  for i, triggerName in ipairs(LIST_OF_PROC_TYPES) do
    if GLOBAL_PROC_LIST[triggerName] then
      Clear_All_Procs(GLOBAL_PROC_LIST[triggerName])
    end
    GLOBAL_PROC_LIST[triggerName] = {}
  end
end

Clear_All_Procs = function(procList)
  for i, proc in ipairs(procList) do
    proc:die()
  end
end

Does_Static_Proc_Exist = function(procName)
  for i, proc in ipairs(GLOBAL_PROC_LIST[PROC_STATIC]) do
    if proc.name == procName then
      return true
    end
  end
  return false
end

Has_Static_Proc = function(teamOrUnit, procName)
  if teamOrUnit.staticProcs then
    for i, proc in ipairs(teamOrUnit.staticProcs) do
      if proc.name == procName then
        return true
      end
    end
  end
  return false
end

--name is passed in from the item data
Proc = Object:extend()
function Proc:init(args)
  if not args or not args.data then
    print('error: proc needs and data to init')
  end

  self.unit = args.unit
  self.team = args.team
  self.data = args.data

  if DEBUG_PROCS then
    print('creating proc: ', self.unit, self.team, self.data)
  end

  self.name = self.data.name
  self:addTriggers()
end

function Proc:hasTrigger(trigger)
  for i, t in ipairs(self.triggers) do
    if t == trigger then
      return true
    end
  end
  return false
end

function Proc:addTriggers()
  if self.scope == 'team' and self.team then
    self:addTriggersToTeam()
  elseif self.scope == 'troop' and self.unit then
    self:addTriggersToTroop()
  elseif self.scope == 'global' then
    self:addTriggersToGlobal()
  else
    if DEBUG_PROCS then
      print('proc not on team or troop (in proc)', self.name)
    end
    self:die()
  end
end

--sets procs for all the units in the team
function Proc:addTriggersToTeam()
  local team = self.team
  table.insert(team.procs, self)
  for i, triggerName in ipairs(LIST_OF_PROC_TYPES) do
    if self:hasTrigger(triggerName) then
      self:addTriggerToAllTroops(triggerName)
    end
  end
end

function Proc:addTriggerToAllTroops(triggerName)
  for i, troop in ipairs(self.team.troops) do
    local list = troop[triggerName]
    table.insert(list, self)
  end
end

function Proc:addTriggersToTroop()
  local unit = self.unit
  table.insert(unit.procs, self)

  --add procs to the unit callback lists here
  -- still need to deal with proc deletion, right now they should be cleared at end of round (I hope??)
  for i, triggerName in ipairs(LIST_OF_PROC_TYPES) do
    if self:hasTrigger(triggerName) then
      local list = unit[triggerName]
      table.insert(list, self)
    end
  end
end

function Proc:addTriggersToGlobal()
  for i, triggerName in ipairs(LIST_OF_PROC_TYPES) do
    if self:hasTrigger(triggerName) then
      if not GLOBAL_PROC_LIST[triggerName] then
        GLOBAL_PROC_LIST[triggerName] = {}
      end
      table.insert(GLOBAL_PROC_LIST[triggerName], self)
    end
  end
end

function Proc:die()
  if DEBUG_PROCS then
    print('destroying proc: ', self.name)
  end
  self.dead = true
end

function Proc:onTick(dt)
  if DEBUG_PROCS then
    print('onTick ', self.unit, dt, self.name)
  end
end

function Proc:onAttack(target)
  if DEBUG_PROCS then
    print('onAttack ', self.unit, target, self.name)
  end
end

function Proc:onPrimaryHit(target, damage, damageType)
  if DEBUG_PROCS then
    print('onPrimaryHit', self.unit, target, damage, damageType, self.name)
  end
end

function Proc:onHit(target, damage, damageType)
  if DEBUG_PROCS then
    print('onHit', self.unit, target, damage, damageType, self.name)
  end
end

function Proc:onGotHit(from, damage, damageType)
  if DEBUG_PROCS then
    print('onGotHit', self.unit, from, damage, damageType, self.name)
  end
end

--this is called when the unit moves
--from engine internals
function Proc:onMove(distance)
  if DEBUG_PROCS then
    print('onMove', distance, self.name)
  end
end

--onDeath is called when the unit dies
--and comes from engine internals, so does not know who killed the unit
function Proc:onDeath(from)
  if DEBUG_PROCS then
    print('onDeath', from, self.name)
  end
end

function Proc:onFreeze(target)
  if DEBUG_PROCS then
    print('onFreeze', target, self.name)
  end
end

function Proc:onBurn(target)
  if DEBUG_PROCS then
    print('onBurn', target, self.name)
  end
end

function Proc:onShock(target)
  if DEBUG_PROCS then
    print('onShock', target, self.name)
  end
end

  --onKill is called in :hit(), when the unit drops to 0 hp
-- this means nothing should revive a unit that drops to 0 hp
function Proc:onKill(target)
  if DEBUG_PROCS then
    print('onKill', target, self.name)
  end
end

--onRoundStart is called at the start of the round
function Proc:onRoundStart()
  if DEBUG_PROCS then
    print('onRoundStart', self.name)
  end
end

--onSell is called when the item is sold
function Proc:onSell()
  if DEBUG_PROCS then
    print('onSell', self.name)
  end
end

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
PROC_ON_MOVE = 'onMoveProcs'
PROC_ON_DEATH = 'onDeathProcs'
PROC_ON_KILL = 'onKillProcs'

PROC_ON_ROUND_START = 'onRoundStartProcs'
PROC_ON_SELL = 'onSellProcs'

--does not include onSell, as that doesn't go in the unit's callback lists
LIST_OF_PROC_TYPES = {
  PROC_ON_TICK,
  PROC_ON_HIT,
  PROC_ON_GOT_HIT,
  PROC_ON_ATTACK,
  PROC_ON_MOVE,
  PROC_ON_DEATH,
  PROC_ON_KILL,
  PROC_ON_ROUND_START,
}


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
    --do global stuff
  else
    print('proc not on team or troop (in proc)', self.name)
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

function Proc:onHit(target, damage)
  if DEBUG_PROCS then
    print('onHit', self.unit, target, damage, self.name)
  end
end

function Proc:onGotHit(from, damage)
  if DEBUG_PROCS then
    print('onGotHit', self.unit, from, damage, self.name)
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
function Proc:onDeath()
  if DEBUG_PROCS then
    print('onDeath', self.name)
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

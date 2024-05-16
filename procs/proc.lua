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

PROC_ON_HIT = 'onHit'
PROC_ON_GOT_HIT = 'onGotHit'
PROC_ON_ATTACK = 'onAttack'
PROC_ON_MOVE = 'onMove'
PROC_ON_DEATH = 'onDeath'
PROC_ON_KILL = 'onKill'


--name is passed in from the item data
Proc = Object:extend()
function Proc:init(args)
  if not args or not args.unit or not args.data then
    print('error: proc needs unit and data to init')
  end

  self.unit = args.unit
  self.data = args.data

  if DEBUG_PROCS then
    print('creating proc: ', self.unit, self.data)
  end

  self.name = self.data.name
end

function Proc:hasTrigger(trigger)
  for i, t in ipairs(self.triggers) do
    if t == trigger then
      return true
    end
  end
  return false
end

function Proc:die()
  if DEBUG_PROCS then
    print('destroying proc: ', self.name)
  end
  self.dead = true
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

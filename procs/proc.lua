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

Proc = Object:extend()
function Proc:init(data)
  if DEBUG_PROCS then
    print('creating proc: ', data.name)
  end
  self.name = data.name
  --the unit that has this proc
  self.unit = data.unit
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

function Proc:onAttack(unit, target)
  if DEBUG_PROCS then
    print('onAttack ', unit, target, self.name)
  end
end

function Proc:onHit(unit, target)
  if DEBUG_PROCS then
    print('onHit', unit, target, self.name)
  end
end

function Proc:onGotHit(unit, from)
  if DEBUG_PROCS then
    print('onGotHit', unit, from, self.name)
  end
end

function Proc:onMove(unit, distance)
  if DEBUG_PROCS then
    print('onMove', unit, distance, self.name)
  end
end

function Proc:onDeath(unit)
  if DEBUG_PROCS then
    print('onDeath', unit, self.name)
  end
end

function Proc:onKill(unit, target)
  if DEBUG_PROCS then
    print('onKill', unit, target, self.name)
  end
end

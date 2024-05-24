Spell = Object:extend()
Spell:implement(GameObject)
function Spell:init(args)
  if not args or not args.unit then
    print('error: spell needs unit to init')
  end

  --load the args into the spell object
  self:init_game_object(args)

  --set some spell defaults, if they are not set in the data
  self.die_with_unit = self.die_with_unit or true
  self.startTime = Helper.Time.time

  if DEBUG_SPELLS then
    print('creating spell: ', self.unit, self.name)
  end

  self.name = self.name or 'spell'
  self.startTime = Helper.Time.time
end

function Spell:draw()
  if DEBUG_SPELLS then
    print('draw ', self.unit, self.name)
  end
end

function Spell:update(dt)
  if DEBUG_SPELLS then
    print('update ', self.unit, dt, self.name)
  end

  if self.unit and self.unit.dead and self.die_with_unit then
    self:die()
  end
end

--think about moving :die to GameObject (but then it still has to call the unit procs)
--when self.dead = true is set on a group object, then:
-- 1. calls onDeath() fn
-- 2. calls destroy() fn
-- 3. removes from group .objects_by_id table
-- 4. deletes from group .objects_by_class table
-- 5. removes from group .objects table
-- which stops the object from being drawn or updated
-- and hopefully it is then garbage collected

function Spell:die()
  if DEBUG_SPELLS then
    print('destroying spell: ', self.name)
  end
  self.dead = true
end
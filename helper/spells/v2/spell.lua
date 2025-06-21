
-- example usage:
--on enemy
-- self.attack_options = {}
-- local fire = {
--   name = 'fire',
--   viable = function() return Helper.Spell:there_is_target_in_range(self, 100) end,
--   cast_length = 0.5,
--   castcooldown = 0.5,
--   rotation_lock = false,
--   oncaststart = function() turret_hit_wall2:play{volume = 0.9} end,
--   spellclass = BreatheFire,
--   spelldata = {
--     color = Helper.Color.orange,
--     group = main.current.effects,
--     etc,
--   }
-- }

-- cast will be on unit's castObject variable, and the cast timer will be drawn on the unit
-- the cast will be cancelled if the unit dies or is stunned

-- and then when the cast:cast() is called, it will create a new instance of BreatheFire(spelldata)
-- and store it in the unit's .spellObject variable
-- the breathefire class will have its own duration and actions (rotating towards target, etc)
-- has a :die() when the spell finishes normally
-- that calls :finish_cast() to reset the unit's state and remove the spellObject

-- or the unit should be able to cancel the spellObject if it dies or is stunned

Try_Cancel_Cast = function(self)
  if self.cancel_on_death and (not self.unit or self.unit.dead) then
    self:cancel()
  end
  if self.cancel_on_range then
    if 
      not (self.unit and self.unit.target)
      or
      Get_Distance_To_Target(self.unit) > self.cancel_range
      then
      self:cancel()
    end
  end
  if self.cancel_no_target and 
    (not self.unit or not self.unit:my_target() or self.unit:my_target().dead == true) then
    self:cancel()
  end
end

Deep_Copy_Cast = function(castdata)
  local newcast = {}
  for k, v in pairs(castdata) do
    newcast[k] = v
  end
  newcast.spelldata = {}
  for k, v in pairs(castdata.spelldata) do
    newcast.spelldata[k] = v
  end
  return newcast

end

Cast = Object:extend()
Cast:implement(GameObject)
function Cast:init(args)
  args.group = args.group or main.current.main

  self:init_game_object(args)

  if self.cast_sound then
    self.cast_volume = self.cast_volume or 1
    self.cast_sound:play{volume = self.cast_volume}
  end

  --unit and target and x and y are set in objects.lua 
  self.unit = self.unit
  self.target = self.target
  self.x = self.x or self.unit.x
  self.y = self.y or self.unit.y

  self.name = self.name or 'cast'
  self.spellclass = self.spellclass
  self.spelldata = self.spelldata
  
  if not self:validate_data() then
    self:die()
    return
  end
  self.spelldata.unit = self.unit

  --vars from data
  self.rotation_lock = self.rotation_lock or false
  self.cast_length = self.cast_length or 0.5
  
  self.cancel_on_death = self.cancel_on_death or true
  self.cancel_on_range = self.cancel_on_range or false
  self.cancel_range = self.cancel_range or 300
  self.cancel_no_target = false

  --internal memory
  self.startTime = Helper.Time.time
  self.elapsedTime = 0

  self.unit.state = unit_states['casting']
end

function Cast:draw()
  if DEBUG_SPELLS then
    print('draw ', self.unit, self.name)
  end
end

function Cast:update(dt)
  if DEBUG_SPELLS then
    print('update cast', self.unit, dt, self.name)
  end
  if self.dead then return end
  
  if self.cancel_on_death then
    if not self.unit or self.unit.dead then
      self:cancel()
    end
  end
  
  Try_Cancel_Cast(self)


  self.elapsedTime = Helper.Time.time - self.startTime
  if self.elapsedTime > self.cast_length then
    self:cast()
  end
end

function Cast:cast()
  if DEBUG_SPELLS then
    print('cast spell', self.unit, self.name)
  end
  self.spelldata.x = self.x
  self.spelldata.y = self.y
  self.spelldata.unit = self.unit
  self.spelldata.target = self.target

  local castcooldown = self.castcooldown or 1
  self.spelldata.castcooldown = castcooldown

  if self.oncastfinish then
    self.oncastfinish(self)
  end
  local spell = self.spellclass(self.spelldata)
  if self.instantspell then
    if self.spelldata.on_attack_callbacks and self.unit.onAttackCallbacks then
      self.unit:onAttackCallbacks(self.target)
    end
    self.unit:end_cast(castcooldown)
  else
    self.unit.spellObject = spell
  end
  self:die()
end

function Cast:cancel()
  if DEBUG_SPELLS then
    print('cancel cast', self.unit, self.name)
  end
  self:die()
  if self.unit then
    self.unit:cancel_cast()
  end
end

function Cast:die()
  if DEBUG_SPELLS then
    print('destroying cast: ', self.name)
  end
  if self.unit and self.unit.castObject == self then
    self.unit.castObject = nil
  end
  self.dead = true
end

function Cast:validate_data()
  if not self.unit then
    print('error: cast needs unit to init')
    return false
  end
  if not self.spellclass then
    print('error: cast needs spellclass to init')
    return false
  end
  if not self.spelldata then
    print('error: cast needs spelldata to init')
    return false
  end
  return true
end

function Cast:get_cast_percentage()
  return self.elapsedTime / self.cast_length
end

Spell = Object:extend()
Spell:implement(GameObject)
function Spell:init(args)
  args.group = args.group or main.current.effects

  if DEBUG_SPELLS then
    print('creating spell: ', self.unit, self.name)
  end

  --load the args into the spell object
  self:init_game_object(args)
  self.name = self.name or 'spell'
  
  if not self:validate_data() then
    self:die()
    return
  end


  --set some spell defaults, if they are not set in the data

  --instant casts are 0?
  self.spell_duration = self.spell_duration or 0
  self.die_on_finish = self.die_on_finish
  self.duration = self.duration or 10



  --when to cancel
  self.cancel_on_death = self.cancel_on_death
  self.cancel_on_range = self.cancel_on_range
  self.cancel_range = self.range or 300

  self.cancel_no_target = self.cancel_no_target

  self.startTime = Helper.Time.time
  self.elapsedTime = 0

  if self.spell_duration > 0 then
    self.unit.state = unit_states['channeling']
  end

end

function Spell:validate_data()
  if not self.unit then
    print('error: spell needs unit to init')
    return false
  end
  return true
end

function Spell:draw()
  if DEBUG_SPELLS then
    print('draw spell', self.unit, self.name)
  end
end

function Spell:update(dt)
  if DEBUG_SPELLS then
    print('update spell', self.unit, dt, self.name)
  end
  self:update_game_object(dt)

  Try_Cancel_Cast(self)
  self.elapsedTime = Helper.Time.time - self.startTime
  if self.elapsedTime > self.spell_duration then
    self:die()
  end
  if self.elapsedTime > self.spell_duration + self.duration then
    self:die()
  end

end

function Spell:cancel()
  if DEBUG_SPELLS then
    print('cancel spell', self.unit, self.name)
  end
  if self.unit then
    self.unit:cancel_cast()
  end
  self:die()
end

function Spell:try_end_cast()
  if self.unit and self.unit.spellObject == self and self.unit.end_cast then
    if self.on_attack_callbacks and self.unit.onAttackCallbacks then
      self.unit:onAttackCallbacks(self.target)
    end
    self.unit:end_cast(self.castcooldown)
    self.unit.spellObject = nil
    if self.unit_dies_at_end then
      self.unit:die()
    end
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
  self:try_end_cast()
  self.dead = true
end
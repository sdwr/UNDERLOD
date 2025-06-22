Archer_Troop = Troop:extend()
function Archer_Troop:init(data)
  self.base_attack_range = attack_ranges['medium-long']
  Archer_Troop.super.init(self, data)


  self.baseCooldown = attack_speeds['buff']
  self.cooldownTime = self.baseCooldown
  self.baseCast = attack_speeds['medium-cast']
  self.castTime = self.baseCast
  self.backswing = data.backswing or 0.1
  self.castcooldown = math.random() * (self.base_castcooldown or self.baseCast)

end

function Archer_Troop:setup_cast()
  local data = {
    name = 'arrow',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, false) end,
    oncast = function() end,
    unit = self,
    target = self:my_target(),
    castcooldown = self.cooldownTime,
    cast_length = self.castTime,
    backswing = 0.2,
    instantspell = true,
    spellclass = Arrow,
    spelldata = {
      group = main.current.effects,
      on_attack_callbacks = true,
      spell_duration = 1,
      color = blue[0],
      damage = self.dmg,

    }
  }
  self.castObject = Cast(data)
end

--need to implement generic cooldown time and cast time, so that we can use the same logic for all units
--it should go on UNIT, not on TROOP or CHARACTER
--and have decision-making separate from the actual attack
--so that enemies can be controlled by their own logic
--but the attack itself (plus interaction with stun, slow, etc) is the same for all units

--we can even use the helper state machine to manage the state changes
--states are:
--1. normal - can move (chasing enemy), can attack if cooldown is ready
--2. following - is following mouse 
--3. rallying - is moving to rally point
--4. casting - is casting an attack + standing still
--5. stopped - after casting, is standing still, can move but won't by default (backswing)
--6. frozen - is stunned

--do we need modifiable state change functions? or can they be hard-coded in unit base class?
--even if every unit has the same attack process - 1 attack w 1 cast time, 1 cooldown time, 1 attack range
--targeting and movement will be different
-- so the state from 'casting' to 'normal' will be different for each unit
--as it picks up a new target, or moves to a new position
-- that could be handled in the character :update() function, after the state change

--should maybe add previous state to the state change functions, so we know what the unit was doing before

function Archer_Troop:update(dt)
  --movement state changes happen here
  Archer_Troop.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function Archer_Troop:set_state_functions()
  --if ready to cast and has target in range, start cast
  self.state_always_run_functions['always_run'] = function()    
  end

  self.state_always_run_functions['casting'] = function(self)
    if Helper.Unit:target_out_of_range(self) then
      self:cancel_cast()
    end
  end


  self.state_always_run_functions['following_or_rallying'] = function(self)
  end

  self.state_always_run_functions['normal_or_stopped'] = function(self)
  end

  --cancel on death
  self.state_change_functions['death'] = function(self)
    self:cancel_cast()
    Helper.Unit:unclaim_target(self)
  end
end

function Archer_Troop:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
  self.aggro_sensor = Circle(self.x, self.y, self.base_attack_range + AGGRO_RANGE_BOOST)
  --total cooldown is cooldownTime + castTime
  self.baseCooldown = attack_speeds['fast']
  self.cooldownTime = self.baseCooldown
  self.baseCast = attack_speeds['buff']
  self.castTime = self.baseCast


  self:set_state_functions()
end


function Archer_Troop:draw()
  Archer_Troop.super.draw(self)
end

function Archer_Troop:draw_cast_timer()
  Archer_Troop.super.draw_cast_timer(self)
end

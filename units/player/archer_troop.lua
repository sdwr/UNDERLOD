Archer_Troop = Troop:extend()
function Archer_Troop:init(data)
  self.base_attack_range = TROOP_RANGE
  Archer_Troop.super.init(self, data)

  self.backswing = data.backswing or 0.1
  -- Cast/cooldown values are now set in calculate_stats() first run
end

function Archer_Troop:create_spelldata()
  return {
    group = main.current.main,
    on_attack_callbacks = true,
    spell_duration = 10,
    bullet_size = 3,
    pierce = false,
    homing = true,
    speed = 210,
    is_troop = true,
    color = blue[0],
    damage = function() return self.dmg end,
  }
end

function Archer_Troop:setup_cast(cast_target)
  --calculate distance multiplier
  Archer_Troop.super.setup_cast(self, cast_target)

  local data = {
    name = 'arrow',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() 
      self:stretch_on_attack()
    end,
    unit = self,
    target = cast_target,
    backswing = self.backswing,
    instantspell = true,
    cast_distance_multiplier = self.cast_distance_multiplier,
    spellclass = ArrowProjectile,
    spelldata = self:create_spelldata()
  }
  self.castObject = Cast(data)
end

--instant attack skips the unit cooldown, is a double attack or retaliate
function Archer_Troop:instant_attack(cast_target)
  local spelldata = self:create_spelldata()
  spelldata.on_attack_callbacks = false
  spelldata.unit = self
  spelldata.target = cast_target
  ArrowProjectile(spelldata)
end
  
function Archer_Troop:instant_attack_at_angle(angle, damage_multi)
  local spelldata = self:create_spelldata()
  spelldata.on_attack_callbacks = false
  spelldata.unit = self
  spelldata.angle = angle
  spelldata.damage = function() return self.dmg * damage_multi end
  ArrowProjectile(spelldata)
end

function Archer_Troop:multishot(angle)
  local angle1 = angle + MULTISHOT_ANGLE_OFFSET
  local angle2 = angle - MULTISHOT_ANGLE_OFFSET

  local proc = Get_Static_Proc(self, 'multishot')
  local damage_multi = proc:get_damage_multi()

  self:instant_attack_at_angle(angle1, damage_multi)
  self:instant_attack_at_angle(angle2, damage_multi)
  
  if Get_Static_Proc(self, 'extraMultishot') then
    local angle3 = angle + MULTISHOT_ANGLE_OFFSET / 2
    local angle4 = angle - MULTISHOT_ANGLE_OFFSET / 2

    self:instant_attack_at_angle(angle3, damage_multi)
    self:instant_attack_at_angle(angle4, damage_multi)
  end
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
  
  self.infinite_range = true

  self:set_state_functions()
  -- Cast/cooldown values are set in calculate_stats() first run
end


function Archer_Troop:draw()
  Archer_Troop.super.draw(self)
end

function Archer_Troop:draw_cast_timer()
  Archer_Troop.super.draw_cast_timer(self)
end

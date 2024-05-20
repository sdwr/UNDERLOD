Archer_Troop = Troop:extend()
function Archer_Troop:init(data)
  Archer_Troop.super.init(self, data)

  self.castCountdown = self.castTime
end

function Archer_Troop:update(dt)
  --movement state changes happen here
  Archer_Troop.super.update(self, dt)

  -- continue the cast
  if self.state == unit_states['casting'] then
    self.castCountdown = self.castCountdown - dt
    
    --unclaim target if it moves out of range
    if self:my_target() and not Helper.Spell:target_is_in_range(self, 130, true) then
      Helper.Unit:unclaim_target(self)
      --can set this directly, because we know we are in casting state
      self.state = unit_states['normal']
    end

    if self.castCountdown <= 0 then
      self:cast()
    end
  else
    --if not casting, reset the cast timer
    self.castCountdown = self.castTime
  end
  
end

function Archer_Troop:cast()
  --reset everything, and attack if the target is still in range
  self.state = unit_states['normal']
  if self:my_target() and Helper.Spell:target_is_in_range(self, 130, true) then
    self.last_attack_finished = Helper.Time.time
  end
  Helper.Unit:unclaim_target(self)
  --on attack callbacks
  if self.onAttackCallbacks then
    self:onAttackCallbacks(self.target)
  end
  alert1:play{volume=0.7}
  local data = {
    group = main.current.effects, 
    unit = self,
    target = self.target,
    direction_lock = false,
    laser_aim_width = 3,
    color = Helper.Color.blue,
    damage = self.dmg,
    castTime = self.castTime,
  }
  local args = {
    data = data,
    unit = self,
    group = main.current.effects
  }

  Spell_Arrow(args)
end

function Archer_Troop:draw()
  Archer_Troop.super.draw(self)
end

function Archer_Troop:draw_cast_timer()
  Archer_Troop.super.draw_cast_timer(self)
end

function Archer_Troop:start_cast()
  --start casting, set timer
  --and once the timer is up, if the target is still in range and the unit is still casting, attack
  --we need to break when target moves out of range
  --and its more complicated, because if the unit moves back in range, we need to start casting again
  --from the beginning, not just continue the cast
  --so i guess the cast should be on the spell like it is now
  --or have a "cast" obj on the unit, that we can destroy when the spell gets canceled
  self.state = unit_states['casting']
  self.castCountdown = self.castTime


end

--attack logic is split between character and spell
-- 1. character sets up the attack sensor and cooldowns
-- 2. character sets up the always_run functions
-- 3. character triggers the attack cast
-- 4. spell handles the attack cast
-- 5. spell handles the attack callbacks
-- 6. character handles canceling the attack if moves or target moves
function Archer_Troop:set_character()
  self.attack_sensor = Circle(self.x, self.y, 130)

  --total cooldown is cooldownTime + castTime
  self.baseCooldown = attack_speeds['fast']
  self.cooldownTime = self.baseCooldown
  self.baseCast = attack_speeds['buff']
  self.castTime = self.baseCast

  --if ready to cast and has target in range, start cast
  self.state_always_run_functions['always_run'] = function()
    
    if Helper.Unit:can_cast(self) then
      Helper.Unit:claim_target(self, Helper.Spell:get_nearest_least_targeted(self, 130, true))
      Helper.Time:wait(get_random(0, 0.1), self:start_cast())
    end
    
  end


  --cancel on move
  self.state_always_run_functions['following_or_rallying'] = function()
    Helper.Spell.Laser:stop_aiming(self)
    Helper.Unit:unclaim_target(self)
  end

  self.state_change_functions['normal'] = function() end

  --cancel on death
  self.state_change_functions['death'] = function()
    Helper.Spell.Laser:stop_aiming(self)
    Helper.Unit:unclaim_target(self)
  end

end
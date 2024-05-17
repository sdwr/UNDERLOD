Laser_Troop = Troop:extend()
function Laser_Troop:init(data)
  Laser_Troop.super.init(self, data)
end

-- can remove this, no need to override
function Laser_Troop:update(dt)
  Laser_Troop.super.update(self, dt)
end

function Laser_Troop:draw()
  Laser_Troop.super.draw(self)
end

function Laser_Troop:draw_cast_timer()
  Laser_Troop.super.draw_cast_timer(self)
end

function Laser_Troop:set_character()
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
      Helper.Time:wait(get_random(0, 0.1), function()
        
        --on attack callbacks
        if self.onAttackCallbacks then
          self:onAttackCallbacks(self.claimed_target)
        end
        sniper_load:play{volume=0.7}
        local data = {
          group = main.current.effects, 
          unit = self,
          target = self.claimed_target,
          direction_lock = false,
          laser_aim_width = 3,
          color = Helper.Color.blue,
          damage = self.dmg,
        }
        Helper.Spell.Laser:create(Helper.Color.blue, 1, false, 20, self, true)
      end)
    end
    
    --cancel if target moves out of range
    if self.have_target and not Helper.Spell:claimed_target_is_in_range(self, 130, true) then
      Helper.Spell.Laser:stop_aiming(self)
      Helper.Unit:unclaim_target(self)
    end
  end

  --cancel on move
  self.state_always_run_functions['following_or_rallying'] = function()
    if self.have_target then
      Helper.Spell.Laser:stop_aiming(self)
      Helper.Unit:unclaim_target(self)
    end
  end

  self.state_change_functions['normal'] = function() end

  --cancel on death
  self.state_change_functions['death'] = function()
    Helper.Spell.Laser:stop_aiming(self)
    Helper.Unit:unclaim_target(self)
  end

end
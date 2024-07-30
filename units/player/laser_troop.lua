Laser_Troop = Troop:extend()
function Laser_Troop:init(data)
  self.base_attack_range = attack_ranges['ranged']
  Laser_Troop.super.init(self, data)
end

-- can remove this, no need to override
function Laser_Troop:update(dt)
  Laser_Troop.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function Laser_Troop:draw()
  Laser_Troop.super.draw(self)
end

function Laser_Troop:draw_cast_timer()
  Laser_Troop.super.draw_cast_timer(self)
end


--conditions to attack should be:
--1. state is 'normal' (includes has assigned_target)
--2. target is in range
--3. cooldown is ready

-- so these should be managed by:
--1. state can be set by spell/helper
--2. target is set by RMB click, and if not set there is auto-targetted by spell/helper
--3. cooldown should be in unit
function Laser_Troop:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)

  --total cooldown is cooldownTime + castTime
  self.baseCooldown = attack_speeds['fast']
  self.cooldownTime = self.baseCooldown
  self.baseCast = attack_speeds['buff']
  self.castTime = self.baseCast

  self:set_state_functions()
  self.castcooldown = math.random() * (self.base_castcooldown or self.baseCast)
end

function Laser_Troop:set_state_functions()

    --if ready to cast and has target in range, start cast
    self.state_always_run_functions['always_run'] = function()

      --prioritize moving towards target
      --should only have a target if it is assigned now
      -- or if it grabs a random target
      --because random targets will be taken away after each attack
      if Helper.Unit:target_out_of_range(self) then
        self:cancel_cast()
  
      elseif Helper.Unit:can_cast(self) then
        if not self:my_target() then
          Helper.Unit:claim_target(self, Helper.Spell:get_random_in_range(self, self.attack_sensor.rs, true))
        end
        local data = {
          name = 'laser',
          viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.enemies); return target end,
          oncast = function() end,
          castcooldown = self.cooldownTime,
          cast_length = 0.1,
          spellclass = Laser_Spell,
          spelldata = {
            group = main.current.main,
            spell_duration = 10,
            color = blue[0],
            on_attack_callbacks = true,
            damage = self.dmg,
            lasermode = 'target',
            laser_aim_width = 1,
            damage_troops = false,
            damage_once = true,
            end_spell_on_fire = false,
            fire_follows_unit = false,
            fade_fire_draw = true,
            fade_in_aim_draw = true,
          }
        }
        self:cast(data)
      end
      
      --need 2 types of target - one for random targets, one for assigned targets
      --if target is assigned, it will remain until the target dies or is reassigned
      --but random targets will be reassigned every attack, to keep a nice spread of damage
  
      --cancel if target moves out of range
      if self:my_target() and not Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, true) then
        self:cancel_cast()
        Helper.Unit:unclaim_target(self)
      end
    end
  
    --cancel on move
    self.state_always_run_functions['following_or_rallying'] = function()
      self:cancel_cast()
      Helper.Unit:unclaim_target(self)
    end
  
    self.state_change_functions['normal'] = function() end
  
    --cancel on death
    self.state_change_functions['death'] = function()
      self:cancel_cast()
      Helper.Unit:unclaim_target(self)
    end

  end

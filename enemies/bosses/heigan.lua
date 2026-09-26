local fns = {}

fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = orange[-2]:clone()
  Set_Enemy_Shape(self, self.size)
  
  self.class = 'boss'
  self.icon = 'beholder'

  --set sensors
  self.attack_sensor = Circle(self.x, self.y, 80)



  -- Attack speed now handled by base class

  --set attacks
  self.attack_options = {}
  

  local safety_dance = {
    name = 'safety_dance',
    viable = function() return true end, -- Can always be cast
    
    -- The time the unit will be locked in the 'casting' state
    cast_length = BEHOLDER_CAST_TIME,
    cast_sound = earth1,
    cast_volume = 1.5,
    -- Boss abilities have longer cooldowns, handled by base class
    
    spellclass = SafetyDanceSpell,
    
    -- This spell is not instant; it has its own duration after the cast.
    instantspell = false, 
    
    -- This data is passed to the SafetyDanceSpell:init() function
    spelldata = {
        damage = 25,
        total_zones = 4,
        charge_duration = 3.5, -- Should match the cast_length
        active_duration = 2.0, -- How long the damage zones stay active
        color = orange[-5],
        damage_troops = true,
        -- Only the lane with the most troops erupts: rewards splitting up.
        hit_busiest_lane = true,
    }
  }

  local laser_ball = {
    name = 'laser_ball',
    viable = function () return true end,

    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    cast_sound = earth1,
    cast_volume = 1.5,
    spellclass = LaserBall,
    instantspell = true,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      x = self.x,
      y = self.y,
      color = purple[-5],
      damage = function() return self.dmg end,
      parent = self
    },
  }

  -- Narrow orb cone aimed at one unit (3 volleys, re-aimed each volley). Only
  -- the targeted unit has to sidestep unless the team is stacked in the cone.
  local orb_cone = {
    name = 'orb_cone',
    viable = function () return true end,

    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    cast_sound = earth1,
    cast_volume = 1.5,
    spellclass = Plasma_Barrage,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      spell_duration = 100,
      x = self.x,
      y = self.y,
      cone_count = 5,
      cone_spread = math.pi / 7,
      num_balls = 3,
      time_between_balls = 0.6,
      speed = 65,
      color = purple[-5],
      damage = function() return self.dmg end,
      parent = self
    },
  }

  -- Slam telegraphed on the average position of all troops: a clumped team
  -- all gets hit, a split team leaves empty ground in the middle.
  local center_slam = {
    name = 'center_slam',
    viable = function() return Helper.Unit:get_player_location() ~= nil end,

    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    cast_sound = earth1,
    cast_volume = 1.5,
    spellclass = function(data)
      local p = Helper.Unit:get_player_location()
      data.x, data.y = p.x, p.y
      return Stomp_Spell(data)
    end,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      spell_duration = HEIGAN_CENTER_SLAM_CHARGE,
      cancel_on_death = true,
      rs = HEIGAN_CENTER_SLAM_RADIUS,
      color = orange[-5],
      damage = function() return self.dmg * 1.2 end,
      parent = self,
    }
  }

  local plasma_ball = {
    name = 'plasma_ball',
    viable = function () return true end,

    instantspell = true,
    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    cast_sound = earth1,
    cast_volume = 1.5,
    spellclass = PlasmaBall,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      x = self.x,
      y = self.y,
      r = self.r,
      color = purple[-5],
      damage = function() return self.dmg end,
      parent = self
    },
  }

  local quick_stomp = {
    name = 'quick_stomp',
    viable = function() return self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,

    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME, 
    cast_sound = earth1,
    cast_volume = 1.5,
    spellclass = Stomp_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      x = self.x,
      y = self.y,
      color = orange[-5],
      rs = 50,
      damage = function() return self.dmg end,
      parent = self,
    }
  }

  table.insert(self.attack_options, orb_cone)
  table.insert(self.attack_options, center_slam)
  table.insert(self.attack_options, safety_dance)
  table.insert(self.attack_options, laser_ball)
  -- table.insert(self.attack_options, plasma_ball)
  -- table.insert(self.attack_options, quick_stomp)
end

fns['draw_enemy'] = function(self)
    local animation_success = self:draw_animation()

    if not animation_success then
      self:draw_fallback_animation()
    end
end

enemy_to_class['heigan'] = fns
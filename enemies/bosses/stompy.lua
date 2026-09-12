local fns = {}

fns['attack'] = function(self, area, mods, color)
  mods = mods or {}
  local t = {team = "enemy", group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = (area or 64), color = color or self.color, damage = function() return self.dmg end,
    character = self.character, level = self.level, parent = self, unit = self}

  Helper.Unit:set_state(self, unit_states['frozen'])

  self.t:after(0.3, function() 
    Helper.Unit:set_state(self, unit_states['stopped'])
    Area(table.merge(t, mods))
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  end, 'stopped')
  self.t:after(0.4 + .4, function() Helper.Unit:set_state(self, unit_states['idle']) end, 'normal')
end

fns['init_enemy'] = function(self)
  self.boss_name = 'stompy'
  self.icon = 'golem'
  
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size, 'circle')

  self.class = 'boss'

  self.stopChasingInRange = false

--set sensors
  self.attack_sensor = Circle(self.x, self.y, 120)

  -- avalanche runs on its own timer, seeded here so the first one lands mid-fight
  self.last_avalanche_time = Helper.Time.time

  --set attacks
  self.attack_options = {}

  local stomp = {
    name = 'stomp',
    viable = function() return self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
    oncast = function() end,
    cast_length = 1.20,
    cast_sound = usurer1,
    cast_volume = 2,

    spellclass = Stomp_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      spell_duration = GOLEM_CAST_TIME,
      cancel_on_death = true,
      x = self.x,
      y = self.y,
      rs = self.attack_sensor.rs,
      knockback = true,
      color = grey[0],
      damage = function() return self.dmg * 1.2 end,
      parent = self
    }
  }

  local mortar = {
    name = 'mortar',
    viable = function() return true end,
    oncast = function() end,
    instantspell = true,
    cast_length = GOLEM_CAST_TIME,
    cast_sound = usurer1,
    cast_volume = 2,
    spellclass = Mortar_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      spell_duration = 10,
      shell_style = 'rock',
      num_shots = 3,
      shot_interval = 0.7,
      -- small shell, lighter hit than the telegraphed set-piece attacks
      damage = function() return self.dmg * 0.6 end,
      rs = 25,
      parent = self
    }
  }

  local avalanche = {
    name = 'avalanche',
    -- set-piece: fires on its own cadence and preempts the random pick
    priority = true,
    viable = function() return Helper.Time.time - self.last_avalanche_time >= enemy_attack_cooldowns['stompy_avalanche'] end,

    instantspell = true,
    cast_length = GOLEM_CAST_TIME,
    cast_sound = usurer1,
    cast_volume = 1,
    oncast = function()
      self.last_avalanche_time = Helper.Time.time
      turret_hit_wall2:play{volume = 0.5}
    end,
    spellclass = Avalanche,
    spelldata = {
      group = main.current.main,
      unit = self,
      team = "enemy",
      x = self.x,
      y = self.y,
      damage = function() return self.dmg end
    }
  }

  local summon = {
    name = 'summon',
    -- only re-summon once the previous pack is mostly cleared
    viable = function()
      local count = 0
      for _, e in ipairs(Helper.Unit:get_list(false)) do
        if not e.dead and e.type == 'hunter_swarmer' and e.parent == self then count = count + 1 end
      end
      return count < 3
    end,
    instantspell = true,
    cast_length = GOLEM_CAST_TIME,
    cast_sound = usurer1,
    cast_volume = 2,
    oncast = function() end,
    spellclass = SummonHunters_Spell,
    spelldata = {
      group = main.current.main,
      team = 'enemy',
      x = self.x,
      y = self.y,
      num_hunters = 5,
      spawn_radius = 28,
      parent = self,
    }
  }

  local prevent_casting = {
    name = 'prevent_casting',
    viable = function() return true end,

    cast_length = 0.5,
    oncast = function() end,
    spellclass = PreventCasting_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",

      x = self.x,
      y = self.y,
      duration = 3,
    }
  }

  -- Pinball charge: aim at a troop, wind up with a line to the first wall,
  -- then launch and bounce off walls for STOMPY_CHARGE_DURATION. Troop hits
  -- are handled in on_collision_enter below.
  local charge = {
    name = 'charge',
    viable = function()
      local target = Helper.Target:get_random_enemy(self)
      return target and self:distance_to_object(target) > 60
    end,
    oncast = function()
      self.target = Helper.Target:get_random_enemy(self)
      if self.target then self:set_angle(self:angle_to_object(self.target)) end
    end,
    cast_sound = usurer1,
    cast_volume = 2,
    spellclass = Launch_Spell,
    spelldata = {
      group = main.current.main,
      team = 'enemy',
      charge_duration = STOMPY_CHARGE_WINDUP,
      fire_distance = 1000,
      line_to_wall = true,
      aim_width = 14,
      cancel_on_death = true,
      keep_original_angle = true,
      aim_spread = STOMPY_CHARGE_SPREAD,
      draw_under_units = true,
      show_charge_line = true,
      play_charge_sound = true,
      x = self.x,
      y = self.y,
      color = grey[5],
      impulse_magnitude = 500,
      launch_duration = STOMPY_CHARGE_DURATION,
      pinball = true,
      pinball_speed = STOMPY_CHARGE_SPEED,
      damage = function() return self.dmg end,
      parent = self,
    }
  }

  table.insert(self.attack_options, stomp)
  table.insert(self.attack_options, mortar)
  table.insert(self.attack_options, summon)
  table.insert(self.attack_options, avalanche)
  table.insert(self.attack_options, charge)
  -- table.insert(self.attack_options, prevent_casting)

end

-- Pinball charge hooks (see Enemy:update_launch): the bounds reflection and
-- troop overlap are detected there; these supply the effects and the hit.
fns['on_pinball_bounce'] = function(self)
  self.hfx:use('hit', 0.15, 200, 10, 0.1)
  turret_hit_wall2:play{pitch = random:float(0.8, 1.0), volume = 0.6}
  camera:shake(4, 0.2)
end

fns['on_pinball_hit'] = function(self, troop)
  troop:push(LAUNCH_PUSH_FORCE_BOSS, self.pinball_heading, nil, KNOCKBACK_DURATION_BOSS)
  troop:hit(self.dmg * STOMPY_CHARGE_DAMAGE_MULT, self, nil, true, true)
end

-- Physical wall contact is a no-op mid-charge (bounds reflection owns it);
-- troop contact is masked off entirely for the charge.
fns['on_collision_enter'] = function(self, other, contact)
  if self.pinball_charging and other:is(Wall) then return end
  Enemy.on_collision_enter(self, other, contact)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation(self.state, self.x, self.y, 0, 1, 1)

  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['stompy'] = fns


local fns = {}

fns['init_enemy'] = function(self)
  self.boss_name = 'dragon'
  
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)
  
  self.class = 'boss'
  self.icon = 'dragon'

  --set attacks
  self.fireDmg = 5
  self.fireDuration = 3
  self.fireRange = 100

  self.fireSweepRange = 200
  
  self.attack_options = {}

  local fire = {
    name = 'fire',
    viable = function() return #main.current.main:get_objects_in_shape(Circle(self.x, self.y, 150), main.current.friendlies, nil) > 0 end,

    oncast = function(self) self.target = Helper.Spell:get_nearest_target(self) end,
    spellclass = Breathe_Fire,
    spelldata = {
      group = main.current.main,
      color = red[0],
      team = "enemy",
      cancel_on_death = true,
      flamewidth = 30,
      flameheight = 150,
      tick_interval = 0.125,
      dps = 30,
      spell_duration = 5,
      follow_target = true,
      freeze_rotation = true,
    }, 
  }

  local fire_sweep = {
    name = 'fire_sweep',
    viable = function() return true end,

    oncast = function(self) self.target = Helper.Spell:get_nearest_target(self) end,
    spellclass = Breathe_Fire,
    spelldata = {
      group = main.current.main,
      color = red[0],
      team = "enemy",
      cancel_on_death = true,
      flamewidth = 30,
      flameheight = 150,
      tick_interval = 0.125,
      rotate_tick_interval = 1,
      dps = 30,
      spell_duration = 5,
      follow_target = false,
      freeze_rotation = true,
      follow_speed = 45,
    },
  }

  local fire_wall = {
    name = 'fire_wall',
    viable = function() return true end,

    oncast = function(self) end,
    spellclass = FireWall,
    instantspell = true,
    spelldata = {
      group = main.current.main,
      color = red[0],
      team = "enemy",
      wall_type = "half",
    },
  }

  table.insert(self.attack_options, fire)
  --table.insert(self.attack_options, fire_sweep)
  table.insert(self.attack_options, fire_wall)

  self.state_always_run_functions['always_run'] = function(self)
      self.hitbox_points_rotation = math.deg(self:get_angle())
  end

  self.state_change_functions['target_death'] = function()
  end

    self.state_change_functions['death'] = function(self)
      Helper.Spell.Flame:end_flame_after(self, 0)
  end
end

fns['draw_enemy'] = function(self)
    local animation_success = self:draw_animation()

    if not animation_success then
      self:draw_fallback_animation()
    end
end

enemy_to_class['dragon'] = fns
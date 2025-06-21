

local fns = {}

fns['attack'] = function(self, area, mods, color)
  mods = mods or {}
  local t = {team = "enemy", group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(area or 64), color = color or self.color, dmg = self.dmg,
    character = self.character, level = self.level, parent = self}

  self.state = unit_states['frozen']

  self.t:after(0.3, function() 
    self.state = unit_states['stopped']
    Area(table.merge(t, mods))
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  end, 'stopped')
  self.t:after(0.4 + .4, function() self.state = unit_states['normal'] end, 'normal')
end

fns['init_enemy'] = function(self)
  self.boss_name = 'stompy'
  self.icon = 'golem'
  
  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'stompy'

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'boss'

  self.stopChasingInRange = false

--set sensors
  self.attack_sensor = Circle(self.x, self.y, 80)



  --set attacks
  self.attack_options = {}

  local stomp = {
    name = 'stomp',
    viable = function() return self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
    castcooldown = 1,
    oncast = function() end,
    cast_length = 0.1,
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
      dmg = 30,
      parent = self
    }
  }

  local mortar = {
    name = 'mortar',
    viable = function() return true end,
    castcooldown = 2,
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
      num_shots = 3,
      shot_interval = 0.7,
      dmg = 20,
      rs = 25,
      parent = self
    }
  }

  local avalanche = {
    name = 'avalanche',
    viable = function() return true end,
    castcooldown = 4,
    instantspell = true,
    cast_length = GOLEM_CAST_TIME,
    cast_sound = usurer1,
    cast_volume = 2,
    oncast = function() turret_hit_wall2:play{volume = 0.9} end,
    spellclass = Avalanche,
    spelldata = {
      group = main.current.main,
      unit = self,
      team = "enemy",
      x = self.x,
      y = self.y,
      dmg = 20
    }
  }

  local charge = {
    name = 'charge',
    viable = function() return true end,
    castcooldown = 3,
    cast_length = 0.1,
    oncast = function() end,
    cast_sound = usurer1,
    cast_volume = 2,
    spellclass = Launch_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      charge_duration = GOLEM_CAST_TIME,
      spell_duration = GOLEM_CAST_TIME + 0.75,
      impulse_magnitude = 300,
      cancel_on_death = true,
      keep_original_angle = true,
      draw_under_units = true,
      x = self.x,
      y = self.y,
      color = red[0],
      dmg = 30,
      parent = self
    }
  }

  local prevent_casting = {
    name = 'prevent_casting',
    viable = function() return true end,
    castcooldown = 3,
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

  table.insert(self.attack_options, stomp)
  table.insert(self.attack_options, mortar)
  table.insert(self.attack_options, avalanche)
  table.insert(self.attack_options, charge)
  -- table.insert(self.attack_options, prevent_casting)

end

fns['draw_enemy'] = function(self)   
  graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)

  local animation_success = self:draw_animation(self.state, self.x, self.y, 0, 1, 1)

  if not animation_success then
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 10, 10, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
  end

  graphics.pop()
end

enemy_to_class['stompy'] = fns
local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'lizardman'

  --set sensors
  self.attack_sensor = Circle(self.x, self.y, 80)

  --set attacks
  self.attack_options = {}

  local charge = {
    name = 'charge',
    viable = function() return Helper.Target:get_random_enemy(self) end,
    castcooldown = 3,
    cast_length = 0.1,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,
    spellclass = Launch_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      charge_duration = 1.75,
      spell_duration = 2.5,
      aim_width = 8,
      cancel_on_death = true,
      keep_original_angle = true,
      draw_under_units = true,
      target = self.target,
      show_charge_line = true,
      play_charge_sound = true,
      x = self.x,
      y = self.y,
      color = red[0],
      impulse_magnitude = 500,
      damage = function() return self.dmg end,
      parent = self
    }
  }
  table.insert(self.attack_options, charge)
end

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

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end
end

enemy_to_class['charger'] = fns
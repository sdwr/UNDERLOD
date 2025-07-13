local fns = {}
fns['attack'] = function(self, mods, color)
  mods = mods or {}
  local t = {team = "enemy", group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = 20, color = color or self.color, damage = function() return self.dmg end,
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
  
  --set extra data from variables
  self.data = self.data or {}
  self.icon = 'rat1'

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.movementStyle = MOVEMENT_TYPE_RANDOM

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'regular_enemy'

  --set sensors
  self.attack_sensor = Circle(self.x, self.y, 500)

  self.move_option_weight = 0.4

  self.movement_options = {
    MOVEMENT_TYPE_RANDOM,
  }

  --set attacks
  self.attack_options = {}

  local charge = {
    name = 'charge',
    viable = function() return true end,
    castcooldown = 2, -- Shorter cooldown than charger (3)
    cast_length = 0.1,
    oncast = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); self.target = target end,
    spellclass = Launch_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      charge_duration = 0.5, -- Shorter charge time than charger (1.75)
      spell_duration = 1.8, -- Shorter duration than charger (2.5)
      aim_width = 4, -- Thinner aim line than charger (8)
      cancel_on_death = true,
      keep_original_angle = true,
      draw_under_units = true,
      target = self.target,
      show_charge_line = false,
      play_charge_sound = false,
      x = self.x,
      y = self.y,
      color = grey[0], -- Use seeker's color instead of red
      impulse_magnitude = 150, -- Less force than charger (500)
      damage = function() return self.dmg end,
      parent = self
    }
  }
  table.insert(self.attack_options, charge)

end

fns['draw_enemy'] = function(self)

  
  local animation_success = self:draw_animation()
  
  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end


end

enemy_to_class['seeker'] = fns
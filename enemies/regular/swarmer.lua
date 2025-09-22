local fns = {}
fns['init_enemy'] = function(self)

  self.data = self.data or {}
  self.icon = 'swarmer'

  self.can_damage_orb = true
  load_special_swarmer_data(self)

  if self.special_swarmer_type == 'orbkiller' then
    self.color = red[0]:clone()
    -- Create targeting line to orb
    if main.current and main.current.current_arena and main.current.current_arena.level_orb then
      self.targeting_line = OrbDangerLine{
        group = main.current.current_arena.effects,
        parent = self,
        orb = main.current.current_arena.level_orb
      }
    end
  elseif self.special_swarmer_type == 'exploder' then
    self.color = orange[0]:clone()
  elseif self.special_swarmer_type == 'poison' then
    self.color = purple[0]:clone()
  elseif self.special_swarmer_type == 'touch' then
    self.color = green[0]:clone()

    -- Touch-specific properties - always green (helpful)
    self.is_green = true  -- Always in green (touchable) state

    -- Make invulnerable to normal damage
    self.invulnerable = true
    self.can_be_touched = true

    -- Add callback for when damage is rejected due to invulnerability
    self.rejectDamageCallback = function()
      if tink then
        tink:play{pitch = random:float(1.2, 1.4), volume = 0.3}
      end
    end
  elseif self.special_swarmer_type == 'touch_fade' then
    self.color = green[0]:clone()  -- Start with green

    -- Touch fade-specific properties
    self.is_green = true  -- Start in green (touchable) state
    self.color_switch_timer = 0
    self.color_switch_interval = 2.5  -- Switch colors every 2.5 seconds
    self.fade_progress = 0  -- For smooth color transitions
    self.fade_duration = 0.5  -- Take 0.5 seconds to fade between colors
    self.is_fading = false

    -- Make invulnerable to normal damage
    self.invulnerable = true
    self.can_be_touched = true

    -- Colors for switching
    self.green_color = green[0]:clone()
    self.red_color = red[0]:clone()

    -- Add callback for when damage is rejected due to invulnerability
    self.rejectDamageCallback = function()
      if tink then
        tink:play{pitch = random:float(1.2, 1.4), volume = 0.3}
      end
    end
  else
    self.color = grey[0]:clone()
  end

  Set_Enemy_Shape(self, self.size)



  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'regular_enemy'
  self.baseIdleTimer = 0


  self.attack_options = {}
end

fns['update_enemy'] = function(self, dt)
  if self.special_swarmer_type == 'touch_fade' then
    self:update_touch_color(dt)
  end
end

fns['update_touch_color'] = function(self, dt)
  -- Update color switching timer
  self.color_switch_timer = self.color_switch_timer + dt

  if self.color_switch_timer >= self.color_switch_interval then
    -- Start fading to the opposite color
    self.is_fading = true
    self.fade_progress = 0
    self.color_switch_timer = 0
  end

  -- Handle color fading
  if self.is_fading then
    self.fade_progress = self.fade_progress + dt / self.fade_duration

    -- Interpolate between colors - FIXED ORDER
    local t = math.min(self.fade_progress, 1)
    if self.is_green then
      -- Currently green, fading TO red
      self.color.r = math.lerp(t, self.green_color.r, self.red_color.r)
      self.color.g = math.lerp(t, self.green_color.g, self.red_color.g)
      self.color.b = math.lerp(t, self.green_color.b, self.red_color.b)
    else
      -- Currently red, fading TO green
      self.color.r = math.lerp(t, self.red_color.r, self.green_color.r)
      self.color.g = math.lerp(t, self.red_color.g, self.green_color.g)
      self.color.b = math.lerp(t, self.red_color.b, self.green_color.b)
    end

    if self.fade_progress >= 1 then
      -- Fade complete, switch states
      self.fade_progress = 1
      self.is_fading = false
      self.is_green = not self.is_green
    end
  end
end

fns['draw_enemy'] = function(self)

  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Add visual feedback for touch enemies
  if self.special_swarmer_type == 'touch' or self.special_swarmer_type == 'touch_fade' then
    if self.is_green and not self.is_fading then
      -- Add a pulsing effect when in green (touchable) state
      local pulse = math.sin(love.timer.getTime() * 4) * 0.1 + 0.9
      graphics.push(self.x, self.y, 0, pulse, pulse)
      local outline_color = green[0]:clone()
      outline_color.a = 0.3
      graphics.circle(self.x, self.y, self.shape.h, outline_color, 2)
      graphics.pop()
    end
  end

end

fns['explode'] = function(self)
  explosion_new:play{pitch = random:float(0.95, 1.05), volume = 0.3}
  Area{
    group = main.current.effects,
    unit = self,
    is_troop = false,
    x = self.x,
    y = self.y,
    r = self.radius * 2,
    duration = self.duration,
    pick_shape = 'circle',
    damage = function() return self.dmg * 2 end,
    color = red[0],
    parent = self,
  }

  local angle_between = 2*math.pi / self.num_pieces
  local angle = 0

  for i = 1, self.num_pieces do
    angle = angle + angle_between
    BurstBullet{
      group = self.group,
      color = self.color,
      x = self.x,
      y = self.y,
      r = angle,
      speed = self.secondary_speed,
      distance = self.secondary_distance,
      damage = function() return self.dmg end,
      unit = self.unit,
    }
  end
end

fns['poison'] = function(self)
  local effect_color_outline = self.color:clone()
  effect_color_outline.a = 0.5
  local effect_color_opacity = 0.3

  wizard1:play{pitch = random:float(0.9, 1.1), volume = 0.2}
  Area_Spell{
    group = main.current.effects,
    unit = self,
    is_troop = false,
    x = self.x,
    y = self.y,
    damage = 0.1,
    damage_ticks = true,
    hit_only_once = false,
    radius = 0,
    max_radius = self.radius,
    expand_duration = 1.5,
    color = effect_color_outline,
    opacity = effect_color_opacity,
    line_width = 0,
    tick_rate = self.tick_rate,
    duration = self.duration,
    pick_shape = 'circle',
    on_tick_hit_sound = wizard1,
    parent = self,
    floor_effect = 'poison',
  }
end

fns['touch_collision'] = function(self, other)
  if self.is_green then
    -- Green state - explode and damage nearby enemies
    self:touch_explosion()
    self:die()
    return true  -- Prevent normal collision damage
  end
  return false
end

fns['touch_explosion'] = function(self)

  -- Use Area_Spell for the explosion
  Area_Spell{
    group = main.current.effects,
    unit = self,
    is_troop = true,
    x = self.x,
    y = self.y,
    damage = function() return self.dmg * 1.5 end,  -- Good damage for the risk/reward
    radius = 45,
    duration = 0.2,
    pick_shape = 'circle',
    color = green[0],  -- Don't modify alpha, let Area_Spell handle it
    opacity = 0.08,  -- Very transparent fill (default Area_Spell opacity)
    line_width = 2,  -- Slightly thicker outline
  }

  -- Play explosion sound
    gold1:play{pitch = random:float(1.1, 1.3), volume = 0.4}
end

fns['on_death'] = function(self)
  if self.special_swarmer_type == 'exploder' then
    self:explode()
  elseif self.special_swarmer_type == 'poison' then
    self:poison()
  elseif self.special_swarmer_type == 'orbkiller' then
    -- Clean up targeting line
    if self.targeting_line then
      self.targeting_line.dead = true
    end
  elseif self.special_swarmer_type == 'touch' or self.special_swarmer_type == 'touch_fade' then
    -- Touch enemies don't explode on death, only on green touch
  end
end



enemy_to_class['swarmer'] = fns
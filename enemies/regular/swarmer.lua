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
    TouchBehavior.apply_touch_behavior(self, {
      touch_aoe_radius = self.touch_aoe_radius or 25,
      touch_damage_multiplier = self.touch_damage_multiplier or 1.0,
    })
  elseif self.special_swarmer_type == 'touch_fade' then
    TouchBehavior.apply_touch_fade_behavior(self, {
      touch_aoe_radius = self.touch_aoe_radius or 25,
      touch_damage_multiplier = self.touch_damage_multiplier or 1.0,
      color_switch_interval = self.color_switch_interval or 2.5,
      fade_duration = self.fade_duration or 0.5,
    })
  else
    self.color = grey[0]:clone()
  end

  Set_Enemy_Shape(self, self.size)



  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'regular_enemy'
  self.baseIdleTimer = 0


  self.attack_options = {}

  -- Optional aggro switching behavior (enabled via data.enable_aggro_switching)
  self.enable_aggro_switching = true

  if self.enable_aggro_switching then
    AggroSwitchingBehavior.apply_aggro_switching(self, {
      orb_movement = MOVEMENT_TYPE_SEEK_ORB_STALL,
      player_movement = MOVEMENT_TYPE_SEEK,
      -- No speed buff for swarmers
    })
  end
end

fns['update_enemy'] = function(self, dt)
  if self.special_swarmer_type == 'touch_fade' then
    TouchBehavior.update_touch_fade_color(self, dt)
  end

  -- Update aggro switching if enabled
  if self.has_aggro_switching then
    AggroSwitchingBehavior.update_aggro_switching(self)
  end
end

fns['draw_enemy'] = function(self)

  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end

  if self.special_swarmer_type == 'touch' or self.special_swarmer_type == 'touch_fade' then
    TouchBehavior.draw_touch_visual(self)
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
  return TouchBehavior.handle_touch_collision(self, other)
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
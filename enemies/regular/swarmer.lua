local fns = {}
fns['init_enemy'] = function(self)

  self.data = self.data or {}
  self.icon = 'swarmer'

  load_special_swarmer_data(self)

  if self.special_swarmer_type == 'exploder' then
    self.color = red[0]:clone()
  elseif self.special_swarmer_type == 'poison' then
    self.color = purple[0]:clone()
  else
    self.color = grey[0]:clone()
  end

  Set_Enemy_Shape(self, self.size)



  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  -- Reduce the wander "jitter" added on top of the seek by 40% so grey
  -- swarmers track the player more directly.
  self.seek_wander_mult = 0.6

  self.class = 'regular_enemy'
  self.baseIdleTimer = 0


  self.attack_options = {}
end

fns['get_proximity_speed_ratio'] = function(self)
  local radius = SWARMER_PROXIMITY_SLOW_RADIUS
  local min_radius = SWARMER_PROXIMITY_MIN_RADIUS
  local nearest_distance_sq = radius * radius
  -- Scan only player troops; no arena scan or temporary lists.
  for _, team in ipairs(Helper.Unit.teams) do
    for _, troop in ipairs(team.troops) do
      if not troop.dead then
        local dx, dy = troop.x - self.x, troop.y - self.y
        local distance_sq = dx * dx + dy * dy
        if distance_sq <= min_radius * min_radius then
          return SWARMER_PROXIMITY_MIN_SPEED_RATIO
        end
        if distance_sq < nearest_distance_sq then
          nearest_distance_sq = distance_sq
        end
      end
    end
  end
  if nearest_distance_sq >= radius * radius then return 1 end
  local progress = (math.sqrt(nearest_distance_sq) - min_radius) / (radius - min_radius)
  return SWARMER_PROXIMITY_MIN_SPEED_RATIO + (1 - SWARMER_PROXIMITY_MIN_SPEED_RATIO) * progress
end

fns['draw_enemy'] = function(self)

  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Draw steering debug vectors
  self:draw_steering_debug()

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
    damage = function() return self.dmg * self.damage_multi end,
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

fns['on_death'] = function(self)
  if self.special_swarmer_type == 'exploder' then
    self:explode()
  elseif self.special_swarmer_type == 'poison' then
    self:poison()
  end
end



enemy_to_class['swarmer'] = fns
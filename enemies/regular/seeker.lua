local fns = {}
fns['init_enemy'] = function(self)

  --set extra data from variables
  self.data = self.data or {}
  self.icon = 'seeker'

  load_special_seeker_data(self)

  -- Set to same size as swarmer
  self.size = 'swarmer'

  self.class = 'regular_enemy'
  self.group_tag = 'ghost_enemy'

  Set_Enemy_Shape(self, self.size)

  -- Never stop chasing, keep going until contact
  self.stopChasingInRange = false
  self.haltOnPlayerContact = false
  self.not_damage_orb = true

  -- No idle time, constantly seeking
  self.baseIdleTimer = 0

  -- No attacks - just seeks the player cursor
  self.attack_options = {}
  self.can_attack = false

  if self.special_seeker_type == 'touch' then
    TouchBehavior.apply_touch_behavior(self, {
      touch_aoe_radius = self.touch_aoe_radius or 25,
      touch_damage_multiplier = self.touch_damage_multiplier or 1.0,
    })
  elseif self.special_seeker_type == 'touch_fade' then
    TouchBehavior.apply_touch_fade_behavior(self, {
      touch_aoe_radius = self.touch_aoe_radius or 25,
      touch_damage_multiplier = self.touch_damage_multiplier or 1.0,
      color_switch_interval = self.color_switch_interval or 2.5,
      fade_duration = self.fade_duration or 0.5,
    })
  else
    -- Red triangle special enemy
    self.color = red[0]:clone()
  end

    -- Momentum system - gains speed over time
  if not self.no_stacking_mvspd then
    self.momentum_timer = 0
    self.momentum_stack_interval = 1
    self.momentum_mvspd_per_stack = 0.1
    self.momentum_max_stacks = 35
  end
end

fns['update_enemy'] = function(self, dt)
  if not self.no_stacking_mvspd then
    self.momentum_timer = self.momentum_timer + dt

    if self.momentum_timer >= self.momentum_stack_interval then
      self.momentum_timer = self.momentum_timer - self.momentum_stack_interval

      local existing_buff = self:get_buff('momentum')
      if existing_buff then
        self:increment_buff_stacks('momentum')
      else
        self:add_buff(
          {name = 'momentum',
          duration = 999,
          maxDuration = 999,
          stacks = 1,
          max_stacks = self.momentum_max_stacks,
          stats = {mvspd = self.momentum_mvspd_per_stack},
        })
      end
    end
  elseif self.mvspd_buff_range then
    local existing_buff = self:get_buff('seeker_mvspd_buff')
    if not existing_buff then
      local mvspd_buff_multiplier = random:float(self.mvspd_buff_range[1], self.mvspd_buff_range[2])
      self:add_buff(
        {name = 'seeker_mvspd_buff',
        duration = 999,
        maxDuration = 999,
        stats = {mvspd = mvspd_buff_multiplier},
      })
    end
  end
  if self.special_seeker_type == 'touch_fade' then
    TouchBehavior.update_touch_fade_color(self, dt)
  end
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_custom()
  end

  if self.special_seeker_type == 'touch' or self.special_seeker_type == 'touch_fade' then
    TouchBehavior.draw_touch_visual(self)
  end
end

fns['draw_fallback_custom'] = function(self)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color

  graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)

  local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70, self:get_angle())
  graphics.polygon(points, base_color)

  graphics.pop()

  self:draw_fallback_status_effects()
end

fns['touch_collision'] = function(self, other)
  return TouchBehavior.handle_touch_collision(self, other)
end

enemy_to_class['seeker'] = fns
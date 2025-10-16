local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Set class before shape
  self.class = 'special_enemy'

  -- Create shape - bigger than regular touch enemies
  self.size = 'special'
  Set_Enemy_Shape(self, self.size)
  self.icon = 'big_touch'
  
  self.baseIdleTimer = 0
  
  -- Movement behavior
  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true
  
  -- Apply touch behavior with larger explosion radius
  TouchBehavior.apply_touch_behavior(self, {
    touch_aoe_radius = 55,  -- Larger explosion than regular touch
    touch_damage_multiplier = 2.0
  })
  
  -- Apply aggro switching behavior with speed buff
  AggroSwitchingBehavior.apply_aggro_switching(self, {
    orb_movement = MOVEMENT_TYPE_SEEK_ORB,
    player_movement = MOVEMENT_TYPE_SEEK,
    on_aggro_player = function(self)
      self:add_buff({name = 'aggro_speed_buff', duration = 999, maxDuration = 999, stats = {mvspd = 1.2}})
    end,
    on_aggro_orb = function(self)
      self:remove_buff('aggro_speed_buff')
    end
  })
end

fns['update_enemy'] = function(self, dt)
  AggroSwitchingBehavior.update_aggro_switching(self)
end

fns['attack'] = function(self)
  -- Big touch doesn't attack directly, just moves
end

fns['draw_enemy'] = function(self)
  -- Try to draw animation first
  local animation_success = self:draw_animation()

  if not animation_success then
    -- Fallback to simple shape
    self:draw_fallback_custom()
  end

  -- Draw touch visual effect
  TouchBehavior.draw_touch_visual(self)
end

fns['draw_fallback_custom'] = function(self)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color
  graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)
  local points = self:make_regular_polygon(6, (self.shape.w / 2) / 60 * 70, self:get_angle())
  graphics.polygon(points, base_color)
  graphics.pop()
  self:draw_fallback_status_effects()
end

fns['touch_collision'] = function(self, other)
  return TouchBehavior.handle_touch_collision(self, other)
end

enemy_to_class['big_touch'] = fns

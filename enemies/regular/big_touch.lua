local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Set class before shape
  self.class = 'special_enemy'

  -- Create shape - bigger than regular touch enemies
  self.size = 'special'
  Set_Enemy_Shape(self, self.size)
  self.icon = 'big_touch'

  -- Apply touch behavior with larger explosion radius
  TouchBehavior.apply_touch_behavior(self, {
    touch_aoe_radius = 55,  -- Larger explosion than regular touch
    touch_damage_multiplier = 2.0
  })

  self.baseIdleTimer = 0

  -- Movement behavior
  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true

  -- Aggro range detection
  self.aggro_range = 80  -- Range to detect player and switch targets
end

fns['update_enemy'] = function(self, dt)
  -- Check if any player units are in aggro range
  local closest_troop = Helper.Target:get_closest_enemy(self)

  if closest_troop and not closest_troop.dead then
    local distance_to_troop = math.distance(self.x, self.y, closest_troop.x, closest_troop.y)

    if distance_to_troop <= self.aggro_range then
      -- Switch to seeking player
      if self.currentMovementAction ~= MOVEMENT_TYPE_SEEK then
        -- Force re-acquisition of target
        self:set_movement_action(MOVEMENT_TYPE_SEEK)
        self:add_buff({name = 'seek_movement_buff', duration = 999, maxDuration = 999, stats = {mvspd = 1.2}})
      end
    else
      -- Switch back to seeking orb
      if self.currentMovementAction ~= MOVEMENT_TYPE_SEEK_ORB then
        -- Force re-acquisition of target
        self:set_movement_action(MOVEMENT_TYPE_SEEK_ORB)
        self:remove_buff('seek_movement_buff')
      end
    end
  else
    -- No player units found, seek orb
    if self.currentMovementAction ~= MOVEMENT_TYPE_SEEK_ORB then
      self:set_movement_action(MOVEMENT_TYPE_SEEK_ORB)
      self:remove_buff('seek_movement_buff')
    end
  end
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

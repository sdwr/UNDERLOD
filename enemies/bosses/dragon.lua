

local fns = {}

fns['init_enemy'] = function(self)
  self.boss_name = 'dragon'
  
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size, 'circle')
  
  self.class = 'boss'
  self.icon = 'dragon'

  --set attacks
  self.fireDmg = 5
  self.fireDuration = 3
  self.fireRange = 100

  self.fireSweepRange = 200

  -- Shared with the preview wedge in draw_enemy. fireRotationSpeed matches
  -- Breathe_Fire's default so the windup preview rotates at the same rate the
  -- actual breath will once it fires.
  self.fireFlameWidth = 30
  self.fireFlameHeight = 150
  self.fireRotationSpeed = 5

  self.attack_options = {}

  local fire = {
    name = 'fire',
    viable = function() return #main.current.main:get_objects_in_shape(Circle(self.x, self.y, 150), main.current.friendlies, nil) > 0 end,

    oncast = function(self) self.target = Helper.Spell:get_nearest_target(self) end,
    -- Hand the preview wedge's final direction to the spell so the breath
    -- starts along the line the player has been watching, not the live target.
    oncastfinish = function(cast)
      local u = cast.unit
      if u and u.preview_dx and u.preview_dy then
        cast.spelldata.directionx = u.preview_dx
        cast.spelldata.directiony = u.preview_dy
      end
    end,
    -- Longer windup paired with the preview wedge gives the player a dodge window.
    cast_length = 2.91,
    spellclass = Breathe_Fire,
    spelldata = {
      group = main.current.main,
      color = red[0],
      team = "enemy",
      cancel_on_death = true,
      flamewidth = self.fireFlameWidth,
      flameheight = self.fireFlameHeight,
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
    -- Hitbox ring drawn first so it reads as ground-shadow underneath the body.
    if self.shape and self.shape.rs then
      graphics.circle(self.x, self.y, self.shape.rs, fg[0], 1)
    end

    local animation_success = self:draw_animation()

    if not animation_success then
      self:draw_fallback_animation()
    end

    -- Fire breath windup preview: red wedge matching the Breathe_Fire triangle.
    if self.state == unit_states['casting'] and self.castObject and self.castObject.name == 'fire' then
      local target = self:my_target()
      if target and not target.dead then
        local now = Helper.Time.time

        -- (Re-)init the slow-tracking preview direction at the start of each cast.
        if self.preview_cast ~= self.castObject then
          self.preview_cast = self.castObject
          self.preview_dx = target.x - self.x
          self.preview_dy = target.y - self.y
          self.preview_last_time = now
        end

        local dt = now - (self.preview_last_time or now)
        self.preview_last_time = now
        local max_rot = math.rad(self.fireRotationSpeed or 5) * dt

        local cur_angle = math.atan2(self.preview_dy, self.preview_dx)
        local desired = math.atan2(target.y - self.y, target.x - self.x)
        local diff = desired - cur_angle
        if diff > math.pi then diff = diff - 2 * math.pi
        elseif diff < -math.pi then diff = diff + 2 * math.pi end
        local rot = math.max(-max_rot, math.min(max_rot, diff))
        local new_angle = cur_angle + rot
        self.preview_dx = math.cos(new_angle)
        self.preview_dy = math.sin(new_angle)

        local fw = self.fireFlameWidth or 30
        local fh = self.fireFlameHeight or 150
        local x1, y1, x2, y2, x3, y3 = Helper.Geometry:get_triangle_from_height_and_width(
          self.x, self.y, self.x + self.preview_dx, self.y + self.preview_dy, fh, fw)
        local pct = self.castObject:get_cast_percentage() or 0
        local fill = red[0]:clone(); fill.a = 0.15 + 0.25 * math.clamp(pct, 0, 1)
        graphics.polygon({x1, y1, x2, y2, x3, y3}, fill)
      end
    elseif self.preview_cast then
      self.preview_cast = nil
    end
end

enemy_to_class['dragon'] = fns
local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  -- Set class before shape so Set_Enemy_Shape knows it's a special enemy
  self.class = 'special_enemy'

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)
  self.icon = 'archer'  -- Using goblin2 icon for now


  --set stats and cooldowns - fast attack speed for short action timer
  -- Attack speed and cast time now handled by base class

  self.baseIdleTimer = 0

  -- Set attack range and sensor
  self.attack_range = attack_ranges['big-archer']
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  -- Turret properties
  self.turret_angle = nil
  self.turret_max_arc = 160 * math.pi / 180  -- 140 degrees total arc
  self.turret_rotation_speed = 0.1 

  --set attacks
  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() return true end,
    oncast = function()
      -- Shoot in the direction the turret is facing
      self.shoot_angle = self.turret_angle
    end,
    cancel_on_range = false,
    instantspell = true,
    cast_length = 0.1,
    cast_sound = scout1,
    spellclass = DoubleShot,  -- Custom spell class for 2 bullets
    spelldata = {
      group = main.current.main,
      color = red[0],
      radius = 4,
      damage = function() return self.dmg end,
      v = 120,  -- Speed for physics-based movement
      unit = self,
      source = 'archer',
    },
  }

  table.insert(self.attack_options, shoot)
end

fns['update_enemy'] = function(self, dt)
  
  -- Update turret angle
  local center_x = gw/2
  local center_y = gh/2

  -- Default angle pointing at center
  local angle_to_center = math.atan2(center_y - self.y, center_x - self.x)

  -- Check if cursor is within arc
  local cursor = main.current.current_arena and main.current.current_arena.player_cursor
  local desired_angle = angle_to_center

  if self.turret_angle == nil then
    self.turret_angle = angle_to_center
  end

  if cursor and not cursor.dead then
    local angle_to_cursor = math.atan2(cursor.y - self.y, cursor.x - self.x)
    local angle_diff = angle_to_cursor - angle_to_center

    -- Clamp to arc limits (half arc on each side)
    local half_arc = self.turret_max_arc / 2
    if math.abs(angle_diff) <= half_arc then
      -- Cursor is within arc, aim at it
      desired_angle = angle_to_cursor
    else
      -- Cursor is outside arc, clamp to center
      desired_angle = angle_to_center
    end
  end

  -- Smoothly rotate turret toward desired angle self.turret_angle =  desired_angle
  self.turret_angle = math.lerp_angle_dt(self.turret_rotation_speed, dt, self.turret_angle, desired_angle)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end

fns['draw_fallback_custom'] = function(self)
  -- Draw the turret on top of the enemy
  graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)

  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color
  local corner_radius = get_enemy_corner_radius(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, corner_radius, corner_radius, base_color)

  -- Draw turret barrel
  if self.turret_angle then
    local barrel_length = 12
    local barrel_width = 3
    local barrel_x = self.x + math.cos(self.turret_angle) * barrel_length
    local barrel_y = self.y + math.sin(self.turret_angle) * barrel_length

    -- Draw barrel as a line
    graphics.line(self.x, self.y, barrel_x, barrel_y, grey[-2], barrel_width)

    -- Draw barrel tip
    graphics.circle(barrel_x, barrel_y, 2, grey[-4])
  end

  graphics.pop()
end
 
enemy_to_class['archer'] = fns

-- Custom spell class for shooting 2 projectiles with offsets
DoubleShot = Spell:extend()
function DoubleShot:init(args)
  DoubleShot.super.init(self, args)

  -- No target needed, we shoot based on turret angle
  self.radius = args.radius or 4
  if self.unit then 
    self.x = self.unit.x
    self.y = self.unit.y
  end

  -- Use the turret angle set by the archer
  local angle = self.unit.shoot_angle or 0

  -- Offset perpendicular to shooting direction for spread
  local offset_distance = 20  -- Distance between the two bullets
  local perp_angle = angle + math.pi/2

  -- Create first projectile with positive offset
  EnemyProjectile{
    group = self.group,
    x = self.x + math.cos(perp_angle) * offset_distance/2,
    y = self.y + math.sin(perp_angle) * offset_distance/2,
    r = angle,
    speed = self.v or 80,
    radius = self.radius or 4,
    damage = self.damage,
    color = self.color,
    unit = self.unit,
    source = self.source or 'archer',
  }

  -- Create second projectile with negative offset
  EnemyProjectile{
    group = self.group,
    x = self.x - math.cos(perp_angle) * offset_distance/2,
    y = self.y - math.sin(perp_angle) * offset_distance/2,
    r = angle,
    speed = self.v or 80,
    radius = self.radius or 4,
    damage = self.damage,
    color = self.color,
    unit = self.unit,
    source = self.source or 'archer',
  }

  -- Die immediately after creating projectiles
  self:die()
end 
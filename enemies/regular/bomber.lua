local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  -- Set class before shape so Set_Enemy_Shape knows it's a special enemy
  self.class = 'special_enemy'

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)
  self.icon = 'bomber'

  --set stats and cooldowns - fast attack speed for short action timer
  -- Attack speed and cast time now handled by base class

  self.baseIdleTimer = 0

  -- Set attack range and sensor
  self.attack_range = attack_ranges['big-archer']
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  -- No turret tracking needed - tailpipes point backwards
  self.tailpipe_offset = 5  -- Distance from center to each tailpipe

  --set attacks
  self.attack_options = {}

  local drop_bomb = {
    name = 'drop_bomb',
    viable = function() return true end,
    oncast = function()
      -- Drop bomb (no angle needed, just drops at current position)
      self.bomb_angle = 0
    end,
    cancel_on_range = false,
    instantspell = true,
    cast_length = 0.1,
    cast_sound = scout1,
    spellclass = BombDropSpell,
    spelldata = {
      group = main.current.main,
      color = orange[0],
      damage = function() return self.dmg end,
      unit = self,
      source = 'bomber',
    },
  }

  table.insert(self.attack_options, drop_bomb)
end

fns['update_enemy'] = function(self, dt)
  -- No update needed - tailpipes just follow velocity direction
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end

fns['draw_fallback_custom'] = function(self)
  -- Draw the bomber with two tailpipes pointing backwards
  graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)

  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color
  local corner_radius = get_enemy_corner_radius(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, corner_radius, corner_radius, base_color)

  -- Get velocity angle (direction of movement)
  local vx, vy = self:get_velocity()
  local velocity_angle = math.atan2(vy, vx)

  -- Tailpipes point backwards (opposite of velocity)
  local tailpipe_angle = velocity_angle + math.pi

  -- Perpendicular offset for two tailpipes
  local perp_angle = velocity_angle + math.pi / 2

  -- Draw two tailpipes
  local tailpipe_length = 12
  local tailpipe_width = 2

  -- Left tailpipe
  local left_base_x = self.x + math.cos(perp_angle) * self.tailpipe_offset
  local left_base_y = self.y + math.sin(perp_angle) * self.tailpipe_offset
  local left_end_x = left_base_x + math.cos(tailpipe_angle) * tailpipe_length
  local left_end_y = left_base_y + math.sin(tailpipe_angle) * tailpipe_length
  graphics.line(left_base_x, left_base_y, left_end_x, left_end_y, grey[-2], tailpipe_width)
  graphics.circle(left_end_x, left_end_y, 1.5, grey[-4])

  -- Right tailpipe
  local right_base_x = self.x - math.cos(perp_angle) * self.tailpipe_offset
  local right_base_y = self.y - math.sin(perp_angle) * self.tailpipe_offset
  local right_end_x = right_base_x + math.cos(tailpipe_angle) * tailpipe_length
  local right_end_y = right_base_y + math.sin(tailpipe_angle) * tailpipe_length
  graphics.line(right_base_x, right_base_y, right_end_x, right_end_y, grey[-2], tailpipe_width)
  graphics.circle(right_end_x, right_end_y, 1.5, grey[-4])

  graphics.pop()
end

enemy_to_class['bomber'] = fns

-- Custom spell class for dropping a bomb
BombDropSpell = Spell:extend()
function BombDropSpell:init(args)
  BombDropSpell.super.init(self, args)

  -- Drop bomb at unit's position
  if self.unit then
    self.x = self.unit.x
    self.y = self.unit.y
  end

  -- Use the bomb angle set by the bomber
  local angle = self.unit.bomb_angle or 0

  -- Create the bomb
  EnemyBomb{
    group = self.group,
    x = self.x,
    y = self.y,
    damage = self.damage,
    color = self.color,
    unit = self.unit,
    explosion_delay = self.explosion_delay,
    num_projectiles = self.num_projectiles,
    projectile_speed = self.projectile_speed,
    projectile_radius = self.projectile_radius,
    projectile_duration = self.projectile_duration,
  }

  -- Die immediately after creating bomb
  self:die()
end

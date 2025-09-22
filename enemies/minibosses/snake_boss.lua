local fns = {}

-- Spell definitions for snake miniboss attacks
SnakeSidewaysShot = Spell:extend()
function SnakeSidewaysShot:init(args)
  SnakeSidewaysShot.super.init(self, args)

  -- Fire from every other segment
  for i = 1, #self.unit.spawned_segments, 2 do
    local segment = self.unit.spawned_segments[i]
    if segment and not segment.dead then
      -- Calculate perpendicular angles
      local perp_angle1 = segment.r + math.pi/2
      local perp_angle2 = segment.r - math.pi/2

      -- Fire projectile to the left
      EnemyProjectile{
        group = self.group,
        x = segment.x,
        y = segment.y,
        r = perp_angle1,
        speed = 120,
        radius = 5,
        damage = self.unit.dmg * 0.5,
        color = purple[2],
        unit = self.unit,
        duration = 3,
      }

      -- Fire projectile to the right
      EnemyProjectile{
        group = self.group,
        x = segment.x,
        y = segment.y,
        r = perp_angle2,
        speed = 120,
        radius = 5,
        damage = self.unit.dmg * 0.5,
        color = purple[2],
        unit = self.unit,
        duration = 3,
      }
    end
  end

  shoot1:play{pitch = random:float(0.8, 1.0), volume = 0.4}
  self:die()
end

SnakeLaserBarrage = Spell:extend()
function SnakeLaserBarrage:init(args)
  SnakeLaserBarrage.super.init(self, args)

  -- Fire lasers starting from forward direction, then spreading outward in both directions
  Spread_Laser{
    group = main.current.main,
    unit = self.unit,
    x = self.unit.x,
    y = self.unit.y,
    spread_type = 'forward',
    starting_r = self.unit.r,  -- Start from unit's current rotation
    num_shots = 6,  -- 1 forward + 5 pairs spreading outward
    shot_interval = 0.3,  -- Delay between lasers
    charge_duration = 1.3,  -- Charge time for each laser
    fire_duration = 0.15,  -- How long each laser fires
    total_rotation = math.pi * 0.8,  -- Maximum spread angle (144 degrees total)
    both_directions = true,  -- Alternate firing left and right from center
    damage = function() return self.unit.dmg * 0.75 end,
    color = purple[5],
    laser_aim_width = 3,
    is_troop = false,
    team = 'enemy',
  }

  self:die()
end

SnakeSpeedBoost = Spell:extend()
function SnakeSpeedBoost:init(args)
  SnakeSpeedBoost.super.init(self, args)

  -- Add speed buff with 3 stacks that decay over time
  self.unit:add_buff({
    name = 'speed_boost',
    duration = 3,
    maxDuration = 1,  -- Each stack lasts 1 second
    stats = {mvspd = 0.3},  -- +25% per stack (75% total with 3 stacks)
    stacks = 3
  })

  buff1:play{pitch = random:float(0.9, 1.1), volume = 0.4}
  self:die()
end

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  -- Boss properties
  self.class = 'boss'
  self.isBoss = true  -- Mark as boss for level completion
  self.type = 'snake_boss'

  -- Create shape - long snake head
  self.color = purple[0]:clone()
  self.snake_length = 30  -- Longer head for miniboss
  self.snake_width = 20   -- Wider body

  self:set_as_rectangle(self.snake_length, self.snake_width, 'dynamic', 'ghost_enemy')
  self.icon = 'snake'
  self.name = 'Snake Lord'

  -- Movement properties
  self.haltOnPlayerContact = false
  self.stopChasingInRange = false
  self.ignoreKnockback = true
  self.bounces_off_walls = true
  self.permanent_freezerotation = true
  self.move_while_casting = true

  self.baseIdleTimer = 0

  -- Snake segment management
  self.spawned_segments = {}  -- All spawned segments
  self.max_segments = 20  -- Maximum number of segments (200 units / 20 per segment)
  self.segment_spawn_distance = 20  -- Distance between segments
  self.distance_traveled = 19  -- Start close to spawning first segment
  self.last_position = {x = self.x, y = self.y}

  -- Attack timers
  self.baseActionTimer = 2.5  -- Time between attacks

  -- Initialize angle based on spawn position
  if self.x < gw/2 then
    self.r = 0  -- Face right if spawning on left
  else
    self.r = math.pi  -- Face left if spawning on right
  end
  local offset = random:float(math.pi / 4, math.pi / 2)
  self.r = self.r + (offset * math.random(2) == 1 and 1 or -1)

  -- Attack options
  self.attack_options = {}

  -- Attack 1: Sideways projectiles from segments
  local sideways_shot = {
    name = 'sideways_shot',
    viable = function() return #self.spawned_segments > 4 end,  -- Need at least 4 segments
    oncast = function() end,
    instantspell = true,

    spellclass = SnakeSidewaysShot,
    spelldata = {
      group = main.current.main,
      unit = self,
    },
    cast_sound = scout1,
  }

  -- Attack 2: Laser barrage
  local laser_barrage = {
    name = 'laser_barrage',
    viable = function() return true end,
    oncast = function() end,
    cast_length = 0.5,
    spellclass = SnakeLaserBarrage,
    spelldata = {
      group = main.current.main,
      unit = self,
    },
    instantspell = true,
    cast_sound = laser1,
  }

  -- Attack 3: Speed boost
  local speed_boost = {
    name = 'speed_boost',
    viable = function() return not self:has_buff('speed_boost') end,  -- Only when not already boosted
    oncast = function() end,
    cast_length = 0.5,
    spellclass = SnakeSpeedBoost,
    spelldata = {
      group = main.current.main,
      unit = self,
    },
    instantspell = true,
    cast_sound = buff1,
  }

  table.insert(self.attack_options, sideways_shot)
  table.insert(self.attack_options, laser_barrage)
  table.insert(self.attack_options, speed_boost)
end

fns['update_enemy'] = function(self, dt)
  if not self.last_position then
    self.last_position = {x = self.x, y = self.y}
  end

  -- Track distance traveled
  local dist = math.distance(self.x, self.y, self.last_position.x, self.last_position.y)
  self.distance_traveled = self.distance_traveled + dist
  self.last_position = {x = self.x, y = self.y}

  -- Spawn new segment every 20 units traveled, up to max
  if self.distance_traveled >= self.segment_spawn_distance and #self.spawned_segments < self.max_segments then
    self:spawn_segment()
    self.distance_traveled = 0  -- Reset distance counter
  end

  -- Remove oldest segment if we're at max
  if #self.spawned_segments >= self.max_segments then
    local oldest_segment = table.remove(self.spawned_segments)  -- Remove from end (oldest)
    if oldest_segment and not oldest_segment.dead then
      oldest_segment:die()
    end
  end

  -- Clean up dead segments
  for i = #self.spawned_segments, 1, -1 do
    if self.spawned_segments[i] and self.spawned_segments[i].dead then
      table.remove(self.spawned_segments, i)
    end
  end

  -- Handle wall bouncing
  if self.bounces_off_walls and self.has_been_onscreen then
    self:check_wall_bounce()
  end
end

fns['spawn_segment'] = function(self)
  -- Get movement direction
  local vx, vy = self:get_velocity()
  local speed = math.sqrt(vx * vx + vy * vy)

  if speed > 0.1 then
    local dir_x = vx / speed
    local dir_y = vy / speed

    -- Place segment 15 units behind the center (half of snake_length)
    local segment_x = self.x - dir_x * 15
    local segment_y = self.y - dir_y * 15

    -- Spawn segment enemy
    local segment = Enemy{
      type = 'snake_segment',
      group = self.group,
      x = segment_x,
      y = segment_y,
      level = self.level,
      parent_snake = self,
    }

    -- Set rotation and health after creation
    if segment then
      segment.r = self.r
      segment.freezerotation = true
      segment.hp = segment.hp * 2  -- Tougher segments for miniboss
      segment.max_hp = segment.max_hp * 2
      table.insert(self.spawned_segments, 1, segment)  -- Add to front (newest)
    end
  end
end

fns['check_wall_bounce'] = function(self)
  local margin = 2
  local bounced = false

  local vx, vy = self:get_velocity()

  -- Check horizontal walls
  -- Bounce only if moving towards the wall
  if (self.y < margin and vy < 0) or (self.y > gh - margin and vy > 0) then
    self.r = -self.r  -- Flip vertical component
    self:set_velocity(vx, -vy)
    bounced = true
  end

  -- Check vertical walls
  -- Bounce only if moving towards the wall
  if (self.x < margin and vx < 0) or (self.x > gw - margin and vx > 0) then
    self.r = math.pi - self.r  -- Flip horizontal component
    self:set_velocity(-vx, vy)
    bounced = true
  end

  -- Normalize angle
  while self.r > math.pi do self.r = self.r - 2 * math.pi end
  while self.r < -math.pi do self.r = self.r + 2 * math.pi end

  if bounced then
    self:choose_movement_target()
    hit2:play({pitch = random:float(0.9, 1.1), volume = 0.3})
  end
end



fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end

fns['draw_fallback_custom'] = function(self)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color

  graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x * 1.2, self.hfx.hit.x * 1.2)

  -- Draw main body rectangle (larger for miniboss)
  graphics.rectangle(self.x, self.y, self.snake_length, self.snake_width, 4, 4, base_color)

  -- Draw pattern on body
  local pattern_color = base_color:clone()
  pattern_color = pattern_color:lighten(0.2)
  for i = -1, 1 do
    graphics.rectangle(self.x + i * 8, self.y, 4, self.snake_width * 0.6, 2, 2, pattern_color)
  end

  -- Draw head (not rotated, just offset)
  local head_x = self.x + (self.snake_length / 2)
  local head_y = self.y

  graphics.circle(head_x, head_y, 10, base_color)

  -- Draw menacing eyes
  local eye_color = red[5]:clone()
  eye_color.a = 0.9
  local eye_size = 3
  local eye_offset = 5

  -- Eyes perpendicular to direction (not rotated)
  local perp_x = 0
  local perp_y = 1

  graphics.circle(head_x + perp_x * eye_offset,
                  head_y + perp_y * eye_offset,
                  eye_size, eye_color)
  graphics.circle(head_x - perp_x * eye_offset,
                  head_y - perp_y * eye_offset,
                  eye_size, eye_color)

  graphics.pop()

  -- Draw speed boost effect
  if self:has_buff('speed_boost') then
    local boost_color = purple[8]:clone()
    boost_color.a = 0.3
    graphics.circle(self.x, self.y, 35, boost_color, 2)

    -- Motion lines
    for i = 1, 3 do
      local offset = i * 10
      local line_color = purple[5]:clone()
      line_color.a = 0.4 - i * 0.1

      graphics.line(
        self.x - math.cos(self.r) * offset,
        self.y - math.sin(self.r) * offset,
        self.x - math.cos(self.r) * (offset + 15),
        self.y - math.sin(self.r) * (offset + 15),
        line_color,
        3 - i
      )
    end
  end
end

fns['on_death'] = function(self)
  -- Kill all segments when the head dies
  for _, segment in ipairs(self.spawned_segments) do
    if segment and not segment.dead then
      segment:die()
    end
  end

  -- Death explosion
  Area{
    group = main.current.effects,
    x = self.x,
    y = self.y,
    r = 60,
    duration = 0.3,
    pick_shape = 'circle',
    damage = 0,
    color = purple[0],
  }

  explosion1:play{pitch = random:float(0.7, 0.9), volume = 0.5}
end

enemy_to_class['snake_boss'] = fns
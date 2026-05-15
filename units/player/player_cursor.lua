PlayerCursor = Troop:extend()
PlayerCursor.__class_name = 'PlayerCursor'
PLAYER_CURSOR_INVULNERABILITY_TIME = 1.25

function PlayerCursor:init(args)
  -- Set troop properties before calling parent init
  args.character = args.character or 'swordsman' -- Dummy character type
  args.level = args.level or 1
  args.no_collision = false -- Must set before parent init to ensure physics setup
  
  self.is_player_cursor = true
  -- Call parent init
  PlayerCursor.super.init(self, args)
  
  -- Override troop defaults  
  -- Reference to the orb
  self.orb = args.orb
  
  -- Position (starts at center of orb)
  self.x = self.orb.x
  self.y = self.orb.y
  
  -- Movement properties
  self.cursor_radius = 4 -- Small radius for the cursor
  self.size = self.cursor_radius * 2 -- Size used by physics setup
  
  -- Visual properties
  self.color = white[0]:clone()
  self.pulse_timer = 0
  self.scale = 1.0
  
  -- Make sure we're targetable
  self.faction = 'friendly'
  self.is_troop = true
  
  -- Override HP to redirect to orb
  self.invulnerable = false
  self.max_hp = 9999999 -- High HP so we don't die, damage redirects to orb
  
  -- After physics is set up, make it a sensor so it doesn't push enemies
  if self.fixture then
    self.fixture:setSensor(true)
  end

  self.is_dashing = false
  self.dash_cooldown = 0
  self.dash_timer = 0
  self.dash_duration = 0
  self.dash_from_x = 0
  self.dash_from_y = 0
  self.dash_to_x = 0
  self.dash_to_y = 0
  self.dash_hit_enemies = {}
  self.right_was_down = false
  self.dash_trail = {}
end

function PlayerCursor:update(dt)
  -- Don't call parent update since we override everything
  self:update_game_object(dt)

  -- Update pulse animation for visibility
  self.pulse_timer = self.pulse_timer + dt * 3
  self.scale = 1.0 + 0.2 * math.sin(self.pulse_timer)

  if self.dash_cooldown > 0 then
    self.dash_cooldown = self.dash_cooldown - dt
  end

  local right_down = love.mouse.isDown(2)
  local right_clicked = right_down and not self.right_was_down
  self.right_was_down = right_down

  if right_clicked and not self.is_dashing and self.dash_cooldown <= 0 then
    self:start_dash()
  end

  if self.is_dashing then
    self:update_dash(dt)
  else
    self:follow_mouse()
  end

  for i = #self.dash_trail, 1, -1 do
    local node = self.dash_trail[i]
    node.life = node.life - dt
    if node.life <= 0 then table.remove(self.dash_trail, i) end
  end

  -- Update attack sensor position
  if self.attack_sensor then
    self.attack_sensor:move_to(self.x, self.y)
  end
end

PLAYER_CURSOR_MAX_SPEED = 200
PLAYER_CURSOR_ARRIVAL_RADIUS = 60
PLAYER_DASH_SPEED = 2000
PLAYER_DASH_MAX_RANGE = 250
PLAYER_DASH_COOLDOWN = 0.8
PLAYER_DASH_PATH_RADIUS = 18
PLAYER_DASH_END_RADIUS = 40
PLAYER_DASH_PATH_DAMAGE = 12
PLAYER_DASH_END_DAMAGE = 25

function PlayerCursor:follow_mouse()
  local dt = love.timer.getDelta()
  local mouse_x, mouse_y = love.mouse.getPosition()
  mouse_x = mouse_x / sx
  mouse_y = mouse_y / sx

  local dx = mouse_x - self.x
  local dy = mouse_y - self.y
  local dist = math.sqrt(dx*dx + dy*dy)

  if dist > 0.5 then
    local speed = PLAYER_CURSOR_MAX_SPEED
    if dist < PLAYER_CURSOR_ARRIVAL_RADIUS then
      speed = speed * (dist / PLAYER_CURSOR_ARRIVAL_RADIUS)
    end
    local step = speed * dt
    if step > dist then step = dist end
    local nx, ny = dx / dist, dy / dist
    self.x = self.x + nx * step
    self.y = self.y + ny * step

    self.smooth_vx = (self.smooth_vx or 0) * 0.82 + (nx * step) * 0.18
    self.smooth_vy = (self.smooth_vy or 0) * 0.82 + (ny * step) * 0.18
    if self.smooth_vx*self.smooth_vx + self.smooth_vy*self.smooth_vy > 0.25 then
      self.movement_angle = math.atan2(self.smooth_vy, self.smooth_vx)
    end
  end

  self.body:setPosition(self.x, self.y)
end

function PlayerCursor:start_dash()
  local mouse_x, mouse_y = love.mouse.getPosition()
  mouse_x = mouse_x / sx
  mouse_y = mouse_y / sx
  local dx = mouse_x - self.x
  local dy = mouse_y - self.y
  local dist = math.sqrt(dx*dx + dy*dy)
  if dist < 0.5 then return end

  local range = math.min(dist, PLAYER_DASH_MAX_RANGE)
  local nx, ny = dx/dist, dy/dist
  self.dash_from_x = self.x
  self.dash_from_y = self.y
  self.dash_to_x = self.x + nx * range
  self.dash_to_y = self.y + ny * range
  self.dash_duration = range / PLAYER_DASH_SPEED
  self.dash_timer = 0
  self.dash_hit_enemies = {}
  self.is_dashing = true
  self.invulnerable = true
  self.movement_angle = math.atan2(ny, nx)
end

function PlayerCursor:update_dash(dt)
  self.dash_timer = self.dash_timer + dt
  local t = math.min(1, self.dash_timer / self.dash_duration)
  self.x = self.dash_from_x + (self.dash_to_x - self.dash_from_x) * t
  self.y = self.dash_from_y + (self.dash_to_y - self.dash_from_y) * t
  self.body:setPosition(self.x, self.y)

  table.insert(self.dash_trail, {x = self.x, y = self.y, life = 0.25, max_life = 0.25})

  self:apply_dash_path_damage()

  if t >= 1 then
    self:end_dash()
  end
end

function PlayerCursor:apply_dash_path_damage()
  if not main.current then return end
  local sensor = Circle(self.x, self.y, PLAYER_DASH_PATH_RADIUS)
  local enemies = main.current.main:get_objects_in_shape(sensor, main.current.enemies)
  for _, enemy in ipairs(enemies) do
    if enemy and not enemy.dead and not self.dash_hit_enemies[enemy] then
      self.dash_hit_enemies[enemy] = true
      enemy:hit(PLAYER_DASH_PATH_DAMAGE, self, nil, true)
    end
  end
end

function PlayerCursor:end_dash()
  self.is_dashing = false
  self.dash_cooldown = PLAYER_DASH_COOLDOWN
  self.invulnerable = false

  if main.current then
    local sensor = Circle(self.x, self.y, PLAYER_DASH_END_RADIUS)
    local enemies = main.current.main:get_objects_in_shape(sensor, main.current.enemies)
    for _, enemy in ipairs(enemies) do
      if enemy and not enemy.dead then
        enemy:hit(PLAYER_DASH_END_DAMAGE, self, nil, true)
      end
    end
  end
end

function PlayerCursor:enforce_orb_boundary()
  local dist_to_center = math.distance(self.x, self.y, self.orb.x, self.orb.y)
  local max_distance = self.orb.boundary_radius - self.cursor_radius - 2 -- Leave a small buffer
  if dist_to_center > max_distance then
    local angle = math.angle(self.orb.x, self.orb.y, self.x, self.y)
    self.x = self.orb.x + math.cos(angle) * max_distance
    self.y = self.orb.y + math.sin(angle) * max_distance
    
    -- Update physics body position to match
    if self.body then
      self.body:setPosition(self.x, self.y)
      
      -- Cancel outward velocity component to prevent sticking
      local vx, vy = self.body:getLinearVelocity()
      local radial_x = (self.x - self.orb.x) / dist_to_center
      local radial_y = (self.y - self.orb.y) / dist_to_center
      local radial_velocity = vx * radial_x + vy * radial_y
      
      if radial_velocity > 0 then
        -- Remove only the outward component
        vx = vx - radial_velocity * radial_x
        vy = vy - radial_velocity * radial_y
        self.body:setLinearVelocity(vx, vy)
      end
    end
  end
end

function PlayerCursor:draw()
  for _, node in ipairs(self.dash_trail) do
    local a = node.life / node.max_life
    local c = white[0]:clone()
    c.a = a * 0.7
    graphics.circle(node.x, node.y, PLAYER_DASH_PATH_RADIUS * a, c)
  end

  -- Draw a small white circle with glow effect
  graphics.push(self.x, self.y, 0, self.scale, self.scale)
  
  -- Outer glow
  local glow_color = self.color:clone()
  glow_color.a = 0.3
  graphics.circle(self.x, self.y, self.cursor_radius + 2, glow_color)
  
  -- Inner circle
  local inner_color = self.color:clone()
  if self.invulnerable then
    inner_color.a = 0.5
  end
  graphics.circle(self.x, self.y, self.cursor_radius, inner_color)
  
  -- Center dot
  graphics.circle(self.x, self.y, 1, self.color)
  
  graphics.pop()

  self:draw_steering_debug()
end

function PlayerCursor:on_trigger_enter(other)
  if other.touch_collision then
    local success = other:touch_collision()
    if success then
      return
    end
  end

  if other:is(Enemy) then
    self:hit(other.dmg, other, nil, true, true)
  end
end

function PlayerCursor:hit(damage, from, damageType, playHitEffects, cannotProcOnHit)
  if from and from.x ~= from.x then return end
  self:take_damage(damage)
end

function PlayerCursor:take_damage(damage)
  if self.invulnerable then return end
  -- Redirect damage to the orb
  if self.orb and not self.orb.dead then
    self.orb:hit(damage, nil, DAMAGE_TYPE_PHYSICAL)
    if damage >= 1 then
      self.invulnerable = true
      self.t:after(PLAYER_CURSOR_INVULNERABILITY_TIME, function() self.invulnerable = false end)
    end
  end
end

function PlayerCursor:die()
  -- Don't die - we're immortal and redirect damage to orb
  return
end

function PlayerCursor:do_automatic_movement()
  -- No automatic movement
end

function PlayerCursor:setup_cast(cast_target)
  -- No casting for cursor
end
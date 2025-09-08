PlayerCursor = Troop:extend()
PlayerCursor.__class_name = 'PlayerCursor'

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
end

function PlayerCursor:update(dt)
  -- Don't call parent update since we override everything
  self:update_game_object(dt)
  
  -- Update pulse animation for visibility
  self.pulse_timer = self.pulse_timer + dt * 3
  self.scale = 1.0 + 0.2 * math.sin(self.pulse_timer)
  
  self:follow_mouse()
  -- self:follow_wasd()
  -- self:enforce_orb_boundary()

  -- Update attack sensor position
  if self.attack_sensor then
    self.attack_sensor:move_to(self.x, self.y)
  end
end

function PlayerCursor:follow_mouse()
  local mouse_x, mouse_y = love.mouse.getPosition()
  mouse_x = mouse_x / sx
  mouse_y = mouse_y / sx
  self.x = mouse_x
  self.y = mouse_y
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
  -- Draw a small white circle with glow effect
  graphics.push(self.x, self.y, 0, self.scale, self.scale)
  
  -- Outer glow
  local glow_color = self.color:clone()
  glow_color.a = 0.3
  graphics.circle(self.x, self.y, self.cursor_radius + 2, glow_color)
  
  -- Inner circle
  graphics.circle(self.x, self.y, self.cursor_radius, self.color)
  
  -- Center dot
  graphics.circle(self.x, self.y, 1, self.color)
  
  graphics.pop()

  self:draw_steering_debug()
end

function PlayerCursor:hit(damage, from, damageType, playHitEffects, cannotProcOnHit)
  -- Redirect damage to the orb
  if self.orb and not self.orb.dead then
    self.orb:hit(damage, from, damageType, playHitEffects)
  end
end

function PlayerCursor:take_damage(damage)
  -- Redirect damage to the orb
  if self.orb and not self.orb.dead then
    self.orb:hit(damage, nil, DAMAGE_TYPE_PHYSICAL)
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
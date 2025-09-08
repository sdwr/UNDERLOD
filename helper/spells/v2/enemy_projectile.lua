-- Base class for all enemy projectiles
-- Provides standardized hit detection against PlayerCursor
-- and common projectile functionality

EnemyProjectile = Object:extend()
EnemyProjectile.__class_name = 'EnemyProjectile'
EnemyProjectile:implement(GameObject)
EnemyProjectile:implement(Physics)

function EnemyProjectile:init(args)
  self:init_game_object(args)
  
  -- Basic properties
  self.team = args.team or 'enemy'
  self.unit = args.unit
  self.damage = get_dmg_value(args.damage or 10)
  self.damage_type = args.damage_type or DAMAGE_TYPE_PHYSICAL
  
  -- Position and movement
  self.x = args.x or (self.unit and self.unit.x) or gw/2
  self.y = args.y or (self.unit and self.unit.y) or gh/2
  self.r = args.r or 0
  self.speed = args.speed or 100
  
  -- Collision shape
  self.radius = args.radius or 4
  self.shape = Circle(self.x, self.y, self.radius)
  
  -- Visual properties
  self.color = args.color or red[0]
  if type(self.color) == 'table' and self.color.clone then
    self.color = self.color:clone()
  end
  
  -- Lifetime
  self.duration = args.duration or 10
  self.elapsed = 0
  if self.duration > 0 then
    self.t:after(self.duration, function() self:die() end)
  end
  
  -- Hit tracking
  self.hit_cursor = false  -- Track if we've already hit the cursor
  self.pierce = args.pierce or false  -- If true, don't die on hit
  
  -- Optional properties
  self.on_hit_callback = args.on_hit_callback
  self.on_die_callback = args.on_die_callback
end

function EnemyProjectile:update(dt)
  self:update_game_object(dt)
  
  -- Update elapsed time
  self.elapsed = self.elapsed + dt
  
  -- Update movement (override in subclasses for special patterns)
  self:update_movement(dt)
  
  -- Update collision shape position
  if self.shape then
    self.shape:move_to(self.x, self.y)
  end
  
  -- Check for hits
  self:check_hits()
  
  -- Check if out of bounds
  self:check_bounds()
end

function EnemyProjectile:update_movement(dt)
  -- Default straight-line movement
  -- Override this in subclasses for special movement patterns
  self.x = self.x + self.speed * math.cos(self.r) * dt
  self.y = self.y + self.speed * math.sin(self.r) * dt
end

function EnemyProjectile:check_hits()
  -- Only check if we're an enemy projectile
  if self.team ~= 'enemy' then return end
  
  -- Check collision with player cursor
  local cursor = main.current.current_arena and main.current.current_arena.player_cursor
  if cursor and not cursor.dead and not self.hit_cursor then
    if self:collides_with_cursor(cursor) then
      -- Mark as hit (to prevent multiple hits if pierce is false)
      if not self.pierce then
        self.hit_cursor = true
      end
      
      -- Deal damage to cursor (which redirects to orb)
      cursor:hit(self.damage, self.unit, self.damage_type, true, false)
      
      -- Call custom hit callback if provided
      if self.on_hit_callback then
        self.on_hit_callback(self, cursor)
      end
      
      -- Trigger on-hit behavior
      self:on_hit_cursor(cursor)
    end
  end
end

function EnemyProjectile:collides_with_cursor(cursor)
  if not self.shape or not cursor then return false end
  
  -- Check circle-to-circle collision
  local dist = math.distance(self.x, self.y, cursor.x, cursor.y)
  local collision_distance = self.radius + (cursor.cursor_radius or 4)
  return dist <= collision_distance
end

function EnemyProjectile:on_hit_cursor(cursor)
  -- Default behavior - die on hit unless pierce is true
  if not self.pierce then
    self:die()
  end
  
  -- Override this in subclasses for special effects (explosions, etc)
end

function EnemyProjectile:check_bounds()
  -- Check if projectile is outside the arena
  if Outside_Arena and Outside_Arena(self) then
    self:die()
  elseif not Outside_Arena then
    -- Fallback bounds checking
    local margin = 50
    if self.x < -margin or self.x > gw + margin or 
       self.y < -margin or self.y > gh + margin then
      self:die()
    end
  end
end

function EnemyProjectile:draw()
  -- Default draw - simple circle
  -- Override in subclasses for custom visuals
  graphics.push(self.x, self.y, 0, self.spring and self.spring.x or 1, self.spring and self.spring.x or 1)
    graphics.circle(self.x, self.y, self.radius, self.color)
  graphics.pop()
end

function EnemyProjectile:die()
  if self.dead then return end
  self.dead = true
  
  -- Call custom die callback if provided
  if self.on_die_callback then
    self.on_die_callback(self)
  end
end
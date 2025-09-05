WipeRing = Object:extend()
WipeRing.__class_name = 'WipeRing'
WipeRing:implement(GameObject)
WipeRing:implement(Physics)

function WipeRing:init(args)
  self:init_game_object(args)
  
  -- Position and basic properties
  self.x = args.x or gw/2
  self.y = args.y or gh/2
  self.group = args.group or main.current.main
  
  -- Ring properties
  self.radius = 0
  self.max_radius = args.max_radius or math.max(gw, gh)
  self.expand_duration = args.expand_duration or 1.5
  self.timer = 0
    
  -- Visual properties
  self.ring_color = white[0]:clone()
  self.ring_color.a = 0.8
  self.glow_color = yellow[0]:clone()
  self.glow_color.a = 0.4
  
  -- Play initial sound effect
  explosion1:play{pitch = random:float(1.2, 1.4), volume = 0.8}
end

function WipeRing:update_radius(radius)
  self.radius = radius
end

function WipeRing:update(dt)
  self:update_game_object(dt)
  
  self.timer = self.timer + dt
  
  -- Expand the ring
  local progress = math.min(self.timer / self.expand_duration, 1)
  self:update_radius(progress * self.max_radius)  
  
  -- Manually check for enemies and enemy projectiles within radius
  if self.radius > 0 then
    local shape = Circle(self.x, self.y, self.radius)
    
    -- Check for enemies
    local enemies = main.current.main:get_objects_in_shape(shape, main.current.enemies)
    for _, enemy in ipairs(enemies) do
      if enemy and not enemy.dead then
        local dist = math.distance(self.x, self.y, enemy.x, enemy.y)
        if dist <= self.radius then
          enemy:die()
          explosion1:play{pitch = random:float(0.8, 1.2), volume = 0.1}
        end
      end
    end
    
    -- Check for enemy projectiles
    local enemy_projectiles = main.current.main:get_objects_in_shape(shape, main.current.enemy_projectile_classes)
    for _, projectile in ipairs(enemy_projectiles) do
      if projectile and not projectile.dead then
        local dist = math.distance(self.x, self.y, projectile.x, projectile.y)
        if dist <= self.radius then
          projectile:die()
          -- Add small visual effect
          HitParticle{group = main.current.effects, x = projectile.x, y = projectile.y, color = self.ring_color}
          explosion1:play{pitch = random:float(0.8, 1.2), volume = 0.1}
        end
      end
    end
  end
  
  -- Remove ring when expansion is complete
  if progress >= 1 then
    self.dead = true
  end
end

function WipeRing:draw()
  if self.dead then return end
  
  -- Draw expanding ring with visual effect
  -- Draw outer ring
  graphics.circle(self.x, self.y, self.radius, self.ring_color, 3)
  
  -- Draw inner glow effect
  if self.radius > 5 then
    graphics.circle(self.x, self.y, self.radius - 5, self.glow_color, 8)
  end
end
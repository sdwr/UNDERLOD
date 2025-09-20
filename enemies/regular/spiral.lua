local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  -- Set class before shape so Set_Enemy_Shape knows it's a special enemy
  self.class = 'special_enemy'

  --create shape
  self.color = purple[2]:clone()  -- Purple color for spiral enemy
  Set_Enemy_Shape(self, self.size)
  self.icon = 'spiral'
  
  self.baseIdleTimer = 0.5

  -- Set custom spiral parameters
  self.spiral_rotation_speed = 2.5  -- Faster rotation for more dramatic spiral
  self.spiral_inward_speed = 0.25   -- Slightly slower inward movement

  --set attacks
  self.attack_options = {}

  local spiral_attack = {
    name = 'spiral_shot',
    viable = function() return true end,
    oncast = function() 
      self.target = Helper.Target:get_random_enemy(self)
    end,

    instantspell = true,

    spellclass = SpiralShot,
    spelldata = {
      group = main.current.main,
      unit = self,
      target = self.target,
      x = self.x,
      y = self.y,
      color = purple[0],
      damage = function() return self.dmg end,
      speed = 120,
      parent = self
    }
  }

  table.insert(self.attack_options, spiral_attack)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    -- Draw as a spiral shape
    graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)
    
    -- Draw main body as a circle with spiral pattern
    graphics.circle(self.x, self.y, self.shape.w / 2, self.color)
    
    -- Draw spiral arms
    local num_arms = 3
    local arm_length = self.shape.w / 2
    local rotation = (Helper.Time.time or 0) * 0.5  -- Animated rotation
    
    for i = 1, num_arms do
      local base_angle = (i - 1) * (2 * math.pi / num_arms) + rotation
      
      -- Draw curved spiral arm
      local points = {self.x, self.y}
      for j = 0, 5 do
        local t = j / 5
        local radius = arm_length * (1 - t * 0.5)
        local angle = base_angle + t * math.pi / 3
        local x = self.x + math.cos(angle) * radius
        local y = self.y + math.sin(angle) * radius
        points[#points + 1] = x
        points[#points + 1] = y
      end
      
      if #points >= 4 then
        local arm_color = self.color:clone()
        arm_color = arm_color:lighten(0.3)
        graphics.polyline(arm_color, 2, unpack(points))
      end
    end
    
    graphics.pop()
    
    -- Apply status effect overlays if needed
    self:draw_fallback_status_effects()
  end
end

enemy_to_class['spiral'] = fns

-- Custom spell for spiral enemy - shoots a single homing projectile
SpiralShot = Spell:extend()
SpiralShot:implement(GameObject)
SpiralShot:implement(Physics)

function SpiralShot:init(args)
  self:init_game_object(args)
  
  self.damage = get_dmg_value(self.damage)
  
  if self.target then
    -- Create a homing projectile
    HomingProjectile{
      group = self.group,
      x = self.x,
      y = self.y,
      target = self.target,
      damage = self.damage,
      speed = self.speed,
      color = self.color,
      unit = self.unit,
      is_troop = false,
      homing_strength = 0.5  -- Moderate homing
    }
  end
  
  -- Play sound effect
  shoot1:play{pitch = random:float(1.0, 1.2), volume = 0.3}
  
  -- Die immediately after creating projectile
  self:die()
end

-- Homing projectile for spiral enemy
HomingProjectile = GameObject:extend()
HomingProjectile:implement(Physics)

function HomingProjectile:init(args)
  self:init_game_object(args)
  
  self.damage = self.damage or 10
  self.speed = self.speed or 100
  self.color = self.color or purple[0]
  self.target = self.target
  self.is_troop = self.is_troop or false
  self.homing_strength = self.homing_strength or 0.5
  
  -- Set up physics
  self:set_as_circle(4, 'dynamic', true)
  self:set_restitution(0.4)
  self:set_linear_damping(0)
  
  -- Initial velocity toward target
  if self.target then
    local angle = math.atan2(self.target.y - self.y, self.target.x - self.x)
    local vx = math.cos(angle) * self.speed
    local vy = math.sin(angle) * self.speed
    self:set_velocity(vx, vy)
    self.r = angle
  end
  
  self.already_hit_targets = {}
  self.lifetime = 5  -- Max lifetime of 5 seconds
end

function HomingProjectile:update(dt)
  self:update_game_object(dt)
  
  if self.dead then return end
  
  self.lifetime = self.lifetime - dt
  if self.lifetime <= 0 then
    self:die()
    return
  end
  
  -- Homing behavior
  if self.target and not self.target.dead then
    local current_vx, current_vy = self:get_velocity()
    local current_speed = math.sqrt(current_vx * current_vx + current_vy * current_vy)
    
    -- Calculate desired direction
    local angle_to_target = math.atan2(self.target.y - self.y, self.target.x - self.x)
    local desired_vx = math.cos(angle_to_target) * self.speed
    local desired_vy = math.sin(angle_to_target) * self.speed
    
    -- Interpolate toward desired velocity
    local new_vx = current_vx + (desired_vx - current_vx) * self.homing_strength * dt
    local new_vy = current_vy + (desired_vy - current_vy) * self.homing_strength * dt
    
    -- Maintain constant speed
    local new_speed = math.sqrt(new_vx * new_vx + new_vy * new_vy)
    if new_speed > 0 then
      new_vx = (new_vx / new_speed) * self.speed
      new_vy = (new_vy / new_speed) * self.speed
    end
    
    self:set_velocity(new_vx, new_vy)
    self.r = math.atan2(new_vy, new_vx)
  end
  
  -- Check if out of bounds
  local margin = 50
  if self.x < -margin or self.x > gw + margin or 
     self.y < -margin or self.y > gh + margin then
    self:die()
  end
end

function HomingProjectile:draw()
  if self.dead then return end
  
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
  
  -- Draw projectile as a pointed shape
  local length = 8
  local width = 4
  local points = {
    self.x + math.cos(self.r) * length,
    self.y + math.sin(self.r) * length,
    self.x + math.cos(self.r + 2.5) * width,
    self.y + math.sin(self.r + 2.5) * width,
    self.x + math.cos(self.r - 2.5) * width,
    self.y + math.sin(self.r - 2.5) * width
  }
  graphics.polygon(points, self.color)
  
  -- Trail effect
  local trail_color = self.color:clone()
  trail_color.a = 0.3
  graphics.circle(self.x - math.cos(self.r) * 6, self.y - math.sin(self.r) * 6, 3, trail_color)
  
  graphics.pop()
end

function HomingProjectile:on_trigger_enter(other)
  if other:is(Wall) then
    self:die()
  end
  
  -- Hit player units if this is an enemy projectile
  if not self.is_troop and other:is(Troop) then
    self:hit_target(other)
  end
  -- Hit enemies if this is a player projectile
  if self.is_troop and other:is(Enemy) then
    self:hit_target(other)
  end
end

function HomingProjectile:hit_target(target)
  if self.dead then return end
  if table.contains(self.already_hit_targets, target) then return end
  
  table.insert(self.already_hit_targets, target)
  
  -- Deal damage
  Helper.Damage:primary_hit(target, self.damage, self.unit, DAMAGE_TYPE_PHYSICAL, true)
  
  -- Create hit effect
  HitCircle{
    group = main.current.effects,
    x = self.x, y = self.y,
    rs = 8, color = self.color
  }
  
  -- Die after hitting
  self:die()
end
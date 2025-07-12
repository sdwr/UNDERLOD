AimProjectile_Spell = Spell:extend()
function AimProjectile_Spell:init(args)
  AimProjectile_Spell.super.init(self, args)

  self.color = self.color or red[0]
  self.aim_color = self.aim_color or red[0]
  self.aim_color = self.aim_color:clone()
  self.aim_color.a = 0.6

  self.damage = get_dmg_value(self.damage)
  self.speed = self.speed or 200
  self.radius = self.radius or 4

  -- Aim line properties
  self.aim_duration = self.aim_duration or 1.5  -- How long to show the aim line
  self.line_length = self.line_length or 300  -- Length of the aim line
  self.dash_length = self.dash_length or 8  -- Length of each dash
  self.dash_gap = self.dash_gap or 2  -- Gap between dashes
  
  -- Projectile properties
  self.num_shots = self.num_shots or 1  -- Number of projectiles to fire
  self.spread = self.spread or 0  -- Spread angle in radians
  self.delay_after_aim = self.delay_after_aim or 0.2  -- Delay after aim line disappears
  self.max_distance = self.max_distance or 500
  
  -- Calculate aim direction
  if self.target then
    self.aim_angle = math.atan2(self.target.y - self.y, self.target.x - self.x)
  else
    self.aim_angle = random:float(0, 2 * math.pi)
  end
  
  -- State tracking
  self.aim_timer = 0
  self.fired = false
  self.aim_complete = false
  
  -- Sound
  arcane1:play{pitch = random:float(0.9, 1.1), volume = 0.3}
end

function AimProjectile_Spell:update(dt)
  AimProjectile_Spell.super.update(self, dt)
  
  if not self.fired then
    self.aim_timer = self.aim_timer + dt
    
    -- Show aim line
    if self.aim_timer <= self.aim_duration then
      -- Still aiming
    else
      -- Aim complete, fire projectiles after delay
      if not self.aim_complete then
        self.aim_complete = true
        self.t:after(self.delay_after_aim, function()
          self:fire_projectiles()
        end)
      end
    end
  end
end

function AimProjectile_Spell:fire_projectiles()
  if self.fired then return end
  self.fired = true
  
  -- Calculate spread angles
  local base_angle = self.aim_angle
  local angles = {}
  
  if self.num_shots == 1 then
    angles = {base_angle}
  else
    local total_spread = self.spread
    local angle_step = total_spread / (self.num_shots - 1)
    local start_angle = base_angle - total_spread / 2
    
    for i = 1, self.num_shots do
      local angle = start_angle + (i - 1) * angle_step
      table.insert(angles, angle)
    end
  end
  
  -- Fire projectiles
  for i, angle in ipairs(angles) do
    -- Create a dummy target at the angle for the existing ArrowProjectile
    local target_distance = 100
    local target_x = self.x + math.cos(angle) * target_distance
    local target_y = self.y + math.sin(angle) * target_distance
    
    ArrowProjectile{
      group = main.current.main,
      unit = self.unit,
      team = "enemy",
      x = self.x,
      y = self.y,
      target = {x = target_x, y = target_y},
      max_distance = self.max_distance,
      speed = self.speed,
      damage = self.damage,
      color = self.color,
      level = self.level,
    }
  end
  
  -- Die after firing
  self:die()
end

function AimProjectile_Spell:draw()
  if self.fired then return end
  
  -- Draw dashed aim line
  if self.aim_timer <= self.aim_duration then
    self:draw_aim_line()
  end
end

function AimProjectile_Spell:draw_aim_line()
  -- Calculate spread angles (same logic as in fire_projectiles)
  local base_angle = self.aim_angle
  local angles = {}
  
  if self.num_shots == 1 then
    angles = {base_angle}
  else
    local total_spread = self.spread
    local angle_step = total_spread / (self.num_shots - 1)
    local start_angle = base_angle - total_spread / 2
    
    for i = 1, self.num_shots do
      local angle = start_angle + (i - 1) * angle_step
      table.insert(angles, angle)
    end
  end
  
  -- Draw aim line for each projectile
  for i, angle in ipairs(angles) do
    self:draw_single_aim_line(angle)
  end
end

function AimProjectile_Spell:draw_single_aim_line(angle)
  local start_x, start_y = self.x, self.y
  local end_x = start_x + math.cos(angle) * self.line_length
  local end_y = start_y + math.sin(angle) * self.line_length
  
  -- Draw dashed line with more fill, less space
  local dx = end_x - start_x
  local dy = end_y - start_y
  local distance = math.sqrt(dx * dx + dy * dy)
  local dash_length = self.dash_length * 1.5  -- Longer dashes
  local dash_gap = self.dash_gap * 0.3  -- Shorter gaps
  local total_dash_length = dash_length + dash_gap
  
  local current_distance = 0
  local dash_phase = 0  -- 0 = dash, 1 = gap
  
  while current_distance < distance do
    local segment_length = math.min(total_dash_length, distance - current_distance)
    
    if dash_phase == 0 then
      -- Draw dash
      local dash_end = math.min(dash_length, segment_length)
      local dash_end_x = start_x + math.cos(angle) * (current_distance + dash_end)
      local dash_end_y = start_y + math.sin(angle) * (current_distance + dash_end)
      
      
      graphics.line(start_x + math.cos(angle) * current_distance, 
                   start_y + math.sin(angle) * current_distance,
                   dash_end_x, dash_end_y, self.aim_color, 2)
    end
    
    current_distance = current_distance + segment_length
    dash_phase = (dash_phase + 1) % 2
  end
end

function AimProjectile_Spell:die()
  AimProjectile_Spell.super.die(self)
end 
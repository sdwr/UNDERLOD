Cleave = Object:extend()
Cleave:implement(GameObject)

function Cleave:init(args)
    self:init_game_object(args) -- Loads properties from spelldata

    -- Define default values for the cleave
    self.is_troop = false
    self.damage = get_dmg_value(self.damage)
    self.cone_radius = self.cone_radius or 40 -- The length of the cone
    self.cone_angle = self.cone_angle or math.pi / 2 
    self.knockback_force = self.knockback_force or LAUNCH_PUSH_FORCE_ENEMY
    self.knockback_duration = self.knockback_duration or KNOCKBACK_DURATION_ENEMY
    self.duration = self.duration or 0.15 -- How long the visual stays on screen
    self.color = self.color or red[0]
    self.color_transparent = self.color:clone()
    self.color_transparent.a = 0.3

    self.attack_sensor = Circle(self.x, self.y, self.cone_radius)

    -- The spell needs a caster (unit) and a target to determine its direction
    if not self.unit or not self.target then
        self:die()
        return
    end

    -- Determine the center angle of the cone, pointing from the caster to the target
    self.angle = self.unit:angle_to_object(self.target)

    -- Create the visual mesh for the cone
    self.mesh = self:create_cone_mesh()

    -- Track units that have been affected to avoid hitting them multiple times
    self.affected_units = {}

    -- Set a timer for the visual to disappear
    self.time_elapsed = 0
end

function Cleave:apply_effects()
  local potential_targets = {}
  if self.is_troop then
    potential_targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies)
  else
    potential_targets = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.friendlies)
  end

  local angle_start = self.angle - (self.cone_angle / 2)
  local angle_end = self.angle + (self.cone_angle / 2)
  
  -- Calculate current cone radius based on progress
  local progress = self.time_elapsed / self.duration
  local current_radius = self.cone_radius * progress

  for _, target in ipairs(potential_targets) do
    -- Skip if already affected
    if not self.affected_units[target] then
      local angle_to_target = self.unit:angle_to_object(target)
      local distance_to_target = self.unit:distance_to_object(target)
      
      -- Check if the target is within the current cone radius and angle
      if Helper.Geometry:is_angle_between(angle_to_target, angle_start, angle_end) and distance_to_target <= current_radius then
        -- Target is inside the current cone, apply effects!
        target:hit(self.damage, self.unit)
        target:push(self.knockback_force, angle_to_target, nil, self.knockback_duration)
        
        -- Mark as affected to avoid hitting again
        self.affected_units[target] = true
      end
    end
  end
end

function Cleave:create_cone_mesh()
  local vertices = {}
  
  -- Prepare the color components. The Mesh function expects numbers from 0-255.
  local r, g, b, a = self.color_transparent[1], self.color_transparent[2], self.color_transparent[3], self.color_transparent[4] or 255

  -- The center of the cone is at the caster's position
  -- FIX 1: Unpack the color into four separate numbers (r, g, b, a)
  table.insert(vertices, {self.unit.x, self.unit.y, 0, 0, r, g, b, a})

  local segments = 20
  local angle_step = self.cone_angle / segments
  
  -- FIX 2: Calculate the starting angle for the cone's arc
  local angle_start = self.angle - (self.cone_angle / 2)

  for i = 0, segments do
      local current_angle = angle_start + (i * angle_step)
      local vx = self.unit.x + self.cone_radius * math.cos(current_angle)
      local vy = self.unit.y + self.cone_radius * math.sin(current_angle)
      
      -- Also use the unpacked color components here
      table.insert(vertices, {vx, vy, 0, 0, r, g, b, a})
  end

  -- Create the mesh with the correctly formatted vertex data
  return love.graphics.newMesh(vertices, "fan")
end

function Cleave:update(dt)
  self:update_game_object(dt) 
  self.time_elapsed = self.time_elapsed + dt
  
  -- Apply effects progressively as the cone grows
  self:apply_effects()
  
  if self.time_elapsed > self.duration then
    self:die()
  end
end

function Cleave:draw()
    if self.mesh then
        graphics.push(self.x, self.y, 0)
        
        -- Calculate the growth progress (0 to 1)
        local progress = self.time_elapsed / self.duration
        
        -- Use draw_with_mask to create the growing cone effect
        local draw_cone = function()
            graphics.set_color(self.color_transparent)
            love.graphics.draw(self.mesh)
        end
        
        local draw_mask = function()
            -- Draw a growing circle mask
            local current_radius = self.cone_radius * progress
            graphics.circle(self.unit.x, self.unit.y, current_radius, self.color_transparent)
        end
        
        graphics.draw_with_mask(draw_cone, draw_mask)
        
        graphics.pop()
    end
end

function Cleave:die()
    self.dead = true
end
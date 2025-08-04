-----------------------------------------------------------
--[[
  ChainSpell
  A generic game object for creating spells and effects that chain between targets.

  Handles the core logic of:
  - Finding subsequent targets within a specified range.
  - Chaining from one target to the next with a configurable delay.
  - Tracking which targets have been hit to prevent infinite loops.
  - Terminating when the maximum number of chains is reached or no new targets are found.

  To use this, you should extend it and provide implementations for the
  'on_hit' and 'on_bounce' effects in the constructor arguments.
--]]
ChainSpell = Object:extend()
ChainSpell:implement(GameObject)
ChainSpell:implement(Physics)

function ChainSpell:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end

  -- Parameters for configuration by subclasses.
  self.caster = args.parent                      -- The object that originally cast the spell.
  self.source = args.source or args.parent       -- The object that the current chain link starts from.
  self.initial_target = args.target              -- The first target to be hit.
  self.max_chains = args.max_chains or 5         -- Maximum number of bounces.
  self.range = args.range or 50                -- The radius to search for the next target.
  self.delay = args.delay or 0.15                -- The time in seconds between each chain link.
  self.target_classes = args.target_classes or {}-- Table of classes to consider valid targets (e.g., main.current.enemies).
  self.target_condition = args.target_condition or function() return true end
  self.skip_first_bounce = args.skip_first_bounce or false -- Skip bounce effect from parent to first target

  -- Callback functions to be defined by the spell implementation.
  -- on_hit(spell, target): Action to perform on the target (e.g., deal damage).
  self.on_hit = args.on_hit
  -- on_bounce(spell, from_target, to_target): Action to perform for the visual/audio effect between links.
  self.on_bounce = args.on_bounce

  -- Internal state management.
  self.targets = {self.initial_target}  -- A list of targets to be hit. Grows dynamically.
  self.hit_targets = {}                 -- A hash map to track targets that have already been hit.
  self.current_index = 0                -- The index of the current target in the self.targets list.
  -- Set last_target based on skip_first_bounce flag
  if self.skip_first_bounce then
    self.last_target = nil  -- No initial source for first bounce
  else
    self.last_target = self.source  -- The source of the current chain link
  end

  -- Initiate the chaining process. We use a timer to avoid blocking the main thread
  -- and to handle the delay between bounces.
  self:process_next_link()
end

function ChainSpell:process_next_link()
  self.current_index = self.current_index + 1

  -- ## Termination Conditions ##
  -- 1. We've exceeded the maximum number of chains.
  -- 2. We've run out of targets in our list.
  if self.current_index > self.max_chains or self.current_index > #self.targets then
    self:die()
    return
  end

  local current_target = self.targets[self.current_index]

  -- 3. The current target is no longer valid (e.g., it's dead or nil).
  if not current_target or current_target.dead then
    self:die() -- End the chain if a link is broken.
    return
  end

  -- ## Process the Target ##
  -- This check prevents re-hitting a target if it somehow ends up in the queue twice.
  if not self.hit_targets[current_target] then
    -- Mark the target as hit to prevent it from being targeted again.
    self.hit_targets[current_target] = true

    -- 1. Apply the spell's effect to the target.
    if self.on_hit then
      self:on_hit(current_target)
    end

    -- 2. Trigger the visual/audio effect for the bounce.
    if self.on_bounce and self.last_target then
      self:on_bounce(self.last_target, current_target)
    end

    -- 3. Find all valid new targets around the current one for the next link.
    self:find_next_targets(current_target)

    -- 4. The current target becomes the starting point for the next bounce.
    self.last_target = current_target
  end

  -- Schedule the next link in the chain if we haven't reached the end.
  if self.current_index < #self.targets and self.current_index < self.max_chains then
    self.t:after(self.delay, function() self:process_next_link() end)
  else
    -- No more targets to jump to.
    self:die()
  end
end

function ChainSpell:find_next_targets(from_target)
  local search_sensor = Circle(from_target.x, from_target.y, self.range)
  local potential_targets = self:get_objects_in_shape(search_sensor, self.target_classes)

  for _, p_target in ipairs(potential_targets) do
    -- Stop looking if we've already queued up the maximum number of targets.
    if #self.targets >= self.max_chains then break end

    -- Add the target if it hasn't been hit yet.
    -- Our main loop (`process_next_link`) already checks `hit_targets`, but checking
    -- here too prevents adding useless entries to the `targets` list.
    if not self.hit_targets[p_target] and self.target_condition(p_target) then
        table.insert(self.targets, p_target)
    end
  end
end

function ChainSpell:update(dt)
  -- The base GameObject update handles timer updates (`self.t`).
  self:update_game_object(dt)
end

function ChainSpell:draw()
  -- Drawing is typically handled by the `on_bounce` callback, e.g., creating a LightningLine effect.
end

function ChainSpell:die()
  self.dead = true
end

--[[
  ChainLightning
  An implementation of ChainSpell for a classic lightning effect.
  This object primarily serves to configure and launch the generic ChainSpell.
--]]
ChainLightning = ChainSpell:extend()

function ChainLightning:init(args)
  -- 1. Define lightning-specific parameters.
  self.group = args.group or main.current.main
  self.target = args.target
  self.caster = args.parent
  self.source = args.source or args.parent
  self.range = args.range or 50
  self.is_troop = args.is_troop or false
  self.damage = get_dmg_value(args.damage)
  self.damageType = args.damageType or DAMAGE_TYPE_SHOCK
  self.color = args.color or {1, 1, 1, 1}

  -- Define the enemy/friendly targeting logic.
  local target_classes
  if not self.is_troop then
    target_classes = main.current.friendlies
  else
    target_classes = main.current.enemies
  end

  -- 2. Create the configuration table for the base ChainSpell.
  local spell_args = {
    group = self.group,
    parent = self.caster,
    target = self.target,
    max_chains = SHOCK_MAX_CHAINS,
    range = self.range, -- Use the radius specified in the original arguments
    target_classes = target_classes,
    skip_first_bounce = true, -- Skip lightning line from parent to first target

    -- ## Define Callbacks ##

    -- on_hit: This function is called on each target in the chain.
    on_hit = function(spell, target)
      -- 'spell' is the ChainLightning instance. 'self' would also work here.
      target:hit(self.damage, nil, self.damageType, false, true)
    end,

    -- on_bounce: This function creates the visual and audio effects between targets.
    on_bounce = function(spell, from_target, to_target)
      spark2:play{pitch = random:float(0.8, 1.2), volume = 0.4}
      -- The LightningLine effect is a separate, temporary object.
      LightningLine{
        group = main.current.effects,
        src = from_target,
        dst = to_target,
        color = self.color
      }
    end
  }

  -- 3. Initialize the base ChainSpell with our configuration.
  -- This will automatically start the chaining logic.
  ChainSpell.init(self, spell_args)
end

--[[
  ChainHeal
  An implementation of ChainSpell that heals friendly targets.
--]]
ChainHeal = ChainSpell:extend()

function ChainHeal:init(args)
  -- 1. Define heal-specific parameters
  self.group = args.group or main.current.main
  self.target = args.target
  self.caster = args.parent
  self.source = args.source or args.parent
  self.range = args.range or 50
  self.heal_amount = args.heal_amount or 10
  self.time_between_bounces = args.time_between_bounces or 0.3
  self.is_troop = args.is_troop or false
  self.color = args.color or {0.2, 0.9, 0.3, 1} -- Healing green

  -- Define the targeting logic to ONLY hit friendlies.
  local target_classes
  if not self.is_troop then
    target_classes = main.current.enemies -- Assuming enemies healing enemies
  else
    target_classes = main.current.friendlies -- Assuming troops healing friendlies
  end

  local target_condition = function(target)
    return target.hp < target.max_hp
  end

  -- 2. Create the configuration table for the base ChainSpell.
  local spell_args = {
    group = self.group,
    parent = self.caster,
    target = self.target,
    max_chains = args.max_chains or 4,
    delay = self.time_between_bounces,
    range = self.range,
    target_classes = target_classes,

    -- ## Define Callbacks ##

    -- on_hit: This function is called on each target in the chain.
    on_hit = function(spell, target)
      -- Assuming targets have a 'heal' method or we can add health directly.
      if target.heal then
        target:heal(self.heal_amount)
      else
        target.hp = math.min(target.max_hp, target.hp + self.heal_amount)
      end
    end,

    -- on_bounce: This function creates the visual and audio effects.
    on_bounce = function(spell, from_target, to_target)
      -- Play a gentle sound for healing
      heal1:play{pitch = random:float(0.9, 1.1), volume = 0.3}
      
      -- Create our new HealLine effect
      HealLine{
        group = main.current.effects,
        src = from_target,
        dst = to_target,
        color = self.color
      }
    end
  }

  -- 3. Initialize the base ChainSpell with our configuration.
  ChainSpell.init(self, spell_args)
end

--[[
  ChainCurse
  An implementation of ChainSpell for a dark curse effect.
  This object primarily serves to configure and launch the generic ChainSpell.
--]]
ChainCurse = ChainSpell:extend()

function ChainCurse:init(args)
  -- 1. Define curse-specific parameters.
  self.group = args.group or main.current.main
  self.target = args.target
  self.caster = args.parent
  self.source = args.source or args.parent
  self.range = args.range or 50
  self.is_troop = args.is_troop or false
  self.curse_data = args.curse_data or {name = 'curse', duration = 3, color = purple[0], stats = {percent_def = -0.4}}
  self.primary_color = args.primary_color or purple[-3] -- Dark purple
  self.secondary_color = args.secondary_color or black[0] -- Black

  self.primary_color.a = 0.8
  self.secondary_color.a = 0.3

  self.delay = args.delay or 0.5
  -- Define the enemy/friendly targeting logic.
  local target_classes
  if not self.is_troop then
    target_classes = main.current.friendlies
  else
    target_classes = main.current.enemies
  end

  -- 2. Create the configuration table for the base ChainSpell.
  local spell_args = {
    group = self.group,
    parent = self.caster,
    target = self.target,
    max_chains = args.max_chains or 4,
    range = self.range,
    target_classes = target_classes,
    skip_first_bounce = false, -- Skip curse line from parent to first target
    delay = self.delay,
    -- ## Define Callbacks ##

    -- on_hit: This function is called on each target in the chain.
    on_hit = function(spell, target)
      -- Apply curse debuff to the target
      target:curse(spell.caster)
    end,

    -- on_bounce: This function creates the visual and audio effects between targets.
    on_bounce = function(spell, from_target, to_target)
      wizard1:play{pitch = random:float(0.9, 1.1), volume = 0.4}
      -- The CurseLine effect is a separate, temporary object.
      CurseLine{
        group = main.current.effects,
        src = from_target,
        dst = to_target,
        primary_color = self.primary_color,
        secondary_color = self.secondary_color,
        duration = 0.6
      }
    end
  }

  -- 3. Initialize the base ChainSpell with our configuration.
  -- This will automatically start the chaining logic.
  ChainSpell.init(self, spell_args)
end




--line effects

LightningLine = Object:extend()
LightningLine:implement(GameObject)
function LightningLine:init(args)
  self:init_game_object(args)
  self.lines = {}
  table.insert(self.lines, {x1 = self.src.x, y1 = self.src.y, x2 = self.dst.x, y2 = self.dst.y})
  self.w = 3
  self.generations = args.generations or 3
  self.max_offset = args.max_offset or 8
  self.duration = args.duration or 0.067 -- Reduce by 33%
  self:generate()
  self.t:tween(self.duration, self, {w = 1}, math.linear, function() self.dead = true end)
  
  self.color = args.color or blue[0]
  self.color = self.color:clone()
  self.color.a = 0.5

  self.hit_circle_radius = args.hit_circle_radius or 3

  HitCircle{group = main.current.effects, x = self.src.x, y = self.src.y, rs = self.hit_circle_radius, color = fg[0], duration = self.duration}
  for i = 1, 2 do HitParticle{group = main.current.effects, x = self.src.x, y = self.src.y, color = self.color} end
  HitCircle{group = main.current.effects, x = self.dst.x, y = self.dst.y, rs = self.hit_circle_radius, color = fg[0], duration = self.duration}
  HitParticle{group = main.current.effects, x = self.dst.x, y = self.dst.y, color = self.color}
end


function LightningLine:update(dt)
  self:update_game_object(dt)
end


function LightningLine:draw()
  graphics.polyline(self.color, self.w, unpack(self.points))
end


function LightningLine:generate()
  local offset_amount = self.max_offset
  local lines = self.lines

  for j = 1, self.generations do
    for i = #self.lines, 1, -1 do
      local x1, y1 = self.lines[i].x1, self.lines[i].y1
      local x2, y2 = self.lines[i].x2, self.lines[i].y2
      table.remove(self.lines, i)

      local x, y = (x1+x2)/2, (y1+y2)/2
      local p = Vector(x2-x1, y2-y1):normalize():perpendicular()
      x = x + p.x*random:float(-offset_amount, offset_amount)
      y = y + p.y*random:float(-offset_amount, offset_amount)
      table.insert(self.lines, {x1 = x1, y1 = y1, x2 = x, y2 = y})
      table.insert(self.lines, {x1 = x, y1 = y, x2 = x2, y2 = y2})
    end
    offset_amount = offset_amount/2
  end

  self.points = {}
  while #self.lines > 0 do
    local min_d, min_i = 1000000, 0
    for i, line in ipairs(self.lines) do
      local d = math.distance(self.src.x, self.src.y, line.x1, line.y1)
      if d < min_d then
        min_d = d
        min_i = i
      end
    end
    local line = table.remove(self.lines, min_i)
    if line then
      table.insert(self.points, line.x1)
      table.insert(self.points, line.y1)
    end
  end
end

--[[
  HealLine
  A visual effect for a flowing line of healing energy between two points.
  Similar to LightningLine, but with a distinct visual style for healing.
--]]
HealLine = Object:extend()
HealLine:implement(GameObject)

function HealLine:init(args)
  self:init_game_object(args)
  self.src = args.src
  self.dst = args.dst
  self.duration = args.duration or 0.3
  self.w = args.w or 4
  self.color = args.color or green[0]
  self.color = self.color:clone()
  self.color.a = 0.7
  
  -- Healing-specific parameters
  self.flow_segments = args.flow_segments or math.random(4, 8)
  self.flow_amplitude = args.flow_amplitude or 3
  self.healing_particles = args.healing_particles or 5
  
  -- Generate the flowing path
  self:generate_flowing_path()
  
  -- Animate the line width for a "pulse" effect
  self.t:tween(self.duration, self, {w = 1}, math.linear, function() self.dead = true end)
  
  -- Create healing circles at both ends
  HealCircle{group = main.current.effects, x = self.src.x, y = self.src.y, rs = 8, color = self.color, duration = self.duration}
  HealCircle{group = main.current.effects, x = self.dst.x, y = self.dst.y, rs = 8, color = self.color, duration = self.duration}
  
  -- Add flowing healing particles along the path
  for i = 1, self.healing_particles do
    local t = (i - 1) / (self.healing_particles - 1)
    local point = self:get_point_at_time(t)
    HealingParticle{
      group = main.current.effects,
      x = point.x,
      y = point.y,
      color = self.color,
      v = random:float(20, 40),
      duration = self.duration * 0.8
    }
  end
  
  -- Add extra particles at the destination
  for i = 1, 3 do
    HealingParticle{
      group = main.current.effects,
      x = self.dst.x + random:float(-5, 5),
      y = self.dst.y + random:float(-5, 5),
      color = self.color,
      v = random:float(15, 30),
      duration = 0.4
    }
  end
end

function HealLine:generate_flowing_path()
  self.path_points = {}
  
  -- Start with the source point
  table.insert(self.path_points, {x = self.src.x, y = self.src.y})
  
  -- Generate flowing intermediate points
  for i = 1, self.flow_segments do
    local t = i / (self.flow_segments + 1)
    local base_x = self.src.x + (self.dst.x - self.src.x) * t
    local base_y = self.src.y + (self.dst.y - self.src.y) * t
    
    -- Add perpendicular offset for flowing effect
    local dx = self.dst.x - self.src.x
    local dy = self.dst.y - self.src.y
    local length = math.sqrt(dx * dx + dy * dy)
    
    if length > 0 then
      local perp_x = -dy / length
      local perp_y = dx / length
      
      -- Use sine wave for smooth flowing motion
      local offset = math.sin(t * math.pi * 2) * self.flow_amplitude
      
      local x = base_x + perp_x * offset
      local y = base_y + perp_y * offset
      
      table.insert(self.path_points, {x = x, y = y})
    end
  end
  
  -- End with the destination point
  table.insert(self.path_points, {x = self.dst.x, y = self.dst.y})
end

function HealLine:get_point_at_time(t)
  if #self.path_points <= 1 then
    return {x = self.src.x, y = self.src.y}
  end
  
  local segment_count = #self.path_points - 1
  local segment_index = math.floor(t * segment_count)
  local segment_t = (t * segment_count) - segment_index
  
  segment_index = math.min(segment_index, segment_count - 1)
  
  local p1 = self.path_points[segment_index + 1]
  local p2 = self.path_points[segment_index + 2]
  
  return {
    x = p1.x + (p2.x - p1.x) * segment_t,
    y = p1.y + (p2.y - p1.y) * segment_t
  }
end

function HealLine:update(dt)
  self:update_game_object(dt)
end

function HealLine:draw()
  if #self.path_points < 2 then return end
  
  -- Draw the flowing healing line
  love.graphics.setLineWidth(self.w)
  love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
  
  -- Draw the path as a series of connected lines
  for i = 1, #self.path_points - 1 do
    local p1 = self.path_points[i]
    local p2 = self.path_points[i + 1]
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
  end
  
  love.graphics.setLineWidth(1)
end

--[[
  HealCircle
  A gentle healing circle effect for the endpoints of healing chains.
--]]
HealCircle = Object:extend()
HealCircle:implement(GameObject)

function HealCircle:init(args)
  self:init_game_object(args)
  self.rs = args.rs or 8
  self.color = args.color or green[0]
  self.duration = args.duration or 0.3
  
  -- Animate the circle size
  self.t:tween(self.duration, self, {rs = 2}, math.linear, function() self.dead = true end)
end

function HealCircle:update(dt)
  self:update_game_object(dt)
end

function HealCircle:draw()
  love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a * 0.6)
  love.graphics.circle('line', self.x, self.y, self.rs)
end

--[[
  HealingParticle
  A gentle particle effect for healing spells.
--]]
HealingParticle = Object:extend()
HealingParticle:implement(GameObject)

function HealingParticle:init(args)
  self:init_game_object(args)
  self.v = args.v or 30
  self.color = args.color or green[0]
  self.duration = args.duration or 0.3
  
  -- Gentle upward motion with some randomness
  self.vx = random:float(-10, 10)
  self.vy = -self.v + random:float(-10, 10)
  
  -- Track the initial time for alpha calculation
  self.start_time = 0
  
  -- Animate the particle fading
  self.t:tween(self.duration, self, {vx = 0, vy = 0}, math.linear, function() self.dead = true end)
end

function HealingParticle:update(dt)
  self:update_game_object(dt)
  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt
  self.start_time = self.start_time + dt
end

function HealingParticle:draw()
  local alpha = 1 - (self.start_time / self.duration)
  alpha = math.max(0, math.min(1, alpha))
  love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a * alpha)
  love.graphics.circle('fill', self.x, self.y, 2)
end

--[[
  CurseLine
  A visual effect for a dark curse line between two points.
  Creates a sinister black and purple line with dark particles.
--]]
CurseLine = Object:extend()
CurseLine:implement(GameObject)

function CurseLine:init(args)
  self:init_game_object(args)
  self.src = args.src
  self.dst = args.dst
  self.duration = args.duration or 0.4
  self.w = args.w or 3
  self.primary_color = args.primary_color or purple[-3]
  self.secondary_color = args.secondary_color or black[0]
  
  -- Curse-specific parameters
  self.segments = args.segments or math.random(6, 10)
  self.max_offset = args.max_offset or 6
  self.curse_particles = args.curse_particles or 4
  
  -- Generate the cursed path
  self:generate_cursed_path()
  
  -- Animate the line width for a "dark pulse" effect
  self.t:tween(self.duration, self, {w = 1}, math.linear, function() self.dead = true end)
  
  -- Create dark circles at both ends
  CurseCircle{group = main.current.effects, x = self.src.x, y = self.src.y, rs = 6, color = self.primary_color, duration = self.duration}
  CurseCircle{group = main.current.effects, x = self.dst.x, y = self.dst.y, rs = 6, color = self.primary_color, duration = self.duration}
  
  
  -- Add dark curse particles along the path
  for i = 1, self.curse_particles do
    local t = (i - 1) / (self.curse_particles - 1)
    local point = self:get_point_at_time(t)
    CurseParticle{
      group = main.current.effects,
      x = point.x,
      y = point.y,
      color = self.primary_color,
      v = random:float(15, 35),
      duration = self.duration * 0.9
    }
  end
  
  -- Add extra dark particles at the destination
  for i = 1, 2 do
    CurseParticle{
      group = main.current.effects,
      x = self.dst.x + random:float(-4, 4),
      y = self.dst.y + random:float(-4, 4),
      color = self.primary_color,
      v = random:float(10, 25),
      duration = 0.5
    }
  end
end

function CurseLine:generate_cursed_path()
  self.path_points = {}
  
  -- Start with the source point
  table.insert(self.path_points, {x = self.src.x, y = self.src.y})
  
  -- Generate cursed intermediate points with dark, jagged motion
  for i = 1, self.segments do
    local t = i / (self.segments + 1)
    local base_x = self.src.x + (self.dst.x - self.src.x) * t
    local base_y = self.src.y + (self.dst.y - self.src.y) * t
    
    -- Add perpendicular offset for dark, jagged effect
    local dx = self.dst.x - self.src.x
    local dy = self.dst.y - self.src.y
    local length = math.sqrt(dx * dx + dy * dy)
    
    if length > 0 then
      local perp_x = -dy / length
      local perp_y = dx / length
      
      -- Use sawtooth wave for jagged, dark motion
      local offset = math.sin(t * math.pi * 3) * math.cos(t * math.pi * 2) * self.max_offset
      
      local x = base_x + perp_x * offset
      local y = base_y + perp_y * offset
      
      table.insert(self.path_points, {x = x, y = y})
    end
  end
  
  -- End with the destination point
  table.insert(self.path_points, {x = self.dst.x, y = self.dst.y})
end

function CurseLine:get_point_at_time(t)
  if #self.path_points <= 1 then
    return {x = self.src.x, y = self.src.y}
  end
  
  local segment_count = #self.path_points - 1
  local segment_index = math.floor(t * segment_count)
  local segment_t = (t * segment_count) - segment_index
  
  segment_index = math.min(segment_index, segment_count - 1)
  
  local p1 = self.path_points[segment_index + 1]
  local p2 = self.path_points[segment_index + 2]
  
  return {
    x = p1.x + (p2.x - p1.x) * segment_t,
    y = p1.y + (p2.y - p1.y) * segment_t
  }
end

function CurseLine:update(dt)
  self:update_game_object(dt)
end

function CurseLine:draw()
  if #self.path_points < 2 then return end
  
  -- Draw secondary color lines first (background)
  for i = 1, #self.path_points - 1 do
    local p1 = self.path_points[i]
    local p2 = self.path_points[i + 1]
    graphics.line(p1.x, p1.y, p2.x, p2.y, self.secondary_color, self.w + 1)
  end
  
  -- Draw primary color lines on top (foreground)
  for i = 1, #self.path_points - 1 do
    local p1 = self.path_points[i]
    local p2 = self.path_points[i + 1]
    graphics.line(p1.x, p1.y, p2.x, p2.y, self.primary_color, self.w)
  end
end

--[[
  CurseCircle
  A dark circle effect for the endpoints of curse lines.
--]]
CurseCircle = Object:extend()
CurseCircle:implement(GameObject)

function CurseCircle:init(args)
  self:init_game_object(args)
  self.rs = args.rs or 6
  self.color = args.color or purple[-3]
  self.duration = args.duration or 0.4
  
  -- Animate the circle size
  self.t:tween(self.duration, self, {rs = 1}, math.linear, function() self.dead = true end)
end

function CurseCircle:update(dt)
  self:update_game_object(dt)
end

function CurseCircle:draw()
  local color = self.color:clone()
  color.a = color.a * 0.7
  graphics.circle(self.x, self.y, self.rs, color, 1)
end

--[[
  CurseParticle
  A dark particle effect for curse spells.
--]]
CurseParticle = Object:extend()
CurseParticle:implement(GameObject)

function CurseParticle:init(args)
  self:init_game_object(args)
  self.v = args.v or 25
  self.color = args.color or purple[-3]
  self.duration = args.duration or 0.4
  
  -- Dark downward motion with some randomness
  self.vx = random:float(-8, 8)
  self.vy = self.v + random:float(-8, 8)
  
  -- Track the initial time for alpha calculation
  self.start_time = 0
  
  -- Animate the particle fading
  self.t:tween(self.duration, self, {vx = 0, vy = 0}, math.linear, function() self.dead = true end)
end

function CurseParticle:update(dt)
  self:update_game_object(dt)
  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt
  self.start_time = self.start_time + dt
end

function CurseParticle:draw()
  local alpha = 1 - (self.start_time / self.duration)
  alpha = math.max(0, math.min(1, alpha))
  local color = self.color:clone()
  color.a = color.a * alpha
  graphics.circle(self.x, self.y, 1.5, color)
end
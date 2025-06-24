
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
  self.parent = args.parent                      -- The object that cast the spell.
  self.initial_target = args.target              -- The first target to be hit.
  self.max_chains = args.max_chains or 5         -- Maximum number of bounces.
  self.range = args.range or 50                -- The radius to search for the next target.
  self.delay = args.delay or 0.15                -- The time in seconds between each chain link.
  self.target_classes = args.target_classes or {}-- Table of classes to consider valid targets (e.g., main.current.enemies).

  -- Callback functions to be defined by the spell implementation.
  -- on_hit(spell, target): Action to perform on the target (e.g., deal damage).
  self.on_hit = args.on_hit
  -- on_bounce(spell, from_target, to_target): Action to perform for the visual/audio effect between links.
  self.on_bounce = args.on_bounce

  -- Internal state management.
  self.targets = {self.initial_target}  -- A list of targets to be hit. Grows dynamically.
  self.hit_targets = {}                 -- A hash map to track targets that have already been hit.
  self.current_index = 0                -- The index of the current target in the self.targets list.
  self.last_target = self.parent        -- The source of the current chain link.

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
    if not self.hit_targets[p_target] then
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
  self.parent = args.parent
  self.is_troop = args.is_troop or false
  self.dmg = args.dmg or 5
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
    parent = self.parent,
    target = self.target,
    max_chains = SHOCK_MAX_CHAINS,
    range = self.rs, -- Use the radius specified in the original arguments
    target_classes = target_classes,

    -- ## Define Callbacks ##

    -- on_hit: This function is called on each target in the chain.
    on_hit = function(spell, target)
      -- 'spell' is the ChainLightning instance. 'self' would also work here.
      target:hit(self.dmg, nil, self.damageType, false)
    end,

    -- on_bounce: This function creates the visual and audio effects between targets.
    on_bounce = function(spell, from_target, to_target)
      spark2:play{pitch = random:float(0.8, 1.2), volume = 0.7}
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
  self:generate()
  self.t:tween(self.duration or 0.1, self, {w = 1}, math.linear, function() self.dead = true end)
  self.color = args.color or blue[0]
  HitCircle{group = main.current.effects, x = self.src.x, y = self.src.y, rs = 6, color = fg[0], duration = self.duration or 0.1}
  for i = 1, 2 do HitParticle{group = main.current.effects, x = self.src.x, y = self.src.y, color = self.color} end
  HitCircle{group = main.current.effects, x = self.dst.x, y = self.dst.y, rs = 6, color = fg[0], duration = self.duration or 0.1}
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

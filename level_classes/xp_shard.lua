XPShard = Object:extend()
XPShard.__class_name = 'XPShard'
XPShard:implement(GameObject)
XPShard:implement(Physics)

function XPShard:init(args)
  self:init_game_object(args)

  -- XP value based on enemy round power
  self.xp_value = args.xp_value or 25

  -- Position
  self.x = args.x
  self.y = args.y

  -- Visual properties - smaller and blue
  self.radius = 2  -- Smaller draw radius
  self.color = blue[5]:clone()  -- Blue color for all XP shards

  self.pulse_timer = 0
  self.scale = 1.0

  -- Pickup properties
  self.pickup_radius = 10  -- Larger pickup radius
  self.being_collected = false
  self.collection_speed = 400

  -- Physics setup for collision detection
  self:set_as_circle(self.pickup_radius, 'dynamic', 'xp_shard')
  self.fixture:setSensor(true)  -- Make it a sensor for trigger detection

  -- Drop animation - launch in random direction with reduced bounce
  local angle = random:float(0, 2*math.pi)
  local speed = random:float(50, 80)  -- Lower initial speed
  self.body:setLinearVelocity(speed * math.cos(angle), speed * math.sin(angle))

  -- Add vertical component for bouncing effect (reduced)
  self.z = 10  -- Lower starting height
  self.z_velocity = -80  -- Slower falling speed
  self.bounce_damping = 0.3  -- Much less bouncy
  self.gravity = 300  -- Lighter gravity

  -- Reference to arena
  self.arena = main.current.current_arena
end

function XPShard:update(dt)
  self:update_game_object(dt)

  -- Handle bouncing animation
  if self.z > 0 or self.z_velocity ~= 0 then
    -- Apply gravity
    self.z_velocity = self.z_velocity - self.gravity * dt
    self.z = self.z + self.z_velocity * dt

    -- Check for bounce
    if self.z <= 0 then
      self.z = 0
      if math.abs(self.z_velocity) > 5 then  -- Stop bouncing sooner
        self.z_velocity = -self.z_velocity * self.bounce_damping
      else
        self.z_velocity = 0  -- Stop bouncing
        -- Stop rolling when done bouncing
        if not self.being_collected then
          self.body:setLinearVelocity(0, 0)
        end
      end
    end
  else
    -- Also apply friction to stop rolling after landing
    if not self.being_collected then
      local vx, vy = self.body:getLinearVelocity()
      self.body:setLinearVelocity(vx * 0.9, vy * 0.9)  -- Apply friction
      -- Stop completely if moving very slowly
      if math.abs(vx) < 5 and math.abs(vy) < 5 then
        self.body:setLinearVelocity(0, 0)
      end
    end
  end

  -- Pulse animation (slower when higher)
  local pulse_speed = self.z > 0 and 2 or 3
  self.pulse_timer = self.pulse_timer + dt * pulse_speed
  self.scale = 1.0 + 0.2 * math.sin(self.pulse_timer)

  -- Handle collection if triggered
  if self.being_collected then
    -- Move toward collection target
    if self.collection_target and not self.collection_target.dead then
      local angle = math.angle(self.x, self.y, self.collection_target.x, self.collection_target.y)
      local speed = self.collection_speed
      self.body:setLinearVelocity(speed * math.cos(angle), speed * math.sin(angle))

      -- Check if reached target
      local dist = math.distance(self.x, self.y, self.collection_target.x, self.collection_target.y)
      if dist < 5 then
        self:collect()
      end
    else
      -- Target died, stop collection
      self.being_collected = false
      self.body:setLinearVelocity(0, 0)
    end
  end
end


function XPShard:start_collection(target)

  self.being_collected = true
  self.collection_target = target
end

function XPShard:collect()
  if self.dead then return end
  
  if hit2 then
    hit2:play{pitch = random:float(1.2, 1.4), volume = 0.3}
  end

  -- Immediately trigger progress bar particles
  if self.arena and self.arena.progress_bar then
    self.arena.progress_bar:increase_with_particles(self.xp_value, self.x, self.y)
    self:check_level_complete()
  end

  self.dead = true
end

function XPShard:check_level_complete()
  if not self.arena or not self.arena.progress_bar then return end

  local progress_bar = self.arena.progress_bar
  local total_progress = 0

  -- Calculate total progress across all segments
  for _, segment in ipairs(progress_bar.segments) do
    total_progress = total_progress + (segment.progress or 0)
  end

  -- Calculate total required XP (65% of round power for faster completion)
  local total_required = 0
  for _, power in ipairs(progress_bar.waves_power) do
    total_required = total_required + power
  end
  total_required = total_required * 0.65  -- Only need 65% to complete

  -- Check if we've collected enough XP
  if total_progress >= total_required then
    -- Prevent multiple triggers
    if self.arena.transitioning_to_buy then return end
    self.arena.transitioning_to_buy = true

    -- Level complete - transition to buy screen
    if main.current and main.current.transition_to_next_level_buy_screen then
      -- Delay slightly to let particles reach the bar
      self.arena.t:after(0.5, function()
        main.current:transition_to_next_level_buy_screen()
      end)
    end
  end
end

function XPShard:draw()
  -- Draw shadow on ground (gets smaller as shard goes higher)
  if self.z > 0 then
    local shadow_scale = math.max(0.3, 1 - self.z / 50)
    local shadow_color = bg[2]:clone()
    shadow_color.a = 0.3 * shadow_scale
    graphics.circle(self.x, self.y, self.radius * shadow_scale, shadow_color)
  end

  -- Draw shard at height offset
  local draw_y = self.y - self.z

  -- Draw with pulsing effect
  graphics.push(self.x, draw_y, 0, self.scale, self.scale)

  -- Outer glow
  local glow_color = self.color:clone()
  glow_color.a = 0.3
  graphics.circle(self.x, draw_y, self.radius + 3, glow_color)

  -- Main shard
  graphics.circle(self.x, draw_y, self.radius, self.color)

  -- Inner bright spot
  local bright_color = white[0]:clone()
  bright_color.a = 0.8
  graphics.circle(self.x, draw_y, self.radius * 0.4, bright_color)

  graphics.pop()
end

function XPShard:on_trigger_enter(other)
  -- Check if it's the player cursor
  if other.is_player_cursor and not self.being_collected then
    self:start_collection(other)
  end
end

function XPShard:die()
  self.dead = true
end
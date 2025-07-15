BuyCharacter = FloorInteractable:extend()
BuyCharacter:implement(GameObject)
BuyCharacter:implement(Physics)

function BuyCharacter:init(args)
  -- Initialize floor interactable base class
  FloorInteractable.init(self, args)
  
  -- Position in the middle of the screen, half covered by top wall
  self.x = args.x or gw/2
  self.y = args.y or SpawnGlobals.wall_height or 30

  self.radius = args.radius or 40

  self.cost = args.cost or 10
  
  -- Visual properties
  self.color = yellow[0]
  self.base_color = yellow[0]
  self.highlight_color = yellow[2]
  self.radius = 45
  self.is_active = true
  self.is_triggered = false
  self.trigger_duration = 3.0
  self.trigger_timer = 0
  
  -- Animation properties
  self.pulse_timer = 0
  self.pulse_speed = 2.0
  self.scale = 1.0
  
  -- Sound properties
  self.charging_sound_played = false
  
  -- Set up interaction callbacks
  self.on_activation = function()
    self:trigger_character_selection()
  end
  
  -- Set up disable function
  self.disable_interaction = function()
    return gold < self.cost
  end
end

function BuyCharacter:update(dt)
  -- Call parent update (FloorInteractable)
  FloorInteractable.update(self, dt)
  
  -- Update pulse animation
  self.pulse_timer = self.pulse_timer + dt * self.pulse_speed
  self.scale = 1.0 + 0.1 * math.sin(self.pulse_timer)
  
  -- Update trigger timer
  if self.is_triggered then
    self.trigger_timer = self.trigger_timer + dt
    if self.trigger_timer >= self.trigger_duration then
      self:deactivate()
    end
  end
end

function BuyCharacter:trigger_character_selection()
  if self.is_triggered then return end
  
  self.is_triggered = true
  self.color = self.highlight_color
  
  -- Call parent level callback if it exists
  if self.parent and self.parent.on_buy_character_triggered then
    self.parent:on_buy_character_triggered()
  end
end

function BuyCharacter:deactivate()
  self.is_active = false
  self.color = grey[0]
  
  -- Deactivate floor interactable
  self:interaction_deactivate()
end

function BuyCharacter:draw()
  if self.dead then return end
  
  -- Color definitions based on disabled state
  local basin_color, border_color, ripple_color, ripple_color_inner, charging_color, icon_color, charging_icon_color
  
  if self.interaction_is_disabled then
    -- Grey colors when disabled
    basin_color = Color(80/255, 80/255, 80/255, 0.4) -- Dark grey
    border_color = Color(120/255, 120/255, 120/255, 0.8) -- Medium grey
    ripple_color = Color(100/255, 100/255, 100/255, 0.3) -- Light grey
    ripple_color_inner = Color(90/255, 90/255, 90/255, 0.2) -- Lighter grey
    charging_color = Color(100/255, 100/255, 100/255, 0.5) -- Grey
    icon_color = Color(120/255, 120/255, 120/255, 0.8) -- Medium grey
    charging_icon_color = Color(140/255, 140/255, 140/255, 1.0) -- Light grey
  else
    -- A vibrant teal and gold color palette for the fountain
    basin_color = Color(20/255, 120/255, 140/255, 0.4) -- Deep sea teal
    border_color = Color(100/255, 220/255, 255/255, 0.8) -- Bright cyan
    ripple_color = Color(100/255, 220/255, 255/255, 0.3) -- Fainter cyan for ripples
    ripple_color_inner = Color(100/255, 220/255, 255/255, 0.2) -- Faintest cyan for inner ripples
    charging_color = Color(255/255, 215/255, 80/255, 0.5) -- Energetic gold
    icon_color = Color(100/255, 220/255, 255/255, 0.8) -- Bright cyan to match the border
    charging_icon_color = Color(255/255, 215/255, 80/255, 1.0) -- Solid gold for emphasis
  end
  
  graphics.push(self.x, self.y, 0, 1, 1)
  
  -- 1. Static (Idle) Design
  --------------------------
  -- Draw the main half-circle basin using 'closed' for a solid look.
  -- Angle changed from (math.pi, 2*math.pi) to (0, math.pi) to draw the bottom half.
  graphics.arc('closed', self.x, self.y, self.radius, -math.pi/2, math.pi/2, basin_color)
  
  -- Add a crisp border on top.
  -- Angle changed to draw the bottom half.
  graphics.arc('open', self.x, self.y, self.radius, -math.pi/2, math.pi/2, border_color, 3)
  
  -- Draw subtle, pulsing inner ripples.
  local pulse = (math.sin(self.pulse_timer * 2) + 1) / 2 -- Smoothly pulses from 0 to 1.
  local ripple_alpha = 0.3 + pulse * 0.2
  
  -- Angle changed for the inner ripples.
  ripple_color.a = ripple_alpha
  graphics.arc('open', self.x, self.y, self.radius * 0.75, -math.pi/2, math.pi/2, ripple_color, 2)
  ripple_color_inner.a = ripple_alpha - 0.1
  graphics.arc('open', self.x, self.y, self.radius * 0.55, -math.pi/2, math.pi/2, ripple_color_inner, 1.5)

  -- 2. Activation (Charging) Effect
  ------------------------------------
  if self.is_charging and not self.interaction_is_disabled then
    -- Effect 1: The "Filling" progress bar, now a solid wedge.
    -- The start and end angles are adjusted to fill from right-to-left across the bottom.
    local start_angle = -math.pi/2
    local end_angle = -math.pi/2 + math.pi * self.charge_progress
    graphics.arc('closed', self.x, self.y, self.radius, start_angle, end_angle, charging_color)
    
    -- Effect 2: Expanding ripple of power.
    -- Angle changed to match the new downward orientation.
    local ripple_radius = self.radius * self.charge_progress
    local ripple_alpha_fade = 0.8 * (1 - self.charge_progress) -- Fades out as it expands.
    charging_color.a = ripple_alpha_fade
    graphics.arc('open', self.x, self.y, ripple_radius, -math.pi/2, math.pi/2, charging_color, 3)
  end 

  -- 3. Central Icon (no change needed as it's centered)
  -------------------
  if self.is_charging and not self.interaction_is_disabled then
      -- Make the icon brighter while charging.
      icon_color = charging_icon_color
  end
  
  -- Draw the swirl icon.
  graphics.circle(self.x, self.y, self.radius * 0.2, icon_color, 2)
  graphics.arc('open', self.x + self.radius * 0.1, self.y, self.radius * 0.1, 0, math.pi, icon_color, 2)
  graphics.arc('open', self.x - self.radius * 0.1, self.y, self.radius * 0.1, math.pi, 2*math.pi, icon_color, 2)

  graphics.pop()
end

function BuyCharacter:die()
  self:deactivate()
  -- Call parent die (FloorInteractable)
  FloorInteractable.die(self)
  self.dead = true
end 
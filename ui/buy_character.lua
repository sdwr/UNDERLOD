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
  
  -- Visual properties
  self.color = yellow[0]
  self.base_color = yellow[0]
  self.highlight_color = yellow[2]
  self.radius = 25
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
    self:die()
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
  graphics.push(self.x, self.y, 0, self.scale, self.scale)
    
    -- Draw main circle
    graphics.circle(self.x, self.y, self.radius, self.color, 3)
    
    -- Draw inner circle
    graphics.circle(self.x, self.y, self.radius * 0.7, self.color, 2)
    
    -- Draw character icon in center
    graphics.circle(self.x, self.y, self.radius * 0.4, self.color)
    
    -- Draw plus symbol
    graphics.line(self.x - 8, self.y, self.x + 8, self.y, self.color, 2)
    graphics.line(self.x, self.y - 8, self.x, self.y + 8, self.color, 2)
    
  graphics.pop()
end

function BuyCharacter:die()
  self:deactivate()
  -- Call parent die (FloorInteractable)
  FloorInteractable.die(self)
  self.dead = true
end 
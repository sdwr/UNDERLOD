-- Level map constants
LEVEL_MAP_ICON_SPACING = 30
LEVEL_MAP_ICON_OFFSET_X = 60
LEVEL_MAP_ICON_OFFSET_Y = 0
LEVEL_MAP_CONNECTION_WIDTH = 20
LEVEL_MAP_CONNECTION_HEIGHT = 3
LEVEL_MAP_CONNECTION_OFFSET = 15
LEVEL_MAP_ICON_RADIUS = 10
LEVEL_MAP_ICON_INNER_RADIUS = 9
LEVEL_MAP_ICON_BORDER_WIDTH = 3
LEVEL_MAP_Y_POSITION = 13

LevelMap = Object:extend()
LevelMap:implement(GameObject)
function LevelMap:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = false
  self.shape = Rectangle(self.x, self.y, 200, 40)
  -- Remove text - no longer needed
  self.level = args.level
  self.parent = args.parent
  self.level_list = args.level_list

  -- Animation state
  self.transitioning_out = false
  self.transitioning_in = false
  self.transition_progress = 0
  self.transition_duration_in = TRANSITION_DURATION / 2
  self.transition_duration_out = TRANSITION_DURATION / 2
  self.expanded_spacing = gw
  self.normal_spacing = LEVEL_MAP_ICON_SPACING

  self:build()
end

function LevelMap:build()
  self.levels = {}
  self.level_connections = {}
  self.level = self.parent.level
  local start_level = self.level - 2

  for i = 1, 5 do
    local level = start_level + (6 - i) - 1  -- Reverse the order: 6-i instead of i-1
    if level <= 0 or level > NUMBER_OF_ROUNDS then
      --pass
    else
      table.insert(self.levels, 
        LevelMapLevel{group = self.group, x = self.x - LEVEL_MAP_ICON_OFFSET_X + (i-1)*LEVEL_MAP_ICON_SPACING, y = self.y + LEVEL_MAP_ICON_OFFSET_Y, 
        line_color = (level == self.level) and yellow[2] or fg[0],
        fill_color = self.parent.level_list[level].color,
        level = level,
        parent = self
        })
    end
  end

  self:build_connections()
end

function LevelMap:build_connections()
  self.level_connections = {}
  for i = 1, #self.levels - 1 do
    if i == 1 and self.level > 1 then
      table.insert(self.level_connections, LevelMapConnection{group = self.group, x = self.levels[i].x - LEVEL_MAP_CONNECTION_OFFSET, y = self.levels[i].y, w = LEVEL_MAP_CONNECTION_WIDTH, h = LEVEL_MAP_CONNECTION_HEIGHT, color = fg[1]})
    end
    table.insert(self.level_connections, LevelMapConnection{group = self.group, x = self.levels[i].x + LEVEL_MAP_CONNECTION_OFFSET, y = self.levels[i].y, w = LEVEL_MAP_CONNECTION_WIDTH, h = LEVEL_MAP_CONNECTION_HEIGHT, color = fg[1]})
  end
  if self.level < NUMBER_OF_ROUNDS then
    table.insert(self.level_connections, LevelMapConnection{group = self.group, x = self.levels[#self.levels].x + LEVEL_MAP_CONNECTION_OFFSET, y = self.levels[#self.levels].y, w = LEVEL_MAP_CONNECTION_WIDTH, h = LEVEL_MAP_CONNECTION_HEIGHT, color = fg[1]})
  end
end

function LevelMap:start_transition_out()
  self.transitioning_out = true
  self.transition_progress = 0
end

function LevelMap:end_transition_out()
  self.transitioning_out = false
  -- After transition out, the new level is in the correct position
  -- Now we need to recenter all levels around it
  self:start_transition_in()
end

function LevelMap:start_transition_in()
  self.transitioning_in = true
  self.transition_progress = 0
end

function LevelMap:end_transition_in()
  self.transitioning_in = false
  self.transition_progress = 0
  self:update_level_positions(0) -- Reset to normal spacing
end

function LevelMap:recenter_levels_around_current()
  -- Find the current level index
  local current_level_index = nil
  for i, level in ipairs(self.levels) do
    if level.level == self.level then
      current_level_index = i
      break
    end
  end
  
  if not current_level_index then return end
  
  -- Calculate the offset needed to center the current level
  -- The current level should be at position 3 (center) in normal spacing
  local current_x = self.levels[current_level_index].x
  local target_x = self.x - LEVEL_MAP_ICON_OFFSET_X + (3-1)*LEVEL_MAP_ICON_SPACING
  local offset = target_x - current_x
  
  -- Apply the offset to all levels
  for i, level in ipairs(self.levels) do
    level.x = level.x + offset
    level.shape.x = level.x
  end
  
  -- Rebuild connections
  self:build_connections()
end

function LevelMap:update_level_positions(progress)
  local current_spacing = self.normal_spacing + (self.expanded_spacing - self.normal_spacing) * progress

  for i, level in ipairs(self.levels) do
    level.x = self:CALCULATE_LEVEL_MAP_WORLD_X(i, current_spacing)
    level.shape.x = level.x
  end

  -- Rebuild connections with new positions
  self:build_connections()
end

function LevelMap:update_level_positions_in(progress)
  -- For transition-in, we animate from the recentered positions back to normal spacing
  -- The levels are already positioned around the current level, we just need to adjust spacing
  
  for i, level in ipairs(self.levels) do
    -- Calculate the target position with normal spacing
    local target_x = self.x + gw - LEVEL_MAP_ICON_OFFSET_X + (i-1)*LEVEL_MAP_ICON_SPACING
    
    -- Interpolate from current position to target position
    level.x = level.x + (target_x - level.x) * progress
    level.shape.x = level.x
  end

  -- Rebuild connections with new positions
  self:build_connections()
end

function LevelMap:CALCULATE_LEVEL_MAP_WORLD_X(index, current_spacing)
  return self.x - (current_spacing * (index - 3))
end

function LevelMap:update(dt)
  self:update_game_object(dt)

  if self.transitioning_out then
    self.transition_progress = self.transition_progress + dt / self.transition_duration_out

    if self.transition_progress >= 1 then
      self.transition_progress = 1
      self:end_transition_out()
    end

    -- Use smooth easing for the animation
    local ease_progress = self.transition_progress * self.transition_progress * (3 - 2 * self.transition_progress)
    self:update_level_positions(ease_progress)
  elseif self.transitioning_in then
    self.transition_progress = self.transition_progress + dt / self.transition_duration_in

    if self.transition_progress >= 1 then
      self.transition_progress = 1
      self:end_transition_in()
    end

    -- For transition-in, we animate from the recentered positions back to normal spacing
    local ease_progress = self.transition_progress * self.transition_progress * (3 - 2 * self.transition_progress)
    self:update_level_positions_in(ease_progress)
  end
end

function LevelMap:draw()
  -- graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
  -- Remove text drawing - no longer needed
  -- graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
  --   self.text:draw(self.x, self.y - 15, 0, 1, 1)
  -- graphics.pop()
end

function LevelMap:clear()
  for _, level in ipairs(self.levels) do
    level:die()
  end
  for _, connection in ipairs(self.level_connections) do
    connection:die()
  end
end

function LevelMap:reset()
  self:clear()
  self:build()
end

function LevelMap:die()
  self:clear()
  self.dead = true
end

LevelMapLevel = Object:extend()
LevelMapLevel:implement(GameObject)
function LevelMapLevel:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = true
  self.shape = Circle(self.x, self.y, LEVEL_MAP_ICON_RADIUS, LEVEL_MAP_ICON_BORDER_WIDTH)
  self.line_color = args.line_color
  self.fill_color = args.fill_color
  self.text_color = fg[0]
  self.level = args.level
  self.parent = args.parent

  if Is_Boss_Level(self.level) then
    self.is_boss = true
  end
end

function LevelMapLevel:update(dt)
  self:update_game_object(dt)
end

function LevelMapLevel:draw()

  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.circle(self.x, self.y, LEVEL_MAP_ICON_INNER_RADIUS, self.fill_color)
    if self.is_boss then
      skull:draw(self.x, self.y, 0, 0.7, 0.7)
    else
      graphics.circle(self.x, self.y, LEVEL_MAP_ICON_RADIUS, self.line_color, LEVEL_MAP_ICON_BORDER_WIDTH)
      graphics.print_centered(self.level, pixul_font, self.x, self.y +2, 0, 1, 1, 0, 0, self.text_color)
    end

  graphics.pop()
end

function LevelMapLevel:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.spring:pull(0.2, 200, 10)
  self.level_text = BuildLevelText(self.parent.level_list, 
    self.level, gw/2, LEVEL_TEXT_HOVER_HEIGHT )
end

function LevelMapLevel:on_mouse_exit()
  self.level_text:deactivate()
  self.level_text.dead = true
  self.level_text = nil
  self.selected = false
end

function LevelMapLevel:die()
  self.dead = true
end


LevelMapConnection = Object:extend()
LevelMapConnection:implement(GameObject)
function LevelMapConnection:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = true
  self.shape = Rectangle(self.x, self.y, args.w, args.h)
  self.color = args.color
end

function LevelMapConnection:update(dt)
  self:update_game_object(dt)
end

function LevelMapConnection:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.color)
  graphics.pop()
end

function LevelMapConnection:die()
  self.dead = true
end 
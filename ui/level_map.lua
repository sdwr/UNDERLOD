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
GOLD_COUNTER_X_OFFSET = 48

LevelMap = Object:extend()
LevelMap.__class_name = 'LevelMap'
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

  self.MAX_LEVELS = 5
  self.MAX_LEVELS_IN_TRANSITION = 6

  self:build()
end

function LevelMap:create_level_map_level(level, x, y, line_color, fill_color)
  return LevelMapLevel{
    group = self.group, 
    z_index = 1, 
    x = x, 
    y = y, 
    line_color = line_color,
    fill_color = fill_color,
    level = level,
    parent = self
  }
end

function LevelMap:build()
  self.levels = {}
  self.level_connections = {}
  self.level = self.parent.level
  local start_level = self.level - 2

  for i = 1, 5 do
    local level = start_level + i - 1
    if level < 0 or level > NUMBER_OF_ROUNDS then
      --pass
    else
      local x = self.x - LEVEL_MAP_ICON_OFFSET_X + (i-1)*LEVEL_MAP_ICON_SPACING
      local y = self.y + LEVEL_MAP_ICON_OFFSET_Y
      local line_color = (level == self.level) and yellow[2] or fg[0]
      local fill_color = self.parent.level_list[level] and self.parent.level_list[level].color or grey[0]
      
      table.insert(self.levels, i, self:create_level_map_level(level, x, y, line_color, fill_color))
    end
  end

  self:build_connections()
end

function LevelMap:build_connections()
  for _, connection in ipairs(self.level_connections) do
    connection.dead = true
  end
  self.level_connections = {}

  for i = 1, self.MAX_LEVELS_IN_TRANSITION - 1 do
    --the first one is only drawn if the current level is greater than 1
    if i == 1 and self.level > 1 and self.levels[i] then
      table.insert(self.level_connections, LevelMapConnection{group = self.group, x = self.levels[i].x - LEVEL_MAP_CONNECTION_OFFSET, y = self.levels[i].y, w = LEVEL_MAP_CONNECTION_WIDTH, h = LEVEL_MAP_CONNECTION_HEIGHT, color = fg[1]})
    end
    --the middle ones need to extend to the next level
    if self.levels[i+1] and self.levels[i] then
      local connection_width = LEVEL_MAP_CONNECTION_WIDTH
      if self.levels[i+1] and self.levels[i] then
        connection_width = self.levels[i+1].x - self.levels[i].x
      end
      table.insert(self.level_connections, LevelMapConnection{group = self.group, x = self.levels[i].x + connection_width/2, y = self.levels[i].y, w = connection_width, h = LEVEL_MAP_CONNECTION_HEIGHT, color = fg[1]})
    end

    --this one overlaps with the last one, its ok because its the smallest possible size
    if self.levels[i] and self.levels[i].level < NUMBER_OF_ROUNDS then
      table.insert(self.level_connections, LevelMapConnection{group = self.group, x = self.levels[i].x + LEVEL_MAP_CONNECTION_OFFSET, y = self.levels[i].y, w = LEVEL_MAP_CONNECTION_WIDTH, h = LEVEL_MAP_CONNECTION_HEIGHT, color = fg[1]})
    end
  end
end

function LevelMap:start_transition_out()
  self.transitioning_out = true
  self.transition_progress = 0
end

function LevelMap:end_transition_out()
  self.transitioning_out = false
  self:add_next_level_to_map()
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

function LevelMap:add_next_level_to_map()

  if self.levels[5] and self.levels[5].level < NUMBER_OF_ROUNDS then
    local next_level = self.levels[5].level + 1
    local x = self.x - LEVEL_MAP_ICON_OFFSET_X + (3-1)*LEVEL_MAP_ICON_SPACING
    local y = self.y + LEVEL_MAP_ICON_OFFSET_Y
    local line_color = (next_level == self.level) and yellow[2] or fg[0]
    local fill_color = self.parent.level_list[next_level].color
    
    table.insert(self.levels, 6, self:create_level_map_level(next_level, x, y, line_color, fill_color))
  end
end

function LevelMap:update_level_positions(progress)
  local current_spacing = self.normal_spacing + (self.expanded_spacing - self.normal_spacing) * progress

  for i = 1, self.MAX_LEVELS_IN_TRANSITION do
    local level = self.levels[i]
    if level then
      level.x = self:CALCULATE_LEVEL_MAP_WORLD_X(i, current_spacing)
      level.shape.x = level.x
    end
  end

  -- Rebuild connections with new positions
  self:build_connections()
end

function LevelMap:update_level_positions_in(progress)
  local current_spacing = self.expanded_spacing - (self.expanded_spacing - self.normal_spacing) * progress
  
  for i = 1, self.MAX_LEVELS_IN_TRANSITION do
    local level = self.levels[i]
    if level then
      level.x = self:CALCULATE_NEXT_LEVEL_MAP_WORLD_X(i, current_spacing)
      level.shape.x = level.x
    end
  end

  -- Rebuild connections with new positions
  self:build_connections()
end

function LevelMap:CALCULATE_LEVEL_MAP_WORLD_X(index, current_spacing)
  return self.x - (current_spacing * (3 - index))
end

function LevelMap:CALCULATE_NEXT_LEVEL_MAP_WORLD_X(index, current_spacing)
  return self.x + gw - (current_spacing * (4 - index))
end

function LevelMap:update(dt)
  self:update_game_object(dt)

  if self.transitioning_out then
    self.transition_progress = self.transition_progress + dt / self.transition_duration_out


    -- Use smooth easing for the animation
    local ease_progress = self.transition_progress * self.transition_progress * (3 - 2 * self.transition_progress)
    self:update_level_positions(ease_progress)

    if self.transition_progress >= 1 then
      self.transition_progress = 1
      self:end_transition_out()
    end

  elseif self.transitioning_in then
    self.transition_progress = self.transition_progress + dt / self.transition_duration_in

    -- For transition-in, we animate from the recentered positions back to normal spacing
    local ease_progress = 1 - (1 - self.transition_progress) * (1 - self.transition_progress) * (3 - 2 * (1 - self.transition_progress))
    self:update_level_positions_in(ease_progress)

    if self.transition_progress >= 1 then
      self.transition_progress = 1
      self:end_transition_in()
    end
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
  for i = 1, self.MAX_LEVELS_IN_TRANSITION do
    if self.levels[i] then
      self.levels[i]:die()
    end
  end
  for i, connection in ipairs(self.level_connections) do
    connection.dead = true
  end
  self.levels = {}
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
LevelMapLevel.__class_name = 'LevelMapLevel'
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
      if self.level > 0 then
        graphics.print_centered(self.level, pixul_font, self.x, self.y +2, 0, 1, 1, 0, 0, self.text_color)
      end
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
LevelMapConnection.__class_name = 'LevelMapConnection'
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
RoundPowerVisualizer = Object:extend()
RoundPowerVisualizer.__class_name = 'RoundPowerVisualizer'
RoundPowerVisualizer:implement(GameObject)
function RoundPowerVisualizer:init(args)
  self:init_game_object(args)
  
  self.x = gw - 125
  self.y = 10
  self.width = 115
  self.height = 75
  self.visible = false
  
  -- Graph settings
  self.graph_x = self.x + 5
  self.graph_y = self.y + 15
  self.graph_width = 105
  self.graph_height = 50
  
  -- Data points (store history of power values)
  self.max_data_points = 30  -- Keep last 30 data points (2.5 minutes at 5 second intervals)
  self.data_points = {}
  self.time_since_last_update = 0
  self.update_interval = 5  -- Update every 5 seconds
  
  -- Current values
  self.current_onscreen = 0
  self.current_killed = 0
  self.total_power = 0
  self.max_onscreen = 0
  
  -- Initialize with first data point
  self:update_values()
end

function RoundPowerVisualizer:update_values()
  if not main.current or not main.current.level then return end
  
  self.current_onscreen = current_power_onscreen or 0
  self.current_killed = round_power_killed or 0
  self.total_power = ROUND_POWER_BY_LEVEL(main.current.level) or 0
  self.max_onscreen = MAX_ONSCREEN_ROUND_POWER(main.current.level) or 0
  
  -- Add new data point
  local data_point = {
    onscreen = self.current_onscreen,
    killed = self.current_killed,
    total = self.total_power,
    max_onscreen = self.max_onscreen,
    time = love.timer.getTime()
  }
  
  table.insert(self.data_points, data_point)
  
  -- Remove old data points if we have too many
  while #self.data_points > self.max_data_points do
    table.remove(self.data_points, 1)
  end
end

function RoundPowerVisualizer:update(dt)
  self:update_game_object(dt)

  -- Update data at intervals
  self.time_since_last_update = self.time_since_last_update + dt
  if self.time_since_last_update >= self.update_interval then
    self.time_since_last_update = 0
    self:update_values()
  end
end

function RoundPowerVisualizer:draw()
  if not self.visible then return end
  
  -- No background
  
  -- Draw title
  graphics.print('Round Power', pixul_mini, self.x + self.width/2, self.y + 5, 0, 1, 1, pixul_mini:get_text_width('Round Power')/2, 0, fg[0])
  
  -- Draw current values text
  local text_y = self.y + self.height - 8
  local killed_percent = (self.current_killed / self.total_power) * 100
  local onscreen_percent = (self.current_onscreen / self.max_onscreen) * 100
  
  graphics.print(string.format('K:%d/%d', self.current_killed, self.total_power), 
  pixul_mini, self.x + 5, text_y, 0, 1, 1, 0, 0, green[5])
  graphics.print(string.format('O:%d/%d', self.current_onscreen, self.max_onscreen), 
  pixul_mini, self.x + 5, text_y + 8, 0, 1, 1, 0, 0, yellow[5])
  
  -- Draw graph axes
  graphics.line(self.graph_x, self.graph_y + self.graph_height, 
  self.graph_x + self.graph_width, self.graph_y + self.graph_height, fg[-5], 1)
  graphics.line(self.graph_x, self.graph_y, 
  self.graph_x, self.graph_y + self.graph_height, fg[-5], 1)
  
  -- Draw grid lines
  for i = 0, 4 do
    local y = self.graph_y + (self.graph_height * i / 4)
    graphics.line(self.graph_x, y, self.graph_x + self.graph_width, y, bg[5], 0.5)
  end
  
  -- Calculate scale
  local max_value = math.max(self.total_power, self.max_onscreen * 2)
  
  
  -- Draw max onscreen line
  local max_onscreen_y = self.graph_y + self.graph_height - (self.max_onscreen / max_value) * self.graph_height
  graphics.line(self.graph_x, max_onscreen_y, self.graph_x + self.graph_width, max_onscreen_y, orange[5], 1)
  graphics.print('M', pixul_mini, self.graph_x - 8, max_onscreen_y - 4, 0, 1, 1, 0, 0, orange[5])
  
  if #self.data_points < 2 then return end  -- Need at least 2 points to draw a line

  -- Draw data lines
  if #self.data_points >= 2 then
    -- Calculate x step
    local x_step = self.graph_width / (self.max_data_points - 1)
    
    -- Draw killed power line (green)
    for i = 2, #self.data_points do
      local x1 = self.graph_x + (i - 2) * x_step
      local x2 = self.graph_x + (i - 1) * x_step
      local y1 = self.graph_y + self.graph_height - (self.data_points[i-1].killed / max_value) * self.graph_height
      local y2 = self.graph_y + self.graph_height - (self.data_points[i].killed / max_value) * self.graph_height
      
      graphics.line(x1, y1, x2, y2, green[5], 2)
    end
    
    -- Draw onscreen power line (yellow)
    for i = 2, #self.data_points do
      local x1 = self.graph_x + (i - 2) * x_step
      local x2 = self.graph_x + (i - 1) * x_step
      local y1 = self.graph_y + self.graph_height - (self.data_points[i-1].onscreen / max_value) * self.graph_height
      local y2 = self.graph_y + self.graph_height - (self.data_points[i].onscreen / max_value) * self.graph_height
      
      graphics.line(x1, y1, x2, y2, yellow[5], 2)
    end
    
    -- Draw total killed + onscreen line (white)
    for i = 2, #self.data_points do
      local x1 = self.graph_x + (i - 2) * x_step
      local x2 = self.graph_x + (i - 1) * x_step
      local total1 = self.data_points[i-1].killed + self.data_points[i-1].onscreen
      local total2 = self.data_points[i].killed + self.data_points[i].onscreen
      local y1 = self.graph_y + self.graph_height - (total1 / max_value) * self.graph_height
      local y2 = self.graph_y + self.graph_height - (total2 / max_value) * self.graph_height
      
      graphics.line(x1, y1, x2, y2, fg[0], 1)
    end
  end
  
  -- Draw legend
  local legend_y = self.graph_y - 8
  graphics.print('K', pixul_mini, self.graph_x + 5, legend_y, 0, 1, 1, 0, 0, green[5])
  graphics.print('O', pixul_mini, self.graph_x + 25, legend_y, 0, 1, 1, 0, 0, yellow[5])
  graphics.print('T', pixul_mini, self.graph_x + 45, legend_y, 0, 1, 1, 0, 0, fg[0])
end

function RoundPowerVisualizer:toggle()
  self.visible = not self.visible
  if self.visible then
    self.data_points = {}  -- Clear old data
    self:update_values()  -- Get initial data point
    print('[Round Power Visualizer] Enabled')
  else
    print('[Round Power Visualizer] Disabled')
  end
end

function RoundPowerVisualizer:destroy()
  self.dead = true
end
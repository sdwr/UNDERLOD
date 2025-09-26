LevelSelectScreen = Object:extend()
LevelSelectScreen.__class_name = 'LevelSelectScreen'
LevelSelectScreen:implement(State)
LevelSelectScreen:implement(GameObject)

function LevelSelectScreen:init(name)
  self:init_state(name)
  self:init_game_object()
end

function LevelSelectScreen:on_enter(from)
  slow_amount = 1

  -- Set cursor to simple mode for menus
  set_cursor_simple()

  -- Initialize groups
  self.ui = Group():no_camera()
  self.main_ui = Group():no_camera()
  self.detail_ui = Group():no_camera()
  self.options_ui = Group():no_camera()
  self.paused = false

  -- Title
  self.title_text = Text2{group = self.ui, x = gw/2, y = 20, lines = {{text = '[wavy_mid, fg]SELECT STAGE', font = fat_font, alignment = 'center'}}}

  -- Back button
  self.back_button = Button{group = self.main_ui, x = 40, y = gh - 20, force_update = true, button_text = 'back', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
      main:go_to('mainmenu')
    end}
  end}

  -- Stage data structure
  self.stage_buttons = {}

  -- Load completion data
  system.load_stats()
  if not USER_STATS.stages_completed then USER_STATS.stages_completed = {} end
  if not USER_STATS.stages_no_damage then USER_STATS.stages_no_damage = {} end

  -- Create stage grid (5 per row)
  self:create_stage_grid()

  -- Selected stage info
  self.selected_stage = nil
  self.detail_panel = nil
end

function LevelSelectScreen:create_stage_grid()
  -- Layout constants
  local BUTTON_SIZE = 35
  local BUTTON_SPACING = 10
  local BUTTONS_PER_ROW = 5
  -- Position grid on right side of screen
  local START_X = gw/2 + 20  -- Right side positioning
  local START_Y = 60

  -- Get all stages from STAGE_DATA
  local stages = {}
  local index = 1
  for stage_num, stage_id in pairs(LIST_OF_STAGES) do
    local stage_data = Get_Stage_Data(stage_id)
    stages[index] = {id = stage_id, data = stage_data, num = stage_num}
    index = index + 1
  end

  -- Create buttons for stages
  local index = 0
  for i = 1, 15 do  -- Show up to 15 stages
    local stage_info = stages[i]
    if stage_info then
      local row = math.floor(index / BUTTONS_PER_ROW)
      local col = index % BUTTONS_PER_ROW

      local x = START_X + col * (BUTTON_SIZE + BUTTON_SPACING)
      local y = START_Y + row * (BUTTON_SIZE + BUTTON_SPACING)

      -- Check if unlocked using new logic
      local is_unlocked = self:is_stage_unlocked(i)

      -- Create button
      local button = self:create_stage_button(x, y, i, stage_info.id, stage_info.data, is_unlocked)
      table.insert(self.stage_buttons, button)

      index = index + 1
    end
  end
end

function LevelSelectScreen:create_stage_button(x, y, stage_num, stage_id, stage_data, is_unlocked)
  local BUTTON_SIZE = 35

  -- Determine button appearance
  local bg_color = 'bg'
  local fg_color = is_unlocked and 'fg' or 'bg10'
  local selectable = is_unlocked

  local button_action = nil
  if is_unlocked then
    button_action = function(b)
      ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      self:show_stage_details(stage_num, stage_id, stage_data)
    end
  end

  -- Create the button
  local button = Button{
    group = self.main_ui,
    x = x,
    y = y,
    w = BUTTON_SIZE,
    h = BUTTON_SIZE,
    force_update = true,
    button_text = tostring(stage_num),
    fg_color = fg_color,
    bg_color = bg_color,
    action = button_action
  }

  -- Override interact_with_mouse for disabled buttons
  button.interact_with_mouse = selectable

  -- Store stage info
  button.stage_num = stage_num
  button.stage_id = stage_id
  button.stage_data = stage_data
  button.is_unlocked = is_unlocked

  -- Update text color for disabled buttons
  if not selectable then
    button.text:set_text{{text = '[bg10]' .. tostring(stage_num), font = pixul_font, alignment = 'center'}}
  end

  return button
end

function LevelSelectScreen:show_stage_details(stage_num, stage_id, stage_data)
  -- Clear previous detail panel
  if self.detail_panel then
    self.detail_ui:destroy()
    self.detail_ui = Group():no_camera()
    self.detail_panel = nil
  end

  self.selected_stage = {num = stage_num, id = stage_id, data = stage_data}

  -- Create detail panel on left side
  local panel_x = 120  -- Left side of screen
  local panel_y = gh/2
  local panel_w = 200
  local panel_h = 250

  -- Panel background
  self.detail_panel = GameObject{group = self.detail_ui, x = panel_x, y = panel_y}

  -- Stage name
  local stage_name = stage_data.name or ("Stage " .. stage_id)
  Text2{group = self.detail_ui, x = panel_x, y = panel_y - 100, lines = {{text = '[wavy_mid, fg]' .. stage_name, font = pixul_font, alignment = 'center'}}}

  -- Difficulty buttons
  local difficulties = {'normal', 'hard', 'extreme'}
  local diff_colors = {normal = green[5], hard = yellow[5], extreme = red[5]}

  for i, difficulty in ipairs(difficulties) do
    local diff_y = panel_y - 40 + (i - 1) * 50

    -- Check completion status using new nested format
    local stage_key = string.upper(stage_id)
    local is_completed = false
    local is_no_damage = false

    if USER_STATS.stage_progress and USER_STATS.stage_progress[stage_key] and USER_STATS.stage_progress[stage_key][difficulty] then
      is_completed = USER_STATS.stage_progress[stage_key][difficulty].completed or false
      is_no_damage = USER_STATS.stage_progress[stage_key][difficulty].hitless or false
    end

    -- Difficulty button
    local button_color = 'bg10'
    local text_prefix = ''

    if is_no_damage then
      button_color = 'blue'
      text_prefix = '[blue]'
    elseif is_completed then
      button_color = 'green'
      text_prefix = '[green]'
    end

    Button{
      group = self.detail_ui,
      x = panel_x,
      y = diff_y,
      w = 150,
      h = 30,
      force_update = true,
      button_text = text_prefix .. string.upper(difficulty),
      fg_color = button_color,
      bg_color = 'bg',
      action = function(b)
        ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        self:start_stage(stage_id, difficulty)
      end
    }

    -- Completion indicators
    if is_completed then
      local indicator_text = is_no_damage and "HITLESS" or "COMPLETE"
      local indicator_color = is_no_damage and blue[5] or green[5]
      Text2{group = self.detail_ui, x = panel_x, y = diff_y + 20, lines = {{text = '[' .. (is_no_damage and 'blue' or 'green') .. ']' .. indicator_text, font = pixul_font, alignment = 'center'}}}
    end
  end
end

function LevelSelectScreen:start_stage(stage_id, difficulty)
  -- Use uppercase stage format like 'A1' for STAGE_DATA lookup
  local stage_key = string.upper(stage_id)

  TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
    self.transitioning = true

    -- Set state for the selected stage
    state.selected_stage = stage_key  -- Use 'A1' format
    state.difficulty = difficulty  -- Use 'normal' format
    state.stage_id = stage_key
    state.level = 1  -- Gameplay level starts at 1

    -- Go directly to WorldManager, bypassing buy screen
    main:add(WorldManager'world_manager')
    main:go_to('world_manager', {
      level = 1,
      selected_stage = stage_key,  -- Pass 'A1' format
      difficulty = difficulty,  -- Pass 'normal' format
      stage_id = stage_key,
      units = {},  -- Start with no units
      passives = {},
      shop_item_data = {},
      gold = 0
    })
  end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']starting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
end

function LevelSelectScreen:is_stage_unlocked(stage_num)
  -- Stage 1 is always unlocked
  if stage_num == 1 then
    return true
  end

  -- Check if previous stage is completed (any difficulty)
  local prev_completed = false
  local prev_stage_idx = stage_num - 1
  if prev_stage_idx > 0 and prev_stage_idx <= #LIST_OF_STAGES then
    local prev_stage = LIST_OF_STAGES[prev_stage_idx]
    if USER_STATS.stage_progress and USER_STATS.stage_progress[prev_stage] then
      for _, diff in ipairs({'normal', 'hard', 'extreme'}) do
        if USER_STATS.stage_progress[prev_stage][diff] and USER_STATS.stage_progress[prev_stage][diff].completed then
          prev_completed = true
          break
        end
      end
    end
  end

  -- Check if stage above is unlocked (for grid layout)
  local above_unlocked = false
  if stage_num > 5 then  -- If not in first row
    above_unlocked = self:is_stage_unlocked(stage_num - 5)
  end

  return prev_completed or above_unlocked
end

function LevelSelectScreen:on_exit()
  if self.ui then self.ui:destroy() end
  if self.main_ui then self.main_ui:destroy() end
  if self.detail_ui then self.detail_ui:destroy() end
  if self.options_ui then self.options_ui:destroy() end
  self.ui = nil
  self.main_ui = nil
  self.detail_ui = nil
  self.options_ui = nil
  self.title_text = nil
  self.back_button = nil
  self.stage_buttons = nil
  self.selected_stage = nil
  self.detail_panel = nil
  self.t:destroy()
  self.t = nil
end

function LevelSelectScreen:update(dt)
  -- Handle escape key for options menu
  if input.escape.pressed then
    if not self.paused then
      open_options(self)
    else
      close_options(self)
    end
  end

  self:update_game_object(dt*slow_amount)

  if not self.paused and not self.transitioning then
    if self.ui then self.ui:update(dt*slow_amount) end
    if self.main_ui then self.main_ui:update(dt*slow_amount) end
    if self.detail_ui then self.detail_ui:update(dt*slow_amount) end
  else
    if self.options_ui then self.options_ui:update(dt*slow_amount) end
  end
end

function LevelSelectScreen:draw()
  -- Background
  graphics.rectangle(gw/2, gh/2, gw, gh, nil, nil, bg[-2])

  -- Draw groups
  if self.ui then self.ui:draw() end
  if self.main_ui then self.main_ui:draw() end
  if self.detail_ui then self.detail_ui:draw() end

  -- Draw pause overlay
  if self.paused then
    graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent)
  end
  if self.options_ui then self.options_ui:draw() end

  -- Draw completion indicators on stage buttons
  for _, button in ipairs(self.stage_buttons or {}) do
    if button and not button.dead and button.is_unlocked then
      -- Check completion for all difficulties
      local has_normal = USER_STATS.stages_completed and USER_STATS.stages_completed['normal_' .. button.stage_num]
      local has_hard = USER_STATS.stages_completed and USER_STATS.stages_completed['hard_' .. button.stage_num]
      local has_extreme = USER_STATS.stages_completed and USER_STATS.stages_completed['extreme_' .. button.stage_num]

      if has_normal or has_hard or has_extreme then
        local indicator_y = button.y + button.h/2 + 5
        local indicator_size = 3

        -- Draw small circles for each completed difficulty
        local spacing = 8
        local start_x = button.x - spacing

        if has_normal then
          graphics.circle(start_x - spacing, indicator_y, indicator_size, green[5])
        end
        if has_hard then
          graphics.circle(start_x, indicator_y, indicator_size, yellow[5])
        end
        if has_extreme then
          graphics.circle(start_x + spacing, indicator_y, indicator_size, red[5])
        end
      end
    end
  end
end
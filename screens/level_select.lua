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
  self.options_ui = Group():no_camera()
  self.paused = false

  -- Title
  self.title_text = Text2{group = self.ui, x = gw/2, y = 30, lines = {{text = '[wavy_mid, fg]SELECT LEVEL', font = fat_font, alignment = 'center'}}}

  -- Back button
  self.back_button = Button{group = self.main_ui, x = 40, y = gh - 20, force_update = true, button_text = 'back', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
      main:go_to('mainmenu')
    end}
  end}

  -- Stage data structure
  self.stage_buttons = {}
  self.stage_data = {}

  -- Load stage completion data
  system.load_stats()
  if not USER_STATS.stages_completed then USER_STATS.stages_completed = {} end
  if not USER_STATS.stages_no_damage then USER_STATS.stages_no_damage = {} end

  -- Layout constants
  local COLUMN_TITLE_Y = 50  -- Y position for column titles
  local FIRST_BUTTON_Y = 70  -- Y position for first button (directly under titles)
  local BUTTON_SPACING = 20  -- Vertical spacing between buttons
  local COLUMN_SPACING = 60  -- Horizontal spacing between columns
  local BUTTON_SIZE = 40     -- Size of level buttons

  -- Create stage columns
  local column_x_start = gw/2 + 30  -- Start position for columns on right side
  local levels_per_column = 8

  -- Column headers
  local difficulties = {'normal', 'hard', 'extreme'}
  local column_colors = {
    normal = green[5],
    hard = yellow[5],
    extreme = red[5]
  }

  for col = 1, 3 do
    local difficulty = difficulties[col]
    local column_x = column_x_start + (col - 1) * COLUMN_SPACING

    -- Column title
    Text2{group = self.ui, x = column_x, y = COLUMN_TITLE_Y, lines = {{text = '[wavy_mid, fg]' .. string.upper(difficulty), font = pixul_font, alignment = 'center'}}}

    -- Create stage buttons for this column
    for row = 1, levels_per_column do
      local stage_id = difficulty .. '_' .. row
      local button_y = FIRST_BUTTON_Y + (row - 1) * BUTTON_SPACING

      -- Check if stage is unlocked
      local is_unlocked = self:is_stage_unlocked(difficulty, row)
      local is_beaten = USER_STATS.stages_completed and USER_STATS.stages_completed[stage_id] or false
      local is_no_damage = USER_STATS.stages_no_damage and USER_STATS.stages_no_damage[stage_id] or false

      -- Create button
      local button = self:create_stage_button(column_x, button_y, difficulty, row, is_unlocked, is_beaten, is_no_damage)
      table.insert(self.stage_buttons, button)

      -- Store stage data
      self.stage_data[stage_id] = {
        difficulty = difficulty,
        stage_number = row,
        unlocked = is_unlocked,
        beaten = is_beaten,
        no_damage = is_no_damage
      }
    end
  end
end

function LevelSelectScreen:create_stage_button(x, y, difficulty, stage_number, is_unlocked, is_beaten, is_no_damage)
  local stage_id = difficulty .. '_' .. stage_number
  local BUTTON_SIZE = 36  -- Button size constant

  -- Determine button appearance based on state
  local bg_color = 'bg'
  local fg_color = 'fg'  -- White for playable levels
  local text_color = 'fg'
  local selectable = true

  if not is_unlocked then
    -- Grey out disabled stages
    fg_color = 'bg10'  -- Grey for unplayable levels
    bg_color = 'bg'  -- Use 'bg' instead of 'bg1'
    text_color = 'bg10'  -- Grey text for unplayable
    selectable = false
  elseif is_beaten then
    if is_no_damage then
      fg_color = 'yellow'
      text_color = 'yellow'
    else
      fg_color = 'green'
      text_color = 'green'
    end
  end

  local button_action = nil
  if is_unlocked then
    button_action = function(b)
      ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
        self.transitioning = true

        -- Set difficulty and stage info
        state.difficulty = difficulty
        state.selected_stage = stage_id
        state.stage_number = stage_number
        state.level = 1  -- Gameplay level starts at 1

        -- Start new run with selected stage
        Start_New_Run_And_Go_To_Buy_Screen({
          selected_stage = stage_id,
          difficulty = difficulty,
          stage_number = stage_number
        })
      end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']starting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
    end
  else
    -- Locked stage - no action, button is disabled
    button_action = nil
  end

  -- Create the button
  local button = Button{
    group = self.main_ui,
    x = x,
    y = y,
    w = BUTTON_SIZE,
    h = BUTTON_SIZE,
    force_update = true,
    button_text = tostring(stage_number),
    fg_color = fg_color,
    bg_color = bg_color,
    action = button_action
  }

  -- Override interact_with_mouse after creation since Button:init sets it to true
  button.interact_with_mouse = selectable

  -- For disabled buttons, update the text color
  if not selectable then
    button.text:set_text{{text = '[bg10]' .. tostring(stage_number), font = pixul_font, alignment = 'center'}}
  end

  -- Add visual indicators for beaten/no-damage
  button.stage_id = stage_id
  button.is_beaten = is_beaten
  button.is_no_damage = is_no_damage
  button.difficulty = difficulty

  return button
end

function LevelSelectScreen:is_stage_unlocked(difficulty, stage_number)
  -- Normal stage 1 is always unlocked
  if difficulty == 'normal' and stage_number == 1 then
    return true
  end

  -- Normal stages unlock when previous normal stage is beaten
  if difficulty == 'normal' then
    if stage_number > 1 then
      local prev_stage_id = 'normal_' .. (stage_number - 1)
      return USER_STATS.stages_completed and USER_STATS.stages_completed[prev_stage_id] or false
    end
  end

  -- Hard stages unlock when corresponding normal stage is unlocked (not necessarily beaten)
  if difficulty == 'hard' then
    return self:is_stage_unlocked('normal', stage_number)
  end

  -- Extreme stages unlock after beating corresponding hard stage
  if difficulty == 'extreme' then
    local hard_stage_id = 'hard_' .. stage_number
    return USER_STATS.stages_completed and USER_STATS.stages_completed[hard_stage_id] or false
  end

  return false
end

function LevelSelectScreen:on_exit()
  if self.ui then self.ui:destroy() end
  if self.main_ui then self.main_ui:destroy() end
  if self.options_ui then self.options_ui:destroy() end
  self.ui = nil
  self.main_ui = nil
  self.options_ui = nil
  self.title_text = nil
  self.back_button = nil
  self.stage_buttons = nil
  self.stage_data = nil
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

  -- Draw pause overlay
  if self.paused then
    graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent)
  end
  if self.options_ui then self.options_ui:draw() end

  -- Draw additional indicators for buttons
  for _, button in ipairs(self.stage_buttons or {}) do
    if button and not button.dead then
      -- Draw star for beaten stages
      if button.is_beaten then
        local star_color = button.is_no_damage and yellow[5] or green[5]
        local star_size = 6
        local star_x = button.x
        local star_y = button.y - button.h/2 - 8

        -- Simple star indicator
        graphics.circle(star_x, star_y, star_size/2, star_color)

        -- Double star for no damage
        if button.is_no_damage then
          graphics.circle(star_x - 6, star_y, star_size/2, star_color)
          graphics.circle(star_x + 6, star_y, star_size/2, star_color)
        end
      end
    end
  end
end
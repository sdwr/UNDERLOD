Arena = Object:extend()
Arena:implement(GameObject)
function Arena:init(args)
  self:init_game_object(args)

  
  -- Arena properties
  self.level = args.level or 1
  self.offset_x = args.offset_x or 0
  self.offset_y = args.offset_y or 0
  self.level_list = args.level_list
  
  -- Create arena-specific groups
  self.main = Group()
  self.floor = Group()
  self.effects = Group()
  self.ui = Group()
  
  -- Arena state
  self.enemies = {}
  self.troops = {}
  self.walls = {}
  self.door = nil
  self.main_slow_amount = 1
  self.transition_complete = false
  self.enemies_spawned = false

  self.color = self.color or fg[0]

  self.last_spawn_enemy_time = love.timer.getTime()
  
  -- Initialize arena components
  self:init_physics()
  self:init_spawn_manager()
  
  self:create_progress_bar()
  self:create_walls()

  -- self:create_hotbar()

  self.plusgold_text_offset_x = 0
  self.plusgold_text_offset_y = 0


  --self:create_tutorial_popup()

  self.start_time = 3
  self.last_spawn_enemy_time = love.timer.getTime()
  
  -- Start the level
end

function Arena:delete_walls() 
  for i = 1, #self.walls do
    self.walls[i].dead = true
  end
  self.walls = {}
  if self.door then
    self.door.dead = true
    self.door = nil
  end
end

function Arena:create_walls()
  self:delete_walls()
  -- Spawn solids
  self.mid_x = gw/2 + self.offset_x
  self.mid_y = gh/2 + self.offset_y
  self.x1, self.y1 = LEFT_BOUND + self.offset_x, TOP_BOUND + self.offset_y
  self.x2, self.y2 = RIGHT_BOUND + self.offset_x, BOTTOM_BOUND + self.offset_y
  self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
  self.walls[1] = Wall{group = self.main, vertices = math.to_rectangle_vertices(self.offset_x - 40, self.offset_y - 40, self.x1, self.offset_y + gh + 40), color = bg[-1]}
  self.walls[2] = Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x2, self.offset_y - 40, self.offset_x + gw + 40, self.offset_y + gh + 40), color = bg[-1]}
  self.walls[3] = Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x1, self.offset_y - 40, self.x2, self.y1), color = bg[-1]}
  self.walls[4] = Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, self.offset_y + gh + 40), color = bg[-1]}
  self.walls[5] = WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.offset_x - 40, self.offset_y - 40, self.x1, self.offset_y + gh + 40), color = bg[-1]}
  self.walls[6] = WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x2, self.offset_y - 40, self.offset_x + gw + 40, self.offset_y + gh + 40), color = bg[-1]}
  self.walls[7] = WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x1, self.offset_y - 40, self.x2, self.y1), color = bg[-1]}
  self.walls[8] = WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, self.offset_y + gh + 40), color = bg[-1]}
  self:create_door()
end

function Arena:create_progress_bar()
  if Is_Boss_Level(self.level) then
    
  else
    if self.level_list and self.level_list[self.level] then
      self.progress_bar = ProgressBar{group = self.ui, x = gw/2 + self.offset_x, y = 20 + self.offset_y, w = 200, h = 10, color = orange[0], progress = 0}
      self.progress_bar:set_max_progress(self.level_list[self.level].round_power or 0)
      self.progress_bar:set_number_of_waves(#self.level_list[self.level].waves)
      self.progress_bar:set_waves_power(self.level_list[self.level].waves_power)
    end
  end
end

function Arena:select_character_by_index(i)
  --self.hotbar:select_by_index(i)
end

function Arena:create_hotbar()
    --need to group units by character
  -- HotbarGlobals:clear_hotbar()

  -- Helper.Unit.team_button_width = 47
  -- local total_width = (#self.units + 1) * Helper.Unit.team_button_width + #self.units * 5  -- Total width including spacing (+1 for space button)
  -- local start_x = gw/2 - total_width/2  -- Center the entire hotbar
  
  -- -- Add space button at the beginning
  -- local space_button = HotbarButton{group = self.ui, x = start_x + Helper.Unit.team_button_width/2, 
  --                   y = gh - 15, force_update = true, button_text = 'SPACE', w = Helper.Unit.team_button_width, fg_color = 'white', bg_color = 'bg',
  --                   color_marks = {}, character = 'space',
  --                   action = function() 
  --                     -- Space button action - this will be handled by input system
  --                   end
  --                 }
  -- -- self.hotbar:add_button(0, space_button)  -- Use index 0 for space button
  
  -- for i = 1, #self.units do
  --   local character = self.units[i].character
  --   local type = character_types[character]
  --   local number = i
  --   local b = HotbarButton{group = self.ui, x = start_x + Helper.Unit.team_button_width/2 + (Helper.Unit.team_button_width + 5) * i, 
  --                         y = gh - 15, force_update = true, button_text = tostring(i), w = Helper.Unit.team_button_width, fg_color = 'white', bg_color = 'bg',
  --                         color_marks = {[1] = character_colors[character]}, character = character,
  --                         action = function() 
  --                           Helper.Unit.selected_team_index = number
  --                           Helper.Unit:select_team(number)
  --                         end
  --                       }
  --   -- self.hotbar:add_button(i, b)
  -- end
end

function Arena:spawn_critters(spawn_point, amount)
  Spawn_Critters(self, spawn_point, amount)
end

function Arena:init_physics()
  self.floor = Group()
  self.main = Group():set_as_physics_world(32, 0, 0, {'troop', 'enemy', 'projectile', 'enemy_projectile', 'force_field', 'ghost', 'effect', 'door'})
  self.post_main = Group()
  self.effects = Group()
  self.effects:set_custom_draw_list(main_after_characters)
  self.ui = Group()
  self.ui:set_custom_draw_list(main_after_characters)
  self.tutorial = Group()
  self.tutorial:set_custom_draw_list(full_res_draws)
  self.options_ui = Group()
  self.options_ui:set_custom_draw_list(main_after_characters)
  self.credits = Group()
  self.credits:set_custom_draw_list(main_after_characters)

  self.main:disable_collision_between('troop', 'projectile')
  self.main:disable_collision_between('troop', 'troop')
  self.main:disable_collision_between('projectile', 'projectile')
  self.main:disable_collision_between('projectile', 'enemy_projectile')
  self.main:disable_collision_between('projectile', 'enemy')
  self.main:disable_collision_between('enemy', 'enemy')
  self.main:disable_collision_between('enemy_projectile', 'enemy')
  self.main:disable_collision_between('enemy_projectile', 'enemy_projectile')
  self.main:disable_collision_between('projectile', 'force_field')

  self.main:disable_collision_between('ghost', 'troop')
  self.main:disable_collision_between('ghost', 'projectile')
  self.main:disable_collision_between('ghost', 'enemy')

  self.main:disable_collision_between('effect', 'troop')
  self.main:disable_collision_between('effect', 'projectile')
  self.main:disable_collision_between('effect', 'enemy')
  self.main:disable_collision_between('effect', 'enemy_projectile')
  self.main:disable_collision_between('effect', 'solid')
  self.main:disable_collision_between('effect', 'ghost')
  self.main:disable_collision_between('effect', 'force_field')

  --self.main:disable_collision_between('ghost', 'enemy_projectile')
  self.main:disable_collision_between('ghost', 'ghost')
  self.main:disable_collision_between('ghost', 'force_field')

  self.main:disable_collision_between('door', 'troop')
  self.main:disable_collision_between('door', 'enemy')
  self.main:disable_collision_between('door', 'enemy_projectile')
  self.main:disable_collision_between('door', 'projectile')
  self.main:disable_collision_between('door', 'ghost')
  self.main:disable_collision_between('door', 'effect')
  self.main:disable_collision_between('door', 'force_field')


  self.main:enable_trigger_between('projectile', 'enemy')
  self.main:enable_trigger_between('troop', 'enemy_projectile')
  self.main:enable_trigger_between('enemy_projectile', 'enemy')
  self.main:enable_trigger_between('ghost', 'troop')
  self.main:enable_trigger_between('enemy', 'troop')
  self.main:enable_trigger_between('door', 'troop')

end

function Arena:create_door()
  -- Create door on the right side of the arena
  self.door = Door{
    type = 'door',
    group = self.main, -- Put door on post_main so it's drawn above units but below UI
    x = gw - 50 + self.offset_x,
    y = gh/2 + self.offset_y,
    width = 40,
    height = 80,
    parent = self
  }
end

function Arena:open_door()
  if self.door then
    self.door:open()
  end
end

function Arena:init_spawn_manager()
  -- Initialize the proper SpawnManager class
  self.spawn_manager = SpawnManager(self)
end

function Arena:destroy()
  -- Clean up arena resources
  
  self.floor:destroy()
  self.main:destroy()
  self.post_main:destroy()
  self.effects:destroy()
  self.ui:destroy()
  self.credits:destroy()
  self.t:destroy()
  self.floor = nil
  self.main = nil
  self.post_main = nil
  self.effects = nil
  self.ui = nil
  self.tutorial = nil
  self.options_ui = nil
  self.credits = nil
  self.units = nil
  self.passives = nil
  self.player = nil
  self.t = nil
  self.springs = nil
  self.flashes = nil
  self.hfx = nil
  
  -- Mark arena as dead
  self.dead = true
end

function Arena:update(dt)
  self:update_game_object(dt)

  if Helper.Unit:all_troops_are_dead() then
    self:die()
  end
  
  if not self.paused then
    -- Update arena groups
    star_group:update(dt)
    self.floor:update(dt)
    
    self.main:update(dt)
    
    self.post_main:update(dt)
    self.effects:update(dt)
    
    -- Update spawn manager
    if self.spawn_manager then
      self.spawn_manager:update(dt)
    end
  end
end

function Arena:level_clear()
  spawn_mark2:play{pitch = 1, volume = 0.8}
  self.t:after(DOOR_OPEN_DELAY, function() self.door:open() end)
  main.current:increase_level()
  -- Create 3 floor items for selection
  self:create_floor_items()
end

function Arena:create_floor_items()
  self.floor_items = {}
  
  -- Generate 3 random items
  local items = {}
  for i = 1, 3 do
    local tier = LEVEL_TO_TIER(self.level or 1)
    local item = Get_Random_Item(tier, self.units, items)
    if item then
      table.insert(items, item)
    end
  end
  
  -- Position items on the floor
  local positions = {
    {x = gw/2 - 100, y = gh/2},
    {x = gw/2, y = gh/2},
    {x = gw/2 + 100, y = gh/2}
  }
  
  if not self.floor_item_text then
    self.floor_item_text = Text2{group = self.ui, x = gw/2 + self.offset_x, y = gh/2 - 70 + self.offset_y, lines = {{text = '[wavy_mid, cbyc3]Buy an item:', font = fat_font, alignment = 'center'}}}
  end

  for i, item in ipairs(items) do
    if positions[i] then
      self.t:after(ITEM_SPAWN_DELAY_INITAL + i*ITEM_SPAWN_DELAY_OFFSET, function()
        local floor_item = FloorItem{
          group = self.floor,
          x = positions[i].x + self.offset_x,
          y = positions[i].y + self.offset_y,
          item = item,
          parent = self
        }
        table.insert(self.floor_items, floor_item)
      end)
    end
  end
end

function Arena:remove_all_floor_items()
  if self.floor_item_text then
    self.floor_item_text.dead = true
    self.floor_item_text = nil
  end
  if self.floor_items then
    for _, item in ipairs(self.floor_items) do
      item:die()
    end
    self.floor_items = {}
  end
end

function Arena:quit()
  if self.died then return end

  self.quitting = true
  if IS_DEMO and self.level == DEMO_END_LEVEL then
    print('end of demo')
    self:demo_end()
  else
    print('beat level')
    if Is_Boss_Level(self.level) then
      if self.level == 6 then USER_STATS.stompy_defeated = USER_STATS.stompy_defeated + 1
      elseif self.level == 11 then USER_STATS.dragon_defeated = USER_STATS.dragon_defeated + 1
      elseif self.level == 16 then USER_STATS.heigan_defeated = USER_STATS.heigan_defeated + 1
      elseif self.level == 21 then USER_STATS.final_boss_defeated = USER_STATS.final_boss_defeated + 1
      end
    end
    system.save_stats()
    Check_All_Achievements()

    if not self.arena_clear_text then self.arena_clear_text = Text2{group = self.ui, x = gw/2 + self.offset_x, y = gh/2 - 48 + self.offset_y, lines = {{text = '[wavy_mid, cbyc]arena clear!', font = fat_font, alignment = 'center'}}} end
    self:gain_gold(ARENA_TRANSITION_TIME)
    self.t:after(ARENA_TRANSITION_TIME, function()
      self.slow_transitioning = true
      self.t:tween(0.7, self, {main_slow_amount = 0}, math.linear, function() self.main_slow_amount = 0 end)
    end)
      self.t:after(3, function()
      --[[if (self.level-(25*self.loop)) % 3 == 0 and #self.passives < 8 then
        input:set_mouse_visible(true)
        self.arena_clear_text.dead = true
        trigger:tween(1, _G, {slow_amount = 0}, math.linear, function() slow_amount = 0 end, 'slow_amount')
        trigger:tween(1, _G, {music_slow_amount = 0}, math.linear, function() music_slow_amount = 0 end, 'music_slow_amount')
        trigger:tween(4, camera, {x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, r = 0}, math.linear, function() camera.x, camera.y, camera.r = gw/2 + self.offset_x, gh/2 + self.offset_y, 0 end)
        self:set_passives()
        RerollButton{group = main.current.ui, x = gw - 40, y = gh - 40, parent = self, force_update = true}
        self.shop_text = Text({{text = '[wavy_mid, fg]gold: [yellow]' .. gold, font = pixul_font, alignment = 'center'}}, global_text_tags)

        self.build_text = Text2{group = self.ui, x = 40, y = 20, force_update = true, lines = {{text = "[wavy_mid, fg]your build", font = pixul_font, alignment = 'center'}}}
        for i, unit in ipairs(self.units) do
          CharacterPart{group = self.ui, x = 20, y = 40 + (i-1)*19, character = unit.character, level = unit.level, force_update = true, cant_click = true, parent = self}
          Text2{group = self.ui, x = 20 + 14 + pixul_font:get_text_width(unit.character)/2, y = 40 + (i-1)*19, force_update = true, lines = {
            {text = '[' .. character_color_strings[unit.character] .. ']' .. unit.character, font = pixul_font, alignment = 'left'}
          }}
        end
        for i, passive in ipairs(self.passives) do
          ItemCard{group = self.ui, x = 120 + (i-1)*30, y = gh - 30, w = 30, h = 45, sx = 0.75, sy = 0.75, force_update = true, passive = passive.passive , level = passive.level, xp = passive.xp, parent = self}
        end
        ]]--
      self:transition()
    end, 'transition')
  end
end

function Arena:restore_passives_to_pool(j)
  for i = 1, 4 do
    if i ~= j then
      if self.cards[i] then
        table.insert(run_passive_pool, self.cards[i].passive)
      end
    end
  end
end

function Arena:draw_spawn_markers()
  for i = 1, #SpawnGlobals.spawn_markers do
    local location = SpawnGlobals.spawn_markers[i]
    graphics.push(location.x, location.y)
    graphics.circle(location.x, location.y, 4, yellow[0], 1)
    graphics.pop()
  end

end

function Arena:create_tutorial_popup()
  local combat_tutorial_lines = {
    {text = '[fg]Combat Tutorial', font = fat_font, alignment = 'center'},
    {text = '', height_multiplier = 0.1}, -- Spacer
    {text = '[yellow]Left Click(hold):[fg] move troop', font = pixul_font, height_multiplier = 1.5},
    {text = '[yellow]Right Click:[fg] Target enemy or rally to location', font = pixul_font, height_multiplier = 1.5},
    {text = '[yellow]Space(hold):[fg] move all troops', font = pixul_font, height_multiplier = 1.5},
    {text = '[yellow]Numbers 1-3:[fg] select troop', font = pixul_font, height_multiplier = 1.5},
    {text = '[yellow]Esc:[fg] open options', font = pixul_font, height_multiplier = 1.5},
  }

  self.tutorial_popup = TutorialPopup{
    group = self.tutorial, 
    parent = self,
    lines = combat_tutorial_lines,
    display_show_hints_checkbox = true,
    draw_bg = false,
  }
end

function Arena:quit_tutorial()
  self.in_tutorial = false
  self.paused = false
end

function Arena:display_text()
  if self.start_time and self.start_time > 0 and not self.choosing_passives then
    graphics.push(gw/2, gh/2 - 48, 0, self.hfx.condition1.x, self.hfx.condition1.x)
      graphics.print_centered(tostring(self.start_time), fat_font, gw/2, gh/2 - 48, 0, 1, 1, nil, nil, self.hfx.condition1.f and fg[0] or red[0])
    graphics.pop()
  end

  if self.boss_level then
    if self.start_time <= 0 then
      graphics.push(self.x2 - 106, self.y1 - 10, 0, self.hfx.condition2.x, self.hfx.condition2.x)
        graphics.print_centered('kill the elite', fat_font, self.x2 - 106, self.y1 - 10, 0, 0.6, 0.6, nil, nil, fg[0])
      graphics.pop()
    end
  else
    if self.win_condition then
      if self.win_condition == 'wave' then
        if self.start_time <= 0 then
          graphics.push(self.x2 - 50, self.y1 - 10, 0, self.hfx.condition2.x, self.hfx.condition2.x)
            graphics.print_centered('wave:', fat_font, self.x2 - 50, self.y1 - 10, 0, 0.6, 0.6, nil, nil, fg[0])
          graphics.pop()
          local wave = self.wave
          if wave > self.max_waves then wave = self.max_waves end
          graphics.push(self.x2 - 25 + fat_font:get_text_width(wave .. '/' .. self.max_waves)/2, self.y1 - 8, 0, self.hfx.condition1.x, self.hfx.condition1.x)
            graphics.print(wave .. '/' .. self.max_waves, fat_font, self.x2 - 25, self.y1 - 8, 0, 0.75, 0.75, nil, fat_font.h/2, self.hfx.condition1.f and fg[0] or yellow[0])
          graphics.pop()
        end
      end
    end
  end

end


function Arena:draw()
  self:draw_game_object()
  
  -- Draw arena groups
  self.floor:draw()
  self.main:draw()
  self.post_main:draw()
  self.effects:draw()  
end

function Arena:die()
  if not self.died_text and not self.won and not self.arena_clear_text then
    -- input:set_mouse_visible(true)
    self.t:cancel('divine_punishment')
    self.died = true
    locked_state = false
    system.save_run()
    self.t:tween(2, self, {main_slow_amount = 0}, math.linear, function() self.main_slow_amount = 0 end)
    self.t:tween(2, _G, {music_slow_amount = 0}, math.linear, function() music_slow_amount = 0 end)
    self.died_text = Text2{group = self.ui, x = gw/2 + self.offset_x, y = gh/2 - 32 + self.offset_y, lines = {
      {text = '[wavy_mid, cbyc]you died...', font = fat_font, alignment = 'center', height_multiplier = 1.25},
    }}
    -- trigger:tween(2, camera, {x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, r = 0}, math.linear, function() camera.x, camera.y, camera.r = gw/2 + self.offset_x, gh/2 + self.offset_y, 0 end)
    self.t:after(2, function()
      self.death_info_text = Text2{group = self.ui, x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, sx = 0.7, sy = 0.7, lines = {
        {text = '[wavy_mid, fg]level reached: [wavy_mid, yellow]' .. self.level, font = fat_font, alignment = 'center'},
      }}
      self.restart_button = Button{group = self.ui, x = gw/2 + self.offset_x, y = gh/2 + 24 + self.offset_y, force_update = true, button_text = 'restart run', fg_color = 'bg10', bg_color = 'bg', action = function(b)
        self.transitioning = true
        ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        TransitionEffect{group = main.transitions, x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
          slow_amount = 1
          music_slow_amount = 1
          run_time = 0
          gold = STARTING_GOLD
          passives = {}
          main_song_instance:stop()
          run_passive_pool = {}
          max_units = MAX_UNITS
          main:add(BuyScreen'buy_screen')
          system.save_run()
          local new_run = Start_New_Run()
          main:go_to('buy_screen', new_run)
        end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']restarting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
      end}
    end)
    return true
  end
end


function Arena:endless()
  if self.clicked_loop then return end
  self.clicked_loop = true
  if current_new_game_plus >= 5 then current_new_game_plus = 5
  else current_new_game_plus = current_new_game_plus - 1 end
  if current_new_game_plus < 0 then current_new_game_plus = 0 end
  self.loop = self.loop + 1
  self:transition()
end


function Arena:create_credits()
  local open_url = function(b, url)
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    b.spring:pull(0.2, 200, 10)
    b.selected = true
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    system.open_url(url)
  end

  self.close_button = Button{group = self.credits, x = gw - 20, y = 20, button_text = 'x', bg_color = 'bg', fg_color = 'bg10', credits_button = true, action = function()
    trigger:after(0.01, function()
      self.in_credits = false
      if self.credits_button then self.credits_button:on_mouse_exit() end
      for _, object in ipairs(self.credits.objects) do
        object.dead = true
      end
      self.credits:update(0)
    end)
  end}

  self.in_credits = true
  Text2{group = self.credits, x = 60, y = 20, lines = {{text = '[bg10]main dev: ', font = pixul_font}}}
  Button{group = self.credits, x = 117, y = 20, button_text = 'a327ex', fg_color = 'bg10', bg_color = 'bg', credits_button = true, action = function(b) open_url(b, 'https://store.steampowered.com/dev/a327ex/') end}
  Text2{group = self.credits, x = 60, y = 50, lines = {{text = '[bg10]mobile: ', font = pixul_font}}}
  Button{group = self.credits, x = 144, y = 50, button_text = 'David Khachaturov', fg_color = 'bg10', bg_color = 'bg', credits_button = true, action = function(b) open_url(b, 'https://davidobot.net/') end}
  Text2{group = self.credits, x = 60, y = 80, lines = {{text = '[blue]libraries: ', font = pixul_font}}}
  Button{group = self.credits, x = 113, y = 80, button_text = 'love2d', fg_color = 'bluem5', bg_color = 'blue', credits_button = true, action = function(b) open_url(b, 'https://love2d.org') end}
  Button{group = self.credits, x = 170, y = 80, button_text = 'bakpakin', fg_color = 'bluem5', bg_color = 'blue', credits_button = true, action = function(b) open_url(b, 'https://github.com/bakpakin/binser') end}
  Button{group = self.credits, x = 237, y = 80, button_text = 'davisdude', fg_color = 'bluem5', bg_color = 'blue', credits_button = true, action = function(b) open_url(b, 'https://github.com/davisdude/mlib') end}
  Button{group = self.credits, x = 306, y = 80, button_text = 'tesselode', fg_color = 'bluem5', bg_color = 'blue', credits_button = true, action = function(b) open_url(b, 'https://github.com/tesselode/ripple') end}
  Text2{group = self.credits, x = 60, y = 110, lines = {{text = '[green]music: ', font = pixul_font}}}
  Button{group = self.credits, x = 100, y = 110, button_text = 'kubbi', fg_color = 'greenm5', bg_color = 'green', credits_button = true, action = function(b) open_url(b, 'https://kubbimusic.com/album/ember') end}
  Text2{group = self.credits, x = 60, y = 140, lines = {{text = '[yellow]sounds: ', font = pixul_font}}}
  Button{group = self.credits, x = 135, y = 140, button_text = 'sidearm studios', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://sidearm-studios.itch.io/ultimate-sound-fx-bundle') end}
  Button{group = self.credits, x = 217, y = 140, button_text = 'justinbw', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/JustinBW/sounds/80921/') end}
  Button{group = self.credits, x = 279, y = 140, button_text = 'jcallison', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/jcallison/sounds/258269/') end}
  Button{group = self.credits, x = 342, y = 140, button_text = 'hybrid_v', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/Hybrid_V/sounds/321215/') end}
  Button{group = self.credits, x = 427, y = 140, button_text = 'womb_affliction', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/womb_affliction/sounds/376532/') end}
  Button{group = self.credits, x = 106, y = 160, button_text = 'bajko', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/bajko/sounds/399656/') end}
  Button{group = self.credits, x = 157, y = 160, button_text = 'benzix2', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/benzix2/sounds/467951/') end}
  Button{group = self.credits, x = 204, y = 160, button_text = 'lord', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://store.steampowered.com/developer/T_TGames') end}
  Button{group = self.credits, x = 262, y = 160, button_text = 'InspectorJ', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/InspectorJ/sounds/458586/') end}
  Text2{group = self.credits, x = 70, y = 190, lines = {{text = '[red]playtesters: ', font = pixul_font}}}
  Button{group = self.credits, x = 130, y = 190, button_text = 'Jofer', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/JofersGames') end}
  Button{group = self.credits, x = 172, y = 190, button_text = 'ekun', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/ekunenuke') end}
  Button{group = self.credits, x = 224, y = 190, button_text = 'cvisy_GN', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/cvisy_GN') end}
  Button{group = self.credits, x = 292, y = 190, button_text = 'Blue Fairy', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/blue9fairy') end}
  Button{group = self.credits, x = 362, y = 190, button_text = 'Phil Blank', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/PhilBlankGames') end}
  Button{group = self.credits, x = 440, y = 190, button_text = 'DefineDoddy', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/DefineDoddy') end}
  Button{group = self.credits, x = 140, y = 210, button_text = 'Ge0force', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/Ge0forceBE') end}
  Button{group = self.credits, x = 193, y = 210, button_text = 'Vlad', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/thecryru') end}
  Button{group = self.credits, x = 258, y = 210, button_text = 'Yongmin Park', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/yongminparks') end}
end


--gold is the global gold variable
--need to sum the gold gained, then display it visually in 2 seconds
--so create a list of +gold events, then display them one by one

--not satisfying, numbers aren't understandable
--maybe just have the total gold # on screen, then add the gold gained to it
--and have a popup with the place the gold is from ('interest', 'heart of gold')
--should have round end gold here too
function Arena:gain_gold(duration)

  self.gold_events = {}
  self.bonus_gold = 0
  self.stacks_of_interest = 0
  self.total_interest = 0
  self.gold_gained = self.gold_gained or 0
  self.gold_picked_up = self.gold_picked_up or 0

  local event = nil

  --empty event first 
  event = {type = 'start', amount = 0}
  table.insert(self.gold_events, event)

  --base gold gain
  local amount = GOLD_PER_ROUND
  local boss_round_index = table.find(BOSS_ROUNDS, self.level)
  if boss_round_index then
    amount = GOLD_FOR_BOSS_ROUND[boss_round_index]
  end

  event = {type = 'gained', amount = amount}
  table.insert(self.gold_events, event)

  for _, unit in ipairs(self.starting_units) do
    for _, item in ipairs(unit.items) do
      if item.name == 'heartofgold' then
        event = {type = 'bonus gold', amount = item.stats.gold}
        table.insert(self.gold_events, event)
      end
      if item.name == 'stockmarket' then
        event = {type = 'interest', amount = 1}
        table.insert(self.gold_events, event)
      end
    end
  end

  if self.gold_picked_up > 0 then
    event = {type = 'picked up', amount = self.gold_picked_up}
    table.insert(self.gold_events, event)
    self.gold_picked_up = 0
  end

  if self.gold_gained > 0 then
    event = {type = 'gained', amount = self.gold_gained}
    table.insert(self.gold_events, event)
    self.gold_gained = 0
  end

  if #self.gold_events == 0 then
    return
  end

  local final_event = {type = 'final', amount = 0}
  table.insert(self.gold_events, final_event)

  --create a trigger to add each gold event over time
  --have to cancel when the table is empty
  local timePerEvent = duration / #self.gold_events
  trigger:every(timePerEvent, function() 
    self:process_gold_event()
  end, #self.gold_events)

end


function Arena:process_gold_event()
  self:clear_gold()
  if #self.gold_events == 0 then
    print('no more gold events')
    return
  end
  local event = table.remove(self.gold_events, 1)

  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}

  local plusgold = 0
  local plusgoldtext = nil

  if event.type == 'gained' then
    plusgold = event.amount
    plusgoldtext = '[wavy_mid, yellow[0]]' .. tostring(plusgold) .. ' ' .. event.type
  elseif event.type == 'picked_up' then
    plusgold = event.amount
    plusgoldtext = '[wavy_mid, yellow[0]]' .. tostring(plusgold) .. ' ' .. event.type
  elseif event.type == 'bonus gold' then
    plusgold = event.amount
    plusgoldtext = '[wavy_mid, yellow[0]]' .. tostring(plusgold) .. ' ' .. event.type
  elseif event.type == 'interest' then
    plusgold = event.amount * math.min(MAX_INTEREST, math.floor(gold * INTEREST_AMOUNT))
    plusgoldtext = '[wavy_mid, yellow[0]]' .. tostring(plusgold) .. ' ' ..event.type
  elseif event.type == 'start' then
    --do nothing
  elseif event.type == 'final' then
    Stats_Max_Gold()
  else
    print('unknown gold event type')
    return
  end

  self:draw_gold(plusgold, plusgoldtext)
  self:randomize_plusgold_text_offset()

  if plusgold > 0 then
    gold = gold + plusgold
  end


end

--we want to show the gained gold, and the total gold
--and the total gold includes all the previous gold gains
-- the final event will add in the last gold gain to the total gold
--and everything will add up
function Arena:draw_gold(plusgold, plusgoldtext)
  local text_content = '[wavy_mid, yellow[0]' .. tostring(gold) .. ' gold '
  self.gold_text = Text({{text = text_content, font = fat_font, alignment = 'center'}}, global_text_tags)

  if plusgold == 0 then return end
  if plusgoldtext == nil then return end

  self.plusgold_text = Text({{text = plusgoldtext, font = pixul_font, alignment = 'center'}}, global_text_tags)
  
end

function Arena:randomize_plusgold_text_offset()
  local sign_x = random:float(0, 1)
  if sign_x < 0.5 then sign_x = -1 else sign_x = 1 end
  local sign_y = random:float(0, 1)
  if sign_y < 0.5 then sign_y = -1 else sign_y = 1 end

  self.plusgold_text_offset_x = random:float(0, 20) * sign_x
  self.plusgold_text_offset_y = random:float(20, 30) * sign_y
end

function Arena:clear_gold()
  self.gold_text = nil
  self.plusgold_text = nil
end

function Arena:set_timer_text()
  self.timer_text = Text({{text = '[wavy_mid, yellow[0] ' .. tostring(math.floor(self.time_elapsed)) .. 's', font = pixul_font, alignment = 'center'}}, global_text_tags)
end

function Arena:update_units_with_combat_data()
  -- Update the saved units with combat data from teams
  for i, saved_unit in ipairs(self.units) do
    -- Find the corresponding team by character and position
    for j, team in ipairs(Helper.Unit.teams) do
      if team.unit.character == saved_unit.character and j == i then
        -- Save combat data from team to saved unit
        team:save_combat_data_to_unit()
        break
      end
    end
  end
end


--beat level (win)
function Arena:transition()
  self.transitioning = true
  ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  
  -- Check if this level grants a perk
  if LEVEL_TO_PERKS[self.level] then
    -- Show perk selection overlay
    PerkOverlay{
      group = self.ui,
      perks = self.perks or {}
    }
    return
  end
  
  -- Normal transition to buy screen
  TransitionEffect{group = main.transitions, x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, color = state.dark_transitions and bg[-2] or self.color, transition_action = function(t)

    -- Update units with combat data before transitioning
    self:update_units_with_combat_data()

    Reset_Global_Proc_List()
    slow_amount = 1
    music_slow_amount = 1
    main:add(BuyScreen'buy_screen')
    local save_data = Collect_Save_Data_From_State(self)

    save_data.level = save_data.level + 1
    save_data.reroll_shop = true
    save_data.times_rerolled = 0

    Stats_Level_Complete()
    Stats_Max_Gold()

    system.save_run(save_data)

    main:go_to('buy_screen', save_data)

  end, nil}
end

function Arena:demo_end()
  self.won = true

  trigger:after(2.5, function()
    self.win_text = Text2{group = self.ui, x = gw/2 + 40 + self.offset_x, y = gh/2 - 69 + self.offset_y, force_update = true, lines = {{text = '[wavy_mid, cbyc2]congratulations!', font = fat_font, alignment = 'center'}}}
    self.win_text2 = Text2{group = self.ui, x = gw/2 + 40 + self.offset_x, y = gh/2 + 20 + self.offset_y, force_update = true, lines = {
      {text = "[fg]end of the demo", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
      {text = "[fg]thanks for playing!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
    }}

    -- self.build_text = Text2{group = self.ui, x = 40, y = 20, force_update = true, lines = {{text = "[wavy_mid, fg]your build", font = pixul_font, alignment = 'center'}}}

    -- for i, unit in ipairs(self.units) do
    --   CharacterCard{group = self.main, x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, unit = unit, character = unit.character, i = i, parent = self}
    -- end
  end)
end

-- Called when perk selection is complete
function Arena:on_perk_selected()
  -- Continue with normal transition to buy screen
  TransitionEffect{group = main.transitions, x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, color = state.dark_transitions and bg[-2] or self.color, transition_action = function(t)

    -- Update units with combat data before transitioning
    self:update_units_with_combat_data()

    Reset_Global_Proc_List()
    slow_amount = 1
    music_slow_amount = 1
    main:add(BuyScreen'buy_screen')
    local save_data = Collect_Save_Data_From_State(self)

    save_data.level = save_data.level + 1
    save_data.reroll_shop = true
    save_data.times_rerolled = 0

    Stats_Level_Complete()
    Stats_Max_Gold()

    system.save_run(save_data)

    main:go_to('buy_screen', save_data)

  end, nil}
end
--on game win (beat final boss)
function Arena:on_win()
  self:gain_gold(ARENA_TRANSITION_TIME)

  if not self.win_text and not self.win_text2 then
    -- input:set_mouse_visible(true)
    self.won = true
    locked_state = false

    if current_new_game_plus == new_game_plus then
      new_game_plus = new_game_plus + 1
      state.new_game_plus = new_game_plus
    end
    current_new_game_plus = current_new_game_plus + 1
    state.current_new_game_plus = current_new_game_plus
    max_units = MAX_UNITS

    system.save_run()
    trigger:tween(1, _G, {slow_amount = 0}, math.linear, function() slow_amount = 0 end, 'slow_amount')
    trigger:tween(1, _G, {music_slow_amount = 0}, math.linear, function() music_slow_amount = 0 end, 'music_slow_amount')
    -- trigger:tween(4, camera, {x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, r = 0}, math.linear, function() camera.x, camera.y, camera.r = gw/2 + self.offset_x, gh/2 + self.offset_y, 0 end)
    self.win_text = Text2{group = self.ui, x = gw/2 + 40 + self.offset_x, y = gh/2 - 69 + self.offset_y, force_update = true, lines = {{text = '[wavy_mid, cbyc2]congratulations!', font = fat_font, alignment = 'center'}}}
    trigger:after(2.5, function()
      local open_url = function(b, url)
        ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        b.spring:pull(0.2, 200, 10)
        b.selected = true
        ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        system.open_url(url)
      end

      self.build_text = Text2{group = self.ui, x = 40, y = 20, force_update = true, lines = {{text = "[wavy_mid, fg]your build", font = pixul_font, alignment = 'center'}}}
      for i, unit in ipairs(self.units) do
        CharacterPart{group = self.ui, x = 20, y = 40 + (i-1)*19, unit = unit, character = unit.character, level = unit.level, force_update = true, cant_click = true, parent = self}
        Text2{group = self.ui, x = 20 + 14 + pixul_font:get_text_width(unit.character)/2, y = 40 + (i-1)*19, force_update = true, lines = {
          {text = '[' .. character_color_strings[unit.character] .. ']' .. unit.character, font = pixul_font, alignment = 'left'}
        }}
      end
      for i, passive in ipairs(self.passives) do
        ItemCard{group = self.ui, x = 120 + (i-1)*30, y = 20, w = ITEM_CARD_WIDTH, h = ITEM_CARD_HEIGHT, sx = 0.75, sy = 0.75, force_update = true, passive = passive.passive , level = passive.level, xp = passive.xp, parent = self}
      end

      if current_new_game_plus == 6 then
        if current_new_game_plus == new_game_plus then
          new_game_plus = 5
          state.new_game_plus = new_game_plus
        end
        current_new_game_plus = 5
        state.current_new_game_plus = current_new_game_plus
        max_units = MAX_UNITS

        self.win_text2 = Text2{group = self.ui, x = gw/2 + 40 + self.offset_x, y = gh/2 + 20 + self.offset_y, force_update = true, lines = {
          {text = "[fg]now you've really beaten the game!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
          {text = "[fg]thanks a lot for playing it and completing it entirely!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
          {text = "[fg]this game was inspired by:", font = pixul_font, alignment = 'center', height_multiplier = 3.5},
          {text = "[fg]so check them out! and to get more games like this:", font = pixul_font, alignment = 'center', height_multiplier = 3.5},
          {text = "[wavy_mid, yellow]thanks for playing!", font = pixul_font, alignment = 'center'},
        }}
        SteamFollowButton{group = self.ui, x = gw/2 + 40 + self.offset_x, y = gh/2 + 58 + self.offset_y, force_update = true}
        Button{group = self.ui, x = gw - 40, y = gh - 44, force_update = true, button_text = 'credits', fg_color = 'bg10', bg_color = 'bg', action = function() self:create_credits() end}
        Button{group = self.ui, x = gw - 39, y = gh - 20, force_update = true, button_text = '  loop  ', fg_color = 'bg10', bg_color = 'bg', action = function() self:endless() end}
        self.try_loop_text = Text2{group = self.ui, x = gw - 144, y = gh - 20, force_update = true, lines = {
          {text = '[bg10]continue run (+difficulty):', font = pixul_font},
        }}
        Button{group = self.ui, x = gw/2 - 50 + 40, y = gh/2 + 12, force_update = true, button_text = 'nimble quest', fg_color = 'bluem5', bg_color = 'blue', action = function(b) open_url(b, 'https://store.steampowered.com/app/259780/Nimble_Quest/') end}
        Button{group = self.ui, x = gw/2 + 50 + 40, y = gh/2 + 12, force_update = true, button_text = 'dota underlords', fg_color = 'bluem5', bg_color = 'blue', action = function(b) open_url(b, 'https://store.steampowered.com/app/1046930/Dota_Underlords/') end}

      else
        self.win_text2 = Text2{group = self.ui, x = gw/2 + 40 + self.offset_x, y = gh/2 + 5 + self.offset_y, force_update = true, lines = {
          {text = "[fg]you've beaten the game!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
          {text = "[fg]if you liked it:", font = pixul_font, alignment = 'center', height_multiplier = 3.5},
          {text = "[fg]and if you liked the music:", font = pixul_font, alignment = 'center', height_multiplier = 3.5},
          {text = "[wavy_mid, yellow]thanks for playing!", font = pixul_font, alignment = 'center'},
        }}
        --[[
        self.win_text2 = Text2{group = self.ui, x = gw/2 + 40, y = gh/2 + 20, force_update = true, lines = {
          {text = "[fg]you've beaten the game!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
          {text = "[fg]i made this game in 3 months as a dev challenge", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
          {text = "[fg]and i'm happy with how it turned out!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
          {text = "[fg]if you liked it too and want to play more games like this:", font = pixul_font, alignment = 'center', height_multiplier = 4},
          {text = "[fg]i will release more games this year, so stay tuned!", font = pixul_font, alignment = 'center', height_multiplier = 1.4},
          {text = "[wavy_mid, yellow]thanks for playing!", font = pixul_font, alignment = 'center'},
        }}
        ]]--
        SteamFollowButton{group = self.ui, x = gw/2 + 40 + self.offset_x, y = gh/2 - 10 + self.offset_y, force_update = true}
        Button{group = self.ui, x = gw/2 + 40 + self.offset_x, y = gh/2 + 33 + self.offset_y, force_update = true, button_text = 'buy the soundtrack!', fg_color = 'greenm5', bg_color = 'green', action = function(b) open_url(b, 'https://kubbimusic.com/album/ember') end}
        Button{group = self.ui, x = gw - 40, y = gh - 44, force_update = true, button_text = '  loop  ', fg_color = 'bg10', bg_color = 'bg', action = function() self:endless() end}
        RestartButton{group = self.ui, x = gw - 40, y = gh - 20, force_update = true}
        self.try_loop_text = Text2{group = self.ui, x = gw - 200, y = gh - 44, force_update = true, lines = {
          {text = '[bg10]continue run (+difficulty, +1 max snake size):', font = pixul_font},
        }}
        self.try_ng_text = Text2{group = self.ui, x = gw - 187, y = gh - 20, force_update = true, lines = {
          {text = '[bg10]new run (+difficulty, +1 max snake size):', font = pixul_font},
        }}
        self.credits_button = Button{group = self.ui, x = gw - 40, y = gh - 68, force_update = true, button_text = 'credits', fg_color = 'bg10', bg_color = 'bg', action = function() self:create_credits() end}
      end
    end)

    if current_new_game_plus == 2 then
      state.achievement_new_game_1 = true
      system.save_state()
    end

    if current_new_game_plus == 6 then
      state.achievement_new_game_5 = true
      system.save_state()
    end
  end

end

function Arena:spawn_n_critters(p, j, n, pass, parent)
  self.spawning_enemies = true
  if self.died then return end
  if self.arena_clear_text then return end
  if self.quitting then return end
  if self.won then return end
  if self.choosing_passives then return end
  if n and n <= 0 then return end

  j = j or 1
  n = n or 4
  self.last_spawn_enemy_time = love.timer.getTime()
  local check_circle = Circle(0, 0, 2)
  self.t:every(0.1, function()
    local o = self.spawn_offsets[(self.t:get_every_iteration('spawn_enemies_' .. j) % 5) + 1]
    SpawnEffect{group = self.effects, x = p.x + o.x, y = p.y + o.y, action = function(x, y)
      if not pass then
        check_circle:move_to(x, y)
        local objects = self.main:get_objects_in_shape(check_circle, {Enemy, EnemyCritter, Critter, Player})
        if #objects > 0 then self.enemy_spawns_prevented = self.enemy_spawns_prevented + 1; return end
      end
      critter3:play{pitch = random:float(0.8, 1.2), volume = 0.8}
      parent.summons = parent.summons + 1
      EnemyCritter{group = self.main, x = x, y = y, color = grey[0], r = random:float(0, 2*math.pi), v = 10, parent = parent}

    end}
  end, n, function() self.spawning_enemies = false end, 'spawn_enemies_' .. j)
end

FloorItem = Object:extend()
FloorItem:implement(GameObject)
function FloorItem:init(args)
  self:init_game_object(args)
  
  self.item = args.item
  --cost only used as tier
  self.cost = self.item.cost
  self.image = find_item_image(self.item)
  self.colors = self.item.colors
  self.tier_color = item_to_color(self.item)
  self.stats = self.item.stats
  
  -- Collision detection radius
  self.interaction_radius = 40
  self.aggro_sensor = Circle(self.x, self.y, self.interaction_radius)
  
  -- Visual effects
  self.hover_timer = 0
  self.hover_duration = 2
  self.shake_timer = 0
  self.shake_duration = 2
  self.shake_intensity = 0
  self.is_hovered = false
  self.is_purchased = false
  self.failed_to_purchase = false
  

  self.hover_sound= nil
  self.hover_sound_pitch = 1
  self.hover_sound_pitch_next = 0.5

  -- Mouse interaction
  self.shape = Rectangle(self.x, self.y, 60, 80)
  self.interact_with_mouse = true
  self.colliding_with_mouse = false

  
  -- Cost text
  -- self.cost_text = Text({{text = '[yellow]' .. self.cost, font = pixul_font, alignment = 'center'}}, global_text_tags)
  
  -- Creation effect
  self:creation_effect()
end

function FloorItem:creation_effect()
  if self.cost <= 5 then
    --no effect
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 10 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif self.cost <= 10 then
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.7}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 20 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif self.cost <= 15 then
    pop1:play{pitch = random:float(0.95, 1.05), volume = 0.8}
    self.spring:pull(0.4, 200, 10)
    for i = 1, 30 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  else
    gold3:play{pitch = random:float(0.95, 1.05), volume = 0.8}
    self.spring:pull(0.6, 200, 10)
    for i = 1, 40 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  
  end
end

function FloorItem:update(dt)
  self:update_game_object(dt)
  
  -- Handle tooltip
  if self.colliding_with_mouse then
    if not self.tooltip then
      self:create_tooltip()
    end
  else
    self:remove_tooltip()
  end

  if self.parent and self.parent.main then
    local objects = self.parent.main:get_objects_in_shape(self.aggro_sensor, troop_classes)
    if #objects > 0 then
      self.is_hovered = true
    else
      self.is_hovered = false
      self.failed_to_purchase = false
    end
  end
  
  -- Update hover timer and shake
  if self.is_hovered and not self.failed_to_purchase then
    self.hover_timer = self.hover_timer + dt
    self.hover_sound_pitch_next = self.hover_sound_pitch_next - dt
    if self.hover_sound_pitch_next <= 0 then
      self:hover_sound_pitch_up()
    end
    -- Start shaking immediately when unit is on it
    if self.shake_timer <= 0 then
      self:start_shake()
    end
  else
    -- Reset when unit leaves
    self.hover_timer = 0
    self.shake_timer = 0
    self.shake_intensity = 0
  end
  
  -- Update shake
  if self.shake_timer > 0 then
    self.shake_timer = self.shake_timer - dt
    self.shake_intensity = math.max(0, self.shake_timer / self.shake_duration)
    
    -- Purchase after 2 seconds of shaking
    if self.shake_timer <= 0 then
      self:purchase()
    end
  end
end

function FloorItem:hover_sound_pitch_up()
  self.hover_sound_pitch_next = 0.5
  self.hover_sound_pitch = self.hover_sound_pitch + .3

  if self.hover_sound then
    self.hover_sound:stop()
  end
  self.hover_sound = ui_modern_hover:play{pitch = self.hover_sound_pitch, volume = 1}
end

function FloorItem:start_shake()
  if self.shake_timer <= 0 then
    self.shake_timer = 2 -- 2 seconds of shaking
    self.shake_intensity = 1
  end
  if not self.hover_sound then
    self.hover_sound = ui_modern_hover:play{pitch = self.hover_sound_pitch, volume = 1}
  end
end

function FloorItem:stop_shake()
  self.hover_timer = 0
  self.shake_timer = 0
  self.shake_intensity = 0
  if self.hover_sound then
    self.hover_sound:stop()
    self.hover_sound = nil
  end
  self.hover_sound_pitch = 1
  self.hover_sound_pitch_next = 0.5
end

function FloorItem:purchase()
  
  -- Add item to first available slot
  local try_purchase = main.current:put_in_first_available_inventory_slot(self.item)
  if not try_purchase then
    self:remove_tooltip()
    self:stop_shake()
    self.failed_to_purchase = true
    Create_Info_Text('no empty item slots - right click to sell', self)
    return
  end

  self.is_purchased = true
  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
  self:die()
  
  -- -- Deduct gold
  -- gold = gold - self.cost

  main.current:save_run()


  
  -- Purchase effect
  for i = 1, 20 do
    HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
  end
  
  -- Remove all floor items
  -- self.parent:remove_all_floor_items()
end

function FloorItem:draw()
  -- Calculate shake offset
  local shake_x = 0
  local shake_y = 0
  if self.shake_intensity > 0 then
    shake_x = random:float(-3, 3) * self.shake_intensity
    shake_y = random:float(-3, 3) * self.shake_intensity
  end
  
  graphics.push(self.x + shake_x, self.y + shake_y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
  
  -- Draw item background
  local width = 60
  local height = 80
  graphics.rectangle(self.x + shake_x, self.y + shake_y, width, height, 6, 6, bg[5])
  
  -- Draw item colors
  if self.colors then
    local num_colors = #self.colors
    local color_h = height / num_colors
    for i, color_name in ipairs(self.colors) do
      local color = _G[color_name]
      color = color[0]:clone()
      color.a = 0.6
      local y = (self.y - height/2) + ((i-1) * color_h) + (color_h/2)
      graphics.rectangle(self.x + shake_x, y + shake_y, width, color_h, 6, 6, color)
    end
  end
  
  -- Draw border
  graphics.rectangle(self.x + shake_x, self.y + shake_y, width, height, 6, 6, self.tier_color, 2)
  
  
  -- Draw cost text
  -- self.cost_text:draw(self.x + width/2, self.y - height/2)
  
  -- Draw item image
  if self.image then
    self.image:draw(self.x + shake_x, self.y + shake_y, 0, 0.8, 0.8)
  end
  
  -- Draw hover effect
  if self.is_hovered then
    local alpha = math.min(self.hover_timer / self.hover_duration, 1)
    local radius = ((self.hover_timer / self.hover_duration) * 20) + 10
    local color = white[0]
    color.a = alpha * 0.3
    graphics.rectangle(self.x + shake_x, self.y + shake_y, width, height, 6, 6, color)
    graphics.circle(self.x + shake_x, self.y + shake_y, radius, color)
  end
  
  graphics.pop()
end

function FloorItem:create_tooltip()
  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end

  self.tooltip = ItemTooltip{
    group = main.current.ui,
    item = self.item,
    x = gw/2, 
    y = gh/2 - 50,
  }
end

function FloorItem:remove_tooltip()
  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end
end

function FloorItem:die()
  self.dead = true
  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end
end

function Arena:activate_enemies()
  if self.transition_complete and self.enemies_spawned then
    -- Activate all enemies in the arena
    local enemies = self.main:get_objects_by_classes(main.current.enemies)
    for _, enemy in ipairs(enemies) do
      if enemy and not enemy.dead then
        enemy.t:after(0.5, function()
          enemy.transition_active = true
          enemy.idleTimer = enemy.baseIdleTimer or 0.5
        end)
      end
    end
  end
end

function Arena:set_transition_complete()
  self.transition_complete = true
  self:activate_enemies()
end
MainMenu = Object:extend()
MainMenu.__class_name = 'MainMenu'
MainMenu:implement(State)
MainMenu:implement(GameObject)
function MainMenu:init(name)
  self:init_state(name)
  self:init_game_object()
end


function MainMenu:on_enter(from)
  slow_amount = 1
  trigger:tween(2, main_song_instance, {volume = 0.5, pitch = 1}, math.linear)

  -- Set cursor to simple mode for main menu
  set_cursor_simple()
  self.run_autobattle = false

  --steam.friends.setRichPresence('steam_display', '#StatusFull')
  --steam.friends.setRichPresence('text', 'Main Menu')

  self.floor = Group()
  self.main = Group():set_as_physics_world(32, 0, 0, {'troop', 'enemy', 'projectile', 'enemy_projectile', 'force_field', 'ghost'})
  self.post_main = Group()
  self.effects = Group()
  self.main_ui = Group():no_camera()
  self.ui = Group()
  self.options_ui = Group():no_camera()
  self.main:disable_collision_between('troop', 'projectile')
  self.main:disable_collision_between('projectile', 'projectile')
  self.main:disable_collision_between('projectile', 'enemy_projectile')
  self.main:disable_collision_between('projectile', 'enemy')
  self.main:disable_collision_between('enemy_projectile', 'enemy')
  self.main:disable_collision_between('enemy_projectile', 'enemy_projectile')
  self.main:disable_collision_between('troop', 'force_field')
  self.main:disable_collision_between('projectile', 'force_field')
  self.main:disable_collision_between('ghost', 'troop')
  self.main:disable_collision_between('ghost', 'projectile')
  self.main:disable_collision_between('ghost', 'enemy')
  self.main:disable_collision_between('ghost', 'enemy_projectile')
  self.main:disable_collision_between('ghost', 'ghost')
  self.main:disable_collision_between('ghost', 'force_field')
  self.main:enable_trigger_between('projectile', 'enemy')
  self.main:enable_trigger_between('troop', 'enemy_projectile')
  self.main:enable_trigger_between('enemy_projectile', 'enemy')
  self.main:enable_trigger_between('troop', 'ghost')
  self.main:enable_trigger_between('enemy', 'troop')

  self.damage_dealt = 0
  self.damage_taken = 0

  self.troops = troop_classes
  self.enemies = enemy_classes
  self.friendlies = friendly_classes
  self.enemies_without_critters = enemy_classes_without_critters
  self.friendlies_without_critters = friendly_classes_without_critters

  self.units = {}

  -- Initialize Helper system for unit functionality
  if not Helper.initialized then
    Helper:init()
  end

  -- Spawn solids and player
  self.x1, self.y1 = gw/2 - 0.8*gw/2, gh/2 - 0.8*gh/2
  self.x2, self.y2 = gw/2 + 0.8*gw/2, gh/2 + 0.8*gh/2
  self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
  Wall{group = self.main, vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40), color = bg[-1]}

  self.t:every(0.375, function()
    local p = random:table(star_positions)
    Star{group = star_group, x = p.x, y = p.y}
  end)

  if self.run_autobattle then
    self.autobattle = MainMenuAutoBattle{group = self.main}
  end

  self.title_text = Text({{text = '[wavy_mid, fg]UNDERLOD', font = fat_font, alignment = 'center'}}, global_text_tags)
  local run = system.load_run()
  system.load_stats()

  -- Continue button removed - now goes directly to level select
  -- Play button to go to level select
  self.play_button = Button{group = self.main_ui, x = 34, y = gh/2, force_update = true, button_text = 'play', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
      self.transitioning = true
      slow_amount = 1
      main:add(LevelSelectScreen'level_select')
      main:go_to('level_select')
    end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']loading...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
  end}

  self.achievements_panel = AchievementsPanel{group = self.ui}
  self.options_button = Button{group = self.main_ui, x = 47, y = gh/2 + 24, force_update = true, button_text = 'options', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    if not self.paused then
      open_options(self)
    else
      close_options(self)
    end
  end}
  self.quit_button = Button{group = self.main_ui, x = 37, y = gh/2 + 46, force_update = true, button_text = 'quit', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    cleanup_global_cursor()
    system.save_state()
    --steam.shutdown()
    love.event.quit()
  end}

  -- hide for now (achievement test button)
  -- self.unlock_button = Button{group = self.main_ui, x = 40, y = gh/2  + 100, force_update = true, button_text ='unlock', fg_color = 'bg10', bg_color='bg', action = function(b)
    
  --   Unlock_Achievement('heatingup')
  -- end}
  --[[self.t:every(2, function() self.soundtrack_button.spring:pull(0.025, 200, 10) end)
  self.soundtrack_button = Button{group = self.main_ui, x = gw - 72, y = gh - 40, force_update = true, button_text = 'buy the soundtrack!', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    b.spring:pull(0.2, 200, 10)
    b.selected = true
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    system.open_url('https://kubbimusic.com/album/ember')
  end}
  self.discord_button = Button{group = self.main_ui, x = gw - 92, y = gh - 17, force_update = true, button_text = 'join the community discord!', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    b.spring:pull(0.2, 200, 10)
    b.selected = true
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    system.open_url('https://discord.gg/Yjk2Q5gDqA')
  end}]]--
end


function MainMenu:on_exit()
  self.floor:destroy()
  self.main:destroy()
  self.post_main:destroy()
  self.effects:destroy()
  self.ui:destroy()
  self.main_ui:destroy()
  self.t:destroy()
  self.floor = nil
  self.main = nil
  self.post_main = nil
  self.effects = nil
  self.ui = nil
  self.options_ui = nil
  self.units = nil
  self.player = nil
  self.t = nil
  self.springs = nil
  self.flashes = nil
  self.hfx = nil
  self.title_text = nil
  self.play_button = nil
end


function MainMenu:update(dt)
  if main_song_instance:isStopped() then
    main_song_instance = title_music:play{volume = 1}
  end

  if input.escape.pressed then
    if not self.paused then
      open_options(self)
    else
      close_options(self)
    end
  end

  self:update_game_object(dt*slow_amount)

  if not self.paused and not self.transitioning then
    star_group:update(dt*slow_amount)
    self.floor:update(dt*slow_amount)
    self.main:update(dt*slow_amount)
    self.post_main:update(dt*slow_amount)
    self.options_ui:update(dt*slow_amount)
    self.effects:update(dt*slow_amount)
    self.main_ui:update(dt*slow_amount)
    if self.title_text then self.title_text:update(dt) end
    if self.new_game_label then self.new_game_label:update(dt) end
    self.ui:update(dt*slow_amount)
    
    -- Update Helper system for unit functionality
    Helper:update(dt*slow_amount)
  else
    self.options_ui:update(dt*slow_amount)
  end
end


function MainMenu:draw()
  self.floor:draw()
  self.main:draw()
  self.post_main:draw()
  self.effects:draw()
  
  -- Draw Helper system elements (unit effects, etc.)
  Helper:draw()
  
  graphics.draw_with_mask(function()
    star_canvas:draw(0, 0, 0, 1, 1)
  end, function()
    camera:attach()
    graphics.rectangle(gw/2, gh/2, self.w, self.h, nil, nil, fg[0])
    camera:detach()
  end, true)
  graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent)

  self.main_ui:draw()
  self.title_text:draw(70, gh/2 - 40)
  self.ui:draw()
  if self.paused then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent) end
  self.options_ui:draw()
end

MainMenu = Object:extend()
MainMenu:implement(State)
MainMenu:implement(GameObject)
function MainMenu:init(name)
  self:init_state(name)
  self:init_game_object()
end


function MainMenu:on_enter(from)
  slow_amount = 1
  trigger:tween(2, main_song_instance, {volume = 0.5, pitch = 1}, math.linear)

  --steam.friends.setRichPresence('steam_display', '#StatusFull')
  --steam.friends.setRichPresence('text', 'Main Menu')

  self.floor = Group()
  self.main = Group():set_as_physics_world(32, 0, 0, {'troop', 'enemy', 'projectile', 'enemy_projectile', 'force_field', 'ghost'})
  self.post_main = Group()
  self.effects = Group()
  self.main_ui = Group():no_camera()
  self.ui = Group():no_camera()
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

  self.troops = troop_classes
  self.enemies = enemy_classes
  self.friendlies = friendly_classes

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

  self.units = {
    {character = 'swordsman', level = 1},
    {character = 'archer', level = 1},
    {character = 'shaman', level = 1},
  }

  for i, unit in ipairs(self.units) do
    for j=0,4 do
      local troop_data = {group = self.main, x = gw/2 + random:float(-48, 48), y = gh/2 + 16 + random:float(-48, 48), character = unit.character, level = unit.level}
      Create_Troop(troop_data)
    end
  end

  self.title_text = Text({{text = '[wavy_mid, fg]UNDERLOD', font = fat_font, alignment = 'center'}}, global_text_tags)
  local run = system.load_run()

  --continue game
  if(run and not not next(run)) then
    self.arena_continue_button = Button{group = self.main_ui, x = 52, y = gh/2 - 10, force_update = true, button_text = 'continue',  fg_color = 'bg10', bg_color = 'bg', action = function(b)
      ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
        self.transitioning = true
        slow_amount = 1
        run_passive_pool = run.run_passive_pool or {
          'centipede', 'ouroboros_technique_r', 'ouroboros_technique_l', 'amplify', 'resonance', 'ballista', 'call_of_the_void', 'crucio', 'speed_3', 'damage_4', 'shoot_5', 'death_6', 'lasting_7',
          'defensive_stance', 'offensive_stance', 'kinetic_bomb', 'porcupine_technique', 'last_stand', 'seeping', 'deceleration', 'annihilation', 'malediction', 'hextouch', 'whispers_of_doom',
          'tremor', 'heavy_impact', 'fracture', 'meat_shield', 'hive', 'baneling_burst', 'blunt_arrow', 'explosive_arrow', 'divine_machine_arrow', 'chronomancy', 'awakening', 'divine_punishment',
          'assassination', 'flying_daggers', 'ultimatum', 'magnify', 'echo_barrage', 'unleash', 'reinforce', 'payback', 'enchanted', 'freezing_field', 'burning_field', 'gravity_field', 'magnetism',
          'insurance', 'dividends', 'berserking', 'unwavering_stance', 'unrelenting_stance', 'blessing', 'haste', 'divine_barrage', 'orbitism', 'psyker_orbs', 'psychosink', 'rearm', 'taunt', 'construct_instability',
          'intimidation', 'vulnerability', 'temporal_chains', 'ceremonial_dagger', 'homing_barrage', 'critical_strike', 'noxious_strike', 'infesting_strike', 'burning_strike', 'lucky_strike', 'healing_strike', 'stunning_strike',
          'silencing_strike', 'culling_strike', 'lightning_strike', 'psycholeak', 'divine_blessing', 'hardening', 'kinetic_strike',
        }
        current_new_game_plus = run.current_new_game_plus or current_new_game_plus or 0
        Helper.Unit.team_saves = run.team_saves or {{}, {}, {}, {}}
        system.save_state()
        main:add(BuyScreen'buy_screen')

        run_time = run.time or 0
        locked_state = run.locked_state

        --need to increment loop for NG+ ?
        main:go_to('buy_screen', run)
      end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']starting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
    end}
  end
  --start new game
  self.arena_run_button = Button{group = self.main_ui, x = 49, y = gh/2 + 12, force_update = true, button_text = 'new run', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
      self.transitioning = true
      slow_amount = 1
      run_passive_pool = {
        'centipede', 'ouroboros_technique_r', 'ouroboros_technique_l', 'amplify', 'resonance', 'ballista', 'call_of_the_void', 'crucio', 'speed_3', 'damage_4', 'shoot_5', 'death_6', 'lasting_7',
        'defensive_stance', 'offensive_stance', 'kinetic_bomb', 'porcupine_technique', 'last_stand', 'seeping', 'deceleration', 'annihilation', 'malediction', 'hextouch', 'whispers_of_doom',
        'tremor', 'heavy_impact', 'fracture', 'meat_shield', 'hive', 'baneling_burst', 'blunt_arrow', 'explosive_arrow', 'divine_machine_arrow', 'chronomancy', 'awakening', 'divine_punishment',
        'assassination', 'flying_daggers', 'ultimatum', 'magnify', 'echo_barrage', 'unleash', 'reinforce', 'payback', 'enchanted', 'freezing_field', 'burning_field', 'gravity_field', 'magnetism',
        'insurance', 'dividends', 'berserking', 'unwavering_stance', 'unrelenting_stance', 'blessing', 'haste', 'divine_barrage', 'orbitism', 'psyker_orbs', 'psychosink', 'rearm', 'taunt', 'construct_instability',
        'intimidation', 'vulnerability', 'temporal_chains', 'ceremonial_dagger', 'homing_barrage', 'critical_strike', 'noxious_strike', 'infesting_strike', 'burning_strike', 'lucky_strike', 'healing_strike', 'stunning_strike',
        'silencing_strike', 'culling_strike', 'lightning_strike', 'psycholeak', 'divine_blessing', 'hardening', 'kinetic_strike',
      }
      
      current_new_game_plus = current_new_game_plus or 0
      system.save_state()
      main:add(BuyScreen'buy_screen')
      
      run_time = 0
      locked_state = false

      local new_run = Create_Blank_Save_Data()
      main:go_to('buy_screen', new_run)
    end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']starting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
  end}
  self.achievements_button = Button{group = self.main_ui, x = 65, y = gh/2 + 34, force_update = true, button_text = 'achievements', fg_color = 'bg10', bg_color = 'bg', action = function(b)
      if not self.paused then
        open_achievements(self)
      else
        close_achievements(self)
      end
  end}
  self.options_button = Button{group = self.main_ui, x = 47, y = gh/2 + 56, force_update = true, button_text = 'options', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    if not self.paused then
      open_options(self)
    else
      close_options(self)
    end
  end}
  self.quit_button = Button{group = self.main_ui, x = 37, y = gh/2 + 78, force_update = true, button_text = 'quit', fg_color = 'bg10', bg_color = 'bg', action = function(b)
    system.save_state()
    --steam.shutdown()
    love.event.quit()
  end}
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
end


function MainMenu:update(dt)
  if main_song_instance:isStopped() then
    main_song_instance = silence:play{volume = 0.5}
  end

  if input.escape.pressed then
    if not self.paused then
      open_options(self)
    else
      close_achievements(self)
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
    self.ui:update(dt*slow_amount)
  else
    self.options_ui:update(dt*slow_amount)
  end
end


function MainMenu:draw()
  self.floor:draw()
  self.main:draw()
  self.post_main:draw()
  self.effects:draw()
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

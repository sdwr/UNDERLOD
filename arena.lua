Arena = Object:extend()
Arena:implement(State)
Arena:implement(GameObject)
function Arena:init(name)
  self:init_state(name)
  self:init_game_object()
  LevelManager.init()
  self.hotbar = HotbarGlobals()
end

function Arena:select_character_by_index(i)
  self.hotbar:select_by_index(i)
end



function Arena:on_enter(from)
  
  self.hfx:add('condition1', 1)
  self.hfx:add('condition2', 1)

  self.paused = false
  self.in_tutorial = false
  self.in_options = false

  self.gold_text = nil
  self.timer_text = nil
  self.time_elapsed = 0

  main_song_instance:stop()

  self.starting_units = table.copy(self.units)
  self.targetedEnemy = nil

  --if not state.mouse_control then
    --input:set_mouse_visible(false)
  --end
  --input:set_mouse_visible(true)  -- Commented out to allow custom cursor
  
  -- Set cursor to animated mode for arena
  set_cursor_animated()

  trigger:tween(2, main_song_instance, {volume = 0.5, pitch = 1}, math.linear)

  --steam.friends.setRichPresence('steam_display', '#StatusFull')
  --steam.friends.setRichPresence('text', 'Arena - Level ' .. self.level)

  self.floor = Group()
  self.main = Group():set_as_physics_world(32, 0, 0, {'troop', 'enemy', 'projectile', 'enemy_projectile', 'force_field', 'ghost', 'effect'})
  self.post_main = Group()
  self.effects = Group()
  self.ui = Group()
  self.tutorial = Group()
  self.options_ui = Group()
  self.credits = Group()
  self.main:disable_collision_between('troop', 'projectile')
  self.main:disable_collision_between('projectile', 'projectile')
  self.main:disable_collision_between('projectile', 'enemy_projectile')
  self.main:disable_collision_between('projectile', 'enemy')
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
  self.main:enable_trigger_between('projectile', 'enemy')
  self.main:enable_trigger_between('troop', 'enemy_projectile')
  self.main:enable_trigger_between('enemy_projectile', 'enemy')
  self.main:enable_trigger_between('ghost', 'troop')
  self.main:enable_trigger_between('enemy', 'troop')

  self.gold_picked_up = 0
  self.damage_dealt = 0
  self.damage_taken = 0
  self.main_slow_amount = .67
  self.enemies = enemy_classes
  self.enemies_without_critters = enemy_classes_without_critters
  self.troops = troop_classes
  self.friendlies = friendly_classes
  self.friendlies_without_critters = friendly_classes_without_critters
  self.troop_list = {}
  self.color = self.color or fg[0]

  -- Spawn solids
  self.x1, self.y1 = gw/2 - 0.8*gw/2, gh/2 - 0.8*gh/2
  self.x2, self.y2 = gw/2 + 0.8*gw/2, gh/2 + 0.8*gh/2
  self.w, self.h = self.x2 - self.x1, self.y2 - self.y1

  self.last_spawn_enemy_time = love.timer.getTime()

  Wall{group = self.main, vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40), color = bg[-1]}
  
  --need to group units by character
  HotbarGlobals:clear_hotbar()

  Helper.Unit.team_button_width = 47
  local total_width = #self.units * Helper.Unit.team_button_width + (#self.units - 1) * 5  -- Total width including spacing
  local start_x = gw/2 - total_width/2  -- Center the entire hotbar
  
  for i = 1, #self.units do
    local character = self.units[i].character
    local type = character_types[character]
    local number = i
    local b = HotbarButton{group = self.ui, x = start_x + Helper.Unit.team_button_width/2 + (Helper.Unit.team_button_width + 5) * (i - 1), 
                          y = gh - 15, force_update = true, button_text = tostring(i), w = Helper.Unit.team_button_width, fg_color = 'white', bg_color = 'bg',
                          color_marks = {[1] = character_colors[character]}, character = character,
                          action = function() 
                            Helper.Unit.selected_team_index = number
                            Helper.Unit:select_team(number)
                          end
                        }
    self.hotbar:add_button(i, b)
  end

  --UI elements

  --draw progress bar at the top of the screen
  if Is_Boss_Level(self.level) then
    
  else
    self.progress_bar = ProgressBar{group = self.ui, x = gw/2, y = 20, w = 200, h = 10, color = orange[0], progress = 0}
    self.progress_bar:set_max_progress(self.level_list[self.level].round_power or 0)
    self.progress_bar:set_number_of_waves(#self.level_list[self.level].waves)
    self.progress_bar:set_waves_power(self.level_list[self.level].waves_power)
  end

  self.plusgold_text_offset_x = 0
  self.plusgold_text_offset_y = 0


  self.needs_first_update = true
  self.initial_units_spawned = false

  self:create_tutorial_popup()

  self.start_time = 3
end

function Arena:spawn_critters(spawn_point, amount)
  Spawn_Critters(self, spawn_point, amount)
end


function Arena:on_exit()
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

  Kill_Teams()
  self.hotbar:clear_hotbar()
  Helper:release()
  
  -- Set cursor back to simple mode when leaving arena
  set_cursor_simple()
end


function Arena:update(dt)

  if self.needs_first_update then
    self.needs_first_update = false

    if show_combat_controls then
      self.tutorial_popup:open()
      self.in_tutorial = true
      self.paused = true
    end
  end

  if not self.paused then
  
    if main_song_instance:isStopped() then
      main_song_instance = title_music:play{volume = state.music_volume or 1}
    end

    if not self.initial_units_spawned then
      self.initial_units_spawned = true
      Reset_Global_Proc_List()

      Spawn_Teams(self)

      --select first character by default
      self:select_character_by_index(1)

      self.spawn_manager = SpawnManager(self)
    end

    if self.spawn_manager then
      self.spawn_manager:update(dt)
    end

    --select character from hotbar
    self.troop_list = self.main:get_objects_by_classes(self.troops)
    for i = 1, 9 do
      if input[tostring(i)].pressed then
        self:select_character_by_index(i)
      end
    end
    --target enemy with rightclick
    -- if input["m2"].pressed then
    --   local mx, my = self.main.camera:get_mouse_position()
    --   local mouseCircle = Circle(mx, my, 5)
    --   local targets = self.main:get_objects_in_shape(mouseCircle, self.enemies)
    --   if targets and #targets > 0 then
    --     self:target_enemy(targets[1])
    --   end
    -- end
  end

  if self.shop_text then self.shop_text:update(dt) end

  if input.escape.pressed and not self.transitioning and not self.in_credits and not self.choosing_passives then
    if not self.in_options then
      self.in_options = true
      open_options(self)
    else
      self.in_options = false
      close_options(self, self.in_tutorial)
    end
  end

  if self.paused or self.died or self.won and not self.transitioning then

    if input.escape.pressed then
      self.in_credits = false
      if self.credits_button then self.credits_button:on_mouse_exit() end
      for _, object in ipairs(self.credits.objects) do
        object.dead = true
      end
      self.credits:update(0)
    end
  end

  self:update_game_object(dt*slow_amount)
  main_song_instance.pitch = math.clamp(slow_amount*music_slow_amount, 0.05, 1)

  if not self.paused then
    star_group:update(dt*slow_amount)
    self.floor:update(dt*slow_amount)
    self.main:update(dt*slow_amount)
    self.post_main:update(dt*slow_amount)
    self.effects:update(dt*slow_amount)
    self.ui:update(dt*slow_amount)

    Helper:update(dt*slow_amount)
    LevelManager.update(dt)
  end
  
  self.tutorial:update(dt*slow_amount)
  self.options_ui:update(dt*slow_amount)
  self.credits:update(dt)
end

function Arena:quit()
  if self.died then return end

  self.quitting = true
  if IS_DEMO and self.level == DEMO_END_LEVEL then
    print('end of demo')
    self:demo_end()
  else
    print('beat level')
    if not self.arena_clear_text then self.arena_clear_text = Text2{group = self.ui, x = gw/2, y = gh/2 - 48, lines = {{text = '[wavy_mid, cbyc]arena clear!', font = fat_font, alignment = 'center'}}} end
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
        trigger:tween(4, camera, {x = gw/2, y = gh/2, r = 0}, math.linear, function() camera.x, camera.y, camera.r = gw/2, gh/2, 0 end)
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
  self.floor:draw()
  self.main:draw_custom()
  self.post_main:draw()
  self.effects:draw()
  
  --self:draw_spawn_markers()
  
  graphics.draw_with_mask(function()
    star_canvas:draw(0, 0, 0, 1, 1)
  end, function()
    camera:attach()
    graphics.rectangle(gw/2, gh/2, self.w, self.h, nil, nil, fg[0])
    camera:detach()
  end, true)
  
  
  camera:attach()
  --self:display_text()
  camera:detach()
  
  
  if self.level == 20 and self.trailer then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent) end
  
  
  
  Helper:draw()
  
  
  
  if self.choosing_passives or self.won or self.paused or self.died then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent) end
  self.ui:draw()
  self.tutorial:draw()
  self.options_ui:draw()

  if self.shop_text then self.shop_text:draw(gw - 40, gh - 17) end
  if self.gold_text then self.gold_text:draw(gw / 2, gh / 2 + 10) end
  if self.plusgold_text then self.plusgold_text:draw(gw / 2 + self.plusgold_text_offset_x, gh / 2 + 10 + self.plusgold_text_offset_y) end
  if self.timer_text then self.timer_text:draw(gw - 30, 20) end

  if self.won then
    if self.win_text then self.win_text:draw(gw/2, gh/2 - 48) end
    if self.win_text2 then self.win_text2:draw(gw/2, gh/2) end
  end
  if self.in_credits then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent_2) end
  self.credits:draw()
end

function Arena:all_troops_dead()
  local troops = self.main:get_objects_by_classes(self.troops)

  if #troops == 0 then return true end
  for _, troop in ipairs(troops) do
    if troop.dead ~= true then return false end
  end
  return true
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
    self.died_text = Text2{group = self.ui, x = gw/2, y = gh/2 - 32, lines = {
      {text = '[wavy_mid, cbyc]you died...', font = fat_font, alignment = 'center', height_multiplier = 1.25},
    }}
    trigger:tween(2, camera, {x = gw/2, y = gh/2, r = 0}, math.linear, function() camera.x, camera.y, camera.r = gw/2, gh/2, 0 end)
    self.t:after(2, function()
      self.death_info_text = Text2{group = self.ui, x = gw/2, y = gh/2, sx = 0.7, sy = 0.7, lines = {
        {text = '[wavy_mid, fg]level reached: [wavy_mid, yellow]' .. self.level, font = fat_font, alignment = 'center'},
      }}
      self.restart_button = Button{group = self.ui, x = gw/2, y = gh/2 + 24, force_update = true, button_text = 'restart run', fg_color = 'bg10', bg_color = 'bg', action = function(b)
        self.transitioning = true
        ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
          slow_amount = 1
          music_slow_amount = 1
          run_time = 0
          gold = STARTING_GOLD
          passives = {}
          main_song_instance:stop()
          run_passive_pool = {
            'centipede', 'ouroboros_technique_r', 'ouroboros_technique_l', 'amplify', 'resonance', 'ballista', 'call_of_the_void', 'crucio', 'speed_3', 'damage_4', 'shoot_5', 'death_6', 'lasting_7',
            'defensive_stance', 'offensive_stance', 'kinetic_bomb', 'porcupine_technique', 'last_stand', 'seeping', 'deceleration', 'annihilation', 'malediction', 'hextouch', 'whispers_of_doom',
            'tremor', 'heavy_impact', 'fracture', 'meat_shield', 'hive', 'baneling_burst', 'blunt_arrow', 'explosive_arrow', 'divine_machine_arrow', 'chronomancy', 'awakening', 'divine_punishment',
            'assassination', 'flying_daggers', 'ultimatum', 'magnify', 'echo_barrage', 'unleash', 'reinforce', 'payback', 'enchanted', 'freezing_field', 'burning_field', 'gravity_field', 'magnetism',
            'insurance', 'dividends', 'berserking', 'unwavering_stance', 'unrelenting_stance', 'blessing', 'haste', 'divine_barrage', 'orbitism', 'psyker_orbs', 'psychosink', 'rearm', 'taunt', 'construct_instability',
            'intimidation', 'vulnerability', 'temporal_chains', 'ceremonial_dagger', 'homing_barrage', 'critical_strike', 'noxious_strike', 'infesting_strike', 'burning_strike', 'lucky_strike', 'healing_strike', 'stunning_strike',
            'silencing_strike', 'culling_strike', 'lightning_strike', 'psycholeak', 'divine_blessing', 'hardening', 'kinetic_strike',
          }
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
        event = {type = 'bonus_gold', amount = item.stats.gold}
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
  elseif event.type == 'bonus_gold' then
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


--beat level (win)
function Arena:transition()
  self.transitioning = true
  ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or self.color, transition_action = function(t)


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
    self.win_text = Text2{group = self.ui, x = gw/2 + 40, y = gh/2 - 69, force_update = true, lines = {{text = '[wavy_mid, cbyc2]congratulations!', font = fat_font, alignment = 'center'}}}
    self.win_text2 = Text2{group = self.ui, x = gw/2 + 40, y = gh/2 + 20, force_update = true, lines = {
      {text = "[fg]end of the demo", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
      {text = "[fg]thanks for playing!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
    }}

    -- self.build_text = Text2{group = self.ui, x = 40, y = 20, force_update = true, lines = {{text = "[wavy_mid, fg]your build", font = pixul_font, alignment = 'center'}}}

    -- for i, unit in ipairs(self.units) do
    --   CharacterCard{group = self.main, x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, unit = unit, character = unit.character, i = i, parent = self}
    -- end
  end)
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
    trigger:tween(4, camera, {x = gw/2, y = gh/2, r = 0}, math.linear, function() camera.x, camera.y, camera.r = gw/2, gh/2, 0 end)
    self.win_text = Text2{group = self.ui, x = gw/2 + 40, y = gh/2 - 69, force_update = true, lines = {{text = '[wavy_mid, cbyc2]congratulations!', font = fat_font, alignment = 'center'}}}
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

        self.win_text2 = Text2{group = self.ui, x = gw/2 + 40, y = gh/2 + 20, force_update = true, lines = {
          {text = "[fg]now you've really beaten the game!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
          {text = "[fg]thanks a lot for playing it and completing it entirely!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
          {text = "[fg]this game was inspired by:", font = pixul_font, alignment = 'center', height_multiplier = 3.5},
          {text = "[fg]so check them out! and to get more games like this:", font = pixul_font, alignment = 'center', height_multiplier = 3.5},
          {text = "[wavy_mid, yellow]thanks for playing!", font = pixul_font, alignment = 'center'},
        }}
        SteamFollowButton{group = self.ui, x = gw/2 + 40, y = gh/2 + 58, force_update = true}
        Button{group = self.ui, x = gw - 40, y = gh - 44, force_update = true, button_text = 'credits', fg_color = 'bg10', bg_color = 'bg', action = function() self:create_credits() end}
        Button{group = self.ui, x = gw - 39, y = gh - 20, force_update = true, button_text = '  loop  ', fg_color = 'bg10', bg_color = 'bg', action = function() self:endless() end}
        self.try_loop_text = Text2{group = self.ui, x = gw - 144, y = gh - 20, force_update = true, lines = {
          {text = '[bg10]continue run (+difficulty):', font = pixul_font},
        }}
        Button{group = self.ui, x = gw/2 - 50 + 40, y = gh/2 + 12, force_update = true, button_text = 'nimble quest', fg_color = 'bluem5', bg_color = 'blue', action = function(b) open_url(b, 'https://store.steampowered.com/app/259780/Nimble_Quest/') end}
        Button{group = self.ui, x = gw/2 + 50 + 40, y = gh/2 + 12, force_update = true, button_text = 'dota underlords', fg_color = 'bluem5', bg_color = 'blue', action = function(b) open_url(b, 'https://store.steampowered.com/app/1046930/Dota_Underlords/') end}

      else
        self.win_text2 = Text2{group = self.ui, x = gw/2 + 40, y = gh/2 + 5, force_update = true, lines = {
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
        SteamFollowButton{group = self.ui, x = gw/2 + 40, y = gh/2 - 10, force_update = true}
        Button{group = self.ui, x = gw/2 + 40, y = gh/2 + 33, force_update = true, button_text = 'buy the soundtrack!', fg_color = 'greenm5', bg_color = 'green', action = function(b) open_url(b, 'https://kubbimusic.com/album/ember') end}
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
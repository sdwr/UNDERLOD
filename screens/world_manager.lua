WorldManager = Object:extend()
WorldManager.__class_name = 'WorldManager'
WorldManager:implement(State)
WorldManager:implement(GameObject)

function WorldManager:init(name)
  self:init_state(name)
  self:init_game_object()
  
  -- Arena management
  self.current_arena = nil
  self.next_arena = nil
  self.transitioning = false
  
  -- Camera control
  self.camera_target_x = 0
  self.camera_target_y = 0
  self.camera_scroll_speed = 200 -- pixels per second
  
  -- Transition state
  self.transition_progress = 0
  self.transition_duration = TRANSITION_DURATION -- seconds
end

function WorldManager:on_enter(from)

  Reset_Global_Proc_List()
  Helper.Unit:enable_unit_controls()


  self:create_class_lists()
self:arena_on_enter()

  -- Load stage data and weapons if we have a selected stage
  local stage_data = nil
  if state.selected_stage then
    stage_data = Get_Stage_Data(state.selected_stage)
    if stage_data then
      -- Get number of waves from stage data
      local num_waves = stage_data.number_of_waves or 1

      -- Calculate power distribution across waves (100% of round power)
      local total_required = stage_data.round_power
      local waves_power = {}

      -- Use default wave power splits if available
      if DEFAULT_WAVE_POWER_SPLITS and DEFAULT_WAVE_POWER_SPLITS[num_waves] then
        for i = 1, num_waves do
          waves_power[i] = total_required * DEFAULT_WAVE_POWER_SPLITS[num_waves][i]
        end
      else
        -- Equal distribution as fallback
        for i = 1, num_waves do
          waves_power[i] = total_required / num_waves
        end
      end

      -- Create level list entry for this stage
      self.level_list = {
        [1] = {
          level = 1,
          waves_power = waves_power,  -- Multiple segments based on waves
          round_power = stage_data.round_power,
          color = grey[0],
          environmental_hazards = {}
        }
      }
    else
      -- Fallback if no stage data
      self.level_list = Build_Level_List(NUMBER_OF_ROUNDS)
    end
  else
    -- No stage selected, use default level generation
    self.level_list = Build_Level_List(NUMBER_OF_ROUNDS)
  end

  -- Get weapons from stage data or use defaults
  if stage_data and stage_data.weapons then
    -- Use weapons from stage data
    self.units = {}
    for weapon_name, weapon_config in pairs(stage_data.weapons) do
      table.insert(self.units, {
        character = weapon_name,
        level = weapon_config.level or 1,
        items = weapon_config.items or {}  -- Items are already in the correct format
      })
    end
  elseif self.weapons and #self.weapons > 0 then
    -- Fallback to existing weapon system
    self.units = {}
    for _, weapon in ipairs(self.weapons) do
      local weapon_def = Get_Weapon_Definition(weapon.name)
      local items = {}

      -- Add default items for specific weapons
      if weapon.name == 'cannon' and weapon_def.default_items then
        items = weapon_def.default_items
      end

      table.insert(self.units, {
        character = weapon.name,
        level = weapon.level or 1,
        items = items
      })
    end
  else
    -- Default starting weapon if no weapons purchased yet
    self.units = {
      {character = 'machine_gun', level = 1, items = {}},
    }
  end

  -- Set up the current arena if it doesn't exist
  if not self.current_arena then
    -- Create arena with the current level from save data
    local level = self.level or 1
    self:create_arena(level, 0)
    -- Activate enemies for the first arena
    self.current_arena:set_transition_complete()
    
    -- Pass save data to the arena
    if self.current_arena then
      for _, field in ipairs(EXPECTED_SAVE_FIELDS) do
        if self[field] then
          self.current_arena[field] = self[field]
        end
      end
    end
  end
  -- Set cursor to animated mode for arena
  set_cursor_arena()
  
  -- Initialize music
  main_song_instance:stop()
  trigger:tween(2, main_song_instance, {volume = 0.5, pitch = 1}, math.linear)
end

function WorldManager:arena_on_enter(from)
  self.paused = false
  self.in_tutorial = false
  self.in_options = false
  
  slow_amount = 1
  music_slow_amount = 1

  self.gold_text = nil
  self.timer_text = nil
  self.time_elapsed = 0

  main_song_instance:stop()

  self.starting_units = table.copy(self.units)
  self.targetedEnemy = nil
  
  -- Initialize player perks from save data
  self.perks = self.perks or {}

  --if not state.mouse_control then
    --input:set_mouse_visible(false)
  --end
  --input:set_mouse_visible(true)  -- Commented out to allow custom cursor
  
  -- Set cursor to animated mode for arena
  set_cursor_arena()

  trigger:tween(2, main_song_instance, {volume = 0.5, pitch = 1}, math.linear)

  --steam.friends.setRichPresence('steam_display', '#StatusFull')
  --steam.friends.setRichPresence('text', 'Arena - Level ' .. self.level)

  self.gold_picked_up = 0
  self.damage_dealt = 0
  self.damage_taken = 0
  self.main_slow_amount = .67
end

function WorldManager:create_class_lists()
  self.enemies = enemy_classes
  self.enemies_without_critters = enemy_classes_without_critters
  self.enemy_projectile_classes = enemy_projectile_classes
  self.troops = troop_classes
  self.friendlies = friendly_classes
  self.friendlies_without_critters = friendly_classes_without_critters
  self.all_unit_classes = all_unit_classes


end

function WorldManager:create_arena(level, offset_x)
  local arena_class = CombatLevel

  local arena = arena_class{
    level = level,
    x = offset_x,
    offset_x = offset_x,
    offset_y = 0,
    level_list = self.level_list,
    stage_id = state.selected_stage,
    difficulty = state.difficulty,
  }
  
  if not self.current_arena then
    self.current_arena = arena
    self.camera_target_x = 0
    self.camera_target_y = 0
    self:assign_physics_groups(arena)
    arena.units = self.units
    self.gold_counter = arena.gold_counter

    -- arena:create_walls()
    arena:create_door()

    -- Only spawn teams and enemies for non-tutorial levels
    Spawn_Teams(arena, false)  -- Changed to false to disable suction
    Helper.Unit:update_unit_colors()
    -- Removed suction effect - troops now spawn directly at center

    self.t:after(1.5, function()
      arena.level_orb:spawn()
    end)

    -- Start spawning enemies immediately instead of after suction
    self.t:after(1.5, function()
      arena.spawn_manager:change_state('entry_delay')
    end)

  else
    self.next_arena = arena
    arena.units = self.units
    self.gold_counter = arena.gold_counter
    
    self.camera_target_x = gw -- Scroll to the right
    self.transitioning = true
    self.transition_progress = 0

  end
end

function WorldManager:assign_physics_groups(arena)
  self.floor = arena.floor
  self.main = arena.main
  self.post_main = arena.post_main
  self.effects = arena.effects
  self.arena_ui = arena.ui
  self.world_ui = Group()
  self.tutorial = arena.tutorial
  self.options_ui = arena.options_ui
  self.credits = arena.credits
end

function WorldManager:set_arenas_paused(paused)
  if self.current_arena then
    self.current_arena.paused = paused
  end
  if self.next_arena then
    self.next_arena.paused = paused
  end
end

function WorldManager:gain_gold(amount)
  gold = gold + amount
end

function WorldManager:create_character_cards()
  Kill_All_Cards()
  Character_Cards = {}

  local y = gh/2 - 10
  local x = gw/2

  local number_of_cards = #self.units

  --center single unit, otherwise start on the left
  if number_of_cards == 2 then
    x = gw/2 - CHARACTER_CARD_WIDTH/2 - CHARACTER_CARD_SPACING
  elseif number_of_cards == 3 then
    x = gw/2 - CHARACTER_CARD_WIDTH - CHARACTER_CARD_SPACING - 30
  end

  for i, unit in ipairs(self.units) do
    table.insert(Character_Cards, CharacterCard{group = self.world_ui, x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, unit = unit, character = unit.character, i = i, parent = self})
    unit.spawn_effect = true
  end

  for i, card in ipairs(Character_Cards) do
    card.x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING)
  end

  -- Create perks panel
  if not self.perks_panel then
    self.perks_panel = PerksPanel{
      group = self.world_ui,
      perks = self.perks or {}
    }
  else
    -- Update existing perks panel
    self.perks_panel:set_perks(self.perks or {})
  end
end

function WorldManager:pause_arena()
  if not self.paused then
    self.paused = true
    self:set_arenas_paused(true)
  end
end

function WorldManager:unpause_arena()
  if self.paused then
    self.paused = false
    self:set_arenas_paused(false)
  end
end

function WorldManager:update(dt)
  self:update_game_object(dt)

  if input.escape.pressed then
    if not self.paused then
      self:pause_arena()
      open_options(self)
    else
      self:unpause_arena()
      close_options(self, self.in_tutorial)
    end
  end

  -- Handle 'c' key for character cards
  if input.c.pressed then
    if self.paused then return end
    if self.transitioning then return end

    if not self.character_cards_open then
      self.character_cards_open = true
      self:create_character_cards()
    else
      self.character_cards_open = false
      Kill_All_Cards()
      -- Hide perks panel when closing character cards
      if self.perks_panel then
        self.perks_panel:die()
        self.perks_panel = nil
      end
    end
  end

  if input.x.pressed then
    camera.x = camera.x + 100
  end
  if input.z.pressed then
    camera.x = camera.x - 100
  end
  
  if not self.paused then
  -- Update Helper system for input handling and troop movement
    Helper:update(dt*slow_amount)
    
    LevelManager.update(dt)
    
    if self.current_arena then
      self.current_arena:update(dt*slow_amount)
    end
    if self.next_arena then
      self.next_arena:update(dt*slow_amount)
    end
    
    if self.transitioning then
      self:update_transition(dt*slow_amount)
    end
  end

  self.world_ui:update(dt)
  self.tutorial:update(dt)
  self.options_ui:update(dt)
  self.credits:update(dt)
end

function WorldManager:update_transition(dt)
  self.transition_progress = self.transition_progress + dt / self.transition_duration
  
  if self.transition_progress >= 1 then
    self.transitioning = false
    self:complete_transition()
  else
    -- Smooth camera scroll
    local progress = self.transition_progress
    local ease_progress = progress * progress * (3 - 2 * progress) -- Smooth easing
    
    -- Move camera to create transition effect
    camera.x = gw/2 + (ease_progress * gw)
    camera.y = gh/2
  end
end

function WorldManager:complete_transition()
  -- Transfer player units from old arena to new arena
  if self.current_arena and self.next_arena then

    -- restore all units to full at start of level for now
    -- Helper.Unit:save_all_teams_hps()
    Helper.Unit:restore_all_teams_hps()

    local save_data = Collect_Save_Data_From_State(self)
    save_data.reroll_shop = true
    save_data.times_rerolled = 0

    system.save_run(save_data)
    system.save_stats()
    Check_All_Achievements()

    -- Destroy old arena (this will destroy its groups and all non-player objects)
    self.current_arena:destroy()
    
    -- Set new arena as current
    self.current_arena = self.next_arena
    self.current_arena.offset_x = 0
    self.current_arena.offset_y = 0
    self.next_arena = nil
    camera.x = gw/2
    camera.y = gh/2
    
    -- Clear pending troop data
    self.pending_troop_data = nil
    
    -- Update physics group references for the new arena
    self:assign_physics_groups(self.current_arena)
    
    -- Set up teams for the new arena
    Spawn_Teams(self.current_arena)
    Helper.Unit:update_unit_colors()
    
    -- self.current_arena:create_walls()
    self.current_arena:create_door()
    self.current_arena.spawn_manager:spawn_waves_with_timing()
    
    -- Resume enemy updates and activate enemies
    self.current_arena.enemies_paused = false
    self.current_arena:set_transition_complete()
    
  end
  
  self.transitioning = false
  self.transition_progress = 0
end

function WorldManager:move_objects_in_group(group, offset_x, offset_y)
  for _, object in pairs(group.objects) do
    if object.is and object:is(Enemy) then
      print('enemy', object.x, object.y, object.type)
    end
    if object.x and object.y then
      object.x = object.x - offset_x
      object.y = object.y - offset_y
      if object.is and object:is(Enemy) then
        print('enemy after', object.x, object.y, object.type)
      end
    end
  end
end

function WorldManager:replace_first_unit(character)
  -- Add character to units
  local unit = Get_Basic_Unit(character)
  self.units = {unit}
  Replace_Team(self, 1, unit)

  self.level = 1

  local save_data = Collect_Save_Data_From_State(self)
  system.save_run(save_data)

  -- Save the run
  self:save_run()
end

function WorldManager:add_unit(character)
  local unit = Get_Basic_Unit(character)
  table.insert(self.units, unit)
  Spawn_Team(self, #self.units, unit)
  Helper.Unit:update_unit_colors()

  if self.character_cards_open then
    self:create_character_cards()
  end

  local save_data = Collect_Save_Data_From_State(self)
  system.save_run(save_data)

  self:save_run()
end

function WorldManager:on_exit(to)
  
  Kill_Teams()
  Helper:release()
  set_cursor_simple()

  self:save_run()

  if self.current_arena then
    self.current_arena:destroy()
  end
  if self.next_arena then
    self.next_arena:destroy()
  end
  
  -- Clean up level map
  if self.level_progress then
    self.level_progress:die()
    self.level_progress = nil
  end
end

function WorldManager:advance_to_next_level()
  if not self.transitioning and self.current_arena then

    self:create_arena(self.level, gw)
    -- Start transition
    self.transitioning = true
    Kill_All_Cards()
    
    
    if self.current_arena then
      self.current_arena:remove_all_floor_items()
      if self.current_arena.gold_counter then
        self.current_arena.gold_counter:hide_display()
      end
    end
    self.transition_progress = 0
    
    -- Pause enemy updates in the new arena during transition
    if self.next_arena then
      self.next_arena.enemies_paused = true
    end
  end
end

function WorldManager:draw()
  if self.current_arena then
    self.current_arena:draw()
  end
  if self.next_arena then
    self.next_arena:draw()
  end

  self.world_ui:draw()

  self.tutorial:draw()
  self.options_ui:draw()
  self.credits:draw()

  -- Draw Helper system (selection UI, etc.)
  Helper:draw()
end

function WorldManager:increase_level()
  self.level = self.level + 1
  self:save_run()
end

function WorldManager:save_run()
  local save_data = Collect_Save_Data_From_State(self)
  system.save_run(save_data)
end


function WorldManager:put_in_first_available_inventory_slot(item)
  local unit, slot_index = self:find_available_inventory_slot(item)
  if unit and slot_index then
    unit.items[slot_index] = item
    return true
  end
  return false
end

function WorldManager:find_available_inventory_slot(item)
  return Helper.Unit:find_available_inventory_slot(self.units, item)
end

-- Perk management functions
function WorldManager:add_perk(perk)
  if self.perks_panel and self.perks_panel:add_perk(perk) then
    self:save_run()
    return true
  end
  return false
end

function WorldManager:remove_perk(index)
  if self.perks_panel and self.perks_panel:remove_perk(index) then
    self:save_run()
    return true
  end
  return false
end

function WorldManager:set_perks(perks)
  self.perks = perks or {}
  if self.perks_panel then
    self.perks_panel:set_perks(self.perks)
  end
  self:save_run()
end

function WorldManager:transition_to_next_level_buy_screen(delay)

  if self.current_arena then
    self.current_arena.transitioning = true

    -- Update completion stats if we have a stage selected
    if state.selected_stage then
      -- Load existing stats
      system.load_stats()
      if not USER_STATS.stages_completed then USER_STATS.stages_completed = {} end
      if not USER_STATS.stages_no_damage then USER_STATS.stages_no_damage = {} end

      -- Mark stage as completed
      USER_STATS.stages_completed[state.selected_stage] = true

      -- Check for hitless completion
      local damage_taken = self.current_arena.damage_taken or 0
      if damage_taken == 0 then
        USER_STATS.stages_no_damage[state.selected_stage] = true
      end

      -- Save the updated stats
      system.save_stats()
    end
  end

  Reset_Global_Proc_List()

  -- For stage-based play, go back to level select instead of buy screen
  if state.selected_stage then
    self.t:after(delay or 2, function()
      TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
        main:go_to('level_select')
      end}
    end)
  else
    -- Original behavior for non-stage play
    -- Increment level and set reroll_shop in the current state
    self.level = self.level + 1
    self.reroll_shop = true
    self.times_rerolled = 0
    self:save_run()

    self.t:after(delay or 2, function()
      TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
        Go_To_Buy_Screen()
      end}
    end)
  end

end
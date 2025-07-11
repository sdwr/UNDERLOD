WorldManager = Object:extend()
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
  self.transition_duration = 2 -- seconds
end

function WorldManager:on_enter(from)
  Helper.init()

  Reset_Global_Proc_List()


  self:create_class_lists()
  self:arena_on_enter()

  -- Create level list for spawn management
  self.level_list = Build_Level_List(NUMBER_OF_ROUNDS)

  -- Set up the current arena if it doesn't exist
  if not self.current_arena then
    -- Create arena with the current level from save data
    local level = self.level or 1
    self:create_arena(level, 0)
    self:create_level_map()
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
  set_cursor_animated()
  
  -- Initialize music
  main_song_instance:stop()
  trigger:tween(2, main_song_instance, {volume = 0.5, pitch = 1}, math.linear)
end

function WorldManager:arena_on_enter(from)
  self.paused = false
  self.in_tutorial = false
  self.in_options = false

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
  set_cursor_animated()

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
  self.troops = troop_classes
  self.friendlies = friendly_classes
  self.friendlies_without_critters = friendly_classes_without_critters
  self.all_unit_classes = all_unit_classes


end

function WorldManager:create_level_map()
  if self.level_map then
    self.level_map:die()
  end
  -- Create level map in the top center of the screen
  self.level_map = BuildLevelMap(self.ui, gw/2, LEVEL_MAP_Y_POSITION, self, self.level or 1, self.loop or 0, self.level_list)
end

function WorldManager:update_level_map()
  if self.level_map then
    self.level_map:reset()
  end
end

function WorldManager:create_arena(level, offset_x)

  local arena = Arena{
    level = level,
    x = offset_x,
    offset_x = offset_x,
    offset_y = 0,
    level_list = self.level_list,
  }
  
  if not self.current_arena then
    self.current_arena = arena
    self.camera_target_x = 0
    self.camera_target_y = 0
    self:assign_physics_groups(arena)
    arena.units = self.units
    self.gold_counter = arena.gold_counter

    arena:create_walls()
    Spawn_Teams(arena)
    arena.spawn_manager:spawn_all_enemies_at_once()

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
  -- Don't override ui group since it contains the level map
  self.ui = arena.ui
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

function WorldManager:try_buy_unit(cost)
  if gold >= cost then
    self:gain_gold(-cost)
    gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
    self.select_character_overlay = CharacterSelectOverlay{
      group = self.ui
    }
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
    table.insert(Character_Cards, CharacterCard{group = self.ui, x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, unit = unit, character = unit.character, i = i, parent = self})
    unit.spawn_effect = true
  end

  for i, card in ipairs(Character_Cards) do
    card.x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING)
  end
end

function WorldManager:update(dt)
  self:update_game_object(dt)

  if input.escape.pressed then
    if not self.paused then
      self.paused = true
      open_options(self)
      self:set_arenas_paused(true)
    else
      self.paused = false
      close_options(self, self.in_tutorial)
      self:set_arenas_paused(false)
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

  self.ui:update(dt)
  self.tutorial:update(dt)
  self.options_ui:update(dt)
  self.credits:update(dt)
  
  -- Update character cards if open
  if self.character_cards_open then
    for _, card in ipairs(Character_Cards) do
      card:update(dt)
    end
  end
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
    --should add this onto the existing units
    for _, team in pairs(Helper.Unit.teams) do
      local troop_hps = {}
      for _, troop in pairs(team.troops) do
        if troop.dead then
          table.insert(troop_hps, 0)
        else
          table.insert(troop_hps, troop.hp)
        end
      end
      team.unit.troop_hps = troop_hps
    end

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
    self:create_level_map()
    
    -- Set up teams for the new arena
    Spawn_Teams(self.current_arena)
    self.current_arena:create_walls()
    self.current_arena.spawn_manager:spawn_all_enemies_at_once()
    
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
end

function WorldManager:advance_to_next_level()
  if not self.transitioning and self.current_arena then

    self:create_arena(self.level, gw)
    -- Start transition
    self.transitioning = true
    Kill_All_Cards()
    
    
    if self.current_arena then
      self.current_arena:remove_all_floor_items()
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

  self.ui:draw()
  self.tutorial:draw()
  self.options_ui:draw()
  self.credits:draw()

  -- Draw Helper system (selection UI, etc.)
  Helper:draw()

  -- Draw character cards if open
  if self.character_cards_open then
    for _, card in ipairs(Character_Cards) do
      card:draw()
    end
  end
end

function WorldManager:increase_level()
  self.level = self.level + 1
  self:update_level_map()
  self:save_run()
end

function WorldManager:save_run()
  local save_data = Collect_Save_Data_From_State(self)
  system.save_run(save_data)
end

function WorldManager:unit_first_available_inventory_slot(unit)
  for i = 1, UNIT_LEVEL_TO_NUMBER_OF_ITEMS[unit.level] do
    if not unit.items[i] then
      return i
    end
  end
  return nil
end

function WorldManager:put_in_first_available_inventory_slot(item)
  for _, unit in ipairs(self.units) do
    local index = self:unit_first_available_inventory_slot(unit)
    if index then
      unit.items[index] = item
      return true
    end
  end
  return false
end
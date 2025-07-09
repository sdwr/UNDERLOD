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

function WorldManager:create_arena(level, offset_x)

  local arena = Arena{
    level = level,
    offset_x = offset_x,
    level_list = self.level_list,
  }
  
  if not self.current_arena then
    self.current_arena = arena
    self.camera_target_x = 0
    self.camera_target_y = 0
    self:assign_physics_groups(arena)
    arena.units = self.units
    self.progress_bar = arena.progress_bar

    
    Spawn_Teams(arena)

  else
    self.next_arena = arena
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

  self.tutorial:update(dt)
  self.options_ui:update(dt)
  self.credits:update(dt)
end

function WorldManager:advance_to_next_level()
  print('advance to next level')
end

function WorldManager:update_transition(dt)
  self.transition_progress = self.transition_progress + dt / self.transition_duration
  
  if self.transition_progress >= 1 then
    self:complete_transition()
  else
    -- Smooth camera scroll
    local progress = self.transition_progress
    local ease_progress = progress * progress * (3 - 2 * progress) -- Smooth easing
    camera.x = ease_progress * gw
  end
end

function WorldManager:complete_transition()
  -- Transfer player units from old arena to new arena
  if self.current_arena and self.next_arena then
    local player_units = {}
    
    -- Get all player units from current arena's main group
    for _, unit in pairs(self.current_arena.main:get_objects_by_classes({'Troop'})) do
      table.insert(player_units, unit)
    end
    
    -- Transfer each player unit to the new arena's main group
    for _, unit in pairs(player_units) do
      self.current_arena.main:remove_object(unit)
      self.next_arena.main:add_object(unit)
      
      -- Update unit's group reference
      unit.group = self.next_arena.main
    end
    
    -- Destroy old arena (this will destroy its groups and all non-player objects)
    self.current_arena:destroy()
    
    -- Set new arena as current
    self.current_arena = self.next_arena
    self.next_arena = nil
    
    -- Update physics group references for the new arena
    self:assign_physics_groups(self.current_arena)
  end
  
  -- Reset camera
  camera.x = 0
  camera.y = 0
  self.transitioning = false
  self.transition_progress = 0
end

function WorldManager:on_exit(to)
  Kill_Teams()
  Helper:release()
  set_cursor_simple()

  -- Save current game state
  if self.current_arena then
    -- Collect save data from current arena
    local save_data = {}
    
    -- Copy all expected save fields from the arena
    for _, field in ipairs(EXPECTED_SAVE_FIELDS) do
      if self.current_arena[field] then
        save_data[field] = self.current_arena[field]
      end
    end
    
    -- Add global state
    save_data.gold = gold
    save_data.locked_state = locked_state
    
    -- Save to file
    system.save_run(save_data)
  end

  if self.current_arena then
    self.current_arena:destroy()
  end
  if self.next_arena then
    self.next_arena:destroy()
  end
end

function WorldManager:advance_to_next_level()
  if not self.transitioning and self.current_arena then
    local next_level = self.current_arena.level + 1
    self:create_arena(next_level, gw)
  end
end

function WorldManager:draw()
  if self.current_arena then
    self.current_arena:draw()
  end
  if self.next_arena then
    self.next_arena:draw()
  end

  self.tutorial:draw()
  self.options_ui:draw()
  self.credits:draw()

  -- Draw Helper system (selection UI, etc.)
  Helper:draw()

  -- Draw transition overlay if transitioning
  if self.transitioning then
    local alpha = math.min(self.transition_progress * 2, 1)
    graphics.setColor(0, 0, 0, alpha * 0.3)
    graphics.rectangle(0, 0, gw, gh)
    graphics.setColor(1, 1, 1, 1)
  end
end 
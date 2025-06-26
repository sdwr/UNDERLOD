SpawnGlobals = {}

function SpawnGlobals.Init()

  local left_x = gw/2 - 0.6*gw/2
  local right_x = gw/2 + 0.6*gw/2
  local mid_y = gh/2
  local y_offset = 35
  
  local y_corner_offset = 50

  SpawnGlobals.wall_width = 0.2*gw/2
  SpawnGlobals.wall_height = 0.2*gh/2
  
  SpawnGlobals.spawn_markers = {
    {x = right_x, y = mid_y},
    {x = right_x, y = mid_y - y_offset},
    {x = right_x, y = mid_y + y_offset},
    {x = right_x, y = mid_y - 2*y_offset},
    {x = right_x, y = mid_y + 2*y_offset},
  
    {x = left_x, y = mid_y},
    {x = left_x, y = mid_y - y_offset},
    {x = left_x, y = mid_y + y_offset},
    {x = left_x, y = mid_y - 2*y_offset},
    {x = left_x, y = mid_y + 2*y_offset},
  }
  
  SpawnGlobals.spawn_offsets = 
  {{x = -12, y = -12}, 
  {x = 12, y = -12}, 
  {x = 12, y = 12}, 
  {x = -12, y = 12},
  {x = -6, y = -6},
  {x = -6, y = 6},
  {x = 6, y = -6},
  {x = 6, y = 6}, 
  {x = 0, y = 0}}
  
  
  SpawnGlobals.corner_spawns = {
    {x = left_x, y = y_corner_offset},
    {x = left_x, y = gh - y_corner_offset},
    {x = right_x, y = y_corner_offset},
    {x = right_x, y = gh - y_corner_offset},
  }

  SpawnGlobals.boss_spawn_point = {x = right_x, y = mid_y}

  SpawnGlobals.last_spawn_point = nil

  SpawnGlobals.get_spawn_marker = function(index)
    local spawn_index = index % ((#SpawnGlobals.spawn_markers) - 1)
    local spawn_marker = SpawnGlobals.spawn_markers[spawn_index]

    return spawn_marker or SpawnGlobals.spawn_markers[1]
  end
end

function Get_Close_Spawn(index)
  if index == 1 then
    return 2
  elseif index == 5 then
    return 4
  elseif index < 6 then
    local choices = {index -1, index + 1}
    return random:table(choices)
  elseif index == 6 then
    return 7
  elseif index == 10 then
    return 9
  else
    local choices = {index -1, index + 1}
    return random:table(choices)
  end
end

function Get_Far_Spawn(index)
  if index < 6 then
    local choices = {6,7,8,9,10}
    return random:table(choices)
  else
    local choices = {1,2,3,4,5}
    return random:table(choices)
  end
end

function Can_Spawn(rs, location)
  return true
end
--   local check_circle = Circle(0,0, rs)
--   check_circle:move_to(location.x, location.y)
--   local objects = main.current.main:get_objects_in_shape(check_circle, all_unit_classes)
--   if #objects > 0 or Outside_Arena(location) then
--     return false
--   else
--     return true
--   end
-- end

function Get_Spawn_Point(rs, location)
  for i = 1, SPAWN_CHECKS do
    local offset = SpawnGlobals.spawn_offsets[i % #SpawnGlobals.spawn_offsets]
    local x, y = location.x + offset.x, location.y + offset.y
    if Can_Spawn(rs, {x = x, y = y}) then
      return {x = x, y = y}
    end
  end
  return nil
end


function Outside_Arena(location)
  if location.x < SpawnGlobals.wall_width or 
     location.x > gw - SpawnGlobals.wall_width or 
     location.y < SpawnGlobals.wall_height or
     location.y > gh - SpawnGlobals.wall_height then
      return true
  else
    return false
  end
end

function Get_Point_In_Arena()
  local x = random:int(SpawnGlobals.wall_width, gw - SpawnGlobals.wall_width)
  local y = random:int(SpawnGlobals.wall_height, gh - SpawnGlobals.wall_height)
  return {x = x, y = y}
end

function Kill_Teams()
  for i, team in ipairs(Helper.Unit.teams) do
    team:die()
  end
end

--spawns troops in centre of arena, two rows if over 4 units
function Spawn_Teams(arena)
  local spawn_y
  if #arena.units > 4 then
    spawn_y = gh/2 - 50
  else
    spawn_y = gh/2 - 20
  end

  local spawn_x = gw/2 - 50

  --clear Helper.Unit.teams
  Helper.Unit.teams = {}
  
  for i, unit in ipairs(arena.units) do
    --add a new team
    local team = Team(i, unit)
    table.insert(Helper.Unit.teams, i, team)

    local column_offset = (i-1) % 4

    if i == 5 then
    --make a second row
      spawn_x = gw/2 - 50
      spawn_y = gh/2 + 10
    end


    team:set_troop_data({
      group = arena.main,
      x = spawn_x ,
      y = spawn_y,
      level = unit.level,
      character = unit.character,
      items = unit.items,
      passives = arena.passives
    })
    for row_offset=0, 4 do
      local x = spawn_x + (column_offset*20)
      local y = spawn_y + (row_offset*10)
      team:add_troop(x, y)
    end

    --add items to team / troops here
    --instead of in the unit creation
    -- that way we can distinguish between global/team/troop items

    --a team item still needs to have triggers when the troop does stuff (ATTACK, KILL, MOVE)
    --but it should apply to all troops in the team

    --the proc on the troop will be the same, only difference is there is 1 copy of the proc
    --and not 5

    --only problem is that the item needs to be applied to the troops before its first tick

    team:apply_item_procs()

    
  end
end

-- possible hazards:
-- 1. laser
-- 2. puddle on enemy death
-- 3. mortar strike
-- 4. sweep from dragon
function Spawn_Hazards(arena, hazards)
  local hazard = hazards.type
  local level = hazards.level
  -- need different patterns?
  -- 1. follows player units (random or closest)
  -- 2. stationary, angles towards player units
  -- 3. random movement
  -- 4. straight lines, muliple fire in sequence
  if hazard == 'laser' then
    
  end
end

-- ===================================================================
-- SpawnManager Class (Corrected)
-- ===================================================================

SpawnManager = Object:extend()

function SpawnManager:init(arena)
    self.arena = arena
    self.level_data = arena.level_list[arena.level]
    self.t = self.arena.t -- Use the arena's timer for convenience

    -- Spawning State Machine
    self.state = 'entry_delay'
    -- (States remain the same)

    -- Timers and Trackers
    self.time_between_waves = arena.time_between_waves or 3
    self.max_enemies_on_screen = arena.max_enemies or 20
    
    self.timer = arena.entry_delay or 0.5
    self.current_wave_index = 1
    self.current_group_index = 1
    
    -- New properties for managing wave-level spawning
    self.persistent_wave_spawn_marker = nil
    self.current_wave_spawn_marker_index = nil
    
    -- *** FIX: Add a flag to prevent re-triggering the spawn chain. ***
    self.is_group_spawning = false

    -- Check if this is a boss level
    if table.contains(BOSS_ROUNDS, arena.level) then
        self.state = 'boss_fight'
    end
end

-- ===================================================================
-- The Core Update Loop (Corrected)
-- ===================================================================
function SpawnManager:update(dt)
    if self.state == 'finished' then return end

    self.timer = self.timer - dt

    -- (States 'entry_delay', 'waiting_for_clear', 'between_waves_delay', 'boss_fight' are unchanged)

    -- State: Initial delay before anything happens
    if self.state == 'entry_delay' then
      if self.timer <= 0 then
          self:start_next_wave()
      end
    -- State: Countdown before the wave's spawning begins
    elseif self.state == 'wave_delay' then
        self.wave_delay_timer = self.wave_delay_timer - dt
        self:show_wave_start_countdown(get_starting_wave_countdown_value(self.wave_delay_timer))
        if self.wave_delay_timer <= 0 then
            self.state = 'spawning_wave'
            -- This is the first kick-off of the chain.
            self:create_wave_marker()
            self.is_group_spawning = true
            self.spawning_wave = true
            self.arena.t:after(1, function()
              self:spawn_next_group_in_chain()
            end)
        end

    -- State: Spawning a wave
    elseif self.state == 'spawning_wave' then
        -- *** FIX: Only try to spawn if a group is NOT currently spawning. ***
        -- This prevents the update loop from firing while the callback chain is active.
        -- It also serves as the retry mechanism if spawning was paused by max_enemies.
        if not self.is_group_spawning and self.timer <= 0 then
            self:spawn_next_group_in_chain()
        end
    
     -- State: Waiting for all enemies to be defeated
    elseif self.state == 'waiting_for_clear' then
      if #self.arena.main:get_objects_by_classes(self.arena.enemies) <= 0 then
          if self.current_wave_index >= #self.level_data.waves then
              if main.current.progress_bar:is_complete() then
                  self.state = 'finished'
                  self.arena:quit()
              end
          else
              if self.arena.progress_bar:highest_wave_complete() == self.current_wave_index then
                  self.current_wave_index = self.current_wave_index + 1
                  self.state = 'between_waves_delay'
                  self.timer = self.time_between_waves
                  self:show_wave_complete_text()
              end
          end
      end

    -- State: Paused between waves
    elseif self.state == 'between_waves_delay' then
        if self.timer <= 0 then
            self:start_next_wave()
        end
    
    -- State: Boss Fight Logic
    elseif self.state == 'boss_fight' then
        self:handle_boss_fight()
        self.state = 'finished'
    end
end

-- ===================================================================
-- State Transition and Action Functions
-- ===================================================================

function SpawnManager:start_next_wave()
    local waves = self.level_data.waves
    if not waves or not waves[self.current_wave_index] then
        self.state = 'finished'
        self.arena:quit() 
        return
    end

    print("Starting Wave: " .. self.current_wave_index)
    
    self.state = 'wave_delay'
    self.current_group_index = 1
    self.timer = 0
    self.wave_delay_timer = TOTAL_STARTING_WAVE_DELAY

    -- 1. Determine the single spawn point for the entire wave.
    self.current_wave_spawn_marker_index = random:int(1, #SpawnGlobals.spawn_markers)
    SpawnGlobals.last_spawn_point = self.current_wave_spawn_marker_index
end

function SpawnManager:create_wave_marker()
  -- Create the persistent visual marker that will last the whole wave.
  local center_marker_pos = SpawnGlobals.get_spawn_marker(self.current_wave_spawn_marker_index)

  -- Clean up any old marker just in case.
  if self.persistent_wave_spawn_marker and not self.persistent_wave_spawn_marker.dead then
      self.persistent_wave_spawn_marker:die()
  end
  self.persistent_wave_spawn_marker = SpawnMarker{
      group = self.arena.effects,
      x = center_marker_pos.x,
      y = center_marker_pos.y
  }
end

function SpawnManager:spawn_next_group_in_chain()
  if self.state ~= 'spawning_wave' then return end

  local wave_data = self.level_data.waves[self.current_wave_index]

  if self.current_group_index > #wave_data then
      self.state = 'waiting_for_clear'
      if self.persistent_wave_spawn_marker and not self.persistent_wave_spawn_marker.dead then
          self.persistent_wave_spawn_marker:die()
          self.persistent_wave_spawn_marker = nil
      end
      return
  end

  local num_enemies = #self.arena.main:get_objects_by_classes(self.arena.enemies_without_critters)
  if num_enemies >= self.max_enemies_on_screen then
      self.timer = 0.5 -- Set timer to retry and exit.
      return
  end
  
  self.timer = 0

  -- *** FIX: Set the flag to true BEFORE starting the spawn group. ***
  -- This locks the update() loop from interfering.
  self.is_group_spawning = true

  local group_data = wave_data[self.current_group_index]
  local enemy_type, amount = group_data[1], group_data[2]

  -- *** FIX: The callback now correctly manages the flag. ***
  local on_group_finished_spawning = function()
      -- Spawning for this group is done. Set flag to false.
      self.is_group_spawning = false
      
      self.current_group_index = self.current_group_index + 1
  end

  Spawn_Group(self.arena, self.current_wave_spawn_marker_index, enemy_type, amount, on_group_finished_spawning)
end

function SpawnManager:handle_boss_fight()
  local boss_name = ""
  if self.arena.level == 6 then boss_name = 'stompy'
  elseif self.arena.level == 11 then boss_name = 'dragon'
  elseif self.arena.level == 16 then boss_name = 'heigan'
  -- ... and so on for other bosses
  end
  
  if boss_name ~= "" then
      self.t:after(1.5, function() 
          Spawn_Boss(self.arena, boss_name) 
          self.t:every(function() return not LevelManager.activeBoss end, 
              function() self.arena:quit() end)
      end)
  end
end

function SpawnManager:show_wave_complete_text()
  spawn_mark2:play{pitch = 1, volume = 1.2}
  local text = Text2{group = self.arena.floor, x = gw/2, y = gh/2 - 48, lines = {{text = '[wavy_mid, cbyc]wave complete', font = fat_font, alignment = 'center'}}}
  text.t:after(self.timer - 0.2, function() text.t:tween(0.2, text, {sy = 0}, math.linear, function() text.sy = 0 end) end)
end

function SpawnManager:show_wave_start_countdown(seconds_remaining)
  if seconds_remaining > 0 and seconds_remaining < 4 then
    if not self.wave_start_countdown_timer or self.wave_start_countdown_timer ~= seconds_remaining then
      self.wave_start_countdown_timer = seconds_remaining
      local text = Text2{group = self.arena.floor, x = gw/2, y = gh/2 - 48, lines = {{text = '[wavy_mid, cbyc]' .. seconds_remaining, font = fat_font, alignment = 'center'}}}
      text.t:after(STARTING_WAVE_COUNTDOWN_DURATION, function() text.dead = true end)
    end
  else
    self.wave_start_countdown_timer = nil
  end
end


-- This MODIFIED function spawns a single group rapidly at a given point.
-- It no longer creates its own visual marker or has an initial delay.
function Spawn_Group(arena, group_index, type, amount, on_finished)
    SpawnGlobals.last_spawn_point = group_index
    amount = amount or 1
    -- A shorter interval for "rapid succession" feel between units in a group.
    local spawn_interval = arena.time_between_spawns or 0.1
    
    local spawned_count = 0
    local timer_id = "spawn_group_" .. random:uid()

    -- The action to be performed repeatedly by the timer.
    local spawn_action = function()
        -- 1. Get the position from the persistent wave marker's index.
        local spawn_marker = SpawnGlobals.get_spawn_marker(group_index)
        
        -- Use the current spawned_count to cycle through available offsets safely.
        local offset_index = (spawned_count % #SpawnGlobals.spawn_offsets) + 1
        local offset = SpawnGlobals.spawn_offsets[offset_index]
        
        if offset then
            local spawn_x, spawn_y = spawn_marker.x + offset.x, spawn_marker.y + offset.y

            -- 2. If the spawn is successful, increment our counter.
            Spawn_Enemy(arena, type, {x = spawn_x, y = spawn_y})
            spawned_count = spawned_count + 1
        else
            -- Failsafe in case of bad offset data.
            print("Warning: Invalid spawn offset.")
            spawned_count = spawned_count + 1 
        end

        -- 3. Check if we have finished spawning the entire group.
        if spawned_count >= amount then
            -- Stop this timer from running again.
            arena.t:cancel(timer_id)
            -- Call the callback to signal completion, which will trigger the next group.
            if on_finished then
                on_finished()
            end
        end
    end

    -- Immediately start the spawner timer.
    -- The visual marker is already present, created by the SpawnManager.
    arena.t:every(spawn_interval, spawn_action, nil, nil, timer_id)
end

--spawns a single enemy at a location
--if the location is occupied, the enemy will not spawn
function Spawn_Enemy(arena, type, location)
  local data = {}
  Spawn_Effect(arena, location, type)
  if table.contains(special_enemies, type) then
      hit4:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  else
      hit3:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  end
  local enemy = Enemy{type = type, group = arena.main,
  x = location.x, y = location.y,
  level = 1, data = data}
  
  -- Set enemy to frozen for 1 second on spawn
  Helper.Unit:set_state(enemy, unit_states['frozen'])
  enemy.t:after(1, function()
    if enemy.state == unit_states['frozen'] then
      Helper.Unit:set_state(enemy, unit_states['normal'])
    end
  end)

  return enemy
end

function Countdown(arena)
  arena.t:every(1, function()
    if arena.start_time > 1 then ui_hover1:play{pitch = 0.9, volume = 0.5} end
    arena.start_time = arena.start_time - 1
    arena.hfx:use('condition1', 0.25, 200, 10)
  end, 3, 
    function()
      magic_hit1:play{pitch = 1.2, volume = 0.5}
      camera:shake(4, 0.25)
      
      end)
end

function Spawn_Boss(arena, name)
  --set twice because of initial delay
  arena.spawning_enemies = true
  arena.wave_finished = false
  
  Spawn_Effect(arena, SpawnGlobals.boss_spawn_point, name)
  LevelManager.activeBoss = Enemy{type = name, isBoss = true, group = arena.main, x = SpawnGlobals.boss_spawn_point.x, y = SpawnGlobals.boss_spawn_point.y, level = arena.level}
  arena.spawning_enemies = false
  arena.wave_finished = true
  arena.finished = true
end

function Spawn_Critters(arena, group_index, amount)
  --set twice because of initial delay
  arena.spawning_enemies = true
  
  local spawn_marker = SpawnGlobals.corner_spawns[group_index]
  Spawn_Effect(arena, spawn_marker, 'critter')
  local index = 1
  arena.t:every(arena.time_between_spawns, function()
    alert1:play{pitch = 1, volume = 0.5}

    local offset = SpawnGlobals.spawn_offsets[index]
    local spawn_x, spawn_y = spawn_marker.x + offset.x, spawn_marker.y + offset.y
    EnemyCritter{group = arena.main, x = spawn_x, y = spawn_y, color = grey[0], v = 10}
  end, amount, function() SetSpawning(arena, false) end)


end

function Spawn_Effect(arena, location, type)

  -- spawn_mark2:play{pitch = 1.2, volume = 0.5}
  -- camera:shake(4, 0.25)
  local effect_magnitude = 2
  if table.contains(special_enemies, type) then
    effect_magnitude = 8
  elseif table.contains(boss_enemies, type) then
    effect_magnitude = 12
  end

  SpawnEffect{group = arena.effects, x = location.x, y = location.y, effect_magnitude = effect_magnitude}

end

function SetSpawning(arena, b)
  arena.spawning_enemies = b
end
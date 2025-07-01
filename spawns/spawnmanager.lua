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

  SpawnGlobals.mid_spawns = {
    {x = gw/2, y = y_corner_offset},
    {x = gw/2, y = gh - y_corner_offset},
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

--spawns troops in triangle formation around centre of arena
function Spawn_Teams(arena)
  --clear Helper.Unit.teams
  Helper.Unit.teams = {}
  
  for i, unit in ipairs(arena.units) do
      --add a new team
      local team = Team(i, unit)
      table.insert(Helper.Unit.teams, i, team)

      -- Triangle formation positions
      local spawn_x, spawn_y
      if i == 1 then
          -- First team: top of triangle
          spawn_x = gw/2
          spawn_y = gh/2 - 30
      elseif i == 2 then
          -- Second team: bottom right of triangle
          spawn_x = gw/2 + 50
          spawn_y = gh/2 + 30
      elseif i == 3 then
          -- Third team: bottom left of triangle
          spawn_x = gw/2 - 50
          spawn_y = gh/2 + 30
      else
          -- Additional teams: spread out in a larger triangle or circle
          local angle = (i - 1) * (2 * math.pi / math.max(#arena.units, 3))
          local radius = 80
          spawn_x = gw/2 + math.cos(angle) * radius
          spawn_y = gh/2 + math.sin(angle) * radius
      end

      team:set_troop_data({
          group = arena.main,
          x = spawn_x,
          y = spawn_y,
          level = unit.level,
          character = unit.character,
          items = unit.items,
          passives = arena.passives
      })
      
      -- ====================================================================
      -- MODIFIED SPAWN LOGIC
      -- Spawns 5 troops in a cluster with random jitter.
      -- ====================================================================
      
      -- Define the 5 base positions for the cluster (like the '5' on a die)
      local offsets = {
          {x = 0, y = 0},       -- Center
          {x = -8, y = -6},   -- Top-left
          {x = 8, y = -6},    -- Top-right
          {x = -8, y = 6},    -- Bottom-left
          {x = 8, y = 6}      -- Bottom-right
      }

      for _, offset in ipairs(offsets) do
          -- Add a small random jitter to make the cluster look more natural
          local jitter_x = math.random(-4, 4)
          local jitter_y = math.random(-4, 4)
          
          local x = spawn_x + offset.x + jitter_x
          local y = spawn_y + offset.y + jitter_y
          
          team:add_troop(x, y)
      end
      -- ====================================================================

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
    
    -- New property for handling kicker delays
    self.delay_timer = 0

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
    
    -- Update delay timer for kicker groups
    if self.delay_timer > 0 then
        self.delay_timer = self.delay_timer - dt
    end

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
          -- This state now just means the wave is active. The 'spawn_wave' function handles all logic.
          self.state = 'spawning_wave' 
          self:spawn_wave()
      end

  -- State: Spawning a wave
    elseif self.state == 'spawning_wave' then
      --pass
    
     -- State: Waiting for all enemies to be defeated
    elseif self.state == 'waiting_for_clear' then
      local enemy_count = #self.arena.main:get_objects_by_classes(self.arena.enemies)
      
      if table.contains(BOSS_ROUNDS, self.arena.level) then
        if self.arena.finished and enemy_count <= 0 then
            self.state = 'finished'
            self.arena:quit()
        end
      elseif enemy_count <= 0 then
        if self.current_wave_index >= #self.level_data.waves then
            if main.current.progress_bar:is_complete() then
                self.state = 'finished'
                self.arena:quit()
            end
        else
            -- Check if the current wave is complete by checking if progress >= required for current wave
            local current_wave_required = self.arena.progress_bar.wave_cumulative_power[self.current_wave_index]
            if current_wave_required and self.arena.progress_bar.progress >= current_wave_required then
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
        self.state = 'waiting_for_clear'
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

    self.state = 'wave_delay'
    self.current_group_index = 1
    self.timer = 0
    self.wave_delay_timer = TOTAL_STARTING_WAVE_DELAY

    -- 1. Determine the single spawn point for the entire wave.
    self.current_wave_spawn_marker_index = random:int(1, #SpawnGlobals.spawn_markers)
    SpawnGlobals.last_spawn_point = self.current_wave_spawn_marker_index
end

-- New function to replace 'spawn_next_group_in_chain'
function SpawnManager:spawn_wave()
  local wave_data = self.level_data.waves[self.current_wave_index]
  if not wave_data then
      self.state = 'waiting_for_clear'
      return
  end

  -- 1. Count how many non-kicker groups need to be tracked for completion.
  local parallel_group_count = 0
  for _, group_data in ipairs(wave_data) do
      if group_data[3] ~= 'kicker' then
          parallel_group_count = parallel_group_count + 1
      end
  end

  local finished_parallel_groups = 0
  -- This callback will be shared by all non-kicker groups.
  local on_parallel_group_done = function()
      finished_parallel_groups = finished_parallel_groups + 1
      -- Once all parallel groups are done, we can wait for the player to clear them.
      if finished_parallel_groups >= parallel_group_count then
          self.state = 'waiting_for_clear'
      end
  end

  -- If a wave only contains kickers, transition state immediately.
  if parallel_group_count == 0 then
      self.state = 'waiting_for_clear'
  end

  -- 2. Loop through the wave data and initiate ALL groups.
  for _, group_data in ipairs(wave_data) do
      local spawn_type = group_data[3]
      if spawn_type == 'kicker' then
          -- Kickers run on their own long timers and don't affect the state transition.
          -- The 'on_finished' callback is nil because we aren't tracking them here.
          Spawn_Group(self.arena, self.current_wave_spawn_marker_index, group_data, nil, self)
      else
          -- All other groups are spawned immediately and run in parallel.
          -- Pass the shared callback so we know when they're all done.
          Spawn_Group(self.arena, self.current_wave_spawn_marker_index, group_data, on_parallel_group_done, self)
      end
  end
end

function SpawnManager:handle_boss_fight()
  local boss_name = ""
  boss_name = level_to_boss_enemy[self.arena.level]
  
  if boss_name ~= "" then
      self.t:after(1.5, function() 
        -- Just call Spawn_Boss. It handles everything now.
        Spawn_Boss(self.arena, boss_name) 
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

function Spawn_Group(arena, group_index, group_data, on_finished, spawn_manager)
  local type, amount, spawn_type = group_data[1], group_data[2], group_data[3]


  -- Handle 'kicker' type with its special delay.
  -- The individual enemy markers are now handled by Spawn_Enemy.
  if spawn_type == 'kicker' then
      local total_delay = 5

      -- Set the main delay on the spawn manager. This blocks other groups.
      if spawn_manager then
          spawn_manager.delay_timer = total_delay
      end

      -- Determine the kicker's unique spawn location index ahead of time.
      local kicker_spawn_marker_index = random:int(1, #SpawnGlobals.spawn_markers)
      
      -- After the total delay, start the spawning process for this group.
      arena.t:after(total_delay, function()
          -- Unblock the spawn manager's delay check so the next group can be scheduled.
          if spawn_manager then
              spawn_manager.delay_timer = 0
          end
          
          -- Call the internal spawner. It will handle spawning enemies
          -- one-by-one, and each call to Spawn_Enemy will create a marker.
          -- The original on_finished callback is passed directly.
          Spawn_Group_Internal(arena, kicker_spawn_marker_index, group_data, on_finished)
      end)
      
      -- Exit so the default logic doesn't run for the kicker.
      return
  end

  -- For all non-kicker spawn types, proceed as normal.
  Spawn_Group_Internal(arena, group_index, group_data, on_finished)
end

function Spawn_Group_Internal(arena, group_index, group_data, on_finished)
  local type, amount, spawn_type = group_data[1], group_data[2], group_data[3]
  local spawn_marker_index = group_index
  amount = amount or 1

  -- Determine the final spawn marker location
  if spawn_type == 'far' then
      spawn_marker_index = Get_Far_Spawn(group_index)
  elseif spawn_type == 'random' then
      spawn_marker_index = random:int(1, #SpawnGlobals.spawn_markers)
  elseif spawn_type == 'close' then
      spawn_marker_index = Get_Close_Spawn(group_index)
  end
  
  local spawn_interval = 0
  
  -- This counter tracks how many of the parallel spawns have completed.
  local finished_count = 0
  
  -- This callback will be passed to each individual spawner.
  local on_single_unit_done = function()
      finished_count = finished_count + 1
      -- Once all units have spawned, call the original on_finished callback.
      if finished_count >= amount and on_finished then
          on_finished()
      end
  end

  -- This loop INITIATES all spawn processes at roughly the same time.
  for i = 1, amount do
    local spawn_marker = SpawnGlobals.get_spawn_marker(spawn_marker_index)
    local offset_index = ((i - 1) % #SpawnGlobals.spawn_offsets) + 1
    local offset = SpawnGlobals.spawn_offsets[offset_index]
    local location = {x = spawn_marker.x + offset.x, y = spawn_marker.y + offset.y}

    -- Define the function that creates the unit
    local create_enemy_action = function()
        Spawn_Enemy(arena, type, location)
    end
    
    -- Call the "smart" spawner for this single unit. It will handle its own
    -- stalling if the area is blocked. We pass it our completion tracker.
    arena.t:after(0.1 * i, function()
      Create_Unit_With_Warning(arena, location, 2, create_enemy_action, type, on_single_unit_done)
    end)
  end
end

-- This function is now just a simple unit factory.
function Spawn_Enemy(arena, type, location)
  local data = {}
  
  local enemy = Enemy{type = type, group = arena.main,
                      x = location.x, y = location.y,
                      level = 1, data = data}

  Spawn_Enemy_Effect(arena, enemy)

  -- Set enemy to frozen for 1 second on spawn.
  Helper.Unit:set_state(enemy, unit_states['frozen'])
  enemy.t:after(0.3, function()
      if enemy and not enemy.dead and enemy.state == unit_states['frozen'] then
          Helper.Unit:set_state(enemy, unit_states['normal'])
      end
  end)
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
  arena.spawning_enemies = true
  arena.wave_finished = false
  
  -- Define the action of creating the boss.
  local create_boss_action = function()
      LevelManager.activeBoss = Enemy{type = name, isBoss = true, group = arena.main, x = SpawnGlobals.boss_spawn_point.x, y = SpawnGlobals.boss_spawn_point.y, level = arena.level}
      Spawn_Enemy_Effect(arena, LevelManager.activeBoss)

      arena.spawning_enemies = false
      arena.wave_finished = true
      arena.finished = true
  end

  -- Spawn the boss with a longer, more dramatic 2.5-second warning.
  Create_Unit_With_Warning(arena, SpawnGlobals.boss_spawn_point, 2.5, create_boss_action, name)
end

function Spawn_Critters(arena, group_index, amount)
  arena.spawning_enemies = true
  
  local spawn_location_base = SpawnGlobals.corner_spawns[group_index]
  local spawned_count = 0

  -- This timer schedules the *warnings* for the critters.
  arena.t:every(arena.time_between_spawns, function()
      -- Use an offset for each critter.
      local offset_index = (spawned_count % #SpawnGlobals.spawn_offsets) + 1
      local offset = SpawnGlobals.spawn_offsets[offset_index]
      local spawn_pos = {x = spawn_location_base.x + offset.x, y = spawn_location_base.y + offset.y}

      -- Define the creation action for this specific critter.
      local create_critter_action = function()
          EnemyCritter{group = arena.main, x = spawn_pos.x, y = spawn_pos.y, color = grey[0], v = 10}
          Spawn_Enemy_Effect(arena, enemy)
      end
      
      -- Spawn this critter with its own short warning marker.
      Create_Unit_With_Warning(arena, spawn_pos, 1, create_critter_action, 'critter', group_index)
      
      spawned_count = spawned_count + 1
  end, amount, function() SetSpawning(arena, false) end)
end

function SetSpawning(arena, b)
  arena.spawning_enemies = b
end

function Spawn_Enemy_Effect(arena, enemy)
  local enemy_type = enemy.type
  local enemy_size = enemy_type_to_size[enemy_type]
  local enemy_width = enemy_size_to_xy[enemy_size].x

  local color = enemy.color

  Spawn_Enemy_Sound(arena, enemy)
  
  -- Add spawn wobble/hit effect to the enemy
  enemy.hfx:use('hit', 0.3, 200, 10, 0.2)
  enemy.spring:pull(0.2, 200, 10) -- Add spring wobble effect
  
  -- Add screen shake for bosses
  if enemy.isBoss then
    camera:shake(3, 0.3)
  end
  
  local num_particles = enemy_size_to_num_particles[enemy_size]
  for i = 1, num_particles do
    local particle = HitParticle{
      group = arena.effects,
      color = color,
      x = enemy.x, y = enemy.y,
      type = 'effect',
      size = 1,
      speed = 10,
      direction = random:float(0, 2 * math.pi),
      duration = 1,
      fade_out = true,
      fade_out_duration = 1,
    }
  end
end

function Spawn_Enemy_Sound(arena, enemy)
  local enemy_type = enemy.type
  local enemy_size = enemy_type_to_size[enemy_type]

  if enemy_size == 'small' then
    hit3:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  elseif enemy_size == 'regular' then
    hit3:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  elseif enemy_size == 'regular_big' then
    hit4:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  elseif enemy_size == 'big' then
    hit4:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  elseif enemy_size == 'huge' then
    hit4:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  elseif enemy_size == 'boss' then
    hit4:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  elseif enemy_size == 'heigan' then
    hit4:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  elseif enemy_size == 'stompy' then
    hit4:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  elseif enemy_size == 'critter' then
    alert1:play{pitch = 1, volume = 0.3}
  end
end

-- ===================================================================
-- REVISED Helper Function
-- Shows a warning marker immediately, then stalls until the space is clear to spawn.
-- ===================================================================
function Create_Unit_With_Warning(arena, location, warning_time, creation_callback, enemy_type, on_spawn_success_callback)
  local check_again_delay = 0.25 
  local spawn_radius = 10
  local enemy_size = enemy_type_to_size[enemy_type]

  if enemy_size then
    local enemy_width = enemy_size_to_xy[enemy_size].x
    spawn_radius = enemy_width / 2
  end

  -- 1. Create the visual warning marker immediately.
  -- We get a reference to it so we can destroy it manually later.
  local warning_marker = AnimatedSpawnCircle{
      group = arena.floor, x = location.x, y = location.y,
      duration = 1000, -- Give it a long duration so it doesn't fade early
      enemy_type = enemy_type
  }
  spawn_mark2:play{pitch = random:float(1.1, 1.3), volume = 0.25}

  -- 2. After the initial warning time, start checking if the space is clear.
  arena.t:after(warning_time, function()
      
      local attempt_final_spawn -- Forward-declare for the self-rescheduling timer
      
      attempt_final_spawn = function()
        -- Check if the area is occupied
        local spawn_circle = Circle(location.x, location.y, spawn_radius)
        local objects_in_spawn_area = arena.main:get_objects_in_shape(spawn_circle, arena.all_unit_classes)
          
          -- If the area is still blocked, stall and retry this check in a moment.
          -- The visual warning marker remains on-screen during this stall.
          if #objects_in_spawn_area > 0 then
              arena.t:after(check_again_delay, attempt_final_spawn)
              return
          end
          
          -- The area is finally clear! Time to spawn.
          
          -- First, remove the warning marker since the unit is now appearing.
          warning_marker.dead = true
          
          -- Then, run the callbacks to create the unit and notify the spawn manager.
          if creation_callback then creation_callback() end
          if on_spawn_success_callback then on_spawn_success_callback() end
      end

      -- Start the first attempt to spawn.
      attempt_final_spawn()
  end)
end
SpawnGlobals = {}
GLOBAL_TIME = Helper.Time.time

-- Constants for troop spawn positioning


function SpawnGlobals.Init()


  local left_x = gw/2 - 0.6*gw/2
  local right_x = gw/2 + 0.6*gw/2
  local mid_y = gh/2
  local y_offset = 35
  
  local y_corner_offset = 50

  SpawnGlobals.wall_width = 0.2*gw/2
  SpawnGlobals.wall_height = 0.2*gh/2

  SpawnGlobals.TROOP_SPAWN_BASE_X = SpawnGlobals.wall_width + 50  -- Further left than before
  SpawnGlobals.TROOP_SPAWN_BASE_Y = gh/2
  SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING = 60
  SpawnGlobals.TROOP_SPAWN_CIRCLE_RADIUS = 80
  SpawnGlobals.TROOP_FORMATION_HORIZONTAL_SPACING = 20
  SpawnGlobals.TROOP_FORMATION_VERTICAL_SPACING = 10
  SpawnGlobals.SUCTION_FORCE = 800
  SpawnGlobals.SUCTION_MIN_DISTANCE = 5
  
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
  local avoid_edge_distance = 10
  local x = random:int(SpawnGlobals.wall_width + avoid_edge_distance, gw - SpawnGlobals.wall_width - avoid_edge_distance)
  local y = random:int(SpawnGlobals.wall_height + avoid_edge_distance, gh - SpawnGlobals.wall_height - avoid_edge_distance)
  return {x = x, y = y}
end

function Get_Point_In_Right_Half()
  local avoid_edge_distance = 10
  local mid_x = gw / 2
  local x = random:int(mid_x + avoid_edge_distance, gw - SpawnGlobals.wall_width - avoid_edge_distance)
  local y = random:int(SpawnGlobals.wall_height + avoid_edge_distance, gh - SpawnGlobals.wall_height - avoid_edge_distance)
  return {x = x, y = y}
end

function Suction_Troops_To_Spawn_Locations(arena)
  -- Get all teams and their spawn locations
  for i, team in ipairs(Helper.Unit.teams) do
    if team and not team.dead then
      -- Calculate spawn location for this team (same as in Spawn_Teams)
      local spawn_x, spawn_y
      if i == 1 then
          spawn_x = SpawnGlobals.TROOP_SPAWN_BASE_X
          spawn_y = SpawnGlobals.TROOP_SPAWN_BASE_Y - SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING
      elseif i == 2 then
          spawn_x = SpawnGlobals.TROOP_SPAWN_BASE_X
          spawn_y = SpawnGlobals.TROOP_SPAWN_BASE_Y + SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING
      elseif i == 3 then
          spawn_x = SpawnGlobals.TROOP_SPAWN_BASE_X
          spawn_y = SpawnGlobals.TROOP_SPAWN_BASE_Y + SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING * 1.5
      else
          local angle = (i - 1) * (2 * math.pi / math.max(#arena.units, 3))
          spawn_x = SpawnGlobals.TROOP_SPAWN_BASE_X + math.cos(angle) * SpawnGlobals.TROOP_SPAWN_CIRCLE_RADIUS
          spawn_y = SpawnGlobals.TROOP_SPAWN_BASE_Y + math.sin(angle) * SpawnGlobals.TROOP_SPAWN_CIRCLE_RADIUS
      end
      
      -- Apply suction to each troop in the team
      for j, troop in ipairs(team.troops) do
        if troop and not troop.dead then
          
          local target_x = spawn_x
          local target_y = spawn_y
          
          -- Apply strong suction force towards spawn location
          local distance = Helper.Geometry:distance(troop.x, troop.y, target_x, target_y)
          
          if distance > SpawnGlobals.SUCTION_MIN_DISTANCE then  -- Only apply if not already at spawn
            local angle_to_spawn = math.atan2(target_y - troop.y, target_x - troop.x)
            local force_x = math.cos(angle_to_spawn) * SpawnGlobals.SUCTION_FORCE
            local force_y = math.sin(angle_to_spawn) * SpawnGlobals.SUCTION_FORCE
            
            troop:apply_force(force_x, force_y)
            
          end
        end
      end
    end
  end
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

      -- Left side formation positions
      local spawn_x, spawn_y
      if i == 1 then
          -- First team: top left
          spawn_x = SpawnGlobals.TROOP_SPAWN_BASE_X
          spawn_y = SpawnGlobals.TROOP_SPAWN_BASE_Y - SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING
      elseif i == 2 then
          -- Second team: middle left
          spawn_x = SpawnGlobals.TROOP_SPAWN_BASE_X
          spawn_y = SpawnGlobals.TROOP_SPAWN_BASE_Y + SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING
      elseif i == 3 then
          -- Third team: bottom left
          spawn_x = SpawnGlobals.TROOP_SPAWN_BASE_X
          spawn_y = SpawnGlobals.TROOP_SPAWN_BASE_Y + SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING * 1.5
      else
          -- Additional teams: spread out in a left-side formation
          local angle = (i - 1) * (2 * math.pi / math.max(#arena.units, 3))
          spawn_x = SpawnGlobals.TROOP_SPAWN_BASE_X + math.cos(angle) * SpawnGlobals.TROOP_SPAWN_CIRCLE_RADIUS
          spawn_y = SpawnGlobals.TROOP_SPAWN_BASE_Y + math.sin(angle) * SpawnGlobals.TROOP_SPAWN_CIRCLE_RADIUS
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
      -- Spawns 5 troops in a cluster with fixed, non-overlapping positions.
      -- ====================================================================
      
      -- Define 5 fixed positions that look random but are carefully spaced to avoid collisions
      -- Each position is at least 12 pixels apart from others to prevent overlapping
      local offsets = {
          {x = 0, y = 0},       -- Center
          {x = -12, y = -10},   -- Top-left
          {x = 12, y = -10},    -- Top-right  
          {x = -10, y = 12},    -- Bottom-left
          {x = 10, y = 12},      -- Bottom-right
          {x = 0, y = 24},       -- Bottom-center
          {x = 0, y = -20}       -- Top-center
      }

      local number_of_troops = UNIT_LEVEL_TO_NUMBER_OF_TROOPS[unit.level]

      for i = 1, number_of_troops do
        local offset = offsets[i]
          local x = spawn_x + offset.x
          local y = spawn_y + offset.y
          
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
    self.t = self.arena.t 

    self.spawn_reservations = {}

    -- Spawning State Machine
    self:change_state('entry_delay')
    -- Possible States:
    -- 'entry_delay':           Initial wait before the first wave.
    -- 'between_waves_delay':   Pause between clearing one wave and starting the next.
    -- 'processing_wave':       Actively reading and executing instructions for the current wave.
    -- 'waiting_for_group':     Paused, waiting for a Spawn_Group call to finish.
    -- 'waiting_for_delay':     Paused, waiting for a DELAY instruction's timer to finish.
    -- 'waiting_for_boss_fight': Paused, waiting for the boss fight to finish.
    -- 'waiting_for_clear':     All instructions for the wave are done; waiting for all enemies to be defeated.
    -- 'finished':              All waves are complete.
    -- 'boss_fight':            A special state for boss levels.

    -- Timers and Trackers
    self.time_between_waves = arena.time_between_waves or 3
    self.timer = arena.entry_delay or 2
    self.current_wave_index = 1
    self.current_instruction_index = 1

    self.pending_spawns = 0
    
    if table.contains(BOSS_ROUNDS, arena.level) then
        self:change_state('boss_fight')
    end
end

function SpawnManager:does_spawn_reservation_exist(x, y)
  return self.spawn_reservations[x] and self.spawn_reservations[x][y]
end

function SpawnManager:reserve_spawn(x, y)
  self.spawn_reservations[x] = self.spawn_reservations[x] or {}
  self.spawn_reservations[x][y] = true
  self.t:after(0.1, function()
    self.spawn_reservations[x][y] = nil
  end)
end

function SpawnManager:change_state(new_state)
    if self.state ~= new_state then
        self.state = new_state
    end
end

function SpawnManager:update(dt)
    if self.state == 'finished' then return end

    -- Handle states that are purely time-based
    if self.state == 'entry_delay' or self.state == 'waiting_for_delay' then
      self.timer = self.timer - dt
      if self.timer <= 0 then
        self.pending_spawns = 0
          self:change_state('processing_wave')
          spawn_mark2:play{pitch = random:float(1.1, 1.3), volume = 0.25}
      end
    elseif self.state == 'between_waves_delay' then
        -- Apply continuous suction effect during between-waves delay
        Suction_Troops_To_Spawn_Locations(self.arena)
        self.timer = self.timer - dt
        if self.timer <= 0 then
          self.pending_spawns = 0
            self:change_state('processing_wave')
            spawn_mark2:play{pitch = random:float(1.1, 1.3), volume = 0.25}
        end
    end

    -- If we are ready to process the next instruction in a wave, do so.
    if self.state == 'processing_wave' then
        self:process_next_instruction()
        -- Only change to waiting_for_clear if we're not in a delay state
        if self.state == 'processing_wave' then
            self:change_state('waiting_for_clear')
        end
    
    -- If all instructions are done, wait for the arena to be clear.
    elseif self.state == 'waiting_for_clear' then
      local enemies = self.arena.main:get_objects_by_classes(self.arena.enemies)
      if #enemies <= 0 and self.pending_spawns <= 0 then
          -- Check if this was the final wave
          if self.current_wave_index >= #self.level_data.waves then
              -- For the final wave, we DO check the progress bar to confirm a win.
              if not main.current.progress_bar or main.current.progress_bar:is_complete() then
                  self:change_state('finished')
                  self.arena:open_door()
              end
          else
              -- ===================================================================
              -- FIX: For intermediate waves, the only condition to advance is that
              -- all enemies are dead. We no longer check the progress bar here.
              -- ===================================================================
              -- Trigger suction effect to pull troops back to spawn locations
              Suction_Troops_To_Spawn_Locations(self.arena)
              
              self.t:after(0.5, function()
                spawn_mark2:play{pitch = 1, volume = 1.2}
              end)
              self.current_wave_index = self.current_wave_index + 1
              self.current_instruction_index = 1
              self:change_state('between_waves_delay')
              self.timer = self.time_between_waves
              -- self:show_wave_complete_text()
          end
      end
    
    elseif self.state == 'boss_fight' then
        self:handle_boss_fight(self.arena)
        self:change_state('waiting_for_clear')
    end
end

function SpawnManager:handle_boss_fight(arena)
  local boss_name = ""
  boss_name = level_to_boss_enemy[self.arena.level]

  self.arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns + 1
  
  if boss_name ~= "" then
      self.t:after(1.5, function() 
        -- Just call Spawn_Boss. It handles everything now.
        Spawn_Boss(self.arena, boss_name) 
      end)
  end
end

-- This function processes all instructions for a wave segment at once.
function SpawnManager:process_next_instruction()
  
  --play spawn sound only once for the wave
  self.arena.t:after(WAVE_SPAWN_WARNING_TIME, function()
    Spawn_Enemy_Sound(self.arena, false)
  end)
  
  -- Loop until we explicitly break out (due to a delay or end of wave).
  while true do
      local wave_instructions = self.level_data.waves[self.current_wave_index]

      -- Check if we've finished all instructions for this wave.
      if self.current_instruction_index > #wave_instructions then
          -- All instructions for the wave are queued. Now we just wait for clear.
          self:change_state('waiting_for_clear')
          break
      end

      local instruction = wave_instructions[self.current_instruction_index]
      local type = instruction[1]

      if type == 'GROUP' then
          local group_data = {instruction[2], instruction[3], instruction[4]}
          -- Call Spawn_Group. It will handle incrementing the pending_spawns counter.
          -- No callback is needed here.
          Spawn_Group(self.arena, group_data)

      elseif type == 'DELAY' then
          -- Pause for the specified duration.
          self:change_state('waiting_for_delay')
          self.timer = instruction[2] or 1
          -- IMPORTANT: Increment the index so we don't re-process the DELAY.
          self.current_instruction_index = self.current_instruction_index + 1
          break -- Exit the loop to honor the delay.
      end

      -- Move to the next instruction.
      self.current_instruction_index = self.current_instruction_index + 1
  end
end


-- ===================================================================
-- REFACTORED: Spawn_Group and Spawn_Group_Internal
-- Spawn_Group now just determines the spawn location index.
-- Spawn_Group_Internal handles the actual spawning logic.
-- ===================================================================
function Spawn_Group(arena, group_data, on_finished)
    local type, amount, spawn_type = group_data[1], group_data[2], group_data[3]
    
    -- Determine the spawn marker index based on the spawn type
    local spawn_marker_index
    if spawn_type == 'far' then
        spawn_marker_index = Get_Far_Spawn(SpawnGlobals.last_spawn_point)
    elseif spawn_type == 'close' then
        spawn_marker_index = Get_Close_Spawn(SpawnGlobals.last_spawn_point)
    elseif spawn_type == 'scatter' then
        -- Scatter doesn't use a single marker, so we pass nil
        spawn_marker_index = nil
    else -- 'random' or nil defaults to a random marker
        spawn_marker_index = random:int(1, #SpawnGlobals.spawn_markers)
    end
    
    SpawnGlobals.last_spawn_point = spawn_marker_index
    
    -- Call the internal function that does the real work
    Spawn_Group_Internal(arena, spawn_marker_index, group_data, on_finished)
end

function Spawn_Group_Internal(arena, group_index, group_data, on_finished)
    local type, amount = group_data[1], group_data[2]
    local spawn_type = group_data[3]
    amount = amount or 1

    -- This loop initiates all spawn processes at roughly the same time.
    for i = 1, amount do
        local location
        if spawn_type == 'scatter' then
            -- For scatter, get a new random point for every single unit
            location = Get_Point_In_Right_Half()
        else
            -- For all other types, use offsets from the chosen spawn marker
            location = Get_Point_In_Right_Half()
        end

        local create_enemy_action = function()
            Spawn_Enemy(arena, type, location)
        end
        arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns + 1
        
        -- Stagger the spawn warnings slightly for a better visual effect.
        Create_Unit_With_Warning(arena, location, WAVE_SPAWN_WARNING_TIME, create_enemy_action, type)
    end
end


-- This function is now just a simple unit factory.
function Spawn_Enemy(arena, type, location)
  local data = {}
  
  local enemy = Enemy{type = type, group = arena.main,
                      x = location.x, y = location.y,
                      level = arena.level, data = data}

  Spawn_Enemy_Effect(arena, enemy)

  -- Set enemy to idle for a bit on spawn.
  Helper.Unit:set_state(enemy, unit_states['idle'])
  enemy.idleTimer = math.random() / 2
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
  
  -- Define the action of creating the boss.
  local create_boss_action = function()
      LevelManager.activeBoss = Enemy{type = name, isBoss = true, group = arena.main, x = SpawnGlobals.boss_spawn_point.x, y = SpawnGlobals.boss_spawn_point.y, level = arena.level}
      Spawn_Enemy_Effect(arena, LevelManager.activeBoss)
      Spawn_Enemy_Sound(arena, true)
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
      Create_Unit_With_Warning(arena, spawn_pos, 1, create_critter_action, 'critter')
      
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

function Spawn_Enemy_Sound(arena, isBoss)
  if isBoss then
    hit4:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  else
    hit3:play{pitch = random:float(0.8, 1.2), volume = 0.4}
  end
end

-- ===================================================================
-- REVISED Helper Function
-- Shows a warning marker immediately, then stalls until the space is clear to spawn.
-- ===================================================================
function Create_Unit_With_Warning(arena, location, warning_time, creation_callback, enemy_type)
  local check_again_delay = 0.25
  local spawn_radius = 10
  local enemy_size = enemy_type_to_size[enemy_type]

  if enemy_size then
    local enemy_width = enemy_size_to_xy[enemy_size].x
    spawn_radius = enemy_width / 4
  end

  -- 1. Create the visual warning marker immediately.
  -- We get a reference to it so we can destroy it manually later.
  local warning_marker = AnimatedSpawnCircle{
      group = arena.floor, x = location.x, y = location.y,
      duration = 1000, -- Give it a long duration so it doesn't fade early
      expected_spawn_time = warning_time,
      enemy_type = enemy_type
  }

  -- 2. After the initial warning time, start checking if the space is clear.
  arena.t:after(warning_time, function()
      
      local attempt_final_spawn -- Forward-declare for the self-rescheduling timer
      
      attempt_final_spawn = function()
        -- Check if the area is occupied
        local spawn_circle = Circle(location.x, location.y, spawn_radius)
        local objects_in_spawn_area = arena.main:get_objects_in_shape(spawn_circle, arena.all_unit_classes)
          
          -- If the area is still blocked, stall and retry this check in a moment.
          -- The visual warning marker remains on-screen during this stall.
          if #objects_in_spawn_area > 0 or arena.spawn_manager:does_spawn_reservation_exist(location.x, location.y) then
              arena.t:after(check_again_delay, attempt_final_spawn)
              return
          end

          arena.spawn_manager:reserve_spawn(location.x, location.y)
          
          -- The area is finally clear! Time to spawn.
          
          -- First, remove the warning marker since the unit is now appearing.
          warning_marker.dead = true

          -- Then, run the callbacks to create the unit and notify the spawn manager.
          if creation_callback then creation_callback() end

          arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns - 1

          
      end

      -- Start the first attempt to spawn.
      attempt_final_spawn()
  end)
end


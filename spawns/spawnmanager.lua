SpawnGlobals = {}
GLOBAL_TIME = Helper.Time.time

-- Constants for troop spawn positioning


function SpawnGlobals.Init()


  local left_x = gw/2 - 0.6*gw/2
  local right_x = gw/2 + 0.6*gw/2
  local mid_y = gh/2
  local y_offset = 35
  
  local y_corner_offset = 50

  SpawnGlobals.offscreen_spawn_offset = 15
  SpawnGlobals.CAMERA_BOUNDS_OFFSET = 3
  SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET = 45

  SpawnGlobals.wall_width = 0
  SpawnGlobals.wall_height = 0

  SpawnGlobals.TROOP_0_SPAWN_X = gw/2
  SpawnGlobals.TROOP_0_SPAWN_Y = gh - 50

  SpawnGlobals.FURTHEST_SPAWN_POINT = 1/3
  SpawnGlobals.FURTHEST_SPAWN_POINT_SCATTER = 1/7
  SpawnGlobals.SPAWN_DISTANCE_OUTSIDE_ARENA = 100

  SpawnGlobals.TROOP_SPAWN_BASE_X = SpawnGlobals.wall_width + 50  -- Further left than before
  SpawnGlobals.TROOP_SPAWN_BASE_Y = gh/2
  SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING = 60
  SpawnGlobals.TROOP_SPAWN_CIRCLE_RADIUS = 30
  SpawnGlobals.TROOP_FORMATION_HORIZONTAL_SPACING = 20
  SpawnGlobals.TROOP_FORMATION_VERTICAL_SPACING = 10

  SpawnGlobals.SUCTION_FORCE = 600
  SpawnGlobals.SUCTION_MAX_V = 150
  
  SpawnGlobals.SUCTION_MIN_DISTANCE = 12
  SpawnGlobals.SUCTION_CANCELABLE_DISTANCE = 20
  SpawnGlobals.SUCTION_CANCEL_THRESHOLD = 0.65

  TROOP_0_SPAWN_LOCATION = {x = SpawnGlobals.TROOP_0_SPAWN_X, y = SpawnGlobals.TROOP_0_SPAWN_Y}
  TEAM_INDEX_TO_SPAWN_LOCATION = {
    [0] = {x = SpawnGlobals.TROOP_0_SPAWN_X, y = SpawnGlobals.TROOP_0_SPAWN_Y},
    [1] = {x = SpawnGlobals.TROOP_SPAWN_BASE_X, y = SpawnGlobals.TROOP_SPAWN_BASE_Y - SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING},
    [2] = {x = SpawnGlobals.TROOP_SPAWN_BASE_X, y = SpawnGlobals.TROOP_SPAWN_BASE_Y + SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING},
    [3] = {x = SpawnGlobals.TROOP_SPAWN_BASE_X, y = SpawnGlobals.TROOP_SPAWN_BASE_Y + SpawnGlobals.TROOP_SPAWN_VERTICAL_SPACING * 1.5},
  }

  SpawnGlobals.Get_Team_Spawn_Locations = function(num_teams)
    local center = {x = gw/2, y = gh/2}

    if num_teams == 1 then
      return {center}
    end
    
    local base_angle = 0
    if num_teams == 3 then
      base_angle = -math.pi / 2
    end

    local angle_per_team = 2 * math.pi / num_teams

    local spawn_locations = {}
    for i = 1, num_teams do
      local angle = base_angle + (i - 1) * angle_per_team
      local spawn_location = {x = center.x + math.cos(angle) * SpawnGlobals.TROOP_SPAWN_CIRCLE_RADIUS, y = center.y + math.sin(angle) * SpawnGlobals.TROOP_SPAWN_CIRCLE_RADIUS}
      table.insert(spawn_locations, spawn_location)
    end
    return spawn_locations
  end

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

function Get_Offscreen_Spawn_Point()
  local x, y

  -- Choose which edge to spawn from (top, bottom, left, right)
  local edge = random:int(1, 4)

  if edge == 1 then -- Top edge
    x = random:int(-SpawnGlobals.offscreen_spawn_offset, gw + SpawnGlobals.offscreen_spawn_offset)
    y = -SpawnGlobals.offscreen_spawn_offset -- Just off the top edge
  elseif edge == 2 then -- Bottom edge
    x = random:int(-SpawnGlobals.offscreen_spawn_offset, gw + SpawnGlobals.offscreen_spawn_offset)
    y = gh + SpawnGlobals.offscreen_spawn_offset -- Just off the bottom edge
  elseif edge == 3 then -- Left edge
    x = -SpawnGlobals.offscreen_spawn_offset -- Just off the left edge
    y = random:int(-SpawnGlobals.offscreen_spawn_offset, gh + SpawnGlobals.offscreen_spawn_offset)
  else -- Right edge
    x = gw + SpawnGlobals.offscreen_spawn_offset -- Just off the right edge
    y = random:int(-SpawnGlobals.offscreen_spawn_offset, gh + SpawnGlobals.offscreen_spawn_offset)
  end

  return {x = x, y = y}
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

function Get_Point_In_Arena(unit, min_distance)
  local avoid_edge_distance = 10
  local x, y
  
  if unit and min_distance then
    --find a point at least min_distance away from the unit
    local max_attempts = 50
    local attempts = 0
    while attempts < max_attempts do
      x = random:int(SpawnGlobals.wall_width + avoid_edge_distance, gw - SpawnGlobals.wall_width - avoid_edge_distance)
      y = random:int(SpawnGlobals.wall_height + avoid_edge_distance, gh - SpawnGlobals.wall_height - avoid_edge_distance)
      if math.distance(x, y, unit.x, unit.y) > min_distance then
        return {x = x, y = y}
      end
      attempts = attempts + 1
    end
    --return the last attempt anyway
    return {x = x, y = y}
  else
    local x = random:int(SpawnGlobals.wall_width + avoid_edge_distance, gw - SpawnGlobals.wall_width - avoid_edge_distance)
    local y = random:int(SpawnGlobals.wall_height + avoid_edge_distance, gh - SpawnGlobals.wall_height - avoid_edge_distance)
    return {x = x, y = y}
  end
end

function Get_Point_In_Right_Half(arena)
  local avoid_edge_distance = 10
  local mid_x = gw / 2
  local x = random:int(mid_x + avoid_edge_distance, gw - SpawnGlobals.wall_width - avoid_edge_distance)
  local y = random:int(SpawnGlobals.wall_height + avoid_edge_distance, gh - SpawnGlobals.wall_height - avoid_edge_distance)
  x = x + arena.offset_x
  y = y + arena.offset_y
  return {x = x, y = y}
end

function Get_Edge_Spawn_Point()
  -- Randomly choose an edge: 1=top, 2=right, 3=bottom, 4=left
  local edge = math.random(1, 4)
  local x, y
  
  local center_x = gw / 2
  local center_y = gh / 2
  
  if edge == 1 then -- top
    x = math.random(gw * SpawnGlobals.FURTHEST_SPAWN_POINT, gw * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT))
    y = SpawnGlobals.FURTHEST_SPAWN_POINT * center_y
  elseif edge == 2 then -- right  
    x = gw * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT)
    y = math.random(gh * SpawnGlobals.FURTHEST_SPAWN_POINT, gh * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT))
  elseif edge == 3 then -- bottom
    x = math.random(gw * SpawnGlobals.FURTHEST_SPAWN_POINT, gw * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT))
    y = gh * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT)
  else -- left
    x = SpawnGlobals.FURTHEST_SPAWN_POINT * center_x
    y = math.random(gh * SpawnGlobals.FURTHEST_SPAWN_POINT, gh * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT))
  end
  
  return {x = x, y = y}
end

function Get_Random_Spawn_Point()
  local x = math.random(gw * SpawnGlobals.FURTHEST_SPAWN_POINT, gw * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT))
  local y = math.random(gh * SpawnGlobals.FURTHEST_SPAWN_POINT, gh * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT))
  return {x = x, y = y}
end

function Get_Random_Spawn_Point_Scatter()
  local x = math.random(gw * SpawnGlobals.FURTHEST_SPAWN_POINT_SCATTER, gw * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT_SCATTER))
  local y = math.random(gh * SpawnGlobals.FURTHEST_SPAWN_POINT_SCATTER, gh * (1 - SpawnGlobals.FURTHEST_SPAWN_POINT_SCATTER))
  return {x = x, y = y}
end

function Suction_Troops_To_Spawn_Locations(arena, apply_angular_force)
  

  -- Get all teams and their spawn locations
  local num_troops_close_to_target = 0
  local num_total_troops = #Helper.Unit:get_all_troops()

  for i, team in ipairs(Helper.Unit.teams) do
    if team and not team.dead then
      -- Calculate spawn location for this team (same as in Spawn_Teams)
      local spawn_x = team.spawn_location.x
      local spawn_y = team.spawn_location.y
      
      -- Apply suction to each troop in the team
      for j, troop in ipairs(team.troops) do
        if troop and not troop.dead and troop.being_knocked_back then
          
          local target_x = spawn_x
          local target_y = spawn_y
          
          -- Apply strong suction force towards spawn location
          local distance = Helper.Geometry:distance(troop.x, troop.y, target_x, target_y)
          
          local multiplier = math.remap_clamped(distance, 15, 100, 0.2, 1)
          local damping_multiplier = math.remap_clamped(distance, 100, 10, 1, 3)
          -- local angular_multiplier = math.remap_clamped(distance, 100, 10, 0.2, 0)
          local angular_multiplier = 0

          local force = SpawnGlobals.SUCTION_FORCE * multiplier

          
          if distance < SpawnGlobals.SUCTION_CANCELABLE_DISTANCE then
            num_troops_close_to_target = num_troops_close_to_target + 1
          end
            
          if distance > SpawnGlobals.SUCTION_MIN_DISTANCE then  -- Only apply if not already at spawn
            troop:set_damping(get_damping_by_unit_class(troop.class) * damping_multiplier)
            local angle_to_spawn = math.atan2(target_y - troop.y, target_x - troop.x)
            local suction_force_x = math.cos(angle_to_spawn) * force
            local suction_force_y = math.sin(angle_to_spawn) * force
            
            troop:apply_force(suction_force_x, suction_force_y)

            local angular_force = SpawnGlobals.SUCTION_FORCE * angular_multiplier

            if apply_angular_force then
              local perpendicular_angle = angle_to_spawn + (math.pi / 2)
              local swirl_force_x = math.cos(perpendicular_angle) * angular_force
              local swirl_force_y = math.sin(perpendicular_angle) * angular_force
              troop:apply_force(swirl_force_x, swirl_force_y)
            end
          else
            if team.spawn_marker then
              team.spawn_marker:troop_suctioned()
            end
            Helper.Unit:troop_end_suction(troop)
          end
        end
      end
    end
  end

  if Helper.Unit:all_troops_done_suction() then
    End_Suction(arena)
  end
end

--has to be safe to call multiple times, because there's the fallback call in world manager
function End_Suction(arena)
  Helper.Unit:all_troops_end_suction()

  if arena.spawn_manager.state == 'suction_to_targets' then
    ui_switch1:play{pitch = random:float(1.1, 1.3), volume = 1}
    arena.spawn_manager.timer = TIME_BETWEEN_WAVES
    arena.spawn_manager:change_state('entry_delay')
    if arena.progress_bar then
      arena.progress_bar:begin_fade_in()
    end
  end

end

function Kill_Teams()
  for i, team in ipairs(Helper.Unit.teams) do
    team:die()
  end
end

function Replace_Team(arena, index, unit)
  local unit_locations = {}
  local team = Helper.Unit.teams[index]
  local troops = team.troops
  for i, troop in ipairs(troops) do
    local x = troop.x + (math.random() - 0.5) * 2
    local y = troop.y + (math.random() - 0.5) * 2
    table.insert(unit_locations, {x = x, y = y})
  end

  team:die()
  Helper.Unit.teams[index] = nil

  local newTeam = Team(index, unit)
  table.insert(Helper.Unit.teams, index, newTeam)

  newTeam:set_troop_data({
    group = arena.main,
    x = unit_locations[1].x,
    y = unit_locations[1].y,
    level = 1,
    character = unit.character,
    items = {nil, nil, nil, nil, nil, nil},
    passives = arena.passives
  })
  
  Spawn_Troops_At_Locations(arena, newTeam, unit_locations)
  newTeam:apply_item_procs()
end

function Spawn_Team(arena, index, unit)
  if Helper.Unit.teams[index] then
    print('team already exists', index)
    return
  end

  local first_team = Helper.Unit.teams[1]
  if not first_team then
    print('no first team')
    return
  end

  local spawn_location = first_team:get_center()
  
  local newTeam = Team(index, unit)
  table.insert(Helper.Unit.teams, index, newTeam)

  newTeam:set_troop_data({
    group = arena.main,
    x = spawn_location.x,
    y = spawn_location.y,
    level = unit.level,
    character = unit.character,
    items = unit.items,
    passives = arena.passives
  })

  Spawn_Troops(arena, newTeam, unit, spawn_location)
  newTeam:apply_item_procs()
end



--if suction enabled, troops will be spawned outside [fg]when enemies hit walls they create an area based to the knockback force
--so they can be sucked back in
function Spawn_Teams(arena, suction_enabled)
  --clear Helper.Unit.teams
  Helper.Unit.teams = {}
  
  local spawn_locations = SpawnGlobals.Get_Team_Spawn_Locations(#arena.units)

  for i, unit in ipairs(arena.units) do
      --add a new team
      local team = Team(i, unit)
      table.insert(Helper.Unit.teams, i, team)
      
      -- Left side formation positions
      local team_spawn_location = spawn_locations[i]
      team.spawn_location = team_spawn_location
      
      local spawn_x = team_spawn_location.x
      local spawn_y = team_spawn_location.y

      team:set_troop_data({
          group = arena.main,
          x = spawn_x,
          y = spawn_y,
          level = unit.level,
          character = unit.character,
          items = unit.items,
          passives = arena.passives
      })

      if suction_enabled then
        Spawn_Troops(arena, team, unit)
        team:create_spawn_marker()
      else
        Spawn_Troops(arena, team, unit, team_spawn_location)
      end
      team:apply_item_procs()
  end
end

function Spawn_Troops_At_Locations(arena, team, locations)
  for i, location in ipairs(locations) do
    Helper.Unit:resurrect_troop(team, nil, location)
  end
end

function Get_Random_Spawn_Outside_Arena(distance)
  local random_offset = random:float(0.5, 1) * distance
  if math.random() < 0.5 then
    local x = math.random() * gw
    local y = table.random({-distance - random_offset, gh + distance + random_offset})
    return {x = x, y = y}
  else
    local x = table.random({-distance - random_offset, gw + distance + random_offset})
    local y = math.random() * gh
    return {x = x, y = y}
  end
end

function Spawn_Troops(arena, team, unit, spawn_location)


  local team_spawn_location = spawn_location

  local number_of_troops = UNIT_LEVEL_TO_NUMBER_OF_TROOPS[unit.level]

  if unit.troop_hps then
    for i = 1, number_of_troops do
      
      local health = unit.troop_hps[i]
      if health and health > 0 then
        if not team_spawn_location then
          spawn_location = Get_Random_Spawn_Outside_Arena(SpawnGlobals.SPAWN_DISTANCE_OUTSIDE_ARENA)
        end
        local offset_x = (math.random() - 0.5) * 10
        local offset_y = (math.random() - 0.5) * 10
        local x = spawn_location.x + offset_x
        local y = spawn_location.y + offset_y
        local troop = team:add_troop(x, y)
        troop.hp = unit.troop_hps[i]
      end
    end
  else
    for i = 1, number_of_troops do
      if not team_spawn_location then
        spawn_location = Get_Random_Spawn_Outside_Arena(SpawnGlobals.SPAWN_DISTANCE_OUTSIDE_ARENA)
      end
      local offset_x = (math.random() - 0.5) * 10
      local offset_y = (math.random() - 0.5) * 10
      local x = spawn_location.x + offset_x
      local y = spawn_location.y + offset_y
        
        team:add_troop(x, y)
    end
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
SpawnManager.__class_name = 'SpawnManager'

function SpawnManager:init(arena)
    self.arena = arena
    self.level_data = arena.level_list[arena.level]
    self.t = self.arena.t 

    self.spawn_reservations = {}

    -- Spawning State Machine
    self:change_state('arena_start')
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
    self.timer = arena.entry_delay or 1
    self.current_wave_index = 1
    self.current_instruction_index = 1

    self.pending_spawns = 0
    self.wave_spawn_delay = 0 -- Track cumulative spawn delay for the current wave
  
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

function SpawnManager:complete_wave(wave_index)
    -- Failsafe function to ensure wave progress is complete
    if self.arena and self.arena.progress_bar then
        self.arena.progress_bar:complete_wave(wave_index)
    end
end

function SpawnManager:update(dt)
    if self.state == 'finished' then return end
    --don't do anything until triggered by world manager
    if self.state == 'arena_start' then return end

    if self.state == 'suction_to_targets' then 
      Suction_Troops_To_Spawn_Locations(self.arena, true)
      return
    end

    -- Handle states that are purely time-based
    if self.state == 'entry_delay' or self.state == 'waiting_for_delay' then
      self.timer = self.timer - dt
      if self.timer <= 0 then
        self.pending_spawns = 0
        if Is_Boss_Level(self.arena.level) then
          self:change_state('spawning_boss')
          spawn_mark2:play{pitch = random:float(1.1, 1.3), volume = 0.5}
        else
          self:change_state('processing_wave')
          --spawn_mark2:play{pitch = random:float(1.1, 1.3), volume = 0.25}
        end
      end
    elseif self.state == 'between_waves_delay' then
        -- Apply continuous suction effect during between-waves delay
        -- Suction_Troops_To_Spawn_Locations(self.arena)
        self.timer = self.timer - dt
        if self.timer <= 0 then
          self.pending_spawns = 0
            self:change_state('processing_wave')
            --spawn_mark2:play{pitch = random:float(1.1, 1.3), volume = 0.25}
        end
    end

    -- If we are ready to process the next instruction in a wave, do so.
    if self.state == 'processing_wave' then
        self:process_next_instruction()
        -- Only change to waiting_for_clear if we're not in a delay state
        if self.state == 'processing_wave' then
            self:change_state('waiting_for_clear')
        end
    end

    if self.state == 'spawning_boss' then
      self:spawn_boss_immediately()
      self:change_state('waiting_for_clear')
    end
    
    -- If all instructions are done, wait for the arena to be clear.
    if self.state == 'waiting_for_clear' then
      local enemies = self.arena.main:get_objects_by_classes(main.current.enemies)
      if #enemies <= 0 and self.pending_spawns <= 0 then
          -- Check if this was the final wave
          if self.current_wave_index >= #self.level_data.waves then
              -- For the final wave, we just need all enemies dead
              self:change_state('finished')
              self.arena:level_clear()
          else
              -- ===================================================================
              -- FIX: For intermediate waves, the only condition to advance is that
              -- all enemies are dead. We no longer check the progress bar here.
              -- ===================================================================
              -- Trigger suction effect to pull troops back to spawn locations
              -- Suction_Troops_To_Spawn_Locations(self.arena)
              
              self.t:after(0.5, function()
                -- spawn_mark2:play{pitch = 1, volume = 1.2}
              end)
              -- Ensure wave progress is complete before advancing
              self:complete_wave(self.current_wave_index)
              
              self.current_wave_index = self.current_wave_index + 1
              self.current_instruction_index = 1
              self:change_state('between_waves_delay')
              self.timer = TIME_BETWEEN_WAVES
              -- self:show_wave_complete_text()
          end
        end
      end

end



-- This function processes all instructions for a wave segment at once.
function SpawnManager:process_next_instruction()
  
  -- Reset wave spawn delay for this wave
  self.wave_spawn_delay = 0
  
  -- Get single spawn location for this entire wave (around screen edges, 1/3 toward center)
  local wave_spawn_location = Get_Offscreen_Spawn_Point()
  
  --play spawn sound only once for the wave
  -- Spawn_Enemy_Sound(self.arena, false)
  
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
      local spawn_type = instruction[4]

      if type == 'GROUP' then
          local group_data = {instruction[2], instruction[3], instruction[4]}
          -- Call Spawn_Group with the wave's spawn location
          if spawn_type == 'scatter' then
            Spawn_Group_Scattered(self.arena, group_data)
          elseif spawn_type == 'location' then
            local location = instruction[5]
            Spawn_Group_With_Location(self.arena, group_data, location)
          elseif spawn_type == 'close' and self.arena.last_spawn_point then
            Spawn_Group_With_Location(self.arena, group_data, self.arena.last_spawn_point)
          else
            Spawn_Group_With_Location(self.arena, group_data, wave_spawn_location)
          end

      elseif type == 'DELAY' then
          -- Add delay time to wave spawn delay so enemies after the delay spawn later
          self.wave_spawn_delay = self.wave_spawn_delay + (instruction[2] or 1)
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

function Spawn_Group_With_Location(arena, group_data, wave_spawn_location, on_finished)
    local type, amount, spawn_type = group_data[1], group_data[2], group_data[3]
    amount = amount or 1

    arena.last_spawn_point = wave_spawn_location

    -- AnimatedSpawnCircle{
    --   group = arena.floor, x = wave_spawn_location.x, y = wave_spawn_location.y,
    --   duration = WAVE_SPAWN_WARNING_TIME,
    --   expected_spawn_time = WAVE_SPAWN_WARNING_TIME,
    -- }

    -- This loop initiates all spawn processes with 0.1 second spacing using SpawnManager's delay counter
    local spawn_offsets = {{x = -12, y = -12}, {x = 12, y = -12}, {x = 12, y = 12}, {x = -12, y = 12}, {x = 0, y = 0}}
    
    for i = 1, amount do
        local offset = spawn_offsets[i % #spawn_offsets + 1]
        local location = {x = wave_spawn_location.x + offset.x, y = wave_spawn_location.y + offset.y}

        local create_enemy_action = function()
            Spawn_Enemy(arena, type, location, offset)
            arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns - 1
        end
        arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns + 1
        
        -- Schedule each enemy spawn using cumulative wave delay
        local spawn_delay = WAVE_SPAWN_WARNING_TIME + arena.spawn_manager.wave_spawn_delay
        arena.t:after(spawn_delay, create_enemy_action)
        
        -- Increment wave spawn delay for next enemy
        arena.spawn_manager.wave_spawn_delay = arena.spawn_manager.wave_spawn_delay + 0.1
    end
end

function Spawn_Group_Scattered(arena, group_data)
  local type, amount = group_data[1], group_data[2]
  amount = amount or 1

  arena.last_spawn_point = nil

  for i = 1, amount do
    local location = Get_Offscreen_Spawn_Point()
    local create_enemy_action = function()
      Spawn_Enemy(arena, type, location)
      arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns - 1
    end
    arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns + 1

    local spawn_delay = WAVE_SPAWN_WARNING_TIME + arena.spawn_manager.wave_spawn_delay

    -- arena.t:after(arena.spawn_manager.wave_spawn_delay, function()
    --   local warning_marker = AnimatedSpawnCircle{
    --     group = arena.floor, x = location.x, y = location.y,
    --     duration = spawn_delay,
    --     expected_spawn_time = spawn_delay,
    --     enemy_type = type
    --   }
    -- end)

    arena.t:after(spawn_delay, create_enemy_action)

    arena.spawn_manager.wave_spawn_delay = arena.spawn_manager.wave_spawn_delay + 0.1
  end
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
            location = Get_Point_In_Right_Half(arena)
        else
            -- For all other types, use offsets from the chosen spawn marker
            location = Get_Point_In_Right_Half(arena)
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

  local special_swarmer_type = nil
  if type == 'swarmer' then
    --reduce into 1 value
    local special_swarmer_chance = table.reduce(SPECIAL_SWARMER_WEIGHT_BY_TYPE[arena.level], function(acc, weight) return acc + weight end, 0)
    if random:bool(special_swarmer_chance) then
      special_swarmer_type = SPECIAL_SWARMER_TYPES[random:weighted_pick(unpack(SPECIAL_SWARMER_WEIGHT_BY_TYPE[arena.level]))]
    end
  end
  
  local enemy = Enemy{type = type, group = arena.main,
                      x = location.x, y = location.y,
                      special_swarmer_type = special_swarmer_type,
                      level = arena.level, data = data}

  Spawn_Enemy_Sound(arena, false)
  Spawn_Enemy_Effect(arena, enemy)
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
  
  local num_particles = enemy_size_to_num_particles[enemy_size] or 4
  for i = 1, num_particles do
    local particle = HitParticle{
      group = arena.effects,
      color = color,
      x = enemy.x, y = enemy.y,
      type = 'effect',
      size = 1,
      speed = 10,
      direction = random:float(0, 2 * math.pi),
      duration = 0.4,
      fade_out = true,
      fade_out_duration = 1,
    }
  end
end

function Spawn_Enemy_Sound(arena, isBoss)
  if isBoss then
    alert1:play{pitch = random:float(0.8, 1.2), volume = 1}
  else
    alert1:play{pitch = random:float(0.8, 1.2), volume = 1}
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
  -- local warning_marker = AnimatedSpawnCircle{
  --     group = arena.floor, x = location.x, y = location.y,
  --     duration = 1000, -- Give it a long duration so it doesn't fade early
  --     expected_spawn_time = warning_time,
  --     enemy_type = enemy_type
  -- }

  -- 2. After the initial warning time, start checking if the space is clear.
  arena.t:after(warning_time, function()
      
      local attempt_final_spawn -- Forward-declare for the self-rescheduling timer
      
      attempt_final_spawn = function()
        -- Check if the area is occupied
        local spawn_circle = Circle(location.x, location.y, spawn_radius)
        local objects_in_spawn_area = arena.main:get_objects_in_shape(spawn_circle, main.current.all_unit_classes)
          
          -- If the area is still blocked, stall and retry this check in a moment.
          -- The visual warning marker remains on-screen during this stall.
          if #objects_in_spawn_area > 0 or arena.spawn_manager:does_spawn_reservation_exist(location.x, location.y) then
              arena.t:after(check_again_delay, attempt_final_spawn)
              return
          end

          arena.spawn_manager:reserve_spawn(location.x, location.y)
          
          -- The area is finally clear! Time to spawn.
          
          -- First, remove the warning marker since the unit is now appearing.
          -- warning_marker.dead = true

          -- Then, run the callbacks to create the unit and notify the spawn manager.
          if creation_callback then creation_callback() end

          arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns - 1

          
      end

      -- Start the first attempt to spawn.
      attempt_final_spawn()
  end)
end

-- ===================================================================
-- NEW METHOD: Spawn enemies in waves with timing and markers
-- ===================================================================
function SpawnManager:spawn_waves_with_timing()
  if self.arena.level == 0 then
    self:change_state('finished')
    return
  end
  
  if self.arena.enemies_spawned then
    return -- Already spawned
  end
  
  self.arena.enemies_spawned = true
  
  -- Check if this is a boss level
  if table.contains(BOSS_ROUNDS, self.arena.level) then
    self:spawn_boss_immediately()
    self:change_state('waiting_for_clear')
  else
    -- Start the wave-based spawning using the state machine
    -- Reset to first wave and start with entry delay
    self.current_wave_index = 1
    self.current_instruction_index = 1
    self:change_state('entry_delay')
    self.timer = self.arena.entry_delay or 1
  end
end

function SpawnManager:calc_group_x(index, num_groups)
  --use the right 60% of the arena, with equal padding between and around the groups
  local playable_width = (RIGHT_BOUND - LEFT_BOUND) * 0.6
  local start_x = RIGHT_BOUND
  local spacing = playable_width / (num_groups + 1)

  return start_x - (spacing * index)
end

function SpawnManager:calc_single_y(index, num_in_group)
  local playable_height = (BOTTOM_BOUND - TOP_BOUND)
  local spacing = playable_height / (num_in_group + 1)
  return TOP_BOUND + (spacing * index)
end

function SpawnManager:calc_swarmer_y()
  return math.random(TOP_BOUND + 20, BOTTOM_BOUND - 20)
end

function SpawnManager:spawn_group_immediately(arena, group_data, group_x)
  local type, amount = group_data[1], group_data[2]
  local spawn_type = group_data[3]
  amount = amount or 1
  
  local group_y = self:calc_swarmer_y()
  local group_x = group_x

  for i = 1, amount do
    local y
    local x
    if type == 'swarmer' then
      y = group_y + (math.random() - 0.5) * 20
      x = group_x + (math.random() - 0.5) * 20
    else
      y = self:calc_single_y(i, amount)
      x = group_x
    end

    local location = {x = x, y = y}
    
    -- Spawn enemy immediately without warning
    self:spawn_enemy_immediately(type, location)
  end
end

function SpawnManager:spawn_enemy_immediately(type, location)
  local enemy = Enemy{
    type = type, 
    group = self.arena.main,
    x = location.x, 
    y = location.y,
    level = self.arena.level, 
    data = {}
  }

  Helper.Unit:set_state(enemy, unit_states['idle'])
  enemy.idleTimer = math.random() * 2 + 1 -- Longer idle time
  enemy.transition_active = false -- Keep inactive until transition complete
end

function SpawnManager:spawn_boss_immediately()
  local boss_name = level_to_boss_enemy[self.arena.level]
  
  if boss_name and boss_name ~= "" then
    -- Spawn boss immediately without warning
    local boss = Enemy{
      type = boss_name, 
      isBoss = true, 
      group = self.arena.main, 
      x = SpawnGlobals.boss_spawn_point.x, 
      y = SpawnGlobals.boss_spawn_point.y, 
      level = self.arena.level
    }
    
    -- Set boss to idle but inactive
    Helper.Unit:set_state(boss, unit_states['idle'])
    boss.idleTimer = 1 -- Longer idle time
    
    -- Set as active boss for level manager
    LevelManager.activeBoss = boss
  end
end


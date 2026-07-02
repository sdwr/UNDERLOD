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

  -- Rolling history of recent enemy spawn points for weighted placement. See
  -- Get_Offscreen_Spawn_Point / Record_Spawn_Point.
  SpawnGlobals.recent_spawns = {}

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

-- One random point just off a random edge (top/bottom/left/right).
function Get_Random_Offscreen_Point()
  local off = SpawnGlobals.offscreen_spawn_offset
  local edge = random:int(1, 4)
  if edge == 1 then -- Top edge
    return {x = random:int(-off, gw + off), y = -off}
  elseif edge == 2 then -- Bottom edge
    return {x = random:int(-off, gw + off), y = gh + off}
  elseif edge == 3 then -- Left edge
    return {x = -off, y = random:int(-off, gh + off)}
  else -- Right edge
    return {x = gw + off, y = random:int(-off, gh + off)}
  end
end

-- Push a chosen spawn point onto the rolling history, trimmed to the last
-- SPAWN_WEIGHT_HISTORY entries (oldest dropped).
function Record_Spawn_Point(p)
  local hist = SpawnGlobals.recent_spawns
  if not hist then hist = {}; SpawnGlobals.recent_spawns = hist end
  hist[#hist + 1] = {x = p.x, y = p.y}
  local max = SPAWN_WEIGHT_HISTORY or 4
  while #hist > max do table.remove(hist, 1) end
end

-- Distance from a point to the nearest spawn in the recent history. Large when
-- the candidate sits in open space the recent spawns haven't covered.
local function dist_to_nearest_recent(p)
  local hist = SpawnGlobals.recent_spawns
  if not hist or #hist == 0 then return nil end
  local best = math.huge
  for i = 1, #hist do
    local h = hist[i]
    local d = math.distance(p.x, p.y, h.x, h.y)
    if d < best then best = d end
  end
  return best
end

-- Weighted offscreen spawn point: sample several random edge points and pick
-- one with probability proportional to (distance to nearest recent spawn)^EXP,
-- so spawns drift toward the spaces farthest from recent activity. Records the
-- chosen point in the history (covers all enemy spawns since they all route
-- through here). Falls back to pure random when history is empty.
function Get_Offscreen_Spawn_Point()
  local hist = SpawnGlobals.recent_spawns
  if not hist or #hist == 0 then
    local p = Get_Random_Offscreen_Point()
    Record_Spawn_Point(p)
    return p
  end

  local n = SPAWN_WEIGHT_CANDIDATES or 10
  local exp = SPAWN_WEIGHT_EXPONENT or 2
  local best_p, best_weight, total = nil, 0, 0
  local chosen = nil
  for i = 1, n do
    local cand = Get_Random_Offscreen_Point()
    local d = dist_to_nearest_recent(cand) or 1
    local w = d ^ exp
    total = total + w
    -- Reservoir-style weighted pick: each candidate replaces the current
    -- choice with probability w / running_total, yielding a draw proportional
    -- to weight in a single pass.
    if random:float(0, 1) < w / total then
      chosen = cand
    end
    if w > best_weight then best_p, best_weight = cand, w end
  end

  chosen = chosen or best_p or Get_Random_Offscreen_Point()
  Record_Spawn_Point(chosen)
  return chosen
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

    -- Spawning State Machine. The instruction-cycling waves are gone; in their
    -- place the 'spawning' state runs per-pool timers continuously until the
    -- level's kill_quota is met. Boss levels still use 'spawning_boss'.
    self:change_state('arena_start')
    -- Possible States:
    -- 'entry_delay':       Initial wait before any spawn timer starts.
    -- 'spawning':          Continuous: basic clumps + each special pool on its
    --                      own jittered timer. Skip-on-cap, never queues.
    -- 'spawning_boss':     Single boss spawn for boss levels.
    -- 'waiting_for_clear': kill_quota met; let the field finish out.
    -- 'finished':          Level complete.

    self.timer = arena.entry_delay or 1
    self.current_wave_index = 1   -- Kept at 1 for back-compat with progress bar.
    self.current_instruction_index = 1

    self.pending_spawns = 0
    self.wave_spawn_delay = 0
    -- kill_power tally across the whole level (matches level.kill_quota).
    self.wave_kill_power = 0
    -- Seconds spent in the 'spawning' state; drives the opening grace window
    -- (SPAWN_DIRECTOR_OPENING_GRACE) that holds back non-swarmer slots.
    self.spawning_elapsed = 0

    self:init_spawn_pools()
end

-- Builds the per-pool runtime state from level_data.spawn_config. Each pool
-- carries its own next-fire timer (with one initial jitter so they don't all
-- fire at t=0) and a max_alive cap. The basic pool has no cap; it just keeps
-- producing clumps on its interval.
function SpawnManager:init_spawn_pools()
  self.basic_pool = nil
  self.special_pools = {}
  self.special_events = {}

  -- Fresh spawn-placement history each level so weighting doesn't carry over.
  SpawnGlobals.recent_spawns = {}

  -- Debug arena: manual key-driven queue (see Build_Debug_Level_Entry). nil
  -- queue = normal level. The queue is spawned one entry per key press.
  self.debug_spawn_queue = self.level_data and self.level_data.debug_spawn_queue
  self.debug_spawn_index = 1

  -- Dynamic cadence state (campaign levels). nil pool = no cadence spawns.
  self.special_pool = nil
  self.special_cadence_next_fire = nil

  -- Small-special pool: own timer + cap, separate budget from specials.
  self.small_special_pool = nil

  -- D: unified power-paced director. When present it supersedes the legacy
  -- basic/special/small pools below.
  self.spawn_director = nil

  local config = self.level_data and self.level_data.spawn_config
  if not config then return end

  -- D: when a director config is present it drives spawning; the legacy pool
  -- blocks below are guarded by their own config fields (which director levels
  -- omit), so they simply don't run. The events layer is parsed for both.
  if config.spawn_director then
    self:init_spawn_director(config.spawn_director)
  end

  -- Small-special pool config: { types = {...}, interval?, max_alive? }.
  if config.small_special and config.small_special.types
    and #config.small_special.types > 0 then
    self.small_special_pool = {
      types = config.small_special.types,
      interval = config.small_special.interval or SMALL_SPECIAL_INTERVAL,
      max_alive = config.small_special.max_alive or MAX_ALIVE_SMALL_SPECIALS,
      next_fire = random:float(0.5, (config.small_special.interval or SMALL_SPECIAL_INTERVAL)),
    }
  end

  -- New-style flat draw pool: the cadence picks one type at random each fire.
  if config.special_pool and #config.special_pool > 0 then
    self.special_pool = config.special_pool
    self.special_cadence_next_fire = SPECIAL_CADENCE_INITIAL or 5
  end

  if config.basic then
    self.basic_pool = {
      type = config.basic.type,
      interval = config.basic.interval or BASIC_CLUMP_INTERVAL,
      -- First clump fires almost immediately (0-0.5s) so the first enemies
      -- land just after the progress bar finishes its fade-in (the 1.25s spawn
      -- warning bridges the gap); subsequent clumps use the full interval.
      next_fire = random:float(0, 0.5),
      -- Optional periodic substitution: every Nth basic spawn fires a
      -- `replace_type` group instead of the normal clump. Used by T2 to
      -- mix tanks into the swarmer cadence without a parallel pool.
      replace_type = config.basic.replace_type,
      -- Optional: a list of types; each replacement slot picks one at random.
      -- Takes precedence over replace_type when set.
      replace_pool = config.basic.replace_pool,
      replace_every = config.basic.replace_every,
      replace_group_size = config.basic.replace_group_size or 1,
      spawn_count = 0,
    }
  end

  -- Special config entries can be one of:
  --   {type, at = 0.3, group_size?}        -> one-shot scheduled event,
  --                                            fires when kill progress hits `at`
  --   {type, interval, max_alive, ...}     -> recurring timer-based pool
  -- Both kinds can coexist in one level.
  for _, pool in ipairs(config.specials or {}) do
    if pool.at then
      table.insert(self.special_events, {
        type = pool.type,
        at = pool.at,
        group_size = pool.group_size,
        fired = false,
      })
    elseif not self.spawn_director then
      local first_fire = pool.first_fire or (pool.interval * random:float(0.3, 0.8))
      table.insert(self.special_pools, {
        type = pool.type,
        interval = pool.interval,
        max_alive = pool.max_alive or 1,
        group_size = pool.group_size,
        next_fire = first_fire,
      })
    end
  end
end

-- Roll one jittered interval per SPECIAL_SPAWN_JITTER.
function jittered_interval(base)
  local j = SPECIAL_SPAWN_JITTER or 0
  return base * (1 + random:float(-j, j))
end

-- Called from Enemy:die() and the path-across despawn. Counts toward the
-- current wave's kill_quota (measured in round_power). Safe to call when
-- there's no quota set.
function SpawnManager:on_enemy_removed(enemy)
  local power = (enemy_to_round_power and enemy_to_round_power[enemy.type]) or 0
  self.wave_kill_power = (self.wave_kill_power or 0) + power
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

    if self.state == 'entry_delay' then
      self.timer = self.timer - dt
      if self.timer <= 0 then
        self.pending_spawns = 0
        if Is_Boss_Level(self.arena.level) then
          self:change_state('spawning_boss')
          spawn_mark2:play{pitch = random:float(1.1, 1.3), volume = 0.5}
        else
          self:change_state('spawning')
        end
      end
    end

    if self.state == 'spawning' then
      self.spawning_elapsed = (self.spawning_elapsed or 0) + dt
      self:tick_spawn_pools(dt)
      if self:quota_met() and self.pending_spawns <= 0 then
        self:change_state('waiting_for_clear')
      end
    end

    if self.state == 'spawning_boss' then
      self:spawn_boss_immediately()
      self:change_state('waiting_for_clear')
    end

    if self.state == 'waiting_for_clear' then
      -- Death wins the race: the quota can still complete AFTER the player
      -- dies (lingering burns/effects keep killing enemies and counting kill
      -- power), which used to trigger level_clear -> buy screen on top of
      -- the death screen. A dead run never clears.
      if self.arena.died then
        self:change_state('finished')
        return
      end
      local enemies = self.arena.main:get_objects_by_classes(main.current.enemies)
      local enemies_clear = #enemies <= 0
      -- For non-boss levels we advance the moment the kill_power target is
      -- hit; any stragglers are wiped in the cinematic cascade below. Boss
      -- levels have no quota so they fall through to "all dead".
      local quota = self.level_data and self.level_data.kill_quota
      local done = (quota and (self.wave_kill_power or 0) >= quota) or (not quota and enemies_clear)

      if done and self.pending_spawns <= 0 then
        if self.arena and self.arena.progress_bar
          and self.arena.progress_bar.segments[1]
          and self.arena.progress_bar.segments[1].complete_wave then
          self.arena.progress_bar.segments[1]:complete_wave()
        end

        -- Final cascade: staggered death for stragglers. Total cascade length
        -- is fixed (LEVEL_CLEAR_CASCADE_DURATION) regardless of how many
        -- enemies are left — deaths get spread evenly across that window so
        -- 5 enemies and 100 enemies both wrap in roughly the same time.
        local remaining = self.arena.main:get_objects_by_classes(main.current.enemies) or {}
        local base_delay = LEVEL_CLEAR_KILL_DELAY or 0.3
        local cascade_duration = LEVEL_CLEAR_CASCADE_DURATION or 0.5
        local total = #remaining
        for i, e in ipairs(remaining) do
          if e and not e.dead then
            local frac = (total > 1) and ((i - 1) / (total - 1)) or 0
            local death_time = base_delay + frac * cascade_duration
            self.t:after(death_time, function()
              if e and not e.dead and e.die then
                e:die()
              end
            end)
          end
        end
        self:complete_wave(1)
        self:change_state('finished')
        self.arena:level_clear()
      end
    end
end

function SpawnManager:quota_met()
  local quota = self.level_data and self.level_data.kill_quota
  if not quota then return false end
  return (self.wave_kill_power or 0) >= quota
end

-- Debug arena helpers. debug_next_spawn returns the queue entry that the next
-- key press will spawn (or nil when the queue is exhausted), used by the arena
-- to draw the "press KEY to spawn TYPE" prompt. debug_spawn_next actually
-- spawns it and advances the queue; only active once the level is spawning.
function SpawnManager:debug_next_spawn()
  if not self.debug_spawn_queue then return nil end
  return self.debug_spawn_queue[self.debug_spawn_index]
end

function SpawnManager:debug_spawn_next()
  if self.state ~= 'spawning' then return end
  local entry = self:debug_next_spawn()
  if not entry then return end
  Spawn_Group_With_Location(self.arena,
    {entry.type, entry.count or 1, 'nil'},
    Get_Offscreen_Spawn_Point())
  self.debug_spawn_index = self.debug_spawn_index + 1
end

-- Build the director runtime from a level's spawn_director config. Tuning falls
-- back to the SPAWN_DIRECTOR_* globals when not overridden per level.
function SpawnManager:init_spawn_director(cfg)
  self.spawn_director = {
    setpoints = cfg.setpoints or {},
    special_pool = cfg.special_pool or {},
    ceilings = cfg.ceilings,
    ceiling_mult = cfg.ceiling_mult or SPAWN_DIRECTOR_CEILING_MULT,
    ramp_from = (cfg.ramp and cfg.ramp.from) or SPAWN_DIRECTOR_RAMP_FROM,
    ramp_to = (cfg.ramp and cfg.ramp.to) or SPAWN_DIRECTOR_RAMP_TO,
    global_cap = cfg.global_cap or SPAWN_DIRECTOR_GLOBAL_CAP,
    fill_gain = cfg.fill_gain, fill_exp = cfg.fill_exp,
    creep_gain = cfg.creep_gain, creep_exp = cfg.creep_exp,
    rate_max = cfg.rate_max, rate_min = cfg.rate_min, rate_exp = cfg.rate_exp,
    -- Specials-queue timer (swarmers run on their own lane timer below).
    next_fire = random:float(0, 0.5),
    -- Swarmer-lane timer: first clump lands almost immediately.
    swarmer_next_fire = random:float(0, 0.5),
    -- Per-level override of SWARMER_LANE_FILL_TIME (seconds to fill the
    -- swarm to TARGET_FILL of setpoint from an empty field).
    fill_time = cfg.fill_time,
    -- Per-type in-flight count: spawns queued but not yet alive (still in their
    -- spawn-warning window). Counted toward slot population so the director
    -- doesn't re-pick a slot and overshoot its cap before the first one lands.
    pending = {},
  }
end

-- Weighted average clump size from SWARMER_GROUP_MIX. Feeds the swarmer
-- lane's fill-time interval math, so retuning the mix (burstiness) keeps the
-- fill-time promise intact: bigger clumps = longer gaps, same throughput.
function swarmer_mix_avg_size()
  local mix = SWARMER_GROUP_MIX or {{weight = 1, min = 1, max = 1}}
  local total_w, sum = 0, 0
  for _, e in ipairs(mix) do
    local w = e.weight or 1
    total_w = total_w + w
    sum = sum + w * ((e.min or 1) + (e.max or 1)) / 2
  end
  if total_w <= 0 then return 1 end
  return sum / total_w
end

-- Weighted roll for a swarmer group from SWARMER_GROUP_MIX. Returns the size and
-- whether the group should scatter (each member at its own random point).
-- force_clustered restricts the roll to non-scatter entries (used for a
-- level's opening clump).
function roll_swarmer_group_size(force_clustered)
  local mix = SWARMER_GROUP_MIX or {{weight = 1, min = 1, max = 1}}
  if force_clustered then
    local clustered = {}
    for _, e in ipairs(mix) do
      if not e.scatter then clustered[#clustered + 1] = e end
    end
    if #clustered > 0 then mix = clustered end
  end
  local total = 0
  for _, e in ipairs(mix) do total = total + (e.weight or 1) end
  local r = random:float(0, total)
  for _, e in ipairs(mix) do
    r = r - (e.weight or 1)
    if r <= 0 then return random:int(e.min or 1, e.max or 1), e.scatter end
  end
  return 1, false
end

-- Alive count for a director slot. 'special' is a category (all special_enemy
-- minus tanks, which are their own slot; small_archers are already excluded
-- from counts.specials). Everything else is a concrete type.
function SpawnManager:director_slot_alive(slot, counts)
  local pending = (self.spawn_director and self.spawn_director.pending) or {}
  if slot == 'special' then
    local p = 0
    for _, t in ipairs((self.spawn_director and self.spawn_director.special_pool) or {}) do
      p = p + (pending[t] or 0)
    end
    return math.max(0, (counts.specials or 0) - (counts.by_type['tank'] or 0)) + p
  end
  return (counts.by_type[slot] or 0) + (pending[slot] or 0)
end

-- Representative power for a slot (used for the budget/pacing math). The
-- 'special' category uses the average power of its pool.
function SpawnManager:director_slot_power(slot, d)
  if slot == 'special' then
    local pool = d.special_pool or {}
    if #pool == 0 then return 150 end
    local sum = 0
    for _, t in ipairs(pool) do sum = sum + ((enemy_to_round_power and enemy_to_round_power[t]) or 0) end
    return sum / #pool
  end
  return (enemy_to_round_power and enemy_to_round_power[slot]) or 50
end

-- Resolve a picked slot into (enemy_type, group_size, power_cost). Swarmers roll
-- a group size from the mix (clamped to ceiling headroom); 'special' draws a
-- random type; concrete slots spawn one.
function SpawnManager:director_resolve_spawn(slot, counts, d, ramp, force_clustered)
  if slot == 'swarmer' then
    local alive = self:director_slot_alive('swarmer', counts)
    local sp = math.max(1, (d.setpoints['swarmer'] or 1) * ramp)
    local ceil = (d.ceilings and d.ceilings['swarmer'])
      or math.ceil(sp * (d.ceiling_mult or SPAWN_DIRECTOR_CEILING_MULT))
    local headroom = math.max(1, ceil - alive)
    local size, scatter = roll_swarmer_group_size(force_clustered)
    local gs = math.max(1, math.min(size, headroom))
    return 'swarmer', gs, scatter
  elseif slot == 'special' then
    local pool = d.special_pool or {}
    if #pool == 0 then return nil end
    local etype = random:table(pool)
    return etype, Special_Cadence_Group_Size(etype)
  end
  return slot, 1
end

-- Spawn a resolved (etype, group_size, scatter) pick and track it as pending
-- until it materializes (after the spawn warning), so subsequent ticks count
-- it toward its slot and don't overshoot the cap. Shared by the swarmer lane
-- and the specials queue.
function SpawnManager:director_spawn(etype, group_size, scatter)
  local d = self.spawn_director
  self.wave_spawn_delay = 0
  if scatter then
    -- Scatter: each swarmer at its own pure-random offscreen point (not the
    -- weighted placement), so the group fans in from all sides and these
    -- many cheap spawns don't flood the weighted history used by specials.
    for i = 1, group_size do
      Spawn_Group_With_Location(self.arena, {etype, 1, 'nil'}, Get_Random_Offscreen_Point())
    end
  else
    Spawn_Group_With_Location(self.arena, {etype, group_size, 'nil'}, Get_Offscreen_Spawn_Point())
  end
  d.pending[etype] = (d.pending[etype] or 0) + group_size
  self.arena.t:after((WAVE_SPAWN_WARNING_TIME or 1.25) + 0.15, function()
    d.pending[etype] = math.max(0, (d.pending[etype] or 0) - group_size)
  end)
end

-- Swarmer lane: swarmers spawn on their own clump cadence (SWARMER_LANE_* in
-- game_constants) instead of competing in the specials queue, so the chaff
-- rhythm reads as a steady heartbeat independent of special timing. Keeps the
-- director machinery: setpoint ramp, ceiling skip, group mix, pending
-- tracking and weighted placement.
function SpawnManager:tick_swarmer_lane(dt, counts)
  local d = self.spawn_director
  if not d.setpoints['swarmer'] then return end
  d.swarmer_next_fire = (d.swarmer_next_fire or 0) - dt
  if d.swarmer_next_fire > 0 then return end

  local retry = SWARMER_LANE_RETRY or 0.5
  local total_alive = (counts.basics or 0) + (counts.specials or 0) + (counts.small_specials or 0)
  if self:quota_met() or total_alive >= (d.global_cap or SPAWN_DIRECTOR_GLOBAL_CAP or 9999) then
    d.swarmer_next_fire = retry
    return
  end

  local quota = self.level_data and self.level_data.kill_quota
  local progress = (quota and quota > 0) and math.min((self.wave_kill_power or 0) / quota, 1) or 0
  local ramp = d.ramp_from + (d.ramp_to - d.ramp_from) * progress

  local sp = math.max(1, d.setpoints['swarmer'] * ramp)
  local alive = self:director_slot_alive('swarmer', counts)
  local ceiling = (d.ceilings and d.ceilings['swarmer'])
    or math.ceil(sp * (d.ceiling_mult or SPAWN_DIRECTOR_CEILING_MULT))
  if alive >= ceiling then
    d.swarmer_next_fire = retry
    return
  end

  -- The level's first swarmer spawn is always a clustered clump (never the
  -- scatter roll) so the opening reads as a wave, not lone stragglers.
  local first = not d.swarmer_lane_fired
  local etype, group_size, scatter = self:director_resolve_spawn('swarmer', counts, d, ramp, first)
  if etype and group_size and group_size > 0 then
    self:director_spawn(etype, group_size, scatter)
    d.swarmer_lane_fired = true
  end

  -- Base interval derived from the fill-time goal: reach TARGET_FILL of the
  -- (ramped) setpoint within fill_time seconds from an empty field. M is the
  -- integral of the catch-up curve over [0, target], pricing in the cheap
  -- early fires, so the goal holds despite the speedup. Full math in
  -- documentation/spawn_tuning.md §2. Recomputed per fire, so the ramp
  -- tightens the cadence over the level automatically.
  local catchup = SWARMER_LANE_CATCHUP_MULT or 0.5
  local frac = SWARMER_LANE_CATCHUP_FRACTION or 0.5
  local target = SWARMER_LANE_TARGET_FILL or 0.8
  local M
  if target <= frac then
    M = catchup * target + (1 - catchup) * target * target / (2 * frac)
  else
    M = target - frac * (1 - catchup) / 2
  end
  local fill_time = d.fill_time or SWARMER_LANE_FILL_TIME or 8
  local base = fill_time * swarmer_mix_avg_size() / (sp * M)
  base = math.clamp(base,
    SWARMER_LANE_INTERVAL_MIN or 1.2, SWARMER_LANE_INTERVAL_MAX or 6.5)

  -- Catch-up: full interval once the swarm (incl. the clump just queued)
  -- reaches CATCHUP_FRACTION of setpoint, shrinking toward CATCHUP_MULT of it
  -- on a thin field so openings and post-wipe recoveries fill fast.
  local fill = math.min((alive + (group_size or 0)) / sp, 1)
  local mult = catchup + (1 - catchup) * math.min(fill / frac, 1)
  local j = SPAWN_DIRECTOR_JITTER or 0
  d.swarmer_next_fire = base * mult * (1 + random:float(-j, j))
end

-- Director tick: maintain a per-slot target population, spawning whatever is
-- most lacking, paced by the power spawned. See game_constants SPAWN_DIRECTOR_*.
function SpawnManager:tick_spawn_director(dt, counts)
  local d = self.spawn_director
  d.next_fire = (d.next_fire or 0) - dt
  if d.next_fire > 0 then return end

  local total_alive = (counts.basics or 0) + (counts.specials or 0) + (counts.small_specials or 0)
  if self:quota_met() or total_alive >= (d.global_cap or SPAWN_DIRECTOR_GLOBAL_CAP or 9999) then
    d.next_fire = SPAWN_DIRECTOR_INTERVAL_MIN or 0.2
    return
  end

  -- Ramp setpoints by kill-quota progress.
  local quota = self.level_data and self.level_data.kill_quota
  local progress = (quota and quota > 0) and math.min((self.wave_kill_power or 0) / quota, 1) or 0
  local ramp = d.ramp_from + (d.ramp_to - d.ramp_from) * progress

  -- Per-slot weights (fractional-deficit below setpoint, slow creep above).
  -- Swarmers are NOT in this queue — they spawn on their own cadence in
  -- tick_swarmer_lane. They stay in d.setpoints for the tank gate and for the
  -- whole-field pacing math below, so special timing still responds to how
  -- packed the swarm is.
  local weights, total_w = {}, 0
  for slot, base_sp in pairs(d.setpoints) do
    if slot ~= 'swarmer' then
      local sp = math.max(1, base_sp * ramp)
      local alive = self:director_slot_alive(slot, counts)
      local ceil = (d.ceilings and d.ceilings[slot])
        or math.ceil(sp * (d.ceiling_mult or SPAWN_DIRECTOR_CEILING_MULT))
      local w = 0
      if alive < ceil then
        if alive < sp then
          local f = alive / sp
          w = (d.fill_gain or SPAWN_DIRECTOR_FILL_GAIN) * (1 - f) ^ (d.fill_exp or SPAWN_DIRECTOR_FILL_EXP)
        else
          local c = (alive - sp) / math.max(1, ceil - sp)
          w = (d.creep_gain or SPAWN_DIRECTOR_CREEP_GAIN) * (1 - c) ^ (d.creep_exp or SPAWN_DIRECTOR_CREEP_EXP)
        end
      end
      -- Tanks escort the swarm: gate them behind swarmer presence so a tank that
      -- dies on a thin field isn't immediately re-picked into a solo rush.
      if slot == 'tank' and w > 0 and d.setpoints['swarmer'] then
        local sw_sp = math.max(1, d.setpoints['swarmer'] * ramp)
        local sw_alive = self:director_slot_alive('swarmer', counts)
        if sw_alive < (SPAWN_DIRECTOR_TANK_SWARM_GATE or 0.5) * sw_sp then w = 0 end
      end
      -- Opening grace: nothing in this queue (specials incl. tanks, small
      -- archers) spawns during the first seconds of the level.
      if (self.spawning_elapsed or 0) < (SPAWN_DIRECTOR_OPENING_GRACE or 0) then
        w = 0
      end
      if w > 0 then weights[slot] = w; total_w = total_w + w end
    end
  end

  if total_w > 0 then
    -- Weighted-random slot pick -> resolve -> spawn.
    local r, chosen = random:float(0, total_w), nil
    for slot, w in pairs(weights) do
      r = r - w
      if r <= 0 then chosen = slot; break end
    end
    chosen = chosen or next(weights)

    local etype, group_size, scatter = self:director_resolve_spawn(chosen, counts, d, ramp)
    if etype and group_size and group_size > 0 then
      self:director_spawn(etype, group_size, scatter)
    end
  end

  -- Cooldown is a function of the level's TOTAL power fill (alive + in-flight vs
  -- this level's setpoint power), NOT the unit just spawned. Empty level ->
  -- INTERVAL_MIN (fast); at/above setpoint -> INTERVAL_MAX (trickle). Self-
  -- regulating and responsive: kills drop the fill and shorten the next
  -- cooldown. RATE_EXP shapes the curve (>1 = stays fast until near setpoint).
  local alive_power = 0
  for t, n in pairs(counts.by_type) do
    alive_power = alive_power + n * ((enemy_to_round_power and enemy_to_round_power[t]) or 0)
  end
  for t, p in pairs(d.pending) do
    alive_power = alive_power + p * ((enemy_to_round_power and enemy_to_round_power[t]) or 0)
  end
  local setpoint_power = 0
  for slot, base_sp in pairs(d.setpoints) do
    setpoint_power = setpoint_power + math.max(1, base_sp * ramp) * self:director_slot_power(slot, d)
  end
  local fill = (setpoint_power > 0) and math.min(alive_power / setpoint_power, 1) or 1
  local cd_min = SPAWN_DIRECTOR_INTERVAL_MIN or 0.2
  local cd_max = SPAWN_DIRECTOR_INTERVAL_MAX or 8
  local cd = cd_min + (cd_max - cd_min) * (fill ^ (d.rate_exp or SPAWN_DIRECTOR_RATE_EXP or 1.5))
  local j = SPAWN_DIRECTOR_JITTER or 0
  d.next_fire = cd * (1 + random:float(-j, j))
end

-- Scheduled events: discrete spawns at fixed kill_quota progress (e.g. brute at
-- 30%). Each fires once. Shared by the director and legacy spawn paths.
function SpawnManager:tick_special_events(counts)
  if #self.special_events == 0 then return end
  local quota = self.level_data and self.level_data.kill_quota
  local progress = (quota and quota > 0) and ((self.wave_kill_power or 0) / quota) or 0
  for _, ev in ipairs(self.special_events) do
    -- Scheduled beats bypass the specials cap: a moment authored for `at` should
    -- arrive on time, not drift to whenever the field happens to have room.
    if not ev.fired and progress >= ev.at and not self:quota_met() then
      local group_size = ev.group_size or 1
      if type(group_size) == 'function' then group_size = group_size() end
      self.wave_spawn_delay = 0
      Spawn_Group_With_Location(self.arena, {ev.type, group_size, 'nil'}, Get_Offscreen_Spawn_Point())
      counts.specials = (counts.specials or 0) + group_size
      counts.by_type[ev.type] = (counts.by_type[ev.type] or 0) + group_size
      ev.fired = true
    end
  end
end

-- Tick each pool's timer once per update. Pools that fire and successfully
-- spawn reset to a freshly jittered interval. Pools blocked by cap STILL
-- reset their timer - skip-on-cap, no queueing. This is what creates the
-- "kill before next spawn or it stacks" pressure.
function SpawnManager:tick_spawn_pools(dt)
  local counts = self:count_alive_by_class()

  -- D: power-paced director. Runs in place of the legacy pools when the level
  -- config provides spawn_director; the authored events layer still runs.
  -- Swarmers tick first on their own lane so their pending spawns are visible
  -- to the specials queue's whole-field pacing in the same frame.
  if self.spawn_director then
    self:tick_swarmer_lane(dt, counts)
    self:tick_spawn_director(dt, counts)
    self:tick_special_events(counts)
    return
  end

  local basics_capped = counts.basics >= (MAX_ALIVE_BASICS or 9999)
  local specials_capped = counts.specials >= (MAX_ALIVE_SPECIALS or 9999)

  -- Basics: spawn a clump on tick. Skip when at the basics cap.
  if self.basic_pool then
    self.basic_pool.next_fire = self.basic_pool.next_fire - dt
    if self.basic_pool.next_fire <= 0 then
      if not basics_capped and not self:quota_met() then
        self.wave_spawn_delay = 0
        self.basic_pool.spawn_count = self.basic_pool.spawn_count + 1
        local location = Get_Offscreen_Spawn_Point()

        -- Periodic substitution: every Nth basic tick, fire `replace_type`
        -- (e.g. a tank) instead of the normal swarmer clump.
        local should_replace = (self.basic_pool.replace_type or self.basic_pool.replace_pool)
          and self.basic_pool.replace_every and self.basic_pool.replace_every > 0
          and (self.basic_pool.spawn_count % self.basic_pool.replace_every == 0)

        if should_replace then
          -- replace_pool (random per slot) wins over a single replace_type.
          local replace_type = self.basic_pool.replace_pool
            and random:table(self.basic_pool.replace_pool)
            or self.basic_pool.replace_type
          Spawn_Group_With_Location(self.arena,
            {replace_type, self.basic_pool.replace_group_size, 'nil'},
            location)
        else
          local clump_size = SWARMERS_PER_LEVEL(self.arena.level)
          Spawn_Group_With_Location(self.arena,
            {self.basic_pool.type, clump_size, 'nil'},
            location)
        end
      end
      -- Density throttle: stretch the next interval as the field fills toward
      -- the basics cap, so the cadence eases off instead of hammering the cap.
      local density = math.min(counts.basics / (MAX_ALIVE_BASICS or 9999), 1)
      local throttle = 1 + density * (BASIC_CLUMP_DENSITY_THROTTLE or 0)
      self.basic_pool.next_fire = jittered_interval(self.basic_pool.interval * throttle)
    end
  end

  -- Specials: each pool on its own timer. Gate by:
  --   1. The aggregate special cap (MAX_ALIVE_SPECIALS) across all pools
  --   2. The per-pool max_alive of this specific type
  -- Either being full means skip-and-reroll; the pool's clock keeps ticking.
  for _, pool in ipairs(self.special_pools) do
    pool.next_fire = pool.next_fire - dt
    if pool.next_fire <= 0 then
      local alive_of_type = counts.by_type[pool.type] or 0
      -- group_size can be a function so configs can randomize per-tick
      -- (e.g. spawn 2-3 roaches each time). Safe because level_list is no
      -- longer saved to run.txt.
      local group_size = pool.group_size or 1
      if type(group_size) == 'function' then group_size = group_size() end
      if not self:quota_met()
        and not specials_capped
        and alive_of_type + group_size <= pool.max_alive then
        self.wave_spawn_delay = 0
        Spawn_Group_With_Location(self.arena,
          {pool.type, group_size, 'nil'},
          Get_Offscreen_Spawn_Point())
        -- Reflect the just-queued spawns so a sibling pool firing in the
        -- same frame doesn't blow past the aggregate cap. Spawn_Group_*
        -- schedules via t:after so the enemies don't exist yet this frame.
        counts.specials = counts.specials + group_size
        counts.by_type[pool.type] = alive_of_type + group_size
        specials_capped = counts.specials >= (MAX_ALIVE_SPECIALS or 9999)
      end
      pool.next_fire = jittered_interval(pool.interval)
    end
  end

  -- Small-specials: single pool on its own timer and cap, independent of the
  -- specials budget. Draws one type at random from the pool's list each fire.
  if self.small_special_pool then
    local sp = self.small_special_pool
    sp.next_fire = sp.next_fire - dt
    if sp.next_fire <= 0 then
      local small_capped = counts.small_specials >= (sp.max_alive or MAX_ALIVE_SMALL_SPECIALS or 9999)
      if not self:quota_met() and not small_capped then
        local etype = random:table(sp.types)
        self.wave_spawn_delay = 0
        Spawn_Group_With_Location(self.arena, {etype, 1, 'nil'}, Get_Offscreen_Spawn_Point())
        counts.small_specials = counts.small_specials + 1
        counts.by_type[etype] = (counts.by_type[etype] or 0) + 1
      end
      sp.next_fire = jittered_interval(sp.interval)
    end
  end

  -- Scheduled events (brute at 30%, etc.) — shared helper, also used by D.
  self:tick_special_events(counts)

  -- Dynamic cadence (campaign levels). Single global timer that draws one
  -- random type from special_pool each fire. The delay to the NEXT fire is
  -- computed here, at the moment of this fire: base + increment * (cycle
  -- specials currently alive + the group just queued). Tanks come from the
  -- basic pool and are excluded from the count.
  if self.special_pool and self.special_cadence_next_fire then
    self.special_cadence_next_fire = self.special_cadence_next_fire - dt
    if self.special_cadence_next_fire <= 0 then
      if not self:quota_met() and not specials_capped then
        local enemy_type = random:table(self.special_pool)
        local group_size = Special_Cadence_Group_Size(enemy_type)

        self.wave_spawn_delay = 0
        Spawn_Group_With_Location(self.arena,
          {enemy_type, group_size, 'nil'},
          Get_Offscreen_Spawn_Point())

        -- Reflect the just-queued spawns in the running counts.
        counts.specials = counts.specials + group_size
        counts.by_type[enemy_type] = (counts.by_type[enemy_type] or 0) + group_size
        specials_capped = counts.specials >= (MAX_ALIVE_SPECIALS or 9999)

        -- Cycle specials alive = all specials minus tanks (basic-pool filler).
        local cycle_alive = counts.specials - (counts.by_type['tank'] or 0)
        local base = SPECIAL_CADENCE_BASE or 5
        local inc = SPECIAL_CADENCE_INCREMENT or 3
        self.special_cadence_next_fire = base + inc * math.max(cycle_alive, 0)
      else
        -- Quota met or field full: re-check soon without advancing the big
        -- delay, so we resume the moment there's room.
        self.special_cadence_next_fire = 1
      end
    end
  end
end

-- One pass over the alive enemies bucketing by class + per-type counts. Used
-- by tick_spawn_pools so each tick costs one enemy iteration instead of one
-- per pool.
function SpawnManager:count_alive_by_class()
  local counts = {basics = 0, specials = 0, small_specials = 0, by_type = {}}
  if not self.arena or not self.arena.main or not main.current.enemies then return counts end
  local enemies = self.arena.main:get_objects_by_classes(main.current.enemies)
  for _, e in ipairs(enemies) do
    if not e.dead then
      -- Small-specials share the special_enemy class but get their own budget,
      -- so they're counted separately and excluded from the specials tally.
      if SMALL_SPECIAL_TYPES and SMALL_SPECIAL_TYPES[e.type] then
        counts.small_specials = counts.small_specials + 1
      elseif e.class == 'special_enemy' then
        counts.specials = counts.specials + 1
      else
        counts.basics = counts.basics + 1
      end
      counts.by_type[e.type] = (counts.by_type[e.type] or 0) + 1
    end
  end
  return counts
end



-- This function processes all instructions for a wave segment at once.
function SpawnManager:alive_enemy_count()
  if not self.arena or not self.arena.main or not main.current.enemies then return 0 end
  local enemies = self.arena.main:get_objects_by_classes(main.current.enemies)
  return #enemies
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

function Spawn_Group_With_Location(arena, group_data, wave_spawn_location, on_finished, path_heading_override)
    local type, amount, spawn_type = group_data[1], group_data[2], group_data[3]
    amount = amount or 1

    arena.last_spawn_point = wave_spawn_location

    -- AnimatedSpawnCircle{
    --   group = arena.floor, x = wave_spawn_location.x, y = wave_spawn_location.y,
    --   duration = WAVE_SPAWN_WARNING_TIME,
    --   expected_spawn_time = WAVE_SPAWN_WARNING_TIME,
    -- }

    -- This loop initiates all spawn processes with 0.1 second spacing using SpawnManager's delay counter
    local spawn_offsets = {{x = -18, y = -18}, {x = 18, y = -18}, {x = 18, y = 18}, {x = -18, y = 18}, {x = 0, y = 0}}

    -- For path-across-varied movement, compute one heading for the whole group
    -- so the swarm moves as a unit instead of fanning out individually.
    -- Override lets callers force a specific heading (used to send the first
    -- basic clump straight through center, no jitter).
    local shared_path_heading = path_heading_override
      or Compute_Shared_Path_Heading(type, wave_spawn_location)

    for i = 1, amount do
        local offset = spawn_offsets[i % #spawn_offsets + 1]
        local location = {x = wave_spawn_location.x + offset.x, y = wave_spawn_location.y + offset.y}

        local create_enemy_action = function()
            Spawn_Enemy(arena, type, location, offset, shared_path_heading)
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

    -- For path-across-varied movement, compute one heading for the whole group
    -- so the swarm moves as a unit instead of fanning out individually. Use the
    -- first spawn location as the reference point for the angle-to-center.
    local shared_path_heading = nil

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

        if not shared_path_heading then
            shared_path_heading = Compute_Shared_Path_Heading(type, location)
        end

        local create_enemy_action = function()
            Spawn_Enemy(arena, type, location, nil, shared_path_heading)
        end
        arena.spawn_manager.pending_spawns = arena.spawn_manager.pending_spawns + 1

        -- Stagger the spawn warnings slightly for a better visual effect.
        Create_Unit_With_Warning(arena, location, WAVE_SPAWN_WARNING_TIME, create_enemy_action, type)
    end
end


-- This function is now just a simple unit factory.
function Spawn_Enemy(arena, type, location, offset, path_heading)
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
                      path_heading = path_heading,
                      level = arena.level, data = data}

  -- Specials get the louder danger cue; everything else gets a very faint
  -- spawn tick so a wave has a soft presence without cluttering the mix when
  -- a whole clump pops in at once.
  if enemy and enemy.class == 'special_enemy' then
    Spawn_Special_Sound(arena)
  else
    spawn1:play{pitch = random:float(0.9, 1.1), volume = 0.08}
  end
  Spawn_Enemy_Effect(arena, enemy)
end

-- Distinct cue for special enemies appearing. A low-pitched chime so it reads
-- as "something dangerous just arrived" without competing with the boss alert.
function Spawn_Special_Sound(arena)
  spawn_mark1:play{pitch = random:float(0.65, 0.8), volume = 0.5}
end

-- Returns a single path-across heading shared by an entire spawn group, or nil
-- when the enemy type uses a different movement style. Used by Spawn_Group_*
-- callers so all members of a swarm walk the same direction instead of each
-- picking its own jittered angle.
function Compute_Shared_Path_Heading(enemy_type, location)
  if get_movement_type_by_enemy_type(enemy_type) ~= MOVEMENT_TYPE_PATH_ACROSS_VARIED then
    return nil
  end
  local cx, cy = gw / 2, gh / 2
  local dx, dy = cx - location.x, cy - location.y
  local base
  if dx == 0 and dy == 0 then
    base = random:float(0, 2 * math.pi)
  else
    base = math.atan2(dy, dx)
  end
  return base + random:float(-PATH_ACROSS_VARIED_JITTER, PATH_ACROSS_VARIED_JITTER)
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
    -- Boss spawn: audible alert (volume was 0 — a leftover mute that killed the
    -- boss's audio telegraph).
    alert1:play{pitch = random:float(0.75, 0.9), volume = 1}
  else
    -- Regular spawn: lower and tighter pitch so back-to-back spawns don't
    -- chirp wildly. Was 0.8-1.2 (40% spread, centered at 1.0); now
    -- 0.55-0.65 (~16% spread centered low).
    alert1:play{pitch = random:float(0.55, 0.65), volume = 0}
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

  -- 1. Create the visual warning marker (flashing red exclamation) so onscreen
  -- spawns — especially the boss at boss_spawn_point — telegraph before they
  -- appear. Auto-dies at warning_time, right as the spawn attempt begins.
  AnimatedSpawnCircle{
    group = arena.floor, x = location.x, y = location.y,
    duration = warning_time,
    expected_spawn_time = warning_time,
    enemy_type = enemy_type,
  }

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


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
  local check_circle = Circle(0,0, rs)
  check_circle:move_to(location.x, location.y)
  local objects = main.current.main:get_objects_in_shape(check_circle, all_unit_classes)
  if #objects > 0 or Outside_Arena(location) then
    return false
  else
    return true
  end
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


    --consumed items should be on the team instead
    --troop creation
    for row_offset=0, 4 do
      local troop_data = {
        group = arena.main, 
        character = unit.character, 
        consumedItems = unit.consumedItems,
        items = unit.items, 
        x = spawn_x + (column_offset*20), 
        y = spawn_y + (row_offset*10), 
        level = unit.level, 
        passives = arena.passives}
      team:add_troop(troop_data)
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
    team:apply_consumed_item_procs()

    
  end
end

--TODO: cap the number of troops that can be spawned
--think about spawning special enemies with a group of normal enemies
--also there is no fallback if we can't spawn an enemy
--it just doesn't spawn
--which is fine for calculating end of round maybe(??)
--but not for the progress bar

--if an enemy fails to spawn, the wave will not end
function Spawn_Wave(arena, wave)
  arena.wave_finished = false

  local wave_index = 1
  local current_group = 1
  arena.t:every(arena.time_between_spawn_groups, function()
    --wait until the previous enemy is done spawning
    if arena.spawning_enemies then return end

    --cancel if we're done spawning
    if wave_index > #wave then
      arena.wave_finished = true
      arena.t:cancel('spawnwave')
      return
    end

    arena.spawning_enemies = true
    --wave is in format (enemy, amount, location)
    local wave = wave[wave_index]
    --get spawn location from previous and location type
    local location_index = 1
    if not SpawnGlobals.last_spawn_point then
      location_index = 1
    else
      if wave[3] == 'close' then
        location_index = Get_Close_Spawn(SpawnGlobals.last_spawn_point)
      elseif wave[3] == 'far' then
        location_index = Get_Far_Spawn(SpawnGlobals.last_spawn_point)
      elseif wave[3] == 'random' then
        location_index = random:int(1, #SpawnGlobals.spawn_markers)
      end
    end
    Spawn_Group(arena, location_index, wave[1], wave[2])

    current_group = current_group + 1
    wave_index = wave_index + 1
  end, nil, nil, 'spawnwave')
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

--also manage the spawning of environmental enemies
function Manage_Spawns(arena)
  
  -- Set win condition and enemy spawns
  -- REDO THIS
  arena.win_condition = 'wave'


  arena.boss_levels = {6, 11, 16, 21, 25}

  -- set arena specific values

  arena.max_waves = 1
  arena.wave = 1

  arena.entry_delay = 0.5

  arena.time_between_spawn_groups = 0.4
  arena.time_between_spawns = 0.2

  -- arena.time_between_waves = 8
  arena.time_between_next_wave_check = 1

  arena.start_time = 3
  arena.wave_finished = true
  arena.finished = false


  --new plan - spawn waves after the previous wave is fully killed
  --don't spawn waves on top of each other
  --have multiple waves per level, but don't announce them - just use progress bar

  --conditions for wave end:
  -- 1. done spawning (no more enemies to spawn)
  -- 2. all enemies are dead

  --conditions for level end:
  -- 1. all waves are done / progress bar is full
  arena.t:after(arena.entry_delay, function()
    --trigger onRoundStart
    local troops = Helper.Unit:get_list(true)
    if troops and #troops > 0 then
      for i, troop in ipairs(troops) do
        troop:onRoundStartCallbacks()
      end
    end
    -- --spawn miniboss
    --   Spawn_Enemy(arena, {'bigstomper'}, SpawnGlobals.spawn_markers[6])
    -- arena.wave = arena.wave + 1
    --spawn boss
    if table.contains(arena.boss_levels, arena.level) then
      local boss_name = nil
      SpawnMarker{group = arena.effects, x = SpawnGlobals.boss_spawn_point.x, y = SpawnGlobals.boss_spawn_point.y}
      if arena.level == 6 then
        boss_name = 'stompy'
      elseif arena.level == 11 then
        boss_name = 'dragon'
      elseif arena.level == 16 then
        boss_name = 'heigan'
      elseif arena.level == 21 then
        boss_name = 'dragon'
      elseif arena.level == 25 then 
        boss_name = 'dragon'
      end

      arena.t:after(1.5, function() Spawn_Boss(arena, boss_name) end)

    else
      local waves = arena.level_list[arena.level].waves
      local environmental_hazards = arena.level_list[arena.level].environmental_hazards
      print(waves)
      print(#waves)
      print('starting spawns')
      arena.max_waves = #waves
      SpawnGlobals.last_spawn_point = nil
      --spawn first wave right off the bat
      Spawn_Wave(arena, waves[arena.wave])
      arena.wave = arena.wave + 1

      --and launch the environmental hazards
      Spawn_Hazards(arena, environmental_hazards)

      -- arena.time_until_next_wave = arena.time_between_waves
      arena.t:every(arena.time_between_next_wave_check, function()
        --quit if we're done
        if arena.wave > arena.max_waves or arena.quitting then
          print('done spawning waves', arena.wave, arena.max_waves, arena.quitting)
          arena.finished = true
          arena.t:cancel('spawn_waves')
          return 
        end

        --if spawning is done and all enemies are dead, spawn the next wave
        if arena.wave_finished and #arena.main:get_objects_by_classes(arena.enemies) <= 0 then
          ui_switch1:play{pitch = 1, volume = 0.9}
          Spawn_Wave(arena, waves[arena.wave])
          arena.wave = arena.wave + 1
          -- arena.time_until_next_wave = arena.time_between_waves
        end
        
      end, nil, nil, 'spawn_waves')
    end

    --check for level end
    arena.t:every(function()
      return #arena.main:get_objects_by_classes(arena.enemies) <= 0 and arena.finished
      and not arena.quitting and not arena.spawning_enemies end, function() arena:quit() end)

  end)
    
  if arena.level == 1 or arena.level == 2 then
    local t1 = Text2{group = arena.floor, x = gw/2, y = gh/2 + 2, sx = 0.6, sy = 0.6, lines = {{text = '[light_bg]LMB - move selected units', font = fat_font, alignment = 'center'}}}
    local t2 = Text2{group = arena.floor, x = gw/2, y = gh/2 + 18, lines = {{text = '[light_bg]RMB - rally selected units', font = pixul_font, alignment = 'center'}}}
    local t3 = Text2{group = arena.floor, x = gw/2, y = gh/2 + 46, sx = 0.6, sy = 0.6, lines = {{text = '[light_bg]SPACE - move all units', font = fat_font, alignment = 'center'}}}
    local t4 = Text2{group = arena.floor, x = gw/2, y = gh/2 + 62, lines = {{text = '[light_bg]1, 2, 3 - select troop', font = pixul_font, alignment = 'center'}}}
    t1.t:after(8, function() t1.t:tween(0.2, t1, {sy = 0}, math.linear, function() t1.sy = 0 end) end)
    t2.t:after(8, function() t2.t:tween(0.2, t2, {sy = 0}, math.linear, function() t2.sy = 0 end) end)
    t3.t:after(8, function() t3.t:tween(0.2, t3, {sy = 0}, math.linear, function() t3.sy = 0 end) end)
    t4.t:after(8, function() t4.t:tween(0.2, t4, {sy = 0}, math.linear, function() t4.sy = 0 end) end)
  end

  arena.t:every(0.375, function()
    local p = random:table(star_positions)
    Star{group = star_group, x = p.x, y = p.y}
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
  --set twice because of initial delay
  arena.spawning_enemies = true
  arena.wave_finished = false
  
  Spawn_Effect(arena, SpawnGlobals.boss_spawn_point)
  LevelManager.activeBoss = Enemy{type = name, isBoss = true, group = arena.main, x = SpawnGlobals.boss_spawn_point.x, y = SpawnGlobals.boss_spawn_point.y, level = arena.level}
  arena.spawning_enemies = false
  arena.wave_finished = true
  arena.finished = true
end

--spawns a single enemy at a location
--if the location is occupied, the enemy will not spawn
function Spawn_Enemy(arena, type, location)
  local data = {}
  if Can_Spawn(6, location) then
    Spawn_Effect(arena, location)
    alert1:play{pitch = 1, volume = 0.8}
    Enemy{type = type, group = arena.main,
    x = location.x, y = location.y,
    level = arena.level, data = data}
    return true
  else
    print("failed to spawn enemy " .. type .. " at " .. location.x .. ", " .. location.y)
    return false
  end

end

--tries to spawn a group of enemies at a location
-- if the location is occupied, the group will spawn at the next available location
-- and the function will hold future spawns until the group is fully spawned
function Spawn_Group(arena, group_index, type, amount)
  SpawnGlobals.last_spawn_point = group_index
  local amount = amount or 1
  --set twice because of initial delay
  arena.spawning_enemies = true

  local spawn_marker = SpawnGlobals.spawn_markers[group_index]
  local index = 1
  local total_spawned = 0
  arena.t:every(arena.time_between_spawns, function()
    --end once we've spawned the amount of enemies we want
    if total_spawned >= amount then
      arena.spawning_enemies = false
      arena.t:cancel('spawning')
      return
    end

    --try next spawn group if current one is occupied
    if index > 9 then 
      index = 1
      group_index = group_index + 1
      spawn_marker = SpawnGlobals.spawn_markers[(group_index % #SpawnGlobals.spawn_markers)]
    end

    local offset = SpawnGlobals.spawn_offsets[index]
    local spawn_x, spawn_y = spawn_marker.x + offset.x, spawn_marker.y + offset.y

    local success = Spawn_Enemy(arena, type, {x = spawn_x, y = spawn_y})
    if success then
      total_spawned = total_spawned + 1
    end

    index = index+1
  end, nil, nil, 'spawning')

end

function Spawn_Critters(arena, group_index, amount)
  --set twice because of initial delay
  arena.spawning_enemies = true
  
  local spawn_marker = SpawnGlobals.corner_spawns[group_index]
  Spawn_Effect(arena, spawn_marker)
  local index = 1
  arena.t:every(arena.time_between_spawns, function()
    alert1:play{pitch = 1, volume = 0.5}

    local offset = SpawnGlobals.spawn_offsets[index]
    local spawn_x, spawn_y = spawn_marker.x + offset.x, spawn_marker.y + offset.y
    EnemyCritter{group = arena.main, x = spawn_x, y = spawn_y, color = grey[0], v = 10}
  end, amount, function() SetSpawning(arena, false) end)


end

function Spawn_Effect(arena, location)

  spawn_mark2:play{pitch = 1.2, volume = 0.5}
  camera:shake(4, 0.25)
  SpawnEffect{group = arena.effects, x = location.x, y = location.y}

end

function SetSpawning(arena, b)
  arena.spawning_enemies = b
end
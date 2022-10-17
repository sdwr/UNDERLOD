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

end

function Can_Spawn(rs, location)
  local check_circle = Circle(0,0, rs)
  check_circle:move_to(location.x, location.y)
  local objects = main.current.main:get_objects_in_shape(check_circle, {Enemy, EnemyCritter, Critter, Troop})
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


--spawns troops in centre of arena, two rows if over 4 units
function Spawn_Troops(arena)
  local spawn_y
  if #arena.units > 4 then
    spawn_y = gh/2 - 50
  else
    spawn_y = gh/2 - 20
  end

  local spawn_x = gw/2 - 50
  
  for i, unit in ipairs(arena.units) do
    local column_offset = (i-1) % 4

    if i == 5 then
    --make a second row
      spawn_x = gw/2 - 50
      spawn_y = gh/2 + 10
    end


    for row_offset=0, 4 do
      Troop{group = arena.main, x = spawn_x + (column_offset*20), y = spawn_y + (row_offset*10), level = unit.level, character = unit.character, items = unit.items, passives = arena.passives}
    end
    
  end
end

function Manage_Spawns(arena)
  
  -- Set win condition and enemy spawns
  arena.win_condition = 'wave'
  arena.level_to_spawn_groups = {
    1, 2, 3, 3, 4, 0,
    3, 4, 5, 5, 0,
    3, 4, 5, 6, 0,
  }

  arena.level_to_rare_groups = {
    0, 1, 1, 2, 2, 0,
    1, 2, 3, 3, 0,
    3, 3, 4, 4, 0,
  }

  arena.level_to_minibosses = {
    0, 0, 0, 0, 0, 0,
    1, 0, 0, 1, 0,
    0, 1, 1, 1, 0,
  }

  arena.spawns_in_group = 4

  arena.max_waves = 1
  arena.wave = 0

  arena.entry_delay = 0.5

  arena.time_between_spawn_groups = 1.5
  arena.time_between_spawns = 0.2

  arena.start_time = 3
  arena.spawning_enemies = true
  arena.t:after(arena.entry_delay, function()
    --spawn miniboss
    if arena.level_to_minibosses[arena.level] == 1 then
      Spawn_Enemy(arena, {'bigstomper'}, SpawnGlobals.spawn_markers[6])
    end
    arena.wave = arena.wave + 1
    --spawn boss
    if arena.level == 6 or arena.level == 11 or arena.level == 16 or arena.level == 21 or arena.level == 25 then
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
      --spawn waves

      local num_groups = arena.level_to_spawn_groups[arena.level]
      local num_rares = arena.level_to_rare_groups[arena.level]
      
      local current_group = 1
      arena.t:every(arena.time_between_spawn_groups, function()
        current_group = current_group % #SpawnGlobals.spawn_markers
        --spawns new group every delay, doesn't wait for group before to finish
        --make sure time_between_spawns * spawns_in_group < time_between_spawn_groups
        if current_group <= num_rares then
          if arena.level < 6 then
            Spawn_Enemies(arena, current_group, {'rager', 'stomper'})
          elseif arena.level < 11 then
            Spawn_Enemies(arena, current_group, {'mortar', 'spawner', 'arcspread'})
          elseif arena.level < 16 then
            Spawn_Enemies(arena, current_group, {'summoner', 'mortar', 'assassin', 'spawner', 'arcspread'})
          end
          --Spawn_Enemies(arena, current_group, {'summoner', 'spawner'})
          --Spawn_Enemies(arena, current_group, {'mortar', 'laser', 'spread'})
          --Spawn_Enemies(arena, current_group, {'stomper', 'mortar', 'assassin', 'summoner', 'laser', 'spawner'})
        else
          Spawn_Enemies(arena, current_group, {'shooter', 'seeker'})
        end
        current_group = current_group + 1
      end, num_groups)
    end

    --check for level end
    arena.t:every(function()
      return #arena.main:get_objects_by_classes(arena.enemies) <= 0 and arena.wave >= arena.max_waves 
      and not arena.quitting and not arena.spawning_enemies end, function() arena:quit() end)

  end)
    
  if arena.level == 1 then
    local t1 = Text2{group = arena.floor, x = gw/2, y = gh/2 + 2, sx = 0.6, sy = 0.6, lines = {{text = '[light_bg]LMB - move selected units', font = fat_font, alignment = 'center'}}}
    local t2 = Text2{group = arena.floor, x = gw/2, y = gh/2 + 18, lines = {{text = '[light_bg]RMB - rally selected units', font = pixul_font, alignment = 'center'}}}
    local t3 = Text2{group = arena.floor, x = gw/2, y = gh/2 + 46, sx = 0.6, sy = 0.6, lines = {{text = '[light_bg]SPACE - move all units', font = fat_font, alignment = 'center'}}}
    t1.t:after(8, function() t1.t:tween(0.2, t1, {sy = 0}, math.linear, function() t1.sy = 0 end) end)
    t2.t:after(8, function() t2.t:tween(0.2, t2, {sy = 0}, math.linear, function() t2.sy = 0 end) end)
    t3.t:after(8, function() t3.t:tween(0.2, t3, {sy = 0}, math.linear, function() t3.sy = 0 end) end)
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
  
  Spawn_Effect(arena, SpawnGlobals.boss_spawn_point)
  LevelManager.activeBoss = Enemy{type = name, isBoss = true, group = arena.main, x = SpawnGlobals.boss_spawn_point.x, y = SpawnGlobals.boss_spawn_point.y, level = arena.level}
  SetSpawning(arena, false)
end

function Spawn_Enemy(arena, enemies, location)
  Spawn_Effect(arena, location)
  alert1:play{pitch = 1, volume = 0.8}
  local type = random:table(enemies)
  if Can_Spawn(6, location) then
    Enemy{type = type, group = arena.main, x = location.x, y = location.y, level = arena.level}
  end

end

function Spawn_Enemies(arena, group_index, enemies)
  --set twice because of initial delay
  arena.spawning_enemies = true

  local spawn_marker = SpawnGlobals.spawn_markers[group_index]
  Spawn_Effect(arena, spawn_marker)
  local index = 1
  arena.t:every(arena.time_between_spawns, function()

    local offset = SpawnGlobals.spawn_offsets[index]
    local spawn_x, spawn_y = spawn_marker.x + offset.x, spawn_marker.y + offset.y

    Spawn_Enemy(arena, enemies, {x = spawn_x, y = spawn_y})

    index = index+1
  end, arena.spawns_in_group, function() SetSpawning(arena, false) end)

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

function Manage_Spawns(arena)
    if arena.level == 1000 then
        arena.level_1000_text = Text2{group = arena.ui, x = gw/2, y = gh/2, lines = {{text = '[fg, wavy_mid]UNDERLOD', font = fat_font, alignment = 'center'}}}
      
      else
        -- Set win condition and enemy spawns
        arena.win_condition = 'wave'
        arena.level_to_max_waves = {
          2, 3, 4,
          3, 4, 4, 5,
          5, 5, 5, 5, 7,
          6, 6, 7, 7, 8, 10,
          8, 8, 10, 12, 14, 16, 25,
        }
        for i = 26, 5000 do
          local n = i % 25
          if n == 0 then n = 25 end
          arena.level_to_max_waves[i] = arena.level_to_max_waves[n]
        end
        arena.level_to_distributed_enemies_chance = {
          0, 5, 10,
          10, 15, 15, 20,
          20, 20, 20, 20, 25,
          25, 25, 25, 25, 25, 30,
          20, 25, 30, 35, 40, 45, 50,
        }
        arena.level_to_num_rares = {
          0, 1, 2, 3, 3, 0, 
          3, 4, 5, 5, 0, 
          2, 3, 3, 4, 0,
        }
        arena.level_to_num_enemies = {
          4, 6, 6, 8, 8, 0,
          8, 8, 8, 8, 0,
          8, 8, 8, 6, 0
        }
        for i = 26, 5000 do
          local n = i % 25
          if n == 0 then n = 25 end
          arena.level_to_distributed_enemies_chance[i] = arena.level_to_distributed_enemies_chance[n]
        end
        arena.max_waves = 1
        arena.wave = 0
        arena.start_time = 3
        arena.t:after(1, function()
          arena.t:every(1, function()
            if arena.start_time > 1 then alert1:play{volume = 0.5} end
            arena.start_time = arena.start_time - 1
            arena.hfx:use('condition1', 0.25, 200, 10)
          end, 3, function()
            alert1:play{pitch = 1.2, volume = 0.5}
            camera:shake(4, 0.25)
            SpawnEffect{group = arena.effects, x = gw * 0.7, y = gh/2 - 48}
            local x, y = gw * 0.7, gh/2
            if arena.level == 6 or arena.level == 11 or arena.level == 16 or arena.level == 21 or arena.level == 25 then
              local boss_name = nil
              SpawnMarker{group = arena.effects, x = x, y = y}
              if arena.level == 6 then
                boss_name = 'stompy'
              elseif arena.level == 11 then
                boss_name = 'dragon'
              elseif arena.level == 16 then
                boss_name = 'heigan'
              end
              arena.t:after(1.5, function() arena:spawn_boss({x = x, y = y, name = boss_name}); arena.wave = arena.wave + 1 end)
            else
              SpawnMarker{group = arena.effects, x = x, y = y}
              arena.t:after(1.125, function() arena:spawn_n_enemies({x = x, y = y}, nil, arena.level_to_num_enemies[arena.level]); arena.wave = arena.wave + 1 end)
              local x, y = gw * 0.8, gh/2
              arena.t:after(2.5, function() arena:spawn_n_rares({x = x, y = y}, nil, arena.level_to_num_rares[arena.level]) end)
            end
    
    
          end)
          arena.t:every(function()
            return #arena.main:get_objects_by_classes(arena.enemies) <= 0 and arena.wave >= arena.max_waves and not arena.quitting and not arena.spawning_enemies end, function() arena:quit() end)
        end)
    
        if arena.level == 20 and arena.trailer then
          Text2{group = arena.ui, x = gw/2, y = gh/2 - 24, lines = {{text = '[fg, wavy]UNDERLOD', font = fat_font, alignment = 'center'}}}
          Text2{group = arena.ui, x = gw/2, y = gh/2, sx = 0.5, sy = 0.5, lines = {{text = '[fg, wavy_mid]play now!', font = fat_font, alignment = 'center'}}}
          Text2{group = arena.ui, x = gw/2, y = gh/2 + 24, sx = 0.5, sy = 0.5, lines = {{text = '[light_bg, wavy_mid]music: kubbi - ember', font = fat_font, alignment = 'center'}}}
        end
      end
    
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
    
      arena.enemy_spawns_prevented = 0
      arena.t:every(8, function()
        if arena.died then return end
        if arena.arena_clear_text then return end
        if arena.quitting then return end
        if arena.spawning_enemies then return end
        if arena.won then return end
        if arena.choosing_passives then return end
    
        local n = arena.enemy_spawns_prevented
        if math.floor(n/4) <= 0 then return end
        arena.spawning_enemies = true
        local spawn_points = table.copy(arena.spawn_points)
        arena.t:after({0, 0.2}, function()
          local p = random:table_remove(spawn_points)
          SpawnMarker{group = arena.effects, x = p.x, y = p.y}
          arena.t:after(1.125, function() arena:spawn_n_enemies(p, 1, math.floor(n/4), true) end)
        end)
        arena.t:after({0, 0.2}, function()
          local p = random:table_remove(spawn_points)
          SpawnMarker{group = arena.effects, x = p.x, y = p.y}
          arena.t:after(1.125, function() arena:spawn_n_enemies(p, 2, math.floor(n/4), true) end)
        end)
        arena.t:after({0, 0.2}, function()
          local p = random:table_remove(spawn_points)
          SpawnMarker{group = arena.effects, x = p.x, y = p.y}
          arena.t:after(1.125, function() arena:spawn_n_enemies(p, 3, math.floor(n/4), true) end)
        end)
        arena.t:after({0, 0.2}, function()
          local p = random:table_remove(spawn_points)
          SpawnMarker{group = arena.effects, x = p.x, y = p.y}
          arena.t:after(1.125, function() arena:spawn_n_enemies(p, 4, math.floor(n/4), true) end)
        end)
        arena.t:after(1.125 + math.floor(n/4)*0.25, function() arena.spawning_enemies = false end, 'spawning_enemies')
        arena.enemy_spawns_prevented = 0
      end)
end
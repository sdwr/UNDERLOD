Helper = {}

require 'helper/helper_geometry'
require 'helper/helper_spell'
require 'helper/helper_time'
require 'helper/helper_color'
require 'helper/helper_lua'
require 'helper/helper_unit'
require 'helper/helper_graphics'
require 'helper/helper_sound'
require 'helper/helper_damage_numbers'
require 'helper/helper_damage'
require 'helper/helper_target'

Helper.initialized = false
Helper.mousex = 0
Helper.mousey = 0
Helper.window_width = 0
Helper.window_height = 0
Helper.disable_unit_controls = false

-- Timing state variables
Helper.tick_count = 0
Helper.time_elapsed = 0
Helper.call_counters = {}
Helper.timers = {}

-- Targeting system
Helper.enemies_by_distance = {}  -- Sorted list of enemies by distance from player center
Helper.cycle_targets = {}  -- List of enemies to cycle through
Helper.manually_targeted_enemy = nil  -- Enemy manually targeted by player
Helper.enemy_list_update_counter = 0  -- Counter for updating enemy list
Helper.ENEMY_LIST_UPDATE_INTERVAL = 10  -- Update every 10 frames

--helper fns only work in arena, not in buy screen
function Helper:init()
    Helper.Time.time = love.timer.getTime()
    math.randomseed(Helper.Time.time)

    Helper.Time:set_interval(0.25, function()
        Helper.Spell.Flame:damage()
    end)
end



function Helper:draw()
    for i, spell in ipairs(Helper.Spell.spells) do
        if spell.draw_aims ~= nil then
            spell.draw_aims()
        end
        if spell.draw ~= nil then
            spell.draw()
        end
    end

    Helper.Graphics:draw_particles()
    Helper.Unit:draw_selection()

    Helper.Unit:draw_points()
    
    -- Debug distance circles around player center
    if DEBUG_DISTANCE_MULTI then
        local player_center = Helper.Unit:get_player_location()
        if player_center then
            local distances = TIER_TO_DISTANCE
            for i, distance in ipairs(distances) do
                -- Draw circle
                graphics.circle(player_center.x, player_center.y, distance, yellow[0], 2)
                -- Draw distance text
                graphics.print(tostring(distance), fat_font, player_center.x + distance - 15, player_center.y - 5, 0, 1, 1, 0, 0, white[0])
            end
        end
    end
end



function Helper:update(dt)
    if not Helper.initialized then
        Helper:init()
        Helper.initialized = true
    end

    Helper.Time.time = Helper.Time.time + dt
    Helper.Time.delta_time = dt
    
    -- Increment timing counters for timing utilities
    Helper.tick_count = Helper.tick_count + 1
    Helper.time_elapsed = Helper.time_elapsed + dt

    --update timers, run state functions, update hitbox points
    Helper.Unit:clear_all_target_flags()
    Helper.Unit:update_hitbox_points()
    Helper.Unit:update_player_location()
    Helper.Unit:update_closest_enemy()
    Helper.Unit:update_enemy_distance_tier()
    
    -- Update enemy distance list periodically
    Helper.enemy_list_update_counter = Helper.enemy_list_update_counter + 1
    if Helper.enemy_list_update_counter >= Helper.ENEMY_LIST_UPDATE_INTERVAL then
        Helper:update_manual_target()
        Helper:update_enemies_by_distance()
        Helper:update_cycle_targets()
        Helper.enemy_list_update_counter = 0
    end
    
    Helper.Time:run_intervals()
    Helper.Time:run_waits()
    Helper.Unit:run_state_always_run_functions()
    Helper.Unit:select()

    Helper.Sound:update()


    --update spells

    for i, spell in ipairs(Helper.Spell.spells) do
        if spell.update ~= nil then
            spell.update(dt)
        end
    end

    --particles
    Helper.Graphics:update_particles()

    Helper.Spell:damage_points();



    Helper.mousex, Helper.mousey = love.mouse.getPosition()
    Helper.mousex = Helper.mousex / sx
    Helper.mousey = Helper.mousey / sx

    if love.keyboard.isDown( "d" ) then
        Area{
            group = main.current.effects,
            pick_shape = 'circle',
            x = Helper.mousex,
            y = Helper.mousey,
            r = 30,
            dmg = 10,
            duration = 0.2,
            color = Helper.Color.blue,
            is_troop = false
        }
        Area{
            group = main.current.effects,
            pick_shape = 'circle',
            x = Helper.mousex,
            y = Helper.mousey,
            r = 30,
            dmg = 10,
            duration = 0.2,
            color = Helper.Color.blue,
            is_troop = true
        }
    end

    if input['q'].pressed then
        show_debug_arena_radius = not show_debug_arena_radius
    end

    if show_debug_arena_radius then
        if not Helper.arena_radius_circle then
            Helper.arena_radius_circle = Area{
                group = main.current.effects,
                pick_shape = 'circle',
                x = Helper.Unit.player_location.x,
                y = Helper.Unit.player_location.y,
                r = ARENA_RADIUS,
                duration = 1000,
                color = Helper.Color.red,
                is_troop = false
            }
        end
        if not Helper.seek_to_range_circle then
            Helper.seek_to_range_circle = Area{
                group = main.current.effects,
                pick_shape = 'circle',
                x = Helper.Unit.player_location.x,
                y = Helper.Unit.player_location.y,
                r = SEEK_TO_RANGE_RADIUS,
                duration = 1000,
                color = Helper.Color.blue,
                is_troop = false
            }
        end

        Helper.arena_radius_circle.x = Helper.Unit.player_location.x
        Helper.arena_radius_circle.y = Helper.Unit.player_location.y

        Helper.seek_to_range_circle.x = Helper.Unit.player_location.x
        Helper.seek_to_range_circle.y = Helper.Unit.player_location.y
    else
        if Helper.arena_radius_circle then
            Helper.arena_radius_circle.dead = true
            Helper.arena_radius_circle = nil
        end
        if Helper.seek_to_range_circle then
            Helper.seek_to_range_circle.dead = true
            Helper.seek_to_range_circle = nil
        end
    end

    -- if input['s'].pressed then
    --     if not s_just_pressed then
    --         Helper.Spell.Sweep:create(Helper.Color.blue, true, 100, 50, Helper.mousey - 50, Helper.window_width - 50, Helper.mousey + 50)
    --     end
    -- end
    if input['p'].pressed then
        Helper.Unit.do_draw_points = not Helper.Unit.do_draw_points 
    end
    
    Helper.window_width = love.graphics.getWidth() / sx
    Helper.window_height = love.graphics.getHeight() / sx
end



function Helper:release()
    Helper.initialized = false

    Helper.Time:stop_all_intervals()
    Helper.Time:stop_all_waits()

    for i, spell in ipairs(Helper.Spell.spells) do
        if spell.clear_all ~= nil then
            spell.clear_all()
        end
    end
end


function Helper:update_manual_target()
    if Helper.manually_targeted_enemy and Helper.manually_targeted_enemy.dead then
        Helper.Unit:clear_manual_target()
    end
end


-- Update the sorted list of enemies by distance from player center
function Helper:update_enemies_by_distance()
    if not Helper.Unit.player_location then
        Helper.enemies_by_distance = {}
        return
    end
    
    local enemies = {}
    if main.current and main.current.enemies then
        for _, enemy in ipairs(main.current.enemies) do
            for _, e in ipairs(main.current.main:get_objects_by_classes({enemy})) do
                if not e.dead and e.x and e.y then
                    local distance = math.distance(e.x, e.y, Helper.Unit.player_location.x, Helper.Unit.player_location.y)
                    table.insert(enemies, {enemy = e, distance = distance})
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(enemies, function(a, b) return a.distance < b.distance end)
    
    -- Store just the enemy references in sorted order
    Helper.enemies_by_distance = {}
    for _, entry in ipairs(enemies) do
        table.insert(Helper.enemies_by_distance, entry)
    end
end

function Helper:update_cycle_targets()
    if not Helper.enemies_by_distance or #Helper.enemies_by_distance == 0 then
        Helper.cycle_targets = {}
        return
    end

    local CYCLE_RANGE_THRESHOLD = 50  -- Distance threshold for considering enemies "close" to the closest
    local MIN_CYCLE_TARGETS = 5 

    local closest_distance = Helper.enemies_by_distance[1].distance or 0
    
    Helper.cycle_targets = {}
    for _, entry in ipairs(Helper.enemies_by_distance) do
        if not entry.enemy.dead and entry.enemy.x and entry.enemy.y then
            if #Helper.cycle_targets < MIN_CYCLE_TARGETS then
                table.insert(Helper.cycle_targets, entry.enemy)
            elseif entry.distance <= closest_distance + CYCLE_RANGE_THRESHOLD then
                table.insert(Helper.cycle_targets, entry.enemy)
            else
                break
            end
        end
    end
end
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
end



function Helper:update(dt)
    if not Helper.initialized then
        Helper:init()
        Helper.initialized = true
    end

    Helper.Time.time = Helper.Time.time + dt
    Helper.Time.delta_time = dt

    --update timers, run state functions, update hitbox points
    Helper.Unit:update_hitbox_points()
    Helper.Unit:update_player_location()
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
                color = Helper.Color.red,
                is_troop = false
            }
        end
        Helper.arena_radius_circle.x = Helper.Unit.player_location.x
        Helper.arena_radius_circle.y = Helper.Unit.player_location.y
    else
        if Helper.arena_radius_circle then
            Helper.arena_radius_circle.dead = true
            Helper.arena_radius_circle = nil
        end
    end

    if input['s'].pressed then
        if not s_just_pressed then
            Helper.Spell.Sweep:create(Helper.Color.blue, true, 100, 50, Helper.mousey - 50, Helper.window_width - 50, Helper.mousey + 50)
        end
    end
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
Helper = {}

require 'helper/helper_geometry'
require 'helper/helper_spell'
require 'helper/helper_time'
require 'helper/helper_color'
require 'helper/helper_lua'
require 'helper/helper_unit'
require 'helper/helper_graphics'

Helper.initialized = false
Helper.mousex = 0
Helper.mousey = 0
Helper.window_width = 0
Helper.window_height = 0
Helper.mouse_on_button = false

function Helper:init()
    Helper.Time.time = love.timer.getTime()
    math.randomseed(Helper.Time.time)

    Helper.Unit:load_teams_to_next_round()

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
    Helper.Time:run_intervals()
    Helper.Time:run_waits()
    Helper.Unit:run_state_change_functions()
    Helper.Unit:run_state_always_run_functions()
    Helper.Unit:select()

    --update spells

    for i, spell in ipairs(Helper.Spell.spells) do
        if spell.update ~= nil then
            spell.update()
        end
    end

    --particles
    Helper.Graphics:update_particles()

    Helper.Spell:damage_points();



    Helper.mousex, Helper.mousey = love.mouse.getPosition()
    Helper.mousex = Helper.mousex / sx
    Helper.mousey = Helper.mousey / sx

    if love.keyboard.isDown( "d" ) then
        Helper.Spell.DamageCircle:create(nil, Helper.Color.blue, true, 50, 10, Helper.mousex, Helper.mousey)
        Helper.Spell.DamageCircle:create(nil, Helper.Color.blue, false, 50, 10, Helper.mousex, Helper.mousey)
    end
    if input['c'].pressed then
        print(Helper.mousex .. ' ' .. Helper.mousey)
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

    Helper.Unit:save_teams_to_next_round()
end
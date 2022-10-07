Helper = {}

require 'helper/helper_geometry'
require 'helper/spells/helper_spell_main'
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



function Helper.init()
    Helper.Time.time = love.timer.getTime()
    math.randomseed(Helper.Time.time)

    Helper.Time.set_interval(0.25, function()
        Helper.Spell.Flame.damage()
    end)
end



function Helper.draw()

    for i, spell in ipairs(Helper.Spell.spells) do
        if spell.draw_aims ~= nil then
            spell.draw_aims()
        end
        if spell.draw ~= nil then
            spell.draw()
        end
    end

    Helper.Spell.Missile.draw()
    Helper.Spell.DamageCircle.draw()
    Helper.Spell.Laser.draw_aims()
    Helper.Spell.DamageLine.draw()
    Helper.Spell.SpreadMissile.draw_aims()
    Helper.Spell.Flame.draw()

    Helper.Graphics.draw_particles()
end



function Helper.update(dt)
    if not Helper.initialized then
        Helper.init()
        Helper.initialized = true
    end

    Helper.Time.time = love.timer.getTime()
    Helper.Time.delta_time = dt

    --update timers, run state functions
    Helper.Time.run_intervals()
    Helper.Time.run_waits()
    Helper.Unit.run_state_change_functions()
    Helper.Unit.run_state_always_run_functions()


    --update spells

    for i, spell in ipairs(Helper.Spell.spells) do
        if spell.update ~= nil then
            spell.update()
        end
    end

    --particles
    Helper.Graphics.update_particles()



    Helper.mousex, Helper.mousey = love.mouse.getPosition()
    Helper.mousex = Helper.mousex / sx
    Helper.mousey = Helper.mousey / sx
    if love.keyboard.isDown( "d" ) then
        Helper.Spell.DamageCircle.create(Helper.Color.blue, true, 50, 10, Helper.mousex, Helper.mousey)
        Helper.Spell.DamageCircle.create(Helper.Color.blue, false, 50, 10, Helper.mousex, Helper.mousey)
    end
    
    Helper.window_width = love.graphics.getWidth() / sx
    Helper.window_height = love.graphics.getHeight() / sx
end



function Helper.release()
    Helper.initialized = false

    Helper.Time.stop_all_intervals()
    Helper.Time.stop_all_waits()

    for i, spell in ipairs(Helper.Spell.spells) do
        if spell.clear_all ~= nil then
            spell.clear_all()
        end
    end
end
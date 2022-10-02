Helper = {}
Helper.initialized = false
Helper.mousex = 0
Helper.mousey = 0
Helper.window_width = 0
Helper.window_height = 0

require 'helper/helper_geometry'
require 'helper/spells/helper_spell_main'
require 'helper/helper_time'
require 'helper/helper_color'
require 'helper/helper_lua'
require 'helper/helper_unit'



function Helper.init()
    Helper.Time.time = 0
    math.randomseed(Helper.Time.time)
end



function Helper.draw()
    Helper.Spell.Missile.draw()
    Helper.Spell.DamageCircle.draw()
    Helper.Spell.Laser.draw_aims()
    Helper.Spell.DamageLine.draw()
    Helper.Spell.SpreadMissile.draw_aims()
end



function Helper.update()
    if not Helper.initialized then
        Helper.init()
        Helper.initialized = true
    end

    Helper.Time.time = Helper.Time.time + Helper.Time.delta_time

    Helper.Time.run_intervals()
    Helper.Time.run_waits()
    Helper.Unit.run_state_change_functions()
    Helper.Unit.run_state_always_run_functions()



    Helper.Spell.Missile.update_position()
    Helper.Spell.Missile.explode()
    
    Helper.Spell.DamageCircle.damage()
    Helper.Spell.DamageCircle.delete()

    Helper.Spell.Laser.shoot()

    Helper.Spell.DamageLine.damage()
    Helper.Spell.DamageLine.delete()

    Helper.Spell.SpreadMissile.shoot_missiles()



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
end
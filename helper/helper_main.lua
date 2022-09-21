Helper = {}
Helper.initialized = false

require 'helper/helper_geometry'
require 'helper/spells/helper_spell_main'
require 'helper/helper_time'



function Helper.init()
    Helper.Time.past_time = love.timer.getTime()
    math.randomseed(love.timer.getTime())

    Helper.Time.set_interval(0.5, function() 
        Helper.Spell.Flame.damage() 
    end)
end



function Helper.draw()
    love.graphics.setColor(51 / 255, 153 / 255, 255 / 255, 0.5)
    Helper.Spell.Flame.draw()
    Helper.Spell.Missile.draw()
    Helper.Spell.DamageCircle.draw()
    Helper.Spell.Laser.draw_aims()
    Helper.Spell.DamageLine.draw()
end



function Helper.update()
    if not Helper.initialized then
        Helper.init()
        Helper.initialized = true
    end

    Helper.Time.delta_time = love.timer.getTime() - Helper.Time.past_time
    Helper.Time.past_time = love.timer.getTime()

    Helper.Time.run_intervals()
    Helper.Time.run_waits()
    Helper.Spell.get_last_target_location()



    Helper.Spell.Flame.update_target_location()
    Helper.Spell.Flame.end_flame()

    Helper.Spell.Missile.update_position()
    Helper.Spell.Missile.explode()
    
    Helper.Spell.DamageCircle.damage()
    Helper.Spell.DamageCircle.delete()

    Helper.Spell.Laser.shoot()

    Helper.Spell.DamageLine.damage()
    Helper.Spell.DamageLine.delete()



    local mousex, mousey = love.mouse.getPosition()
    mousex = mousex / sx
    mousey = mousey / sx
    if love.keyboard.isDown( "d" ) then
        Helper.Spell.DamageCircle.create(true, mousex, mousey)
    end   
end



function Helper.release()
    Helper.initialized = false
end
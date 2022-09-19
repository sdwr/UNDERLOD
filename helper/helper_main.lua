require 'helper/helper_geometry'
require 'helper/spells/helper_spell_main'
require 'helper/helper_time'



helper_initialized = false



function helper_init()
    past_time = love.timer.getTime()
    math.randomseed(love.timer.getTime())

    set_interval(0.5, function() 
        damage_enemy_in_flames() 
    end)
end



function helper_draw()
    love.graphics.setColor(51 / 255, 153 / 255, 255 / 255, 0.5)
    draw_flames()
    draw_missiles()
    draw_damage_circles()
    draw_laser_aims()
    draw_damage_lines()

    draw_enemy_damage_circles()
end



function helper_update()
    -- print('troop pos')
    -- local troops = self.main:get_objects_by_class(Troop)
    -- for _, troop in ipairs(troops) do
    --   print(troop.x .. ' ' .. troop.y)
    -- end
    if not helper_initialized then
        helper_init()
        helper_initialized = true
    end

    delta_time = love.timer.getTime() - past_time
    past_time = love.timer.getTime()

    run_intervals()
    run_waits()
    get_last_target_location()



    update_flame_target_location()
    end_flame()

    update_missile_pos()
    missile_explode()
    
    damage_enemies_inside_damage_circles()
    delete_damage_circles()

    shoot_lasers()

    damage_enemies_inside_damage_lines()
    delete_damage_lines()



    local mousex, mousey = love.mouse.getPosition()
    mousex = mousex / sx
    mousey = mousey / sx
    if love.keyboard.isDown( "d" ) then
        create_enemy_damage_circle(mousex, mousey)
    end   
    damage_enemies_inside_enemy_damage_circles()
    delete_enemy_damage_circles()
end



function helper_release()
    helper_initialized = false
end
require 'helper/helper_geometry'
require 'helper/helper_spell'
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
    
    end_flame()
    update_missile_pos()
    missile_explode()
    damage_enemies_inside_damage_circles()
    delete_damage_circles()
end



function helper_release()
    helper_initialized = false
end
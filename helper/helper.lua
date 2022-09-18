require 'helper/helper_geometry'
require 'helper/helper_spell'
require 'helper/helper_time'



helper_initialized = false



function helper_init()
    set_interval(0.5, function() 
        damage_enemy_in_flames() 
    end)
end



function helper_draw()
    love.graphics.setColor(255 / 255, 82 / 255, 76 / 255, 0.5)
    draw_flames()
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

    run_intervals()
    
    end_flame()
end



function helper_release()
    helper_initialized = false
end
flamewidth = 50
flameheight = 50
flameduration = 3
flames = {}



function create_flame(x, y, enemyx, enemyy)
    local flame = {
        x = x,
        y = y,
        enemyx = enemyx,
        enemyy = enemyy,
        flame_start_at = love.timer.getTime()
    }

    table.insert(flames, flame)
end



function end_flame()
    for __, flame in ipairs(flames) do
        if love.timer.getTime() - flame.flame_start_at > flameduration then
            table.remove(flames, __)
        end
    end
end



function damage_enemy_in_flames()
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    for _, enemy in ipairs(enemies) do
        for __, flame in ipairs(flames) do
            if is_insile_triangle(enemy.x, enemy.y, get_triangle_from_height_and_width(flame.x, flame.y, flame.enemyx, flame.enemyy, flameheight, flamewidth)) then
                enemy:hit(3)
                HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
                for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = blue[0]} end
                for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
            end
        end
    end
end



function draw_flames()
    for __, flame in ipairs(flames) do
        draw_triangle_from_height_and_width(flame.x, flame.y, flame.enemyx, flame.enemyy, flameheight, flamewidth)
    end
end
Helper.Spell.Flame = {}

flamewidth = 30
flameheight = 50
flameduration = 3
flames = {}

function Helper.Spell.Flame.create(parent, x, y, enemyx, enemyy)
    local flame = {
        parent = parent,
        x = x,
        y = y,
        enemyx = enemyx,
        enemyy = enemyy,
        flame_start_at = love.timer.getTime()
    }

    table.insert(flames, flame)
end

function Helper.Spell.Flame.end_flame()
    for __, flame in ipairs(flames) do
        if love.timer.getTime() - flame.flame_start_at > flameduration then
            table.remove(flames, __)
        end
    end
end

function Helper.Spell.Flame.damage()
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    for _, enemy in ipairs(enemies) do
        for __, flame in ipairs(flames) do
            if Helper.Geometry.is_inside_triangle(enemy.x, enemy.y, Helper.Geometry.get_triangle_from_height_and_width(flame.parent.x, flame.parent.y, flame.enemyx, flame.enemyy, flameheight, flamewidth)) then
                enemy:hit(3)
                HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
                for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = blue[0]} end
                for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
            end
        end
    end
end

function Helper.Spell.Flame.update_target_location()
    for __, flame in ipairs(flames) do
        flame.enemyx, flame.enemyy = Helper.Spell.get_nearest_target_location(flame.parent.x, flame.parent.y, false)
    end
end

function Helper.Spell.Flame.draw()
    for __, flame in ipairs(flames) do
        Helper.Geometry.draw_triangle_from_height_and_width(flame.parent.x, flame.parent.y, flame.enemyx, flame.enemyy, flameheight, flamewidth)
    end
end
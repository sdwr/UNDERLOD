damage_circle_radius = 20
damage_circle_duration = 3
damage_circles = {}

function create_damage_circle(x, y)
    local damage_circle = {
        x = x,
        y = y,
        creation_time = love.timer.getTime(),
        damage_dealt = false
    }

    table.insert(damage_circles, damage_circle)
end

function draw_damage_circles()
    for i, damage_circle in ipairs(damage_circles) do
        love.graphics.circle( 'line', damage_circle.x, damage_circle.y, damage_circle_radius )
    end
end

function damage_enemies_inside_damage_circles()
    for i, damage_circle in ipairs(damage_circles) do
        if not damage_circle.damage_dealt then
            local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
            for _, enemy in ipairs(enemies) do
                if distance(damage_circle.x, damage_circle.y, enemy.x, enemy.y) < damage_circle_radius then
                    enemy:hit(30)
                    HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = blue[0]} end
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
                end
            end

            damage_circle.damage_dealt = true
        end
    end
end

function delete_damage_circles()
    for i, damage_circle in ipairs(damage_circles) do
        if love.timer.getTime() - damage_circle.creation_time > damage_circle_duration then
            table.remove(damage_circles, i)
        end
    end
end
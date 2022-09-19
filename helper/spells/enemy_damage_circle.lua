enemy_damage_circle_radius = 10
enemy_damage_circle_duration = 0.5
enemy_damage_circles = {}

function create_enemy_damage_circle(x, y)
    local enemy_damage_circle = {
        x = x,
        y = y,
        creation_time = love.timer.getTime(),
        damage_dealt = false
    }

    table.insert(enemy_damage_circles, enemy_damage_circle)
end

function draw_enemy_damage_circles()
    for i, enemy_damage_circle in ipairs(enemy_damage_circles) do
        love.graphics.circle( 'line', enemy_damage_circle.x, enemy_damage_circle.y, enemy_damage_circle_radius )
    end
end

function damage_enemies_inside_enemy_damage_circles()
    for i, enemy_damage_circle in ipairs(enemy_damage_circles) do
        if not enemy_damage_circle.damage_dealt then
            local troops = main.current.main:get_objects_by_class(Troop)
            for _, troop in ipairs(troops) do
                if distance(enemy_damage_circle.x, enemy_damage_circle.y, troop.x, troop.y) < enemy_damage_circle_radius then
                    troop:hit(50)
                    HitCircle{group = main.current.effects, x = troop.x, y = troop.y, rs = 6, color = fg[0], duration = 0.1}
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = troop.x, y = troop.y, color = blue[0]} end
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = troop.x, y = troop.y, color = troop.color} end
                end
            end

            enemy_damage_circle.damage_dealt = true
        end
    end
end

function delete_enemy_damage_circles()
    for i, enemy_damage_circle in ipairs(enemy_damage_circles) do
        if love.timer.getTime() - enemy_damage_circle.creation_time > enemy_damage_circle_duration then
            table.remove(enemy_damage_circles, i)
        end
    end
end
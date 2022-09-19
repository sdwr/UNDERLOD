function get_nearest_target(x, y)
    local targetx = -10000
    local targety = -10000
    local distancemin = 100000000

    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    for _, enemy in ipairs(enemies) do
        if distance(x, y, enemy.x, enemy.y) < distancemin then
            distancemin = distance(x, y, enemy.x, enemy.y)
            targetx = enemy.x
            targety = enemy.y
            found_target = true
        end
    end

    return targetx, targety
end



flamewidth = 30
flameheight = 50
flameduration = 3
flames = {}

function create_flame(parent, x, y, enemyx, enemyy)
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
            if is_inside_triangle(enemy.x, enemy.y, get_triangle_from_height_and_width(flame.parent.x, flame.parent.y, flame.enemyx, flame.enemyy, flameheight, flamewidth)) then
                enemy:hit(3)
                HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
                for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = blue[0]} end
                for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
            end
        end
    end
end

function update_flame_target_location()
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)

    if #enemies ~= 0 then
        for __, flame in ipairs(flames) do
            flame.enemyx, flame.enemyy = get_nearest_target(flame.parent.x, flame.parent.y)
        end
    end
end

function draw_flames()
    for __, flame in ipairs(flames) do
        draw_triangle_from_height_and_width(flame.parent.x, flame.parent.y, flame.enemyx, flame.enemyy, flameheight, flamewidth)
    end
end



missile_speed = 300
missile_length = 10
missile_width = 3
missile_explode_range = 10
missiles = {}

function create_missile(x, y, targetx, targety)
    local missile = {
        x = x,
        y = y,
        targetx = targetx,
        targety = targety
    }

    table.insert(missiles, missile)
end

function draw_missiles()
    for i, missile in ipairs(missiles) do
        local xdivy = 0
        local deltax = 0
        local deltay = 0
        if missile.targety - missile.y ~= 0 then
            xdivy = (missile.targetx - missile.x) / (missile.targety - missile.y)
            deltay = math.sqrt(((missile_length/2)^2) / (xdivy^2 + 1))
            deltax = deltay * xdivy
        else
            deltay = 0
            deltax = missile_length / 2
        end
    
        love.graphics.setLineWidth(missile_width)
        love.graphics.line(missile.x - deltax, missile.y - deltay, missile.x + deltax, missile.y + deltay)
        love.graphics.setLineWidth(1)
    end
end

function update_missile_pos()
    for i, missile in ipairs(missiles) do
        local xdivy = 0
        local deltax = 0
        local deltay = 0
        if missile.targety - missile.y ~= 0 then
            xdivy = (missile.targetx - missile.x) / (missile.targety - missile.y)
            deltay = math.sqrt((((missile_speed * delta_time)/2)^2) / (xdivy^2 + 1))
            deltax = deltay * xdivy
        else
            deltay = 0
            deltax = (missile_speed * delta_time) / 2
        end

        if missile.targety - missile.y > 0 then
            missile.x = missile.x + deltax
            missile.y = missile.y + deltay
        elseif missile.targety - missile.y < 0 then
            missile.x = missile.x - deltax
            missile.y = missile.y - deltay
        else
            if missile.targetx - missile.x > 0 then
                missile.x = missile.x + deltax
            else
                missile.x = missile.x - deltax
            end
        end
    end
end

function missile_explode()
    for i, missile in ipairs(missiles) do
        if distance(missile.x, missile.y, missile.targetx, missile.targety) < missile_explode_range then
            create_damage_circle(missile.targetx, missile.targety)
            table.remove(missiles, i)
        end
    end
end



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
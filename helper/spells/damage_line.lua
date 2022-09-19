damage_lines = {}

function create_damage_line(linewidth, damage, x1, y1, x2, y2)
    local damage_line = {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        start_time = love.timer.getTime(),
        damage_dealt = false,
        linewidth = linewidth,
        damage = damage
    }

    table.insert(damage_lines, damage_line)
end

function draw_damage_lines()
    for i, damage_line in ipairs(damage_lines) do
        if love.timer.getTime() - damage_line.start_time < 0.05 then
            love.graphics.setLineWidth(damage_line.linewidth)
        elseif love.timer.getTime() - damage_line.start_time >= 0.025 and love.timer.getTime() - damage_line.start_time < 0.05 then
            love.graphics.setLineWidth(damage_line.linewidth * 7 / 6)
        elseif love.timer.getTime() - damage_line.start_time >= 0.05 and love.timer.getTime() - damage_line.start_time < 0.075 then
            love.graphics.setLineWidth(damage_line.linewidth * 8 / 6)
        elseif love.timer.getTime() - damage_line.start_time >= 0.075 and love.timer.getTime() - damage_line.start_time < 0.1 then
            love.graphics.setLineWidth(damage_line.linewidth * 7 / 6)
        elseif love.timer.getTime() - damage_line.start_time >= 0.1 and love.timer.getTime() - damage_line.start_time < 0.125 then
            love.graphics.setLineWidth(damage_line.linewidth * 6 / 6)
        elseif love.timer.getTime() - damage_line.start_time >= 0.125 and love.timer.getTime() - damage_line.start_time < 0.15 then
            love.graphics.setLineWidth(damage_line.linewidth / 5 / 6)
        elseif love.timer.getTime() - damage_line.start_time >= 0.15 and love.timer.getTime() - damage_line.start_time < 0.175 then
            love.graphics.setLineWidth(damage_line.linewidth * 4 / 6)
        elseif love.timer.getTime() - damage_line.start_time >= 0.175 and love.timer.getTime() - damage_line.start_time < 0.2 then
            love.graphics.setLineWidth(damage_line.linewidth * 3 / 6)
        elseif love.timer.getTime() - damage_line.start_time >= 0.2 and love.timer.getTime() - damage_line.start_time < 0.225 then
            love.graphics.setLineWidth(damage_line.linewidth * 2 / 6)
        elseif love.timer.getTime() - damage_line.start_time >= 0.225 and love.timer.getTime() - damage_line.start_time < 0.25 then
            love.graphics.setLineWidth(damage_line.linewidth * 1 / 6)
        end

        love.graphics.setColor(51 / 255, 153 / 255, 255 / 255, 1)
        love.graphics.line(damage_line.x1, damage_line.y1, damage_line.x2, damage_line.y2)
        love.graphics.setLineWidth(1)
    end
end

function damage_enemies_inside_damage_lines()
    for i, damage_line in ipairs(damage_lines) do
        if not damage_line.damage_dealt then
            local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
            for _, enemy in ipairs(enemies) do
                if is_on_line(enemy.x, enemy.y, damage_line.x1, damage_line.y1, damage_line.x2, damage_line.y2, damage_line.linewidth) then
                    enemy:hit(damage_line.damage)
                    HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = blue[0]} end
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
                end
            end

            damage_line.damage_dealt = true
        end
    end
end

function delete_damage_lines()
    for i, damage_line in ipairs(damage_lines) do
        if love.timer.getTime() - damage_line.start_time > 0.25 then
            table.remove(damage_lines, i)
        end
    end
end
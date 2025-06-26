Helper.Spell.DamageLine = {}

Helper.Spell.DamageLine.list = {}

function Helper.Spell.DamageLine:create(unit, color, linewidth, damage_troops, damage, x1, y1, x2, y2)
    damage = get_dmg_value(damage)
    local damage_line = {
        unit = unit,
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        start_time = Helper.Time.time,
        damage_dealt = false,
        linewidth = linewidth,
        color = color,
        damage = damage,
        damage_troops = damage_troops
    }

    table.insert(Helper.Spell.DamageLine.list, damage_line)
end

function Helper.Spell.DamageLine:draw()
    for i, damage_line in ipairs(Helper.Spell.DamageLine.list) do
        if Helper.Time.time - damage_line.start_time < 0.05 then
            love.graphics.setLineWidth(damage_line.linewidth)
        elseif Helper.Time.time - damage_line.start_time >= 0.025 and Helper.Time.time - damage_line.start_time < 0.05 then
            love.graphics.setLineWidth(damage_line.linewidth * 7 / 6)
        elseif Helper.Time.time - damage_line.start_time >= 0.05 and Helper.Time.time - damage_line.start_time < 0.075 then
            love.graphics.setLineWidth(damage_line.linewidth * 8 / 6)
        elseif Helper.Time.time - damage_line.start_time >= 0.075 and Helper.Time.time - damage_line.start_time < 0.1 then
            love.graphics.setLineWidth(damage_line.linewidth * 7 / 6)
        elseif Helper.Time.time - damage_line.start_time >= 0.1 and Helper.Time.time - damage_line.start_time < 0.125 then
            love.graphics.setLineWidth(damage_line.linewidth * 6 / 6)
        elseif Helper.Time.time - damage_line.start_time >= 0.125 and Helper.Time.time - damage_line.start_time < 0.15 then
            love.graphics.setLineWidth(damage_line.linewidth / 5 / 6)
        elseif Helper.Time.time - damage_line.start_time >= 0.15 and Helper.Time.time - damage_line.start_time < 0.175 then
            love.graphics.setLineWidth(damage_line.linewidth * 4 / 6)
        elseif Helper.Time.time - damage_line.start_time >= 0.175 and Helper.Time.time - damage_line.start_time < 0.2 then
            love.graphics.setLineWidth(damage_line.linewidth * 3 / 6)
        elseif Helper.Time.time - damage_line.start_time >= 0.2 and Helper.Time.time - damage_line.start_time < 0.225 then
            love.graphics.setLineWidth(damage_line.linewidth * 2 / 6)
        elseif Helper.Time.time - damage_line.start_time >= 0.225 and Helper.Time.time - damage_line.start_time < 0.25 then
            love.graphics.setLineWidth(damage_line.linewidth * 1 / 6)
        end

        love.graphics.setColor(damage_line.color.r, damage_line.color.g, damage_line.color.b, damage_line.color.a)
        love.graphics.line(damage_line.x1, damage_line.y1, damage_line.x2, damage_line.y2)
    end
end

function Helper.Spell.DamageLine:update()
    Helper.Spell.DamageLine:damage()
    Helper.Spell.DamageLine:delete()
end

--update to optionally do ticks of damage
function Helper.Spell.DamageLine:damage()
    for i, damage_line in ipairs(Helper.Spell.DamageLine.list) do
        if not damage_line.damage_dealt then
            for j, unit in ipairs(Helper.Unit:get_list(damage_line.damage_troops)) do
                for k, point in ipairs(unit.points) do
                    local x = unit.x + point.x
                    local y = unit.y + point.y
                    if Helper.Geometry:is_on_line(x, y, damage_line.x1, damage_line.y1, damage_line.x2, damage_line.y2, damage_line.linewidth) then
                        Helper.Spell:register_damage_point(point, damage_line.unit, damage_line.damage)
                    end
                end
            end
            damage_line.damage_dealt = true
        end
    end
end

function Helper.Spell.DamageLine:delete()
    for i = #Helper.Spell.DamageLine.list, 1, -1 do
        if Helper.Time.time - Helper.Spell.DamageLine.list[i].start_time > 0.25 then
            table.remove(Helper.Spell.DamageLine.list, i)
        end
    end
end
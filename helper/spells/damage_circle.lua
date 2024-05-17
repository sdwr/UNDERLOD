Helper.Spell.DamageCircle = {}

Helper.Spell.DamageCircle.duration = 0.25
Helper.Spell.DamageCircle.list = {}

function Helper.Spell.DamageCircle:create(unit, color, damage_troops, damage, radius, x, y, draw_over_units)
    local damage_circle = {
        unit = unit,
        x = x,
        y = y,
        creation_time = Helper.Time.time,
        damage_dealt = false,
        damage_troops = damage_troops,
        color = Helper.Color:set_transparency(color, 0.3),
        radius = radius,
        -- line_width = radius / 15,
        damage = damage,
        draw_over_units = draw_over_units or false
    }

    table.insert(Helper.Spell.DamageCircle.list, damage_circle)
end

function Helper.Spell.DamageCircle:draw()
    for i, damage_circle in ipairs(Helper.Spell.DamageCircle.list) do
        love.graphics.setColor(damage_circle.color.r, damage_circle.color.g, damage_circle.color.b, damage_circle.color.a)
        love.graphics.setLineWidth(1)
        love.graphics.circle( 'fill', damage_circle.x, damage_circle.y, damage_circle.radius )
    end
end

function Helper.Spell.DamageCircle:update()
    Helper.Spell.DamageCircle:damage()
    Helper.Spell.DamageCircle:delete()
end

function Helper.Spell.DamageCircle:damage()
    for i, damage_circle in ipairs(Helper.Spell.DamageCircle.list) do
        if not damage_circle.damage_dealt then
            for i, unit in ipairs(Helper.Unit:get_list(damage_circle.damage_troops)) do
                for j, point in ipairs(unit.points) do
                    if Helper.Geometry:distance(damage_circle.x, damage_circle.y, unit.x + point.x, unit.y + point.y) < damage_circle.radius then
                        Helper.Spell:register_damage_point(point, damage_circle.unit, damage_circle.damage)
                    end
                end
            end

            damage_circle.damage_dealt = true
        end
    end
end

function Helper.Spell.DamageCircle:delete()
    for i = #Helper.Spell.DamageCircle.list, 1, -1 do
        if Helper.Time.time - Helper.Spell.DamageCircle.list[i].creation_time > Helper.Spell.DamageCircle.duration then
            table.remove(Helper.Spell.DamageCircle.list, i)
        end
    end
end
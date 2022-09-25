Helper.Spell.DamageCircle = {}

Helper.Spell.DamageCircle.duration = 0.5
Helper.Spell.DamageCircle.list = {}

function Helper.Spell.DamageCircle.create(color, damage_troops, damage, radius, x, y)
    local damage_circle = {
        x = x,
        y = y,
        creation_time = love.timer.getTime(),
        damage_dealt = false,
        damage_troops = damage_troops,
        color = color,
        radius = radius,
        line_width = radius / 15,
        damage = damage
    }

    table.insert(Helper.Spell.DamageCircle.list, damage_circle)
end

function Helper.Spell.DamageCircle.draw()
    for i, damage_circle in ipairs(Helper.Spell.DamageCircle.list) do
        love.graphics.setColor(damage_circle.color.r, damage_circle.color.g, damage_circle.color.b, damage_circle.color.a)
        love.graphics.setLineWidth(damage_circle.line_width)
        love.graphics.circle( 'line', damage_circle.x, damage_circle.y, damage_circle.radius )
    end
end

function Helper.Spell.DamageCircle.damage()
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    local troops = main.current.main:get_objects_by_class(Troop)

    for i, damage_circle in ipairs(Helper.Spell.DamageCircle.list) do
        if not damage_circle.damage_dealt then
            if not damage_circle.damage_troops then
                for _, enemy in ipairs(enemies) do
                    if Helper.Geometry.distance(damage_circle.x, damage_circle.y, enemy.x, enemy.y) < damage_circle.radius then
                        enemy:hit(damage_circle.damage)
                        HitCircle{group = main.current.effects, x = enemy.x, y = enemy.y, rs = 6, color = fg[0], duration = 0.1}
                        for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = blue[0]} end
                        for i = 1, 1 do HitParticle{group = main.current.effects, x = enemy.x, y = enemy.y, color = enemy.color} end
                    end
                end
            else
                for _, troop in ipairs(troops) do
                    if Helper.Geometry.distance(damage_circle.x, damage_circle.y, troop.x, troop.y) < damage_circle.radius then
                        troop:hit(damage_circle.damage)
                        HitCircle{group = main.current.effects, x = troop.x, y = troop.y, rs = 6, color = fg[0], duration = 0.1}
                        for i = 1, 1 do HitParticle{group = main.current.effects, x = troop.x, y = troop.y, color = blue[0]} end
                        for i = 1, 1 do HitParticle{group = main.current.effects, x = troop.x, y = troop.y, color = troop.color} end
                    end
                end
            end

            damage_circle.damage_dealt = true
        end
    end
end

function Helper.Spell.DamageCircle.delete()
    for i, damage_circle in ipairs(Helper.Spell.DamageCircle.list) do
        if love.timer.getTime() - damage_circle.creation_time > Helper.Spell.DamageCircle.duration then
            table.remove(Helper.Spell.DamageCircle.list, i)
        end
    end
end
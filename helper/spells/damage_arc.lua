Helper.Spell.DamageArc = {}

Helper.Spell.DamageArc.list = {}
Helper.Spell.DamageArc.grow = true

--width in degrees
function Helper.Spell.DamageArc:create(unit, color, damage_troops, pierce, damage, width, angle, speed, x, y, radius)
    local damage_arc = {
        unit = unit,
        x = x,
        y = y,
        creation_time = Helper.Time.time,
        damage_troops = damage_troops,
        pierce = pierce,
        angle = math.rad(angle),
        width = math.rad(width),
        speed = speed,
        color = Helper.Color:set_transparency(color, 0.8),
        radius = radius or 20,
        -- line_width = radius / 15,
        damage = damage
    }

    damage_arc.targets_hit = {}
    damage_arc.x, damage_arc.y = Helper.Geometry:move_point(damage_arc.x, damage_arc.y, 
    damage_arc.angle + math.pi, damage_arc.radius / 2)

    table.insert(Helper.Spell.DamageArc.list, damage_arc)
end

function Helper.Spell.DamageArc:create_spread(unit, color, damage_troops, pierce, damage, width, thickness, numArcs, speed, x, y)
    local angle = math.random(360)
    for i = 1, numArcs do
        angle = angle + (360 / numArcs)
        for j = 0, thickness-1 do
            Helper.Spell.DamageArc:create(unit, color, damage_troops, pierce, damage, width, angle, speed, x, y, 20 - (j*4))
        end
    end
end

function Helper.Spell.DamageArc:draw()
    for i, damage_arc in ipairs(Helper.Spell.DamageArc.list) do
        love.graphics.setColor(damage_arc.color.r, damage_arc.color.g, damage_arc.color.b, damage_arc.color.a)
        local a1 = damage_arc.angle 
        local a2 = damage_arc.angle + damage_arc.width
        love.graphics.arc( 'line', 'open', damage_arc.x, damage_arc.y, damage_arc.radius, a1, a2)
    end
end

function Helper.Spell.DamageArc:update()
    Helper.Spell.DamageArc:move()
    Helper.Spell.DamageArc:damage()
    Helper.Spell.DamageArc:delete()
end

function Helper.Spell.DamageArc:move()
    for i, damage_arc in ipairs(Helper.Spell.DamageArc.list) do
        local movement = Helper.Time.delta_time * damage_arc.speed
        if Helper.Spell.DamageArc.grow then
            damage_arc.radius = damage_arc.radius + movement
        else
            damage_arc.x, damage_arc.y = Helper.Geometry:move_point(damage_arc.x, damage_arc.y, 
            damage_arc.angle, movement)
        end
    end
end

function Helper.Spell.DamageArc:getLine(arc)
    local x1, y1 = Helper.Geometry:move_point(arc.x, arc.y, arc.angle, arc.radius)
    local x2, y2 = Helper.Geometry:move_point(arc.x, arc.y, arc.angle + arc.width, arc.radius)

    return x1, y1, x2, y2
end

function Helper.Spell.DamageArc:damage()
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    local troops = main.current.main:get_objects_by_class(Troop)

    for i, damage_arc in ipairs(Helper.Spell.DamageArc.list) do

        local x1, y1, x2, y2 = Helper.Spell.DamageArc:getLine(damage_arc)
        local line = Line(x1, y1, x2, y2)
        local targets = nil
            if not damage_arc.damage_troops then
                targets = main.current.main:get_objects_in_shape(line, {Enemy, EnemyCritter}, damage_arc.targets_hit)

            else
                targets = main.current.main:get_objects_in_shape(line, {Troop, Critter}, damage_arc.targets_hit)
            end
            for _, target in ipairs(targets) do
                target:hit(damage_arc.damage, damage_arc.unit)
                table.insert(damage_arc.targets_hit, target)

                HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
                for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = blue[0]} end
                for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
            end
            if #damage_arc.targets_hit > 0 and damage_arc.pierce == false then
                table.remove(Helper.Spell.DamageArc.list, i)
            end
    end
end

function Helper.Spell.DamageArc:delete()
    for i = #Helper.Spell.DamageArc.list, 1, -1 do
        local arc = Helper.Spell.DamageArc.list[i]
        if Helper.Geometry:is_off_screen(arc.x, arc.y, arc.angle, arc.radius + 20) then
            table.remove(Helper.Spell.DamageArc.list, i)
        end
    end
end
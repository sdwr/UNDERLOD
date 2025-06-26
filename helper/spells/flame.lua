Helper.Spell.Flame = {}

Helper.Spell.Flame.do_draw_hitbox = false
Helper.Spell.Flame.do_draw_particles = true
Helper.Spell.Flame.list = {}

function Helper.Spell.Flame:create(color, flamewidth, flameheight, damage, unit, follow_target, follow_speed)
    damage = get_dmg_value(damage)
    if unit:my_target() then
        local i, flame = find_in_list(Helper.Spell.Flame.list, unit, function(value) return value.unit end)
        if flame == -1 then
            local flame = {
                unit = unit,
                directionx = unit.target.x - unit.x,
                directiony = unit.target.y - unit.y,
                set_to_end = false,
                end_after = 0,
                start_ending_at = 0,
                particle_interval_id = -1,
                color = color,
                flamewidth = flamewidth,
                flameheight = flameheight,
                damage = damage,
                follow_target = follow_target or true,
                follow_speed = follow_speed or 60
            }

            if unit and unit.area_size_m then
                flame.flamewidth = flame.flamewidth * unit.area_size_m
                flame.flameheight = flame.flameheight * unit.area_size_m
            end

            if Helper.Spell.Flame.do_draw_particles then
                flame.particle_interval_id = Helper.Time:set_interval(0.125, function()
                    for i = 0, math.random(4, 8) do
                        local x = 0
                        local y = 0
                        while not (Helper.Geometry:is_inside_triangle(x, y, Helper.Geometry:get_triangle_from_height_and_width(flame.unit.x, flame.unit.y, flame.unit.x + flame.directionx, flame.unit.y + flame.directiony, flame.flameheight, flamewidth))
                        and Helper.Geometry:distance(unit.x, unit.y, x, y) < flameheight / 5) do
                            x = get_random(unit.x - flameheight/5, unit.x + flameheight/5)
                            y = get_random(unit.y - flameheight/5, unit.y + flameheight/5)
                        end
                        Helper.Graphics:create_particle(color, get_random(0.5, 1.5), x, y, get_random(150, 180), 
                                                            get_random(0.4 * flameheight / 60, 0.5 * flameheight / 60), 
                                                            x - unit.x, y - unit.y, 20)
                    end
                end)
            end

            table.insert(Helper.Spell.Flame.list, flame)
            pyro1:play{volume=0.5}
        else
            flame.set_to_end = false
        end
    end
end

function Helper.Spell.Flame:update(dt)
    Helper.Spell.Flame:update_direction(dt)
    Helper.Spell.Flame:end_flames()
end

function Helper.Spell.Flame:damage()
    for __, flame in ipairs(Helper.Spell.Flame.list) do
        for _, target in ipairs(Helper.Unit:get_list(not flame.unit.is_troop)) do
            if Helper.Geometry:is_inside_triangle(target.x, target.y, Helper.Geometry:get_triangle_from_height_and_width(flame.unit.x, flame.unit.y, flame.unit.x + flame.directionx, flame.unit.y + flame.directiony, flame.flameheight, flame.flamewidth)) 
            and Helper.Geometry:distance(flame.unit.x, flame.unit.y, target.x, target.y) < flame.flameheight then
                target:hit(flame.damage, flame.unit)
                HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
                --for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = blue[0]} end
                --for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
            end
        end
    end
end

function Helper.Spell.Flame:update_direction(dt)
    for __, flame in ipairs(Helper.Spell.Flame.list) do
        if flame.follow_target then
            local target = flame.unit:my_target()
            local x = flame.unit.x + flame.directionx
            local y = flame.unit.y + flame.directiony
            if target then
                x, y = Helper.Geometry.rotate_to(flame.unit.x, flame.unit.y, x, y, target.x, target.y, flame.follow_speed)
                flame.directionx = x - flame.unit.x
                flame.directiony = y - flame.unit.y
            end
        end
    end
end

function Helper.Spell.Flame:draw()
    --debug, draw hitbox
    if Helper.Spell.Flame.do_draw_hitbox then
        for __, flame in ipairs(Helper.Spell.Flame.list) do
            love.graphics.setColor(flame.color.r, flame.color.g, flame.color.b, 0.1)
            local x1, y1, x2, y2, x3, y3 = Helper.Geometry:get_triangle_from_height_and_width(flame.unit.x, flame.unit.y, flame.unit.x + flame.directionx, flame.unit.y + flame.directiony, flame.flameheight, flame.flamewidth)
            love.graphics.line(x1, y1, x2, y2)
            love.graphics.line(x1, y1, x3, y3)
            love.graphics.circle('line', flame.unit.x, flame.unit.y, flame.flameheight)
        end
    end
end

function Helper.Spell.Flame:end_flames()
    for i = #Helper.Spell.Flame.list, 1, -1 do
        local flame = Helper.Spell.Flame.list[i]
        if flame.set_to_end then
            if Helper.Time.time - flame.start_ending_at > flame.end_after then
                Helper.Unit:finish_casting(flame.unit)
                Helper.Time:stop_interval(flame.particle_interval_id)
                table.remove(Helper.Spell.Flame.list, i)
            end
        end
    end
end

function Helper.Spell.Flame:clear_all()
    for i = #Helper.Spell.Flame.list, 1, -1 do
        Helper.Time:stop_interval(Helper.Spell.Flame.list[i].particle_interval_id)
        table.remove(Helper.Spell.Flame.list, i)
    end
end



function Helper.Spell.Flame:end_flame_after(unit, duration)
    local i, flame = find_in_list(Helper.Spell.Flame.list, unit, function(value) return value.unit end)
    if i ~= -1 then
        flame.set_to_end = true
        flame.end_after = duration
        flame.start_ending_at = Helper.Time.time
    end
end
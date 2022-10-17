Helper.Spell.SpreadMissile = {}
Helper.Spell.SpreadMissile.list = {}
Helper.Spell.SpreadMissile.aims_duration = 3

function Helper.Spell.SpreadMissile:create(color, missile_length, damage, unit, explode_radius, show_aims)
    local spread_missile = {
        parent = unit,
        creation_time = Helper.Time.time,
        offset_angle = get_random(0, 360),
        missile_length = missile_length,
        color = color,
        explode_radius = explode_radius,
        show_aims = show_aims,
        damage = damage,
        unit = unit,
    }

    table.insert(Helper.Spell.SpreadMissile.list, spread_missile)
end

function Helper.Spell.SpreadMissile:draw_aims()
    for i, spread_missile in ipairs(Helper.Spell.SpreadMissile.list) do
        if spread_missile.show_aims then
            Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(spread_missile.color, 0.5), spread_missile.missile_length / 4, spread_missile.missile_length * 3 / 4, spread_missile.missile_length * 3 / 8, Helper.Time.time * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle)))
            Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(spread_missile.color, 0.5), spread_missile.missile_length / 4, spread_missile.missile_length * 3 / 4, spread_missile.missile_length * 3 / 8, Helper.Time.time * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60)))
            Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(spread_missile.color, 0.5), spread_missile.missile_length / 4, spread_missile.missile_length * 3 / 4, spread_missile.missile_length * 3 / 8, Helper.Time.time * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 2)))
            Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(spread_missile.color, 0.5), spread_missile.missile_length / 4, spread_missile.missile_length * 3 / 4, spread_missile.missile_length * 3 / 8, Helper.Time.time * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 3)))
            Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(spread_missile.color, 0.5), spread_missile.missile_length / 4, spread_missile.missile_length * 3 / 4, spread_missile.missile_length * 3 / 8, Helper.Time.time * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 4)))
            Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(spread_missile.color, 0.5), spread_missile.missile_length / 4, spread_missile.missile_length * 3 / 4, spread_missile.missile_length * 3 / 8, Helper.Time.time * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 5)))
        end    
    end
end

function Helper.Spell.SpreadMissile:update()
    --shoot missiles
    for i = #Helper.Spell.SpreadMissile.list, 1, -1 do
        local spread_missile = Helper.Spell.SpreadMissile.list[i]
        if Helper.Time.time - spread_missile.creation_time > Helper.Spell.SpreadMissile.aims_duration then
            Helper.Spell.Missile:create(spread_missile.color, spread_missile.missile_length, spread_missile.damage, 300, spread_missile.unit, true, spread_missile.explode_radius, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle))
            Helper.Spell.Missile:create(spread_missile.color, spread_missile.missile_length, spread_missile.damage, 300, spread_missile.unit, true, spread_missile.explode_radius, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60))
            Helper.Spell.Missile:create(spread_missile.color, spread_missile.missile_length, spread_missile.damage, 300, spread_missile.unit, true, spread_missile.explode_radius, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 2))
            Helper.Spell.Missile:create(spread_missile.color, spread_missile.missile_length, spread_missile.damage, 300, spread_missile.unit, true, spread_missile.explode_radius, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 3))
            Helper.Spell.Missile:create(spread_missile.color, spread_missile.missile_length, spread_missile.damage, 300, spread_missile.unit, true, spread_missile.explode_radius, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 4))
            Helper.Spell.Missile:create(spread_missile.color, spread_missile.missile_length, spread_missile.damage, 300, spread_missile.unit, true, spread_missile.explode_radius, Helper.Geometry:rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 5))
            table.remove(Helper.Spell.SpreadMissile.list, i)
        end
    end
end
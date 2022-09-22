Helper.Spell.SpreadMissile = {}
Helper.Spell.SpreadMissile.list = {}
Helper.Spell.SpreadMissile.aims_duration = 2

function Helper.Spell.SpreadMissile.create(parent)
    local spread_missile = {
        parent = parent,
        creation_time = love.timer.getTime(),
        offset_angle = math.random(0, 360)
    }

    table.insert(Helper.Spell.SpreadMissile.list, spread_missile)
end

function Helper.Spell.SpreadMissile.draw_aims()
    for i, spread_missile in ipairs(Helper.Spell.SpreadMissile.list) do
        Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle)))
        Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60)))
        Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 2)))
        Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 3)))
        Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 4)))
        Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 5)))
    end
end

function Helper.Spell.SpreadMissile.shoot_missiles()
    for i, spread_missile in ipairs(Helper.Spell.SpreadMissile.list) do
        if love.timer.getTime() - spread_missile.creation_time > Helper.Spell.SpreadMissile.aims_duration then
            Helper.Spell.Missile.create(true, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle)))
            Helper.Spell.Missile.create(true, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60)))
            Helper.Spell.Missile.create(true, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 2)))
            Helper.Spell.Missile.create(true, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 3)))
            Helper.Spell.Missile.create(true, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 4)))
            Helper.Spell.Missile.create(true, spread_missile.parent.x, spread_missile.parent.y, Helper.Spell.Laser.get_end_location(spread_missile.parent.x, spread_missile.parent.y, Helper.Geometry.rotate_point(spread_missile.parent.x + 100, spread_missile.parent.y, spread_missile.parent.x, spread_missile.parent.y, spread_missile.offset_angle + 60 * 5)))
            table.remove(Helper.Spell.SpreadMissile.list, i)
        end
    end
end
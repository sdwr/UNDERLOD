Helper.Spell.Laser = {}

Helper.Spell.Laser.aims_duration = 2
Helper.Spell.Laser.list = {}

function Helper.Spell.Laser.create(color, laser_aim_width, damage_troops, direction_lock, damage, parent, direction_targetx, direction_targety)
    local laser = {
        parent = parent,
        start_aim_time = love.timer.getTime(),
        direction_targetx = direction_targetx - parent.x,
        direction_targety = direction_targety - parent.y,
        direction_lock = direction_lock,
        laser_aim_width = laser_aim_width,
        color = color,
        damage = damage,
        damage_troops = damage_troops
    }

    table.insert(Helper.Spell.Laser.list, laser)
end

function Helper.Spell.Laser.get_end_location(x, y, targetx, targety)
    local deltax = math.abs(targetx - x)
    local deltay = math.abs(targety - y)
    local length_to_window_width = 0
    local length_to_window_height = 0
    local endx = 0
    local endy = 0

    if targetx - x > 0 and targety - y > 0 then
        length_to_window_width = Helper.window_width - x
        length_to_window_height = Helper.window_height - y

        if length_to_window_height ~= 0 and deltay ~= 0 then
            if length_to_window_width / length_to_window_height > deltax / deltay then
                endy = Helper.window_height
                endx = x + length_to_window_height * (deltax / deltay)
            else
                endx = Helper.window_width
                endy = y + length_to_window_width * (deltay / deltax)
            end
        end

    elseif targetx - x < 0 and targety - y > 0 then
        length_to_window_width = x
        length_to_window_height = Helper.window_height - y

        if length_to_window_height ~= 0 and deltay ~= 0 then
            if length_to_window_width / length_to_window_height > deltax / deltay then
                endy = Helper.window_height
                endx = x - length_to_window_height * (deltax / deltay)
            else
                endx = 0
                endy = y + length_to_window_width * (deltay / deltax)
            end
        end

    elseif targetx - x < 0 and targety - y < 0 then
        length_to_window_width = x
        length_to_window_height = y

        if length_to_window_height ~= 0 and deltay ~= 0 then
            if length_to_window_width / length_to_window_height > deltax / deltay then
                endy = 0
                endx = x - length_to_window_height * (deltax / deltay)
            else
                endx = 0
                endy = y - length_to_window_width * (deltay / deltax)
            end
        end

    elseif targetx - x > 0 and targety - y < 0 then
        length_to_window_width = Helper.window_width - x
        length_to_window_height = y

        if length_to_window_height ~= 0 and deltay ~= 0 then
            if length_to_window_width / length_to_window_height > deltax / deltay then
                endy = 0
                endx = x + length_to_window_height * (deltax / deltay)
            else
                endx = Helper.window_width
                endy = y - length_to_window_width * (deltay / deltax)
            end
        end
    end

    return endx, endy
end

function Helper.Spell.Laser.draw_aims()
    for i, laser in ipairs(Helper.Spell.Laser.list) do
        love.graphics.setLineWidth(laser.laser_aim_width)
        love.graphics.setColor(laser.color.r, laser.color.g, laser.color.b, 0.5)
        if laser.direction_lock then
            love.graphics.line(laser.parent.x, laser.parent.y, Helper.Spell.Laser.get_end_location(laser.parent.x, laser.parent.y, laser.parent.x + laser.direction_targetx, laser.parent.y + laser.direction_targety))
        else
            love.graphics.line(laser.parent.x, laser.parent.y, Helper.Spell.Laser.get_end_location(laser.parent.x, laser.parent.y, Helper.Spell.get_nearest_target_location(laser.parent.x, laser.parent.y)))
        end
    end
end

function Helper.Spell.Laser.shoot()
    for i, laser in ipairs(Helper.Spell.Laser.list) do
        if love.timer.getTime() - laser.start_aim_time > Helper.Spell.Laser.aims_duration then
            if laser.direction_lock then
                Helper.Spell.DamageLine.create(laser.color, laser.laser_aim_width * 3, laser.damage_troops, laser.damage, laser.parent.x, laser.parent.y, Helper.Spell.Laser.get_end_location(laser.parent.x, laser.parent.y, laser.parent.x + laser.direction_targetx, laser.parent.y + laser.direction_targety))
            else
                Helper.Spell.DamageLine.create(laser.color, laser.laser_aim_width * 3, laser.damage_troops, laser.damage, laser.parent.x, laser.parent.y, Helper.Spell.Laser.get_end_location(laser.parent.x, laser.parent.y, Helper.Spell.get_nearest_target_location(laser.parent.x, laser.parent.y)))
            end
            table.remove(Helper.Spell.Laser.list, i)
            shoot1:play{volume=0.9}
        end
    end
end
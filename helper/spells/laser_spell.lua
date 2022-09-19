laser_aims_duration = 2
lasers = {}

function create_laser(laser_aim_width, damage, parent)
    local laser = {
        parent = parent,
        start_aim_time = love.timer.getTime(),
        directionx = 0,
        directiony = 0,
        direction_lock = false,
        laser_aim_width = laser_aim_width,
        damage = damage
    }

    table.insert(lasers, laser)
end

function create_direction_lock_laser(laser_aim_width, damage, parent, targetx, targety)
    local laser = {
        parent = parent,
        start_aim_time = love.timer.getTime(),
        directionx = targetx - parent.x,
        directiony = targety - parent.y,
        direction_lock = true,
        laser_aim_width = laser_aim_width,
        damage = damage
    }

    table.insert(lasers, laser)
end

function get_laser_end_location(x, y, targetx, targety)
    local deltax = math.abs(targetx - x)
    local deltay = math.abs(targety - y)
    local length_to_window_width = 0
    local length_to_window_height = 0
    local endx = 0
    local endy = 0

    if targetx - x > 0 and targety - y > 0 then
        length_to_window_width = love.graphics.getWidth() / sx - x
        length_to_window_height = love.graphics.getHeight() / sx - y

        if length_to_window_height ~= 0 and deltay ~= 0 then
            if length_to_window_width / length_to_window_height > deltax / deltay then
                endy = love.graphics.getHeight() / sx
                endx = x + length_to_window_height * (deltax / deltay)
            else
                endx = love.graphics.getWidth() / sx
                endy = y + length_to_window_width * (deltay / deltax)
            end
        end

    elseif targetx - x < 0 and targety - y > 0 then
        length_to_window_width = x
        length_to_window_height = love.graphics.getHeight() / sx - y

        if length_to_window_height ~= 0 and deltay ~= 0 then
            if length_to_window_width / length_to_window_height > deltax / deltay then
                endy = love.graphics.getHeight() / sx
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
        length_to_window_width = love.graphics.getWidth() / sx - x
        length_to_window_height = y

        if length_to_window_height ~= 0 and deltay ~= 0 then
            if length_to_window_width / length_to_window_height > deltax / deltay then
                endy = 0
                endx = x + length_to_window_height * (deltax / deltay)
            else
                endx = love.graphics.getWidth() / sx
                endy = y - length_to_window_width * (deltay / deltax)
            end
        end
    end

    return endx, endy
end

function draw_laser_aims()
    for i, laser in ipairs(lasers) do
        love.graphics.setLineWidth(laser.laser_aim_width)
        if laser.direction_lock then
            love.graphics.line(laser.parent.x, laser.parent.y, get_laser_end_location(laser.parent.x, laser.parent.y, laser.parent.x + laser.directionx, laser.parent.y + laser.directiony))
        else
            love.graphics.line(laser.parent.x, laser.parent.y, get_laser_end_location(laser.parent.x, laser.parent.y, get_nearest_target_location(laser.parent.x, laser.parent.y)))
        end
        love.graphics.setLineWidth(1)
    end
end

function shoot_lasers()
    for i, laser in ipairs(lasers) do
        if love.timer.getTime() - laser.start_aim_time > laser_aims_duration then
            if laser.direction_lock then
                create_damage_line(laser.laser_aim_width * 3, laser.damage, laser.parent.x, laser.parent.y, get_laser_end_location(laser.parent.x, laser.parent.y, laser.parent.x + laser.directionx, laser.parent.y + laser.directiony))
            else
                create_damage_line(laser.laser_aim_width * 3, laser.damage, laser.parent.x, laser.parent.y, get_laser_end_location(laser.parent.x, laser.parent.y, get_nearest_target_location(laser.parent.x, laser.parent.y)))
            end
            table.remove(lasers, i)
            shoot1:play{volume=0.9}
        end
    end
end
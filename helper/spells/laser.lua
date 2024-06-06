Helper.Spell.Laser = {}
Helper.Spell.Laser.list = {}

function Helper.Spell.Laser:create(color, laser_aim_width, direction_lock, damage, unit, direction_targetx, direction_targety)

    if unit:my_target() then
        local laser = {
            unit = unit,
            start_aim_time = Helper.Time.time,
            cast_time = unit.castTime or 1,
            direction_targetx = -1,
            direction_targety = -1,
            direction_lock = direction_lock,
            laser_aim_width = laser_aim_width,
            color = color,
            damage = damage,
            damage_troops = not unit.is_troop,
            holding_fire = false
        }

        local local_direction_targetx = direction_targetx or -1
        local local_direction_targety = direction_targety or -1 
        if direction_lock and local_direction_targetx == -1 and local_direction_targety == -1 then
            local x, y = Helper.Spell:get_target_nearest_point(unit)
            laser.direction_targetx = x - unit.x
            laser.direction_targety = y - unit.y
        elseif direction_lock and local_direction_targetx ~= -1 and local_direction_targety ~= -1 then
            laser.direction_targetx = local_direction_targetx - unit.x
            laser.direction_targety = local_direction_targety - unit.y
        end

        if unit and unit.area_size_m then
            laser.laser_aim_width = laser.laser_aim_width * unit.area_size_m
        end

        laser.target_last_x = unit:my_target().x
        laser.target_last_y = unit:my_target().y

        if laser.damage_troops then
            laser.charge_sound = laser_charging:play{volume=0.9}
        end

        table.insert(Helper.Spell.Laser.list, laser)
    end
end

function Helper.Spell.Laser:get_end_location(x, y, targetx, targety)
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

function Helper.Spell.Laser:draw_aims()
    for i, laser in ipairs(Helper.Spell.Laser.list) do
        love.graphics.setLineWidth(laser.laser_aim_width / 2)
        love.graphics.setColor(laser.color.r, laser.color.g, laser.color.b, 0.3)
        if laser.direction_lock then
            love.graphics.line(laser.unit.x, laser.unit.y, Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, laser.unit.x + laser.direction_targetx, laser.unit.y + laser.direction_targety))
        else
            local x, y = Helper.Spell:get_target_nearest_point(laser.unit)
            if x == 0 or y == 0 then
                x = laser.target_last_x
                y = laser.target_last_y
            end
            love.graphics.line(laser.unit.x, laser.unit.y, Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, x, y))
        end
    end
end

--if target is dead, the laser should fire at the last known location
--if unit is dead, the laser should cancel
--complicated by direction lock which goes based on distance(??)
function Helper.Spell.Laser:update()
    --shoot
    for i = #Helper.Spell.Laser.list, 1, -1 do
        local laser = Helper.Spell.Laser.list[i]
        --update target last known location
        --spells should be getting this generically
        if laser.unit and laser.unit:my_target() then
            laser.target_last_x = laser.unit:my_target().x
            laser.target_last_y = laser.unit:my_target().y
        end

        if not laser.unit or laser.unit.dead then
            Helper.Spell.Laser:die(i)
        end

        if Helper.Time.time - laser.start_aim_time > laser.cast_time and not laser.holding_fire then
            if laser.direction_lock then
                Helper.Spell.DamageLine:create(laser.unit, laser.color, laser.laser_aim_width * 3, laser.damage_troops, laser.damage, laser.unit.x, laser.unit.y, Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, laser.unit.x + laser.direction_targetx, laser.unit.y + laser.direction_targety))
            else
                local x, y = Helper.Spell:get_target_nearest_point(laser.unit)
                if x == 0 or y == 0 then
                    x = laser.target_last_x
                    y = laser.target_last_y
                end
                Helper.Spell.DamageLine:create(laser.unit, laser.color, laser.laser_aim_width * 3, laser.damage_troops, laser.damage, laser.unit.x, laser.unit.y, Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, x, y))
            end
            Helper.Spell.Laser:die(i)
            shoot1:play{volume=0.7}

            laser.unit.last_attack_finished = Helper.Time.time
            Helper.Unit:unclaim_target(laser.unit)
            Helper.Unit:finish_casting(laser.unit)
        end
    end
end

function Helper.Spell.Laser:create_damage(i)
    local laser = Helper.Spell.Laser.list[i]
    if not laser then return end

    local target_x, target_y = Helper.Spell:get_target_nearest_point(laser.unit)
    if x == 0 or y == 0 then
        target_x = laser.target_last_x
        target_y = laser.target_last_y
    end

    local end_x, end_y = 0, 0

    if laser.direction_lock then
        end_x, end_y = Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, laser.unit.x + laser.direction_targetx, laser.unit.y + laser.direction_targety)
    else
        end_x, end_y = Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, target_x, target_y)
    end

    local length = math.sqrt((end_x - laser.unit.x) ^ 2 + (end_y - laser.unit.y) ^ 2)
    Area{group = main.current.main, 
        x = laser.unit.x, y= laser.unit.y,
        w = laser.laser_aim_width * 3, h = length,
        r = math.atan2(laser.direction_targety, laser.direction_targetx),
        color = laser.color,
        dmg = laser.damage,
        parent = laser.unit,
        team = laser.unit.is_troop and 'friend' or 'enemy',
    }
end

function Helper.Spell.Laser:clear_all()
    Helper.Spell.Laser.list = {}
end



function Helper.Spell.Laser:hold_fire(unit)
    local i, laser = find_in_list(Helper.Spell.Laser.list, unit, function(value) return value.unit end)
    if i ~= -1 then
        laser.holding_fire = true
    end
end

function Helper.Spell.Laser:continue_fire(unit)
    local i, laser = find_in_list(Helper.Spell.Laser.list, unit, function(value) return value.unit end)
    if i ~= -1 then
        laser.holding_fire = false
        laser.start_aim_time = Helper.Time.time - 1
    end
end

function Helper.Spell.Laser:stop_aiming(unit)
    local i, laser = find_in_list(Helper.Spell.Laser.list, unit, function(value) return value.unit end)
    if i ~= -1 then
        Helper.Spell.Laser:die(i)
    end
end

function Helper.Spell.Laser:die(i)
    local laser = Helper.Spell.Laser.list[i]
    if laser then
        if laser.charge_sound then
            laser.charge_sound:stop()
        end
        table.remove(Helper.Spell.Laser.list, i)
    end

end
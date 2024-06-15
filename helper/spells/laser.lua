Helper.Spell.Laser = {}
Helper.Spell.Laser.list = {}

function Helper.Spell.Laser:create(args)

    local laser = {
        unit = args.unit,
        start_aim_time = Helper.Time.time,
        cast_time = args.prefire or args.unit.castTime or 1,
        direction_targetx = -1,
        direction_targety = -1,
        direction_lock = args.direction_lock,
        rotation_angle = args.rotation_angle or 0,
        rotation_lock = args.rotation_lock,
        laser_aim_width = args.laser_aim_width or 4,
        color = args.color or blue[0],
        precolor = args.precolor or red[0],
        damage = args.damage or 10,
        damage_troops = not args.unit.is_troop,
        holding_fire = false
    }

    local local_direction_targetx = args.direction_targetx or -1
    local local_direction_targety = args.direction_targety or -1

    if laser.rotation_lock then
        --do nothing?
    elseif laser.direction_lock then
        if local_direction_targetx == -1 and local_direction_targety == -1 then
            local x, y = Helper.Spell:get_target_nearest_point(laser.unit)
            laser.direction_targetx = x - laser.unit.x
            laser.direction_targety = y - laser.unit.y
        elseif local_direction_targetx ~= -1 and local_direction_targety ~= -1 then
            laser.direction_targetx = local_direction_targetx - laser.unit.x
            laser.direction_targety = local_direction_targety - laser.unit.y
        end
    end

    if laser.unit and laser.unit.area_size_m then
        laser.laser_aim_width = laser.laser_aim_width * laser.unit.area_size_m
    end

    if laser.unit.my_target and laser.unit:my_target() then
        laser.target_last_x = laser.unit:my_target().x
        laser.target_last_y = laser.unit:my_target().y
    end

    if laser.damage_troops then
        laser.charge_sound = laser_charging:play{volume=0.4}
    end

    table.insert(Helper.Spell.Laser.list, laser)
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
        love.graphics.setColor(laser.precolor.r, laser.precolor.g, laser.precolor.b, 0.3)
        if laser.rotation_lock then
            local angle = laser.rotation_angle + laser.unit:get_angle()
            love.graphics.line(laser.unit.x, laser.unit.y, Helper.Geometry:move_point(laser.unit.x, laser.unit.y, angle, 500))
        elseif laser.direction_lock then
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
        if laser.unit and laser.unit.mytarget and laser.unit:my_target() then
            laser.target_last_x = laser.unit:my_target().x
            laser.target_last_y = laser.unit:my_target().y
        end

        if not laser.unit or laser.unit.dead then
            Helper.Spell.Laser:die(i)
        end

        if Helper.Time.time - laser.start_aim_time > laser.cast_time and not laser.holding_fire then
            args = {
                unit = laser.unit,
                color = laser.color,
                damage = laser.damage,
                damage_troops = laser.damage_troops,
                width = laser.laser_aim_width * 3,
                x = laser.unit.x,
                y = laser.unit.y,
            }

            if laser.rotation_lock then
                -- local end_x, end_y = Helper.Geometry:move_point(laser.unit.x, laser.unit.y, laser.rotation_angle + laser.unit:get_angle(), 500)
                -- args.end_x = end_x
                -- args.end_y = end_y
                -- Helper.Spell.Laser:create_damage(i, args)
                Helper.Spell.DamageLine:create(laser.unit, laser.color, laser.laser_aim_width * 3, laser.damage_troops, laser.damage, laser.unit.x, laser.unit.y, Helper.Geometry:move_point(laser.unit.x, laser.unit.y, laser.rotation_angle + laser.unit:get_angle(), 500))

            elseif laser.direction_lock then
                Helper.Spell.DamageLine:create(laser.unit, laser.color, laser.laser_aim_width * 3, laser.damage_troops, laser.damage, laser.unit.x, laser.unit.y, Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, laser.unit.x + laser.direction_targetx, laser.unit.y + laser.direction_targety))
                -- local end_x, end_y = Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, laser.unit.x + laser.direction_targetx, laser.unit.y + laser.direction_targety)
                -- args.end_x = end_x
                -- args.end_y = end_y
                -- Helper.Spell.Laser:create_damage(i, args)
            else
                local x, y = Helper.Spell:get_target_nearest_point(laser.unit)
                if x == 0 or y == 0 then
                    x = laser.target_last_x
                    y = laser.target_last_y
                end
                Helper.Spell.DamageLine:create(laser.unit, laser.color, laser.laser_aim_width * 3, laser.damage_troops, laser.damage, laser.unit.x, laser.unit.y, Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, x, y))                
                -- local end_x, end_y = Helper.Spell.Laser:get_end_location(laser.unit.x, laser.unit.y, x, y)
                -- args.end_x = end_x
                -- args.end_y = end_y
                -- Helper.Spell.Laser:create_damage(i, args)
            end
            Helper.Spell.Laser:die(i)
            shoot1:play{volume=0.5}

            laser.unit.last_attack_finished = Helper.Time.time
            Helper.Unit:unclaim_target(laser.unit)
            Helper.Unit:finish_casting(laser.unit)
        end
    end
end

function Helper.Spell.Laser:create_damage(i, args)
    local laser = Helper.Spell.Laser.list[i]
    local x_mid = (args.x + args.end_x) / 2
    local y_mid = (args.y + args.end_y) / 2

    --get the angle of the laser from x and end_x, using x

    Area{group = main.current.main, 
        x = x_mid, y = y_mid,
        w = args.width, h = 500,
        r = 0,
        color = laser.color,
        dmg = laser.damage,
        parent = laser.unit,
        team = laser.unit.is_troop and 'friend' or 'enemy',
        damage_ticks = true,
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
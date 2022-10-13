Helper.Geometry = {}

function Helper.Geometry.get_triangle_from_height_and_width(x, y, xh, yh, height, width)
    local a = math.atan(math.abs(xh - x) / math.abs(yh - y))
    if xh > x and yh > y then
    elseif xh > x and yh < y then a = math.rad(90) - a + math.rad(90)
    elseif xh < x and yh < y then a = a + math.rad(180)
    elseif xh < x and yh > y then a = math.rad(90) - a + math.rad(270) 
    end

    a = math.rad(360) - a

    local unrotatedx2 = - width/2
    local unrotatedy2 = height

    local x2 = unrotatedx2 * math.cos(a) - unrotatedy2 * math.sin(a)
    local y2 = unrotatedx2 * math.sin(a) + unrotatedy2 * math.cos(a)

    x2 = x2 + x
    y2 = y2 + y

    local unrotatedx3 = width/2
    local unrotatedy3 = height

    local x3 = unrotatedx3 * math.cos(a) - unrotatedy3 * math.sin(a)
    local y3 = unrotatedx3 * math.sin(a) + unrotatedy3 * math.cos(a)

    x3 = x3 + x
    y3 = y3 + y

    return x, y, x2, y2, x3, y3
end

function Helper.Geometry.is_inside_triangle(x0, y0, x1, y1, x2, y2, x3, y3)
    local function sign (p1, p2, p3)
        return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
    end

    local function is_inside_triangle(pt, v1, v2, v3)
        local d1, d2, d3;
        local has_neg, has_pos;

        d1 = sign(pt, v1, v2);
        d2 = sign(pt, v2, v3);
        d3 = sign(pt, v3, v1);

        if d1 < 0 or d2 < 0 or d3 < 0 then
            has_neg = true
        end
        if d1 > 1 or d2 > 0 or d3 > 0 then
            has_pos = true
        end

        local result = true
        if has_neg == true and has_pos == true then
            result = false
        end

        return result
    end

    return is_inside_triangle({x = x0, y = y0}, {x = x1, y = y1}, {x = x2, y = y2}, {x = x3, y = y3})
end



function Helper.Geometry.distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end



function Helper.Geometry.random_in_radius(x, y, radius)
    local newx = -10000
    local newy = -10000

    while Helper.Geometry.distance(x, y, newx, newy) > radius do
        newx = get_random(x - radius, x + radius)
        newy = get_random(y - radius, y + radius)
    end

    return newx, newy
end



function Helper.Geometry.distance_from_line(x, y, linex1, liney1, linex2, liney2)
    local a = (liney2 - liney1) / (linex2 - linex1)
    local b = -1
    local c = -a * linex1 + liney1

    return math.abs(a*x + b*y + c) / math.sqrt(a^2 + b^2)
end

function Helper.Geometry.get_point_on_line(x, y, linex1, liney1, linex2, liney2)
    local a = (liney2 - liney1) / (linex2 - linex1)
    local b = -1
    local c = -a * linex1 + liney1

    return (b^2*x - a*b*y - a*c) / (a^2 + b^2), (a^2*y - a*b*x - b*c) / (a^2 + b^2)
end

function point_on_line_is_part_of_line(x, y, linex1, liney1, linex2, liney2)
    local pointx = 0
    local pointy = 0
    pointx, pointy = Helper.Geometry.get_point_on_line(x, y, linex1, liney1, linex2, liney2)

    return Helper.Geometry.is_inside_rectangle(pointx, pointy, linex1, liney1, linex2, liney2)
end

function Helper.Geometry.is_on_line(x, y, linex1, liney1, linex2, liney2, line_width)
    if Helper.Geometry.distance_from_line(x, y, linex1, liney1, linex2, liney2) < line_width / 2
    and point_on_line_is_part_of_line(x, y, linex1, liney1, linex2, liney2) then
        return true
    else
        return false
    end
end



function Helper.Geometry.is_inside_rectangle(x, y, pointx1, pointy1, pointx2, pointy2)
    local result = true

    if pointx1 > pointx2 then
        if x > pointx1 or x < pointx2 then
            result = false
        end
    else
        if x < pointx1 or x > pointx2 then
            result = false
        end
    end

    if pointy1 > pointy2 then
        if y > pointy1 or y < pointy2 then
            result = false
        end
    else
        if y < pointy1 or y > pointy2 then
            result = false
        end
    end

    return result
end



function Helper.Geometry.rotate_point(x, y, centerx, centery, angle)
    angle = math.rad(angle)
    x = x - centerx
    y = y - centery
    local rotatedx = x * math.cos(angle) - y * math.sin(angle) + centerx
    local rotatedy = x * math.sin(angle) + y * math.cos(angle) + centery

    return rotatedx, rotatedy
end



function Helper.Geometry.get_angle(centerx, centery, x1, y1, x2, y2)
    local vec1x = x1 - centerx
    local vec1y = y1 - centery
    local vec2x = x2 - centerx
    local vec2y = y2 - centery
    local dot_product =  vec1x * vec2x + vec1y * vec2y
    local determinant =  vec1x * vec2y - vec1y * vec2x
    local angle = math.deg(math.atan2(determinant, dot_product))
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

function Helper.Geometry.rotate_to(centerx, centery, fromx, fromy, tox, toy, speed)
    local angle = Helper.Geometry.get_angle(centerx, centery, fromx, fromy, tox, toy)
    if angle > 0.25 and angle < 359.75 then
        if angle > 180 then
            local a = 360 - angle
            if a > 90 then
                a = 180 - a
            end
            speed = speed * math.sqrt(a) / math.sqrt(90)
            return Helper.Geometry.rotate_point(fromx, fromy, centerx, centery, -Helper.Time.delta_time*speed)
        else
            local a = angle
            if a > 90 then
                a = 180 - a
            end
            speed = speed * math.sqrt(a) / math.sqrt(90)
            return Helper.Geometry.rotate_point(fromx, fromy, centerx, centery, Helper.Time.delta_time*speed)
        end
    else
        return tox, toy
    end
end

function Helper.Geometry.move_point(x, y, angle, amount)
    local x2 = x + (amount * math.cos(angle))
    local y2 = y + (amount * math.sin(angle))
    return x2, y2
end

function Helper.Geometry.is_off_screen(x, y, angle, radius)
    local x2, y2 = Helper.Geometry.move_point(x, y, angle, radius)
    if x2 > gw or x2 < 0 or y2 > gh or y2 < 0 then
        return true
    else
        return false
    end
end

function Helper.Geometry.get_arena_rect(index, total)
    local aw = gw - (2 * SpawnGlobals.wall_width)
    local ah = gh - (2 * SpawnGlobals.wall_height)
    local x_offset = (aw * 1.0) / total
    local y_offset = (ah * 1.0) / total

    local x = SpawnGlobals.wall_width
    local y = SpawnGlobals.wall_height + (y_offset * (index - 1))

    return x, y, aw, y_offset
end
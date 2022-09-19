function get_triangle_from_height_and_width(x, y, xh, yh, height, width)
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

function draw_triangle_from_height_and_width(x, y, xh, yh, height, width)
    local x1, y1, x2, y2, x3, y3 = get_triangle_from_height_and_width(x, y, xh, yh, height, width)
    love.graphics.polygon( 'fill', x1, y1, x2, y2, x3, y3)
end

function is_inside_triangle(x0, y0, x1, y1, x2, y2, x3, y3)
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



function distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end



function random_in_radius(x, y, radius)
    local newx = -10000
    local newy = -10000

    while distance(x, y, newx, newy) > radius do
        newx = math.random(x - radius, x + radius)
        newy = math.random(y - radius, y + radius)
    end

    return newx, newy
end



function distance_from_line(x, y, linex1, liney1, linex2, liney2)
    local a = (liney2 - liney1) / (linex2 - linex1)
    local b = -1
    local c = -a * linex1 + liney1

    return math.abs(a*x + b*y + c) / math.sqrt(a^2 + b^2)
end

function get_point_on_line(x, y, linex1, liney1, linex2, liney2)
    local a = (liney2 - liney1) / (linex2 - linex1)
    local b = -1
    local c = -a * linex1 + liney1

    return (b^2*x - a*b*y - a*c) / (a^2 + b^2), (a^2*y - a*b*x - b*c) / (a^2 + b^2)
end

function point_on_line_is_part_of_line(x, y, linex1, liney1, linex2, liney2)
    local pointx = 0
    local pointy = 0
    pointx, pointy = get_point_on_line(x, y, linex1, liney1, linex2, liney2)

    return is_inside_rectangle(pointx, pointy, linex1, liney1, linex2, liney2)
end

function is_on_line(x, y, linex1, liney1, linex2, liney2, line_width)
    if distance_from_line(x, y, linex1, liney1, linex2, liney2) < line_width / 2
    and point_on_line_is_part_of_line(x, y, linex1, liney1, linex2, liney2) then
        return true
    else
        return false
    end
end



function is_inside_rectangle(x, y, pointx1, pointy1, pointx2, pointy2)
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



function rotate_point(x, y, centerx, centery, angle)
    angle = math.rad(angle)
    x = x - centerx
    y = y - centery
    local rotatedx = x * math.cos(angle) - y * math.sin(angle) + centerx
    local rotatedy = x * math.sin(angle) + y * math.cos(angle) + centery

    return rotatedx, rotatedy
end
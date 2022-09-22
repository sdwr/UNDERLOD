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

function Helper.Geometry.draw_triangle_from_height_and_width(x, y, xh, yh, height, width)
    local x1, y1, x2, y2, x3, y3 = Helper.Geometry.get_triangle_from_height_and_width(x, y, xh, yh, height, width)
    love.graphics.polygon( 'fill', x1, y1, x2, y2, x3, y3)
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

    return Helper.Geometry.is_inside_triangle({x = x0, y = y0}, {x = x1, y = y1}, {x = x2, y = y2}, {x = x3, y = y3})
end



function Helper.Geometry.distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end



function Helper.Geometry.random_in_radius(x, y, radius)
    local newx = -10000
    local newy = -10000

    while Helper.Geometry.distance(x, y, newx, newy) > radius do
        newx = math.random(x - radius, x + radius)
        newy = math.random(y - radius, y + radius)
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



function Helper.Geometry.draw_dashed_line(line_width, dash_length, dash_margin, dash_offset_percentage, x1, y1, x2, y2)
    local function line_end_check(drawx, drawy, x1, y1, x2, y2)
        if x2 == x1 and y2 == y1 then
            return true
        elseif x2 == x1 then
            if y2 > y1 then
                return drawy > y2
            else
                return drawy < y2
            end
        elseif y2 == y1 then
            if x2 > x1 then
                return drawx > x2
            else
                return drawx < x2
            end
        else
            if x2 > x1 and y2 > y1 then
                return drawx > x2 and drawy > y2
            elseif x2 > x1 and y2 < y1 then
                return drawx > x2 and drawy < y2
            elseif x2 < x1 and y2 > y1 then
                return drawx < x2 and drawy > y2
            elseif x2 < x1 and y2 < y1 then
                return drawx < x2 and drawy < y2
            end
        end
    end
    
    local xdivy = 0
    local drawx = x1
    local drawy = y1
    local dash = true
    local dash_lengthy = 0
    local dash_lengthx = 0
    local dash_marginy = 0
    local dash_marginx = 0

    if y2 - y1 ~= 0 then
        xdivy = math.abs((x2 - x1) / (y2 - y1))
        dash_lengthy = math.sqrt((dash_length^2) / (xdivy^2 + 1))
        dash_lengthx = dash_lengthy * xdivy
        dash_marginy = math.sqrt((dash_margin^2) / (xdivy^2 + 1))
        dash_marginx = dash_marginy * xdivy
    else
        dash_lengthy = 0
        dash_lengthx = dash_length
        dash_marginy = 0
        dash_marginx = dash_margin
    end

    love.graphics.setLineWidth(line_width)

    if x2 < x1 then 
        dash_lengthx = -dash_lengthx 
        dash_marginx = -dash_marginx
    end
    if y2 < y1 then 
        dash_lengthy = -dash_lengthy 
        dash_marginy = -dash_marginy
    end

    dash_offset_percentage = math.fmod(dash_offset_percentage, 100)
    local dash_offset_length = (dash_length + dash_margin) * dash_offset_percentage / 100
    if dash_offset_length <= dash_margin then
        local dash_offset_lengthy = math.sqrt((dash_offset_length^2) / (xdivy^2 + 1))
        local dash_offset_lengthx = dash_offset_lengthy * xdivy
        if y1 == y2 then 
            dash_offset_lengthx = dash_offset_length 
            dash_offset_lengthy = 0
        end
        if x2 > x1 then 
            drawx = drawx + dash_offset_lengthx 
        elseif x2 < x1 then
            drawx = drawx - dash_offset_lengthx 
        end
        if y2 > y1 then
            drawy = drawy + dash_offset_lengthy
        elseif y2 < y1 then
            drawy = drawy - dash_offset_lengthy            
        end
    else
        dash_offset_length = dash_offset_length - dash_margin
        local dash_offset_lengthy = math.sqrt((dash_offset_length^2) / (xdivy^2 + 1))
        local dash_offset_lengthx = dash_offset_lengthy * xdivy
        if y1 == y2 then 
            dash_offset_lengthx = dash_offset_length 
            dash_offset_lengthy = 0
        end
        
        if x2 < x1 then dash_offset_lengthx = -dash_offset_lengthx end
        if y2 < y1 then dash_offset_lengthy = -dash_offset_lengthy end

        love.graphics.line(drawx, drawy, drawx + dash_offset_lengthx, drawy + dash_offset_lengthy)
        drawx = drawx + dash_offset_lengthx
        drawy = drawy + dash_offset_lengthy

        drawx = drawx + dash_marginx
        drawy = drawy + dash_marginy
    end

    local i = 0
    while i < 10000 do
        if dash then
            if line_end_check(drawx + dash_lengthx, drawy + dash_lengthy, x1, y1, x2, y2) then
                love.graphics.line(drawx, drawy, x2, y2)
                break
            end
            love.graphics.line(drawx, drawy, drawx + dash_lengthx, drawy + dash_lengthy)
            drawx = drawx + dash_lengthx
            drawy = drawy + dash_lengthy
            dash = false
        else
            if line_end_check(drawx + dash_marginx, drawy + dash_marginy, x1, y1, x2, y2) then
                break
            end
            drawx = drawx + dash_marginx
            drawy = drawy + dash_marginy
            dash = true
        end

        i = i + 1
        if i == 10000 then
            print('infinity loop in draw_dashed_line')
        end
    end

    love.graphics.setLineWidth(1)
end

function Helper.Geometry.draw_dashed_rectangle(x1, y1, x2, y2)
    Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, x1, y1, x2, y1)
    Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, x2, y1, x2, y2)
    Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, x2, y2, x1, y2)
    Helper.Geometry.draw_dashed_line(3, 10, 5, love.timer.getTime() * 80, x1, y2, x1, y1)
end
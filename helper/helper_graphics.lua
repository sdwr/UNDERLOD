Helper.Graphics = {}

function Helper.Graphics:draw_triangle_from_height_and_width(x, y, xh, yh, height, width)
    local x1, y1, x2, y2, x3, y3 = Helper.Geometry:get_triangle_from_height_and_width(x, y, xh, yh, height, width)
    love.graphics.polygon( 'fill', x1, y1, x2, y2, x3, y3)
end

function Helper.Graphics:draw_dashed_line(color, line_width, dash_length, dash_margin, dash_offset_percentage, x1, y1, x2, y2)
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
    love.graphics.setColor(color.r, color.g, color.b, color.a)

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

function Helper.Graphics:draw_dashed_rectangle(color, line_width, dash_length, dash_margin, dash_offset_percentage, x1, y1, x2, y2)
    if math.abs(x2 - x1) > dash_length + dash_margin then
        Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(color, 0.3), line_width, dash_length, dash_margin, dash_offset_percentage, x1, y1, x2, y1)
        Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(color, 0.3), line_width, dash_length, dash_margin, dash_offset_percentage, x2, y2, x1, y2)
    end
    if math.abs(y2 - y1) > dash_length + dash_margin then
        Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(color, 0.3), line_width, dash_length, dash_margin, dash_offset_percentage, x2, y1, x2, y2)
        Helper.Graphics:draw_dashed_line(Helper.Color:set_transparency(color, 0.3), line_width, dash_length, dash_margin, dash_offset_percentage, x1, y2, x1, y1)
    end
        love.graphics.setColor(color.r, color.g, color.b, 1)
    love.graphics.setLineWidth(line_width)
    if x1 > x2 then
        local x3 = x1
        x1 = x2
        x2 = x3
    end
    if y1 > y2 then
        local y3 = y1
        y1 = y2
        y2 = y3
    end
    local corner_lengthx = dash_length > x2 - x1 and x2 - x1 or dash_length
    local corner_lengthy = dash_length > y2 - y1 and y2 - y1 or dash_length
    local cornerx1 = x1 - line_width / 2
    local cornery1 = y1 - line_width / 2
    local cornerx2 = x2 + line_width / 2
    local cornery2 = y2 + line_width / 2
    love.graphics.line(cornerx1, y1, cornerx1 + corner_lengthx, y1)
    love.graphics.line(x1, cornery1, x1, cornery1 + corner_lengthy)
    love.graphics.line(cornerx2, y1, cornerx2 - corner_lengthx, y1)
    love.graphics.line(x2, cornery1, x2, cornery1 + corner_lengthy)
    love.graphics.line(cornerx2, y2, cornerx2 - corner_lengthx, y2)
    love.graphics.line(x2, cornery2, x2, cornery2 - corner_lengthy)
    love.graphics.line(cornerx1, y2, cornerx1 + corner_lengthx, y2)
    love.graphics.line(x1, cornery2, x1, cornery2 - corner_lengthy)
end



Helper.Graphics.particles = {}

function Helper.Graphics:create_particle(color, size, x, y, speed, travel_time, directionx, directiony, random)
    local particle = {
        x = x,
        y = y,
        speed = speed,
        creation_time = Helper.Time.time,
        travel_time = travel_time,
        directionx = directionx,
        directiony = directiony,
        random = random,
        color = color,
        size = size
    }

    local unitvx = particle.directionx / math.sqrt(particle.directionx^2 + particle.directiony^2)
    local unitvy = particle.directiony / math.sqrt(particle.directionx^2 + particle.directiony^2)
    unitvx, unitvy = Helper.Geometry:rotate_point(unitvx, unitvy, 0, 0, get_random(-random/2, random/2))
    particle.directionx = unitvx
    particle.directiony = unitvy

    table.insert(Helper.Graphics.particles, particle)
end

function Helper.Graphics:update_particles()
    for i = #Helper.Graphics.particles, 1, -1 do
        local particle = Helper.Graphics.particles[i]
        if Helper.Time.time - particle.creation_time > particle.travel_time then
            table.remove(Helper.Graphics.particles, i)
        end
        -- local t = Helper.Time.time - particle.creation_time
        -- if t > particle.travel_time / 2 then
        --     t = particle.travel_time - t
        -- end
        -- local current_speed = particle.speed * t / (particle.travel_time / 2)
        local current_speed = particle.speed * (particle.travel_time - (Helper.Time.time - particle.creation_time)) / particle.travel_time
        particle.x = particle.x + particle.directionx * current_speed * Helper.Time.delta_time
        particle.y = particle.y + particle.directiony * current_speed * Helper.Time.delta_time
    end
end

function Helper.Graphics:draw_particles()
    for i, particle in ipairs(Helper.Graphics.particles) do
        love.graphics.setColor(particle.color.r, particle.color.g, particle.color.b, particle.color.a)
        love.graphics.circle('fill', particle.x, particle.y, particle.size)
    end
end



Helper.Graphics.inward_circles = {}

function Helper.Graphics:create_inward_circle(x, y, color, radius, speed)
    local inward_circle = {
        x = x,
        y = y,
        color = color,
        start_time = Helper.Time.time,
        radius = radius,
        speed = speed
    }

    table.insert(self.inward_circles, inward_circle)
end

function Helper.Graphics:update_inward_circles()
    for i = #self.inward_circles, 1, -1 do
        local current_radius = self.inward_circles[i].radius - (Helper.Time.time - self.inward_circles[i].start_time)*self.inward_circles[i].speed
        if current_radius <= 0 then
            table.remove(self.inward_circles, i)
            break
        end
    end
end

function Helper.Graphics:draw_inward_circles()
    for i = #self.inward_circles, 1, -1 do
        local current_radius = self.inward_circles[i].radius - (Helper.Time.time - self.inward_circles[i].start_time)*self.inward_circles[i].speed
        local current_radius_percentage = current_radius/self.inward_circles[i].radius * 100
        local alpha = 1
        if current_radius_percentage > 40 then
            alpha = 1 - ((current_radius_percentage - 40) / 60)
        end
        if current_radius > 0 then
            love.graphics.setLineWidth(1.5)
            love.graphics.setColor(self.inward_circles[i].color.r, self.inward_circles[i].color.g, 
                                    self.inward_circles[i].color.b, alpha)
            love.graphics.circle('line', self.inward_circles[i].x, self.inward_circles[i].y, current_radius)
        end
    end
end



Helper.Graphics.damage_numbers = {}
Helper.Graphics.fly_up_damage_numbers = false
Helper.Graphics.show_damage_numbers = true

function Helper.Graphics:create_damage_number(x, y, number, rotation)
    if self.show_damage_numbers then
        local damage_number_overlap = false
        repeat
            damage_number_overlap = false
            for i, damage_number in ipairs(self.damage_numbers) do
                if Helper.Geometry:is_inside_rectangle(x, y, damage_number.x - 7, damage_number.y - 7, damage_number.x + 7, damage_number.y + 7)
                and Helper.Time.time - damage_number.start_time < 0.15 then
                    damage_number_overlap = true
                    break
                end
            end

            if damage_number_overlap then
                local add_positive_value = math.random(0, 1)
                if add_positive_value == 0 then
                    x = x - get_random(7, 10)
                else
                    x = x + get_random(7, 10)
                end

                add_positive_value = math.random(0, 1)
                if add_positive_value == 0 then
                    y = y - get_random(7, 10)
                else
                    y = y + get_random(7, 10)
                end
            end
        until not damage_number_overlap

        local damage_number = {
            x = x,
            y = y,
            number = number,
            start_time = Helper.Time.time,
            rotation = rotation
        }

        table.insert(self.damage_numbers, damage_number)
    end
end

function Helper.Graphics:update_damage_numbers()
    for i = #self.damage_numbers, 1, -1 do
        if self.fly_up_damage_numbers then
            self.damage_numbers[i].y = self.damage_numbers[i].y - Helper.Time.delta_time * 18
        end
        if Helper.Time.time - self.damage_numbers[i].start_time > 1 then
            table.remove(self.damage_numbers, i)
        end
    end
end

function Helper.Graphics:draw_damage_numbers()
    for i, damage_number in ipairs(self.damage_numbers) do
        local alpha = ((1 - (Helper.Time.time - damage_number.start_time)) * 3)
        if alpha > 1 then
            alpha = 1
        end
        alpha = alpha * 0.95
        Helper.Color:set_color(Helper.Color:set_transparency(Helper.Color.red, alpha))
        graphics.print_centered(tostring(damage_number.number), pixul_font, damage_number.x, damage_number.y, math.rad(damage_number.rotation))
    end
end
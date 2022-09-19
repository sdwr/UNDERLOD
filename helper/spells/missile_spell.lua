missile_speed = 300
missile_length = 10
missile_width = 3
missile_explode_range = 10
missiles = {}

function create_missile(x, y, targetx, targety)
    local missile = {
        x = x,
        y = y,
        targetx = targetx,
        targety = targety
    }

    table.insert(missiles, missile)
end

function draw_missiles()
    for i, missile in ipairs(missiles) do
        local xdivy = 0
        local deltax = 0
        local deltay = 0
        if missile.targety - missile.y ~= 0 then
            xdivy = (missile.targetx - missile.x) / (missile.targety - missile.y)
            deltay = math.sqrt(((missile_length/2)^2) / (xdivy^2 + 1))
            deltax = deltay * xdivy
        else
            deltay = 0
            deltax = missile_length / 2
        end
    
        love.graphics.setLineWidth(missile_width)
        love.graphics.line(missile.x - deltax, missile.y - deltay, missile.x + deltax, missile.y + deltay)
        love.graphics.setLineWidth(1)
    end
end

function update_missile_pos()
    for i, missile in ipairs(missiles) do
        local xdivy = 0
        local deltax = 0
        local deltay = 0
        if missile.targety - missile.y ~= 0 then
            xdivy = (missile.targetx - missile.x) / (missile.targety - missile.y)
            deltay = math.sqrt((((missile_speed * delta_time)/2)^2) / (xdivy^2 + 1))
            deltax = deltay * xdivy
        else
            deltay = 0
            deltax = (missile_speed * delta_time) / 2
        end

        if missile.targety - missile.y > 0 then
            missile.x = missile.x + deltax
            missile.y = missile.y + deltay
        elseif missile.targety - missile.y < 0 then
            missile.x = missile.x - deltax
            missile.y = missile.y - deltay
        else
            if missile.targetx - missile.x > 0 then
                missile.x = missile.x + deltax
            else
                missile.x = missile.x - deltax
            end
        end
    end
end

function missile_explode()
    for i, missile in ipairs(missiles) do
        if distance(missile.x, missile.y, missile.targetx, missile.targety) < missile_explode_range then
            create_damage_circle(missile.targetx, missile.targety)
            table.remove(missiles, i)
            shoot1:play{volume=0.9}
        end
    end
end
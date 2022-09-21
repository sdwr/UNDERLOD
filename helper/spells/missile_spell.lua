Helper.Spell.Missile = {}

Helper.Spell.Missile.speed = 300
Helper.Spell.Missile.length = 10
Helper.Spell.Missile.width = 3
Helper.Spell.Missile.explode_range = 10
Helper.Spell.Missile.list = {}

function Helper.Spell.Missile.create(x, y, targetx, targety)
    local missile = {
        x = x,
        y = y,
        targetx = targetx,
        targety = targety
    }

    table.insert(Helper.Spell.Missile.list, missile)
end

function Helper.Spell.Missile.draw()
    for i, missile in ipairs(Helper.Spell.Missile.list) do
        local xdivy = 0
        local deltax = 0
        local deltay = 0
        if missile.targety - missile.y ~= 0 then
            xdivy = (missile.targetx - missile.x) / (missile.targety - missile.y)
            deltay = math.sqrt(((Helper.Spell.Missile.length/2)^2) / (xdivy^2 + 1))
            deltax = deltay * xdivy
        else
            deltay = 0
            deltax = Helper.Spell.Missile.length / 2
        end
    
        love.graphics.setLineWidth(Helper.Spell.Missile.width)
        love.graphics.line(missile.x - deltax, missile.y - deltay, missile.x + deltax, missile.y + deltay)
        love.graphics.setLineWidth(1)
    end
end

function Helper.Spell.Missile.update_position()
    for i, missile in ipairs(Helper.Spell.Missile.list) do
        local xdivy = 0
        local deltax = 0
        local deltay = 0
        if missile.targety - missile.y ~= 0 then
            xdivy = (missile.targetx - missile.x) / (missile.targety - missile.y)
            deltay = math.sqrt((((Helper.Spell.Missile.speed * Helper.Time.delta_time)/2)^2) / (xdivy^2 + 1))
            deltax = deltay * xdivy
        else
            deltay = 0
            deltax = (Helper.Spell.Missile.speed * Helper.Time.delta_time) / 2
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

function Helper.Spell.Missile.explode()
    for i, missile in ipairs(Helper.Spell.Missile.list) do
        if Helper.Geometry.distance(missile.x, missile.y, missile.targetx, missile.targety) < Helper.Spell.Missile.explode_range then
            Helper.Spell.DamageCircle.create(false, missile.targetx, missile.targety)
            table.remove(Helper.Spell.Missile.list, i)
            shoot1:play{volume=0.9}
        end
    end
end
Helper.Spell.Missile = {}

Helper.Spell.Missile.speed = 300
Helper.Spell.Missile.list = {}

function Helper.Spell.Missile.create(color, missile_length, damage_troops, damage, fly_infinitely, explode_radius, x, y, targetx, targety)
    local missile = {
        x = x,
        y = y,
        targetx = targetx,
        targety = targety,
        fly_infinitely = fly_infinitely,
        color = color,
        missile_length = missile_length,
        missile_width = missile_length / 3,
        explode_radius = explode_radius,
        damage_troops = damage_troops,
        damage = damage
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
            deltay = math.sqrt(((missile.missile_length/2)^2) / (xdivy^2 + 1))
            deltax = deltay * xdivy
        else
            deltay = 0
            deltax = missile.missile_length / 2
        end
    
        love.graphics.setLineWidth(missile.missile_width)
        love.graphics.setColor(missile.color.r, missile.color.g, missile.color.b, missile.color.a)
        love.graphics.line(missile.x - deltax, missile.y - deltay, missile.x + deltax, missile.y + deltay)
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
        if not missile.fly_infinitely then
            if Helper.Geometry.distance(missile.x, missile.y, missile.targetx, missile.targety) < missile.missile_length / 3 then
                Helper.Spell.DamageCircle.create(missile.color, missile.damage_troops, missile.damage, missile.explode_radius, missile.x, missile.y)
                table.remove(Helper.Spell.Missile.list, i)
                shoot1:play{volume=0.9}
            end
        else
            local entities = {}
            if not missile.damage_troops then
                entities = main.current.main:get_objects_by_classes(main.current.enemies)
            else
                entities = main.current.main:get_objects_by_class(Troop)
            end
            for _, entity in ipairs(entities) do
                if Helper.Geometry.distance(missile.x, missile.y, entity.x, entity.y) < missile.missile_length / 3 then
                    Helper.Spell.DamageCircle.create(missile.color, missile.damage_troops, missile.damage, missile.explode_radius, missile.x, missile.y)
                    table.remove(Helper.Spell.Missile.list, i)
                    shoot1:play{volume=0.9}
                    break
                end 
            end

            if Helper.window_width - missile.x < missile.missile_length / 3 or missile.x <= missile.missile_length / 3 
            or Helper.window_height - missile.y < missile.missile_length / 3 or missile.y <= missile.missile_length / 3 then
                Helper.Spell.DamageCircle.create(missile.color, missile.damage_troops, missile.damage, missile.explode_radius, missile.x, missile.y)
                table.remove(Helper.Spell.Missile.list, i)
                shoot1:play{volume=0.9}
            end
        end
    end
end
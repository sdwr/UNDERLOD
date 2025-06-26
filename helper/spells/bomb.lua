Helper.Spell.Bomb = {}

Helper.Spell.Bomb.list = {}
Helper.Spell.Bomb.prelist = {}

function Helper.Spell.Bomb:create(color, damage_troops, damage, radius, unit, armed_duration, explode_radius, x, y)

    damage = get_dmg_value(damage)
    local bomb = {
        x = x,
        y = y,
        cast_time = unit.castTime or 0,
        start_aim_time = Helper.Time.time,
        start_armed_time = 0,
        unit = unit,
        color = color,
        radius = radius or 4,
        armed_duration = armed_duration or 1.5,
        explode_radius = explode_radius,
        damage_troops = damage_troops,
        damage = damage
    }

    if unit and unit.area_size_m then
        bomb.explode_radius = bomb.explode_radius * unit.area_size_m
    end

    Helper.Unit:start_casting(unit)
    table.insert(Helper.Spell.Bomb.prelist, bomb)
end

function Helper.Spell.Bomb:draw()
    for i, bomb in ipairs(Helper.Spell.Bomb.list) do

        love.graphics.setColor(bomb.color.r, bomb.color.g, bomb.color.b, bomb.color.a)
        love.graphics.circle("fill", bomb.x, bomb.y, bomb.radius)
        local olc = grey[-5]
        love.graphics.setColor(olc.r, olc.g, olc.b, olc.a)
        love.graphics.circle("line", bomb.x, bomb.y, bomb.radius)
    end
end

function Helper.Spell.Bomb:shoot()
    --move to active list if ready to cast
    for i, bomb in ipairs(Helper.Spell.Bomb.prelist) do
        if Helper.Spell:can_shoot(bomb) then
            bomb.start_armed_time = Helper.Time.time
            table.insert(Helper.Spell.Bomb.list, bomb)
            table.remove(Helper.Spell.Bomb.prelist, i)

            Helper.Unit:unclaim_target(bomb.unit)
            Helper.Unit:finish_casting(bomb.unit)
        end
    end
end

function Helper.Spell.Bomb:update()
    Helper.Spell.Bomb:shoot()
    Helper.Spell.Bomb:explode()
end

function Helper.Spell.Bomb:explode()
    for i = #Helper.Spell.Bomb.list, 1, -1 do
        local bomb = Helper.Spell.Bomb.list[i]
        if Helper.Time.time - bomb.armed_duration > bomb.start_armed_time then
            Helper.Spell.DamageCircle:create(bomb.unit, bomb.color, bomb.damage_troops,
                bomb.damage, bomb.explode_radius, bomb.x, bomb.y)
            table.remove(Helper.Spell.Bomb.list, i)
            cannoneer1:play{volume=1.3}
        end
    end
end

function Helper.Spell.Bomb:stop_aiming(unit)
    local i, bomb = find_in_list(Helper.Spell.Bomb.prelist, unit, function(value) return value.unit end)
    if i ~= -1 then
        table.remove(Helper.Spell.Bomb.prelist, i)
    end
end

function Helper.Spell.Bomb:clear_all()
    Helper.Spell.Bomb.prelist = {}
    Helper.Spell.Bomb.list = {}
end
Helper.Spell.SafetyDance = {}

Helper.Spell.SafetyDance.prelist = {}
Helper.Spell.SafetyDance.list = {}

Helper.Spell.SafetyDance.index = 1
Helper.Spell.SafetyDance.chargeTime = 3
Helper.Spell.SafetyDance.duration = 0.37

--width in degrees
function Helper.Spell.SafetyDance:create(unit, color, damage_troops, damage, x, y, w, h)
    local spell = {
        unit = unit,
        x = x,
        y = y,
        w = w,
        h = h,
        creation_time = Helper.Time.time,
        damage_troops = damage_troops,
        color = Helper.Color:set_transparency(color, 0.8),
        -- line_width = radius / 15,
        damage = damage,
        tick_rate = 0.1,
        next_tick = Helper.Time.time,
    }

    spell.targets_hit = {}

    table.insert(Helper.Spell.SafetyDance.prelist, spell)
end

function Helper.Spell.SafetyDance:create_all(unit, color, damage_troops, pattern, total, damage)

    --set unit state
    Helper.Unit:set_state(unit, unit_states['frozen'])
    trigger:after(Helper.Spell.SafetyDance.chargeTime, function() 
        if unit and unit.state == unit_states['frozen'] then
            Helper.Unit:set_state(unit, unit_states['normal'])
        end
    end)

    if pattern == 'one_safe' then
        for i = 1, total do
            if i ~= Helper.Spell.SafetyDance.index then
                local x, y, w, h = Helper.Geometry:get_arena_rect(i, total)
                Helper.Spell.SafetyDance:create(unit, color, damage_troops, damage,
                    x, y, w, h)
                glass_shatter:play{volume = 0.6}
            end
        end
    end

    Helper.Spell.SafetyDance.index = (Helper.Spell.SafetyDance.index + 1) % (total + 1)
    if Helper.Spell.SafetyDance.index == 0 then
        Helper.Spell.SafetyDance.index = 1
    end
end

function Helper.Spell.SafetyDance:draw_aims()
    for i, spell in ipairs(Helper.Spell.SafetyDance.prelist) do
        local pctCharged = (Helper.Time.time - spell.creation_time) / Helper.Spell.SafetyDance.chargeTime
        local alpha = pctCharged * 0.4
        local color = Helper.Color:clone(spell.color)
        color.a = alpha
        graphics.push(spell.x, spell.y, 0, 1, 1)
        graphics.rectangle(spell.x, spell.y, spell.w, spell.h, 0, 0, color, 1)
        graphics.rectangle(spell.x, spell.y, spell.w - 10, spell.h - 10, 0, 0, color)
        graphics.pop()
    end
end

function Helper.Spell.SafetyDance:draw()
    for i, spell in ipairs(Helper.Spell.SafetyDance.list) do
        graphics.push(spell.x, spell.y, 0, 1, 1)
        graphics.rectangle(spell.x, spell.y, spell.w, spell.h, 0, 0, spell.color)
        graphics.pop()
    end
end

function Helper.Spell.SafetyDance:update()
    Helper.Spell.SafetyDance:activate()
    Helper.Spell.SafetyDance:damage()
    Helper.Spell.SafetyDance:delete()
end

function Helper.Spell.SafetyDance:activate()
    for i, spell in ipairs(Helper.Spell.SafetyDance.prelist) do
        if Helper.Time.time - Helper.Spell.SafetyDance.chargeTime > spell.creation_time then
            table.insert(Helper.Spell.SafetyDance.list, spell)
            table.remove(Helper.Spell.SafetyDance.prelist, i)
            earth1:play{volume = 0.7}
        end
    end
end

function Helper.Spell.SafetyDance:getRect(spell)
    return spell.x, spell.y, spell.w, spell.h
end

function Helper.Spell.SafetyDance:damage()
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    local troops = main.current.main:get_objects_by_classes(main.current.friendlies)

    for i, spell in ipairs(Helper.Spell.SafetyDance.list) do
        --process tick
        if spell.next_tick < Helper.Time.time then
            Helper.Spell.SafetyDance:hit(spell)
            spell.next_tick = Helper.Time.time + spell.tick_rate
        end
    end
end

function Helper.Spell.SafetyDance:hit(spell)
        --the rect isnt working
    local x, y, w, h = Helper.Spell.SafetyDance:getRect(spell)
    local rect = Rectangle(x, y, w, h)
    local targets = nil
    if not spell.damage_troops then
        targets = main.current.main:get_objects_in_shape(rect, main.current.enemies)

    else
        targets = main.current.main:get_objects_in_shape(rect, main.current.friendlies)
    end
    for _, target in ipairs(targets) do
        target:hit(spell.damage, spell.unit)
        table.insert(spell.targets_hit, target)

        HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = blue[0]} end
        for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
    end
end

function Helper.Spell.SafetyDance:delete()
    for i = #Helper.Spell.SafetyDance.list, 1, -1 do
        local spell = Helper.Spell.SafetyDance.list[i]
        if (Helper.Time.time - Helper.Spell.SafetyDance.chargeTime) - 
        Helper.Spell.SafetyDance.duration > spell.creation_time then
            table.remove(Helper.Spell.SafetyDance.list, i)
        end
    end
end
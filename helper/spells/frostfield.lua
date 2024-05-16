Helper.Spell.Frostfield = {}

Helper.Spell.Frostfield.duration = 0.5

Helper.Spell.Frostfield.list = {}
Helper.Spell.Frostfield.prelist = {}

function Helper.Spell.Frostfield:create(unit, color, damage_troops, damage, radius, duration, x, y)

    local frostfield = {
        unit = unit,
        x = x,
        y = y,
        creation_time = Helper.Time.time,
        damage_dealt = false,
        damage_troops = damage_troops,
        color
    }

    --set
    frostfield.start_time = Helper.Time.time
    table.insert(Helper.Spell.Frostfield.list, frostfield)

end

function Helper.Spell.Frostfield:draw()
    for i, frostfield in ipairs(Helper.Spell.Frostfield.list) do
        love.graphics.setColor(frostfield.color.r, frostfield.color.g, frostfield.color.b, frostfield.color.a)
        love.graphics.circle( 'fill', frostfield.x, frostfield.y, frostfield.radius )
    end
end

function Helper.Spell.Frostfield:update()
    Helper.Spell.Frostfield:shoot()
    Helper.Spell.Frostfield:delete()
end
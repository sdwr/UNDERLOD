Helper.Spell.Brust = {}

function Helper.Spell.Brust.create(color, bullet_length, damage, speed, unit)
    Helper.Time.set_interval(0.1, function()
        Helper.Spell.Missile.create(color, bullet_length, damage, speed, unit, true, 1)
    end, 6)
end
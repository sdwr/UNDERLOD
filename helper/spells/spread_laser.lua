Helper.Spell.SpreadLaser = {}

function Helper.Spell.SpreadLaser:create(color, laser_aim_widths, damage, unit)
    local offset_angle = get_random(0, 360)
    Helper.Spell.Laser:create(color, laser_aim_widths, damage_troops, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle))
    Helper.Time:wait(0.05, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 60)) end)
    Helper.Time:wait(0.1, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 120)) end)
    Helper.Time:wait(0.15, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 180)) end)
    Helper.Time:wait(0.2, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 240)) end)
    Helper.Time:wait(0.25, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 300)) end)
end
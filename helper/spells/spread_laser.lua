Helper.Spell.SpreadLaser = {}

function Helper.Spell.SpreadLaser:create(color, laser_aim_widths, damage, unit, damage_troops, draw_over_units)
    local offset_angle = get_random(0, 360)
    Helper.Spell.Laser:create(color, laser_aim_widths, damage_troops, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle), draw_over_units)
    Helper.Time:wait(0.05, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 60), draw_over_units) end)
    Helper.Time:wait(0.1, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 120), draw_over_units) end)
    Helper.Time:wait(0.15, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 180), draw_over_units) end)
    Helper.Time:wait(0.2, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 240), draw_over_units) end)
    Helper.Time:wait(0.25, function() Helper.Spell.Laser:create(color, laser_aim_widths, true, damage, unit, Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + 300), draw_over_units) end)
end
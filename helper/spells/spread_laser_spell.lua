Helper.Spell.SpreadLaser = {}

function Helper.Spell.SpreadLaser.create(parent)
    local offset_angle = math.random(0, 360)
    Helper.Spell.Laser.create(true, 5, 300, parent, Helper.Geometry.rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle))
    Helper.Time.wait(0.05, function() Helper.Spell.Laser.create(true, 5, 300, parent, Helper.Geometry.rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 60)) end)
    Helper.Time.wait(0.1, function() Helper.Spell.Laser.create(true, 5, 300, parent, Helper.Geometry.rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 120)) end)
    Helper.Time.wait(0.15, function() Helper.Spell.Laser.create(true, 5, 300, parent, Helper.Geometry.rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 180)) end)
    Helper.Time.wait(0.2, function() Helper.Spell.Laser.create(true, 5, 300, parent, Helper.Geometry.rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 240)) end)
    Helper.Time.wait(0.25, function() Helper.Spell.Laser.create(true, 5, 300, parent, Helper.Geometry.rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 300)) end)
end
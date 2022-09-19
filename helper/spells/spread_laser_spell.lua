function spread_laser(parent)
    local offset_angle = math.random(0, 360)
    create_direction_lock_laser(5, 300, parent, rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle))
    wait(0.05, function() create_direction_lock_laser(5, 300, parent, rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 60)) end)
    wait(0.1, function() create_direction_lock_laser(5, 300, parent, rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 120)) end)
    wait(0.15, function() create_direction_lock_laser(5, 300, parent, rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 180)) end)
    wait(0.2, function() create_direction_lock_laser(5, 300, parent, rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 240)) end)
    wait(0.25, function() create_direction_lock_laser(5, 300, parent, rotate_point(parent.x + 100, parent.y, parent.x, parent.y, offset_angle + 300)) end)
end
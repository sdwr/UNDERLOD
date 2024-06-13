Helper.Spell.SpreadLaser = {}

function Helper.Spell.SpreadLaser:create(color, laser_aim_widths, damage, unit)
    local offset_angle = get_random(0, 360)

    for i = 0, 5 do
        Helper.Time:wait(i * 0.05, function()

            local target_x, target_y = Helper.Geometry:rotate_point(unit.object.x + 100, unit.object.y, unit.object.x, unit.object.y, offset_angle + (i*60))
            local args = {
                unit = unit,
                direction_lock = true,
                color = color,
                laser_aim_width = laser_aim_widths,
                damage = damage,
                damage_troops = true,
                direction_target_x = target_x,
                direction_target_y = target_y,
            }
            Helper.Spell.Laser:create(args)
        end)
    end
end
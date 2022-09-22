Helper.Spell = {}

require 'helper/spells/flame_spell'
require 'helper/spells/missile_spell'
require 'helper/spells/damage_circle'
require 'helper/spells/laser_spell'
require 'helper/spells/damage_line'
require 'helper/spells/spread_laser_spell'
require 'helper/spells/spread_missile_spell'

Helper.Spell.last_target_location_x = 0
Helper.Spell.last_target_location_y = 0



function Helper.Spell.get_nearest_target_location(x, y)
    local targetx = -10000
    local targety = -10000
    local distancemin = 100000000

    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    for _, enemy in ipairs(enemies) do
        if Helper.Geometry.distance(x, y, enemy.x, enemy.y) < distancemin then
            distancemin = Helper.Geometry.distance(x, y, enemy.x, enemy.y)
            targetx = enemy.x
            targety = enemy.y
            found_target = true
        end
    end

    if distancemin ~= 100000000 then
        return targetx, targety
    else
        return Helper.Spell.last_target_location_x, Helper.Spell.last_target_location_y
    end
end

function Helper.Spell.get_last_target_location()
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    if #enemies ~= 0 then
        Helper.Spell.last_target_location_x = enemies[1].x
        Helper.Spell.last_target_location_y = enemies[1].y
    end
end
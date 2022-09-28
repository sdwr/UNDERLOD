Helper.Spell = {}

require 'helper/spells/flame_spell'
require 'helper/spells/missile_spell'
require 'helper/spells/damage_circle'
require 'helper/spells/laser_spell'
require 'helper/spells/damage_line'
require 'helper/spells/spread_laser_spell'
require 'helper/spells/spread_missile_spell'

function Helper.Spell.get_nearest_target(unit, include_list)
    if #Helper.Unit.get_list(not unit.is_troop) > 0 then
        local target = {}
        local distancemin = 100000000
        for _, value in ipairs(Helper.Unit.get_list(not unit.is_troop)) do
            if Helper.Geometry.distance(unit.object.x, unit.object.y, value.object.x, value.object.y) < distancemin and (#include_list == 0 or is_in_list(include_list, value)) then
                distancemin = Helper.Geometry.distance(unit.object.x, unit.object.y, value.object.x, value.object.y)
                target = value
            end
        end
        return target
    else
        return -1
    end
end

function Helper.Spell.get_nearest_least_targeted(unit)
    local targeted_min = 9999
    for i, value in ipairs(Helper.Unit.get_list(not unit.is_troop)) do
        if value.targeted_by < targeted_min then
            targeted_min = value.targeted_by
        end
    end

    local least_targeted_units = {}
    for i, value in ipairs(Helper.Unit.get_list(not unit.is_troop)) do
        if value.targeted_by == targeted_min then
            table.insert(least_targeted_units, value)
        end
    end

    return Helper.Spell.get_nearest_target(unit, least_targeted_units)
end
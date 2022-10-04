Helper.Spell = {}

require 'helper/spells/flame_spell'
require 'helper/spells/missile_spell'
require 'helper/spells/damage_circle'
require 'helper/spells/laser_spell'
require 'helper/spells/damage_line'
require 'helper/spells/spread_laser_spell'
require 'helper/spells/spread_missile_spell'

function Helper.Spell.get_nearest_target(unit, include_list)
    include_list = include_list or {}

    local unit_list = Helper.Unit.get_list(not unit.is_troop)
    if #unit_list > 0 then
        local target = {}
        local distancemin = 100000000
        for _, value in ipairs(unit_list) do
            if Helper.Geometry.distance(unit.x, unit.y, value.x, value.y) < distancemin and (#include_list == 0 or is_in_list(include_list, value)) then
                distancemin = Helper.Geometry.distance(unit.x, unit.y, value.x, value.y)
                target = value
            end
        end
        return target
    else
        return -1
    end
end

function Helper.Spell.get_nearest_least_targeted(unit, range)
    local target_list = {}
    for i, value in ipairs(Helper.Unit.get_list(not unit.is_troop)) do
        if Helper.Geometry.distance(unit.x, unit.y, value.x, value.y) <= range then
            table.insert(target_list, value)
        end
    end

    local targeted_min = 9999
    for i, value in ipairs(target_list) do
        if #value.targeted_by < targeted_min then
            targeted_min = #value.targeted_by
        end
    end

    local least_targeted_units = {}
    for i, value in ipairs(target_list) do
        if #value.targeted_by == targeted_min then
            table.insert(least_targeted_units, value)
        end
    end

    return Helper.Spell.get_nearest_target(unit, least_targeted_units)
end

function Helper.Spell.claimed_target_is_in_range(unit, range)
    if unit.have_target and Helper.Geometry.distance(unit.x, unit.y, unit.claimed_target.x, unit.claimed_target.y) <= range then
        return true
    end

    return false
end

function Helper.Spell.there_is_target_in_range(unit, range)
    for i, target in ipairs(Helper.Unit.get_list(not unit.is_troop)) do
        if Helper.Geometry.distance(unit.x, unit.y, target.x, target.y) < range then
            return true
        end
    end

    return false
end
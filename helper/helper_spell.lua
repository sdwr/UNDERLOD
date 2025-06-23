Helper.Spell = {}


require 'helper/spells/flame'
require 'helper/spells/damage_circle'
require 'helper/spells/damage_line'
require 'helper/spells/safety_dance'
require 'helper/spells/sweep'
require 'helper/spells/bomb'
require 'helper/spells/frostfield'

require 'helper/spells/v2/spell'
require 'helper/spells/v2/stomp_spell'
require 'helper/spells/v2/laser_spell'
require 'helper/spells/v2/spread_laser'
require 'helper/spells/v2/breathe_fire'
require 'helper/spells/v2/plasma_barrage'
require 'helper/spells/v2/mortar'
require 'helper/spells/v2/summon'
require 'helper/spells/v2/launch'
require 'helper/spells/v2/prevent_casting'
require 'helper/spells/v2/firewall_angled'
require 'helper/spells/v2/area_spell'

require 'helper/spells/v2/cleave'

require 'helper/spells/v2/instants'

Helper.Spell.spells = {
    Helper.Spell.Flame,
    Helper.Spell.DamageCircle, 
    Helper.Spell.DamageLine,
    Helper.Spell.DamageArc,
    Helper.Spell.SafetyDance,
    Helper.Spell.Sweep,
    Helper.Spell.Bomb,
    Helper.Spell.Frostfield,
}

function Helper.Spell:can_shoot(spell)
    if Helper.Time.time - spell.start_aim_time > spell.cast_time then
        return true
    else
        return false
    end
end

function Helper.Spell:get_furthest_target(unit, include_list)
    -- what does this do?
    if Helper.Unit.flagged_enemy ~= -1 then
        return Helper.Unit.flagged_enemy
    end

    include_list = include_list or {}
    local unit_list = Helper.Unit:get_list(not unit.is_troop)
    if #unit_list > 0 then
        local target = {}
        local distancemax = 0

        for _, value in ipairs(unit_list) do
            if Helper.Geometry:distance(unit.x, unit.y, value.x, value.y) > distancemax and (#include_list == 0 or is_in_list(include_list, value)) then
                distancemax = Helper.Geometry:distance(unit.x, unit.y, value.x, value.y)
                target = value
            end
        end
        return target
    else
        return -1
    end
end

function Helper.Spell:get_nearest_target(unit, include_list)
    if Helper.Unit.flagged_enemy ~= -1 then
        return Helper.Unit.flagged_enemy
    end

    include_list = include_list or {}

    local unit_list = Helper.Unit:get_list(not unit.is_troop)
    if #unit_list > 0 then
        local target = {}
        local distancemin = 100000000

        local globalTarget = nil
        if main and main.current and main.current.targetedEnemy then
            globalTarget = main.current.targetedEnemy
        end

        --check global target first
        if is_in_list(include_list, globalTarget) and Helper.Geometry:distance(unit.x, unit.y, globalTarget.x, globalTarget.y) then
            return globalTarget
        end

        for _, value in ipairs(unit_list) do
            if Helper.Geometry:distance(unit.x, unit.y, value.x, value.y) < distancemin and (#include_list == 0 or is_in_list(include_list, value)) then
                distancemin = Helper.Geometry:distance(unit.x, unit.y, value.x, value.y)
                target = value
            end
        end
        return target
    else
        return -1
    end
end

function Helper.Spell:get_all_targets_in_range(unit, range, include_list)
    include_list = include_list or {}
    range = range or 100

    local unit_list = Helper.Unit:get_list(not unit.is_troop)
    local target_list = {}

    for _, value in ipairs(unit_list) do
        if Helper.Geometry:distance(unit.x, unit.y, value.x, value.y) < range and (#include_list == 0 or is_in_list(include_list, value)) then
            table.insert(target_list, value)
        end
    end

    return target_list
end

function Helper.Spell:get_all_allies_in_range(unit, range, include_list)
    include_list = include_list or {}
    range = range or 100

    local unit_list = Helper.Unit:get_list(unit.is_troop)
    local target_list = {}

    for _, value in ipairs(unit_list) do
        if Helper.Geometry:distance(unit.x, unit.y, value.x, value.y) < range and (#include_list == 0 or is_in_list(include_list, value)) then
            table.insert(target_list, value)
        end
    end

    return target_list
end

function Helper.Spell:get_random_target_in_range(unit, range)
    local unit_list = Helper.Unit:get_list(not unit.is_troop)
    if #unit_list > 0 then
        local target = {}
        local distance = 0
        local target_list = {}

        for _, value in ipairs(unit_list) do
            distance = Helper.Geometry:distance(unit.x, unit.y, value.x, value.y)
            if distance < range then
                table.insert(target_list, value)
            end
        end

        if #target_list > 0 then
            local random_index = math.random(1, #target_list) 
            return target_list[random_index]        end
    end

    return -1
end

function Helper.Spell:get_random_target_in_range_from_point(x, y, range, is_troop)
    local unit = {
        x = x,
        y = y,
        is_troop = is_troop
    }

    return self:get_random_target_in_range(unit, range)
end

function Helper.Spell:get_nearest_target_from_point(x, y, target_is_troop)
    local unit = {
        x = x,
        y = y,
        is_troop = not target_is_troop
    }

    return self:get_nearest_target(unit)
end

function Helper.Spell:get_random_in_range(unit, range, points)
    points = points or false
    range = range + 30
    
    if Helper.Unit.flagged_enemy ~= -1 then
        return Helper.Unit.flagged_enemy
    end
    
    local target_list = {}
    if not points then
        for i, value in ipairs(Helper.Unit:get_list(not unit.is_troop)) do
            if Helper.Geometry:distance(unit.x, unit.y, value.x, value.y) <= range then
                table.insert(target_list, value)
            end
        end
    else
        for i, value in ipairs(Helper.Unit:get_list(not unit.is_troop)) do
            for j, point in ipairs(unit.points) do
                if Helper.Geometry:distance(unit.x, unit.y, value.x + point.x, value.y + point.y) <= range then
                    table.insert(target_list, value)
                    break
                end
            end
        end
    end

    if #target_list == 0 then
        return -1
    end
    
    return random:table(target_list)
end

function Helper.Spell:is_in_range(unit, target, range, points)
    points = points or false
    range = range + 40

    if not points then
        if target and Helper.Geometry:distance(unit.x, unit.y, target.x, target.y) <= range then
            return true
        end
    else
        for i, point in ipairs(target.points) do
            if target and Helper.Geometry:distance(unit.x, unit.y, target.x + point.x, target.y + point.y) <= range then
                return true
            end
        end
    end

    return false
end

function Helper.Spell:target_is_in_range(unit, range, points)
    local target = unit:my_target()
    return Helper.Spell:is_in_range(unit, target, range, points)
end

-- remove this at some point
function Helper.Spell:there_is_target_in_range(unit, range, points)
    points = points or false
    range = range + 30
    
    if not points then
        for i, target in ipairs(Helper.Unit:get_list(not unit.is_troop)) do
            if Helper.Geometry:distance(unit.x, unit.y, target.x, target.y) < range then
                return true
            end
        end
    else
        for i, target in ipairs(Helper.Unit:get_list(not unit.is_troop)) do
            for j, point in ipairs(target.points) do
                if Helper.Geometry:distance(unit.x, unit.y, target.x + point.x, target.y + point.y) < range then
                    return true
                end
            end
        end
    end

    return false
end

function Helper.Spell:get_enemies_in_range(unit, range)
  local enemies = {}
  for i, troop in ipairs(Helper.Unit:get_list(not unit.is_troop)) do
    if Helper.Geometry:distance(unit.x, unit.y, troop.x, troop.y) < range then
      table.insert(enemies, troop)
    end
  end
  return enemies
end

function Helper.Spell:get_target_nearest_point(unit)
    local max_distance = 99999999
    local nearestx = 0
    local nearesty = 0
    local target = unit:my_target()
    if not target then
        return 0, 0
    end
    for i, point in ipairs(target.points) do
        local distance = Helper.Geometry:distance(unit.x, unit.y, target.x + point.x, target.y + point.y)
        if distance < max_distance then
            max_distance = distance
            nearestx = target.x + point.x
            nearesty = target.y + point.y
        end
    end

    return nearestx, nearesty
end

function Helper.Spell:register_damage_point(point, damage_source_unit, damage)
    local point_damage = {
        point = point,
        damage_source_unit = damage_source_unit,
        damage = damage
    }

    table.insert(point.unit.point_damages, point_damage)
end

function Helper.Spell:damage_points()
    for i, unit in ipairs(Helper.Unit:get_all_units()) do
        local counted_damage_source_unit = {}
        for j, point_damage in ipairs(unit.point_damages) do
            if not is_in_list(counted_damage_source_unit, point_damage.damage_source_unit) then
                table.insert(counted_damage_source_unit, point_damage.damage_source_unit)
                unit:hit(point_damage.damage, point_damage.damage_source_unit)
            end
            local x = point_damage.point.unit.x + point_damage.point.x
            local y = point_damage.point.unit.y + point_damage.point.y
            -- HitCircle{group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1}
            for i = 1, 1 do HitParticle{group = main.current.effects, x = x, y = y, color = blue[0]} end
            for i = 1, 1 do HitParticle{group = main.current.effects, x = x, y = y, color = blue[0]} end
        end
        for k in ipairs(unit.point_damages) do
            unit.point_damages[k] = nil
        end
    end
end

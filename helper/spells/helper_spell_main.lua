Helper.Spell = {}

require 'helper/spells/flame_spell'
require 'helper/spells/missile_spell'
require 'helper/spells/damage_circle'
require 'helper/spells/laser_spell'
require 'helper/spells/damage_line'
require 'helper/spells/spread_laser_spell'
require 'helper/spells/spread_missile_spell'

Helper.Spell.last_enemy_location_x = 0
Helper.Spell.last_enemy_location_y = 0
Helper.Spell.last_troop_location_x = 0
Helper.Spell.last_troop_location_y = 0



function Helper.Spell.get_nearest_target_location(x, y, target_troops)
    local targetx = -10000
    local targety = -10000
    local distancemin = 100000000
    local found_target = false

    local entities = {}

    if not target_troops then
        entities = main.current.main:get_objects_by_classes(main.current.enemies)
    else
        entities = main.current.main:get_objects_by_class(Troop)
    end

    for _, entity in ipairs(entities) do
        if Helper.Geometry.distance(x, y, entity.x, entity.y) < distancemin then
            distancemin = Helper.Geometry.distance(x, y, entity.x, entity.y)
            targetx = entity.x
            targety = entity.y
            found_target = true
        end
    end

    if found_target then
        return targetx, targety
    else
        if not target_troops then
            return Helper.Spell.last_enemy_location_x, Helper.Spell.last_enemy_location_y
        else
            return Helper.Spell.last_troop_location_x, Helper.Spell.last_troop_location_y
        end
    end
end

function Helper.Spell.get_last_target_location()
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    if #enemies ~= 0 then
        Helper.Spell.last_enemy_location_x = enemies[1].x
        Helper.Spell.last_enemy_location_y = enemies[1].y
    end

    local troops = main.current.main:get_objects_by_class(Troop)
    if #troops ~= 0 then
        Helper.Spell.last_troop_location_x = troops[1].x
        Helper.Spell.last_troop_location_y = troops[1].y
    end
end
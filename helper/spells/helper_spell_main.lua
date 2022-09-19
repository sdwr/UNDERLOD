require 'helper/spells/flame_spell'
require 'helper/spells/missile_spell'
require 'helper/spells/damage_circle'



function get_nearest_target(x, y)
    local targetx = -10000
    local targety = -10000
    local distancemin = 100000000

    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    for _, enemy in ipairs(enemies) do
        if distance(x, y, enemy.x, enemy.y) < distancemin then
            distancemin = distance(x, y, enemy.x, enemy.y)
            targetx = enemy.x
            targety = enemy.y
            found_target = true
        end
    end

    return targetx, targety
end
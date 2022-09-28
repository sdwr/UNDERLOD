Helper.Unit = {}

Helper.Unit.enemy_unit_list = {}
Helper.Unit.troop_unit_list = {}



function Helper.Unit.get_troop_unit(object)
    return Helper.Unit.get_unit(object, true)
end

function Helper.Unit.get_enemy_unit(object)
    return Helper.Unit.get_unit(object, false)
end

function Helper.Unit.get_unit(object, unit_is_troop)
    if unit_is_troop then
        for i, unit in ipairs(Helper.Unit.troop_unit_list) do
            if unit.object == object then
                return unit
            end
        end
    else
        for i, unit in ipairs(Helper.Unit.enemy_unit_list) do
            if unit.object == object then
                return unit
            end
        end
    end

    local unit = {
        previous_state = '',

        is_troop = true,
        object = object,
        targeted_by = 0,
        target = {},
        have_target = false,
        is_in_unit_list = false,
        state_change_functions = {},
        state_always_run_functions = {},
        last_attack_at = -999999,
    }
    Helper.Unit.add_default_state_change_functions(unit)
    Helper.Unit.add_default_state_always_run_functions(unit)

    if not unit_is_troop then 
        unit.is_troop = false
    end

    return unit
end

function Helper.Unit.update_unit_lists()
    local troops = main.current.main:get_objects_by_class(Troop)
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)

    for i, troop in ipairs(troops) do
        local unit = Helper.Unit.get_troop_unit(troop)
        if not unit.is_in_unit_list then
            unit.is_in_unit_list = true
            table.insert(Helper.Unit.troop_unit_list, unit)
        end
    end
    for i, unit in ipairs(Helper.Unit.troop_unit_list) do
        if not is_in_list(troops, unit.object) then
            table.remove(Helper.Unit.troop_unit_list, i)
        end
    end

    for i, enemy in ipairs(enemies) do
        local unit = Helper.Unit.get_enemy_unit(enemy)
        if not unit.is_in_unit_list then
            unit.is_in_unit_list = true
            table.insert(Helper.Unit.enemy_unit_list, unit)
        end
    end
    for i, unit in ipairs(Helper.Unit.enemy_unit_list) do
        if not is_in_list(enemies, unit.object) then
            table.remove(Helper.Unit.enemy_unit_list, i)
        end
    end
end

function Helper.Unit.get_list(troop_list)
    if troop_list then
        return Helper.Unit.troop_unit_list
    else
        return Helper.Unit.enemy_unit_list
    end
end



function Helper.Unit.claim_target(unit, target)
    unit.target = target
    unit.target.targeted_by = unit.target.targeted_by + 1
    unit.have_target = true
end

function Helper.Unit.unclaim_target(unit)
    unit.target.targeted_by = unit.target.targeted_by - 1
    unit.have_target = false
end



function Helper.Unit.add_default_state_change_functions(unit)
    local function default_normal()
    end

    local function default_frozen()
    end

    local function default_channeling()
    end

    local function default_stopped()
    end

    local function default_following()
    end

    local function default_rallying()
    end

    unit.state_change_functions['normal'] = default_normal
    unit.state_change_functions['frozen'] = default_frozen
    unit.state_change_functions['channeling'] = default_channeling
    unit.state_change_functions['stopped'] = default_stopped
    unit.state_change_functions['following'] = default_following
    unit.state_change_functions['rallying'] = default_rallying
end

function Helper.Unit.add_default_state_always_run_functions(unit)
    local function default_normal()
    end

    local function default_frozen()
    end

    local function default_channeling()
    end

    local function default_stopped()
    end

    local function default_following()
        if unit.have_target then
            Helper.Spell.Laser.stop_aiming(unit)
        end
    end

    local function default_rallying()
        if unit.have_target then
            Helper.Spell.Laser.stop_aiming(unit)
        end
    end

    local function default_always_run()
        if unit.have_target and not Helper.Spell.claimed_target_is_in_range(unit, attack_ranges['medium-long'] + 20) then
            Helper.Spell.Laser.stop_aiming(unit)
        end
    end

    unit.state_always_run_functions['normal'] = default_normal
    unit.state_always_run_functions['frozen'] = default_frozen
    unit.state_always_run_functions['channeling'] = default_channeling
    unit.state_always_run_functions['stopped'] = default_stopped
    unit.state_always_run_functions['following'] = default_following
    unit.state_always_run_functions['rallying'] = default_rallying

    unit.state_always_run_functions['always_run'] = default_always_run
end

function Helper.Unit.run_state_change_functions()
    for i, unit in ipairs(Helper.Unit.troop_unit_list) do
        if unit.previous_state ~= unit.object.state then
            unit.state_change_functions[unit.object.state]()
        end
        unit.previous_state = unit.object.state
    end
end

function Helper.Unit.run_state_always_run_functions()
    for i, unit in ipairs(Helper.Unit.troop_unit_list) do
        unit.state_always_run_functions[unit.object.state]()
        unit.state_always_run_functions['always_run']()
    end
end
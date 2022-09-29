Helper.Unit = {}

function Helper.Unit.get_list(troop_list)
    if troop_list then
        return main.current.main:get_objects_by_class(Troop)
    else
        return main.current.main:get_objects_by_classes(main.current.enemies)
    end
end

function Helper.Unit.add_custom_variables_to_unit(unit)
    unit.previous_state = ''

    unit.is_troop = true
    unit.targeted_by = 0
    unit.claimed_target = {}
    unit.have_target = false
    unit.state_change_functions = {}
    unit.state_always_run_functions = {}
    unit.last_attack_at = -999999
    unit.ignore_cooldown = false

    Helper.Unit.add_default_state_change_functions(unit)
    Helper.Unit.add_default_state_always_run_functions(unit)

    if is_in_list(Helper.Unit.get_list(true), unit) then
        unit.is_troop = true
    else
        unit.is_troop = false
    end
end

function Helper.Unit.claim_target(unit, target)
    unit.claimed_target = target
    unit.claimed_target.targeted_by = unit.claimed_target.targeted_by + 1
    unit.have_target = true
end

function Helper.Unit.unclaim_target(unit)
    unit.claimed_target.targeted_by = unit.claimed_target.targeted_by - 1
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
            unit.ignore_cooldown = true
        end
    end

    local function default_rallying()
        if unit.have_target then
            Helper.Spell.Laser.stop_aiming(unit)
            unit.ignore_cooldown = true
        end
    end

    local function default_always_run()
        if unit.have_target and not Helper.Spell.claimed_target_is_in_range(unit, attack_ranges['medium-long'] + 20) then
            Helper.Spell.Laser.stop_aiming(unit)
            unit.ignore_cooldown = true
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
    for i, unit in ipairs(Helper.Unit.get_list(true)) do
        if unit.previous_state ~= unit.state then
            unit.state_change_functions[unit.state]()
        end
        unit.previous_state = unit.state
    end
end

function Helper.Unit.run_state_always_run_functions()
    for i, unit in ipairs(Helper.Unit.get_list(true)) do
        unit.state_always_run_functions[unit.state]()
        unit.state_always_run_functions['always_run']()
    end
end
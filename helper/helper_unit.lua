Helper.Unit = {}

Helper.Unit.cast_flash_duration = 0.08

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
    unit.targeted_by = {}
    unit.claimed_target = nil
    unit.have_target = false
    unit.state_change_functions = {}
    unit.state_always_run_functions = {}
    unit.last_attack_started = -999999
    unit.last_attack_finished = -999999
    unit.ignore_cooldown = false
    unit.death_function = function()  
        for i = #unit.targeted_by, 1, -1 do
            unit.targeted_by[i].state_change_functions['target_death']()
        end   
    end
    unit.damage_taken_at = {
        ['sweep'] = -999999
    }

    Helper.Unit.add_default_state_change_functions(unit)
    Helper.Unit.add_default_state_always_run_functions(unit)

    if is_in_list(Helper.Unit.get_list(true), unit) then
        unit.is_troop = true
    else
        unit.is_troop = false
    end
end

function Helper.Unit.claim_target(unit, target)
    if unit then
        if unit.have_target then
            if unit.claimed_target == target then
                return
            end
            table.remove(unit.claimed_target.targeted_by, find_in_list(unit.claimed_target.targeted_by, unit))
        end
        unit.claimed_target = target
        table.insert(unit.claimed_target.targeted_by, unit)
        unit.have_target = true
    end
end

function Helper.Unit.unclaim_target(unit)
    if unit and unit.have_target then
        table.remove(unit.claimed_target.targeted_by, find_in_list(unit.claimed_target.targeted_by, unit))
        unit.have_target = false
    end
end

function Helper.Unit.can_cast(unit)
    if unit then
        return unit.state == unit_states['normal'] and not unit.have_target
        and Helper.Time.time - unit.last_attack_finished > unit.cooldownTime
        and Helper.Spell.there_is_target_in_range(unit, unit.attack_sensor.rs)
    end
    return false
end

function Helper.Unit.start_casting(unit)
    if unit then
        unit.state = unit_states['casting']
        unit.last_attack_started = Helper.Time.time
    end
end

function Helper.Unit.cancel_casting(unit)

end

function Helper.Unit.finish_casting(unit)
    if unit then
        unit.last_attack_finished = Helper.Time.time
        unit.state = unit_states['normal']
    end
end

function Helper.Unit.is_attack_on_cooldown(unit)
    if unit then
        local time_since_cast = Helper.Time.time - (unit.last_attack_finished or 0)
        if unit.cooldownTime and time_since_cast < unit.cooldownTime then
            return true
        end
    end
    return false
end

function Helper.Unit.add_default_state_change_functions(unit)
    local function default_normal()
    end

    local function default_frozen()
    end

    local function default_casting()
    end

    local function default_channeling()
    end

    local function default_stopped()
    end

    local function default_following()
        unit.state_change_functions['following_or_rallying']()
    end

    local function default_rallying()
        unit.state_change_functions['following_or_rallying']()
    end

    local function default_following_and_rallying()
    end

    local function default_death()
    end

    unit.state_change_functions['normal'] = default_normal
    unit.state_change_functions['frozen'] = default_frozen
    unit.state_change_functions['casting'] = default_casting
    unit.state_change_functions['channeling'] = default_channeling
    unit.state_change_functions['stopped'] = default_stopped
    unit.state_change_functions['following'] = default_following
    unit.state_change_functions['rallying'] = default_rallying
    
    unit.state_change_functions['following_or_rallying'] = default_following_and_rallying
    unit.state_change_functions['death'] = default_death
    unit.state_change_functions['target_death'] = function() end
end

function Helper.Unit.add_default_state_always_run_functions(unit)
    local function default_normal()
    end

    local function default_frozen()
    end

    local function default_casting()
    end

    local function default_channeling()
    end

    local function default_stopped()
    end

    local function default_following()
        unit.state_always_run_functions['following_or_rallying']()
    end

    local function default_rallying()
        unit.state_always_run_functions['following_or_rallying']()
    end

    local function default_following_and_rallying()
    end

    local function default_always_run()
    end

    unit.state_always_run_functions['normal'] = default_normal
    unit.state_always_run_functions['frozen'] = default_frozen
    unit.state_always_run_functions['casting'] = default_casting
    unit.state_always_run_functions['channeling'] = default_channeling
    unit.state_always_run_functions['stopped'] = default_stopped
    unit.state_always_run_functions['following'] = default_following
    unit.state_always_run_functions['rallying'] = default_rallying

    unit.state_always_run_functions['following_or_rallying'] = default_following_and_rallying
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
    for i, unit in ipairs(Helper.Unit.get_list(false)) do
        unit.state_always_run_functions[unit.state]()
        unit.state_always_run_functions['always_run']()
    end
end

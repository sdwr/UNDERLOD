Helper.Unit = {}

Helper.Unit.cast_flash_duration = 0.08
Helper.Unit.do_draw_points = false

function Helper.Unit:get_list(troop_list)
    if troop_list == nil then
        return {}
    end

    --will not work with subclasses for troop
    --the Group:get_objects_by_class method is efficient
    --and searching by self.is_troop will be slow
    --can maybe make a list of all troop types, but that kinda sucks
    --
    if troop_list then
        return main.current.main:get_objects_by_classes(main.current.troops)
    else
        return main.current.main:get_objects_by_classes(main.current.enemies)
    end
end

function Helper.Unit:get_all_units()
    local unit_list = {}
    for i, unit in ipairs(Helper.Unit:get_list(true)) do
        table.insert(unit_list, unit)
    end
    for i, unit in ipairs(Helper.Unit:get_list(false)) do
        table.insert(unit_list, unit)
    end
    return unit_list
end

function Helper.Unit:add_custom_variables_to_unit(unit)
    unit.previous_state = ''

    unit.targeted_by = {}
    unit.state_change_functions = {}
    unit.state_always_run_functions = {}
    unit.last_attack_started = -999999
    unit.last_attack_finished = -999999
    unit.ignore_cooldown = false
    unit.death_function = function()  
        for i = #unit.targeted_by, 1, -1 do
            unit.targeted_by[i].state_change_functions['target_death']()
        end

        if unit == Helper.Unit.flagged_enemy then
            Helper.Unit.flagged_enemy = -1
        end
    end
    unit.damage_taken_at = {
        ['sweep'] = -999999
    }
    unit.selected = false
    unit.spell_wait_id = -1
    unit.points = {}
    self:add_point(unit, 0, 0)
    unit.point_damages = {}
    unit.hitbox_points_can_rotate = false
    unit.hitbox_points_rotation = 0

    Helper.Unit:add_default_state_change_functions(unit)
    Helper.Unit:add_default_state_always_run_functions(unit)
end

-- looks like this is for "least targeted" targeting
function Helper.Unit:claim_target(unit, target)
    if target ~= -1 then
        if unit.target then
            if unit.target == target then
                return
            end
            if unit.target then
                table.remove(unit.target.targeted_by, find_in_list(unit.target.targeted_by, unit))
            end
        end
        unit:set_target(target)
        table.insert(unit.target.targeted_by, unit)
    end
end

--this should remove the target from the unit as well?
function Helper.Unit:unclaim_target(unit)
    --only clear my target, not assigned target
    if unit.target then
        table.remove(unit.target.targeted_by, find_in_list(unit.target.targeted_by, unit))
        unit:clear_my_target()
    end
end

--doesnt check target points, just center
function Helper.Unit:target_out_of_range(unit)
    local target = unit:my_target()
    return target and Helper.Geometry:distance(unit.x, unit.y, target.x, target.y) > unit.attack_sensor.rs
end

function Helper.Unit:can_cast(unit, points)
    points = points or false
    --the goal here is to decouple "has target" from "can cast"
    -- we want an assigned target to persist between attacks, and not 
    -- prevent a unit from casting

    --still missing is chasing down a target that moves out of range
    if unit then
        return unit.state == unit_states['normal']
        and Helper.Time.time - unit.last_attack_finished > unit.cooldownTime
        and Helper.Spell:there_is_target_in_range(unit, unit.attack_sensor.rs, points)
    end
    return false
end

--expects the unit to have a target already
function Helper.Unit:can_attack(unit, points)
    points = points or false
    if unit then
        return unit.state == unit_states['normal']
        and Helper.Spell:target_is_in_range(unit, unit.attack_sensor.rs, points)
        and Helper.Time.time - unit.last_attack_finished > unit.cooldownTime
    end
    return false
end

function Helper.Unit:start_casting(unit)
    if unit then
        unit.state = unit_states['casting']
        unit.last_attack_started = Helper.Time.time
    end
end

function Helper.Unit:cancel_casting(unit)

end

function Helper.Unit:finish_casting(unit)
    if unit then
        unit.last_attack_finished = Helper.Time.time
        unit.state = unit_states['normal']
    end
end

function Helper.Unit:is_attack_on_cooldown(unit)
    if unit then
        local time_since_cast = Helper.Time.time - (unit.last_attack_finished or 0)
        if unit.cooldownTime and time_since_cast < unit.cooldownTime then
            return true
        end
    end
    return false
end

function Helper.Unit:add_default_state_change_functions(unit)
    unit.state_change_functions['normal'] = function() end
    unit.state_change_functions['frozen'] = function() end
    unit.state_change_functions['casting'] = function() end
    unit.state_change_functions['channeling'] = function() end
    unit.state_change_functions['stopped'] = function() end
    unit.state_change_functions['following'] = function() 
        unit.state_change_functions['following_or_rallying']()
    end
    unit.state_change_functions['rallying'] = function() 
        unit.state_change_functions['following_or_rallying']()
    end
    
    unit.state_change_functions['following_or_rallying'] = function() end
    unit.state_change_functions['death'] = function() end
    unit.state_change_functions['target_death'] = function() end
end

function Helper.Unit:add_default_state_always_run_functions(unit)
    unit.state_always_run_functions['normal'] = function() end
    unit.state_always_run_functions['frozen'] = function() end
    unit.state_always_run_functions['casting'] = function() end
    unit.state_always_run_functions['channeling'] = function() end
    unit.state_always_run_functions['stopped'] = function() end
    unit.state_always_run_functions['following'] = function() 
        unit.state_always_run_functions['following_or_rallying']()
    end
    unit.state_always_run_functions['rallying'] = function() 
        unit.state_always_run_functions['following_or_rallying']()
    end

    unit.state_always_run_functions['following_or_rallying'] = function() end
    unit.state_always_run_functions['always_run'] = function() end
end

function Helper.Unit:run_state_change_functions()
    for i, unit in ipairs(Helper.Unit:get_list(true)) do
        if unit.previous_state ~= unit.state then
            unit.state_change_functions[unit.state]()
        end
        unit.previous_state = unit.state
    end
end

function Helper.Unit:run_state_always_run_functions()
    for i, unit in ipairs(Helper.Unit:get_list(true)) do
        unit.state_always_run_functions[unit.state]()
        unit.state_always_run_functions['always_run']()
    end
    for i, unit in ipairs(Helper.Unit:get_list(false)) do
        unit.state_always_run_functions[unit.state]()
        unit.state_always_run_functions['always_run']()
    end
end



Helper.Unit.selection = {
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0
}
Helper.Unit.do_draw_selection = false
Helper.Unit.number_of_teams = 0
Helper.Unit.teams = {}
Helper.Unit.team_targets = {}
Helper.Unit.team_rally_points = {}
Helper.Unit.selected_team = 0
Helper.Unit.flagged_enemy = -1
Helper.Unit.number_of_troop_types = 0
Helper.Unit.troop_type_button_width = 0
Helper.Unit.team_button_width = 0

function Helper.Unit.set_team_rally_point(team_number, x, y)
    local existing_rally = Helper.Unit.team_rally_points[team_number]
    if existing_rally then
        existing_rally.dead = true
    end

    --show the rally point for a few seconds
    --only clear this rally point, not any new ones that are set afterwards
    local rallyCircle = RallyCircle{
        x = x,
        y = y,
        group = main.current.floor
    }
    --add clearing the rally point when all units have reached it
    --or when all units are dead
    Helper.Unit.team_rally_points[team_number] = rallyCircle
    trigger:after(3, function()
        if rallyCircle then
            rallyCircle.dead = true
        end
    end)
end

function Helper.Unit:clear_team_rally_point(team_number)
    local existing_rally = Helper.Unit.team_rally_points[team_number]
    if existing_rally then
        existing_rally.dead = true
    end
    Helper.Unit.team_rally_points[team_number] = nil
end

function Helper.Unit:clear_all_rally_points()
    for i = 1, 4 do
        Helper.Unit:clear_team_rally_point(i)
    end
end


function Helper.Unit:set_team_target(team_number, target)
    if team_number < 1 or team_number > 4 then
        return
    end
    for i, troop in ipairs(Helper.Unit.teams[team_number]) do
        troop:set_assigned_target(target)
    end
    Helper.Unit.team_targets[team_number] = target

    --set a targeting ring around the target
    if target then
        local targetBuff = {name = 'targeted', duration = 9999, color = yellow[0]}
        target:add_buff(targetBuff)
    end
end

--need to clear target when all troops are dead as well
function Helper.Unit:clear_team_target(team_number)
    if team_number < 1 or team_number > 4 then
        return
    end

    local target = Helper.Unit.team_targets[team_number]
    for i, troop in ipairs(Helper.Unit.teams[team_number]) do
        --can't clear the unit target here, because this gets called when the target dies
        troop:clear_assigned_target()
    end
    Helper.Unit.team_targets[team_number] = nil

    --clear the targeting ring around the target, if no other team is targeting it
    if not Helper.Unit:is_a_team_target(target) then
        if target then
            target:remove_buff('targeted')
        end
    end
end

function Helper.Unit:is_a_team_target(target)
    if target == nil then
        return false
    end

    for i = 1, 4 do
        if Helper.Unit.team_targets[i] == target then
            return true
        end
    end
    return false
end

function Helper.Unit:set_team(team_number)
    local team = {}
    for i, troop in ipairs(self:get_list(true)) do
        if troop.selected then
            table.insert(team, troop)
        end
    end
    if #team ~= 0 then
        self.teams[team_number] = team
        self:refresh_button(team_number)
        main.current.hotbar.hotbar_by_index[team_number + self.number_of_troop_types]:action()
    end
end

function Helper.Unit:add_to_team(team_number)
    local added = false
    for i, troop in ipairs(self:get_list(true)) do
        if troop.selected and not is_in_list(self.teams[team_number], troop) then
            table.insert(self.teams[team_number], troop)
            added = true
        end
    end
    if added then
        self:refresh_button(team_number)
        main.current.hotbar.hotbar_by_index[team_number + self.number_of_troop_types]:action()
    end
end

function Helper.Unit:refresh_button(team_number)
    local color_marks = {}
    for i, troop in ipairs(self.teams[team_number]) do
        if not is_in_list(color_marks, character_colors[troop.character]) then
            table.insert(color_marks, character_colors[troop.character])
        end
    end
    main.current.hotbar.hotbar_by_index[team_number + self.number_of_troop_types].color_marks = color_marks
end

function Helper.Unit:select()
    if not Helper.mouse_on_button then
        local flag = false
        --should be on key release, not press? or at least only check the first press
        if input['m2'].pressed then
            Helper.Unit:clear_team_rally_point(self.selected_team)

            for i, enemy in ipairs(self:get_list(false)) do
                if Helper.Geometry:distance(Helper.mousex, Helper.mousey, enemy.x, enemy.y) < 9 then 
                    flag = true
                    break
                end
            end
            --target the flagged enemy with the selected troop
            if flag then
                local flagged_enemy = Helper.Spell:get_nearest_target_from_point(Helper.mousex, Helper.mousey, false)
                Helper.Unit:clear_team_target(self.selected_team)
                Helper.Unit:set_team_target(self.selected_team, flagged_enemy)
                --set the selected troops to 'normal', so they can attack the target
                for i, unit in ipairs(self:get_list(true)) do
                    if unit.selected then
                        unit.state = unit_states['normal']
                    end
                end
            else
                --untarget the flagged enemy for the selected troop, if there is one
                Helper.Unit:clear_team_target(self.selected_team)

                --draw a rally point for the selected troops
                Helper.Unit.set_team_rally_point(self.selected_team, Helper.mousex, Helper.mousey)
                --rally the selected troops to the mouse location
                for i, unit in ipairs(self:get_list(true)) do
                    if unit.selected then
                        unit.state = unit_states['rallying']
                        unit.target_pos = {x = Helper.mousex, y = Helper.mousey}
                    end
                end
            end
        --bug with not moving if you start holding m1 while a unit is casting
        --it will not move until you release m1 and press it again
        --switched to down, but need a longer term solution? same thing will happen with m2 prob
        elseif input['m1'].down then
            --clear rally point for the selected team
            Helper.Unit:clear_team_rally_point(self.selected_team)

            for i, unit in ipairs(self:get_list(true)) do
                if unit.selected then
                    unit.state = unit_states['following']
                end
            end
        end
    end

        --dont need box selection
        -- if input['m1'].pressed and not flag then
        --     self.x1 = Helper.mousex
        --     self.y1 = Helper.mousey
        --     self.do_draw_selection = true
        -- end

        -- if input['m1'].down and self.do_draw_selection then
        --     self.x2 = Helper.mousex
        --     self.y2 = Helper.mousey
            
        --     for i, unit in ipairs(self:get_list(true)) do
        --         if Helper.Geometry:is_inside_rectangle(unit.x, unit.y, self.x1, self.y1, self.x2, self.y2) then
        --             unit.selected = true
        --         else
        --             unit.selected = false
        --         end
        --     end
        -- end


    -- if input['m1'].released then
    --     self.do_draw_selection = false
    -- end

    for i = 1, #main.current.units do
        if input[tostring(i)].pressed and main.current.hotbar.hotbar_by_index[i] then
            main.current.hotbar.hotbar_by_index[i]:on_mouse_enter()
            main.current.hotbar:select_by_index(i)
        end

        if input[tostring(i)].released and main.current.hotbar.hotbar_by_index[i] then
            main.current.hotbar.hotbar_by_index[i]:on_mouse_exit()
        end
    end
end

function Helper.Unit:draw_selection()
    if self.do_draw_selection then
        Helper.Graphics:draw_dashed_rectangle(Helper.Color.white, 2, 8, 4, Helper.Time.time * 80, self.x1, self.y1, self.x2, self.y2)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    for i, unit in ipairs(self:get_list(true)) do
        if unit.selected then
            love.graphics.circle('line', unit.x, unit.y, 5)
        end
    end

    if self.flagged_enemy ~= -1 then
        love.graphics.setLineWidth(1)
        Helper.Color:set_color(Helper.Color.orange)
        love.graphics.circle('line', self.flagged_enemy.x, self.flagged_enemy.y, 9)
    end
end

function Helper.Unit:deselect_all_troops()
    for i, troop in ipairs(self:get_list(true)) do
        troop.selected = false
    end
end

-- Add hitbox points relative to unit's position
function Helper.Unit:add_point(unit, x, y)
    local point = {
        unrotatedx = x,
        unrotatedy = y,
        x = x,
        y = y,
        unit = unit
    }
    table.insert(unit.points, point)
end

function Helper.Unit:update_hitbox_points()
    for i, unit in ipairs(self:get_all_units()) do
        if unit.hitbox_points_can_rotate then
            for j, point in ipairs(unit.points) do
                point.x, point.y = Helper.Geometry:rotate_point(point.unrotatedx, point.unrotatedy, 0, 0, unit.hitbox_points_rotation)
            end
        end
    end
end

function Helper.Unit:draw_points()
    if self.do_draw_points then
        for i, unit in ipairs(self:get_list(true)) do
            for j, point in ipairs(unit.points) do
                Helper.Color:set_color(Helper.Color.orange)
                love.graphics.circle("fill", point.x + unit.x, point.y + unit.y, 2)
            end
        end 
    
        for i, unit in ipairs(self:get_list(false)) do
            for j, point in ipairs(unit.points) do
                Helper.Color:set_color(Helper.Color.orange)
                love.graphics.circle("fill", point.x + unit.x, point.y + unit.y, 2)
            end
        end 
    end
end

function Helper.Unit:get_points(troop_points)
    local points = {}
    for i, unit in ipairs(self:get_list(troop_points)) do
        for j, point in ipairs(unit.points) do
            table.insert(points, point)
        end
    end
    return points
end
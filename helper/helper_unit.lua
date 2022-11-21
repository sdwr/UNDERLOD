Helper.Unit = {}

Helper.Unit.cast_flash_duration = 0.08
Helper.Unit.do_draw_points = false

function Helper.Unit:get_list(troop_list)
    if troop_list == nil then
        return -1
    end

    if troop_list then
        return main.current.main:get_objects_by_class(Troop)
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

    Helper.Unit:add_default_state_change_functions(unit)
    Helper.Unit:add_default_state_always_run_functions(unit)

    if is_in_list(Helper.Unit:get_list(true), unit) then
        unit.is_troop = true
    else
        unit.is_troop = false
    end
end

function Helper.Unit:claim_target(unit, target)
    if target ~= -1 then
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

function Helper.Unit:unclaim_target(unit)
    if unit.have_target then
        table.remove(unit.claimed_target.targeted_by, find_in_list(unit.claimed_target.targeted_by, unit))
        unit.have_target = false
    end
end

function Helper.Unit:can_cast(unit)
    if unit then
        return unit.state == unit_states['normal'] and not unit.have_target
        and Helper.Time.time - unit.last_attack_finished > unit.cooldownTime
        and Helper.Spell:there_is_target_in_range(unit, unit.attack_sensor.rs + 10, true)
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
Helper.Unit.teams = {{}, {}, {}, {}}
Helper.Unit.selected_team = 0
Helper.Unit.flagged_enemy = -1
Helper.Unit.setting_rallying = false
Helper.Unit.number_of_troop_types = 0
Helper.Unit.troop_type_button_width = 0
Helper.Unit.team_button_width = 0

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
        main.current.hotbar_by_index[team_number + self.number_of_troop_types]:action()
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
        main.current.hotbar_by_index[team_number + self.number_of_troop_types]:action()
    end
end

function Helper.Unit:refresh_button(team_number)
    local color_marks = {}
    for i, troop in ipairs(self.teams[team_number]) do
        if not is_in_list(color_marks, character_colors[troop.character]) then
            table.insert(color_marks, character_colors[troop.character])
        end
    end
    main.current.hotbar_by_index[team_number + self.number_of_troop_types].color_marks = color_marks
end

function Helper.Unit:select()
    if not Helper.mouse_on_button and not input['lshift'].down then
        local flag = false
        if input['m1'].pressed then
            for i, enemy in ipairs(self:get_list(false)) do
                if Helper.Geometry:distance(Helper.mousex, Helper.mousey, enemy.x, enemy.y) < 9 then 
                    flag = true
                    break
                end
            end
            if flag then
                local flagged_enemy = Helper.Spell:get_nearest_target_from_point(Helper.mousex, Helper.mousey, false)
                if self.flagged_enemy == flagged_enemy then
                    self.flagged_enemy = -1
                else
                    self.flagged_enemy = flagged_enemy
                    for i, troop in ipairs(self:get_list(true)) do
                        troop.target = self.flagged_enemy
                    end
                end
            end
        end

        if input['m1'].pressed and not flag then
            self.x1 = Helper.mousex
            self.y1 = Helper.mousey
            self.do_draw_selection = true
        end

        if input['m1'].down and self.do_draw_selection then
            self.x2 = Helper.mousex
            self.y2 = Helper.mousey
            
            for i, unit in ipairs(self:get_list(true)) do
                if Helper.Geometry:is_inside_rectangle(unit.x, unit.y, self.x1, self.y1, self.x2, self.y2) then
                    unit.selected = true
                else
                    unit.selected = false
                end
            end
        end

        if not input['m1'].down and input['m2'].down and not self.setting_rallying then
            for i, unit in ipairs(self:get_list(true)) do
                if unit.selected then
                    unit.state = unit_states['following']
                    unit.target = nil
                    unit.target_pos = nil
                end
            end
        end
    end

    if input['lshift'].down and input['m2'].pressed then
        self.setting_rallying = true
        for i, troop in ipairs(self:get_list(true)) do
            if troop.selected then
                troop.target_pos = {x = Helper.mousex, y = Helper.mousey}
                troop.state = unit_states['rallying']
            end
        end
    end

    if input['m2'].released then
        self.setting_rallying = false
    end

    if input['m1'].released then
        self.do_draw_selection = false
    end

    if input['lctrl'].down then
        if input[tostring(self.number_of_troop_types + 1)].pressed then
            self:set_team(1)
        elseif input[tostring(self.number_of_troop_types + 2)].pressed then
            self:set_team(2)
        elseif input[tostring(self.number_of_troop_types + 3)].pressed then
            self:set_team(3)
        elseif input[tostring(self.number_of_troop_types + 4)].pressed then
            self:set_team(4)
        end
    end

    if input['lshift'].down then
        if input[tostring(self.number_of_troop_types + 1)].pressed then
            self:add_to_team(1)
        elseif input[tostring(self.number_of_troop_types + 2)].pressed then
            self:add_to_team(2)
        elseif input[tostring(self.number_of_troop_types + 3)].pressed then
            self:add_to_team(3)
        elseif input[tostring(self.number_of_troop_types + 4)].pressed then
            self:add_to_team(4)
        end
    end



    for i = 1, 9 do
        if not input['lctrl'].down and not input['lshift'].down then
            if input[tostring(i)].pressed and main.current.hotbar_by_index[i] then
                main.current.hotbar_by_index[i]:on_mouse_enter()
            end
        elseif not (input['lctrl'].down and input['lshift'].down) then
            if input['lctrl'].down then
                if input[tostring(i)].pressed and i <= 4 + self.number_of_troop_types and i >= 1 + self.number_of_troop_types then
                    main.current.hotbar['set team ' .. i - self.number_of_troop_types].visible = true
                    main.current.hotbar['set team ' .. i - self.number_of_troop_types]:on_mouse_enter()
                end
            elseif input['lshift'].down then
                if input[tostring(i)].pressed and i <= 4 + self.number_of_troop_types and i >= 1 + self.number_of_troop_types then
                    main.current.hotbar['add to team ' .. i - self.number_of_troop_types].visible = true
                    main.current.hotbar['add to team ' .. i - self.number_of_troop_types]:on_mouse_enter()
                end
            end
        end

        if input[tostring(i)].released and main.current.hotbar_by_index[i] then
            main.current.hotbar_by_index[i]:on_mouse_exit()
            if i <= 4 + self.number_of_troop_types and i >= 1 + self.number_of_troop_types then
                main.current.hotbar['set team ' .. i - self.number_of_troop_types]:on_mouse_exit()
                main.current.hotbar['set team ' .. i - self.number_of_troop_types].visible = false
                main.current.hotbar['add to team ' .. i - self.number_of_troop_types]:on_mouse_exit()
                main.current.hotbar['add to team ' .. i - self.number_of_troop_types].visible = false
            end
        end
    end

    local x = 50 + (Helper.Unit.troop_type_button_width + 5) * (Helper.Unit.number_of_troop_types)
    local y = gh - 50
    for i = 1, 4 do
        if (not input['lshift'].down and not input['lctrl'].down and not input['m1'].down and not input['m2'].down and not input['space'].down) 
        or input[tostring(i + self.number_of_troop_types)].released then
            if Helper.Geometry:is_inside_rectangle(Helper.mousex, Helper.mousey, x + 52 * (i - 1), y, x + 47 + 52 * (i - 1), gh - 10) then
                main.current.hotbar['set team ' .. i].visible = true
                main.current.hotbar['add to team ' .. i].visible = true
            else
                main.current.hotbar['set team ' .. i].visible = false
                main.current.hotbar['add to team ' .. i].visible = false
            end
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



Helper.Unit.team_saves = {{}, {}, {}, {}}

function Helper.Unit:save_teams_to_next_round()
    Helper.Unit.team_saves = {{}, {}, {}, {}}

    for i = 1, 4 do
        if #self.teams[i] > 0 then
            for j, troop in ipairs(self.teams[i]) do
                if self.team_saves[i][troop.character] then
                    self.team_saves[i][troop.character] = self.team_saves[i][troop.character] + 1
                else
                    self.team_saves[i][troop.character] = 1
                end
            end
        end
    end
end

function Helper.Unit:load_teams_to_next_round()
    self.teams = {{}, {}, {}, {}}

    for i = 1, 4 do
        for j, troop in ipairs(self:get_list(true)) do
            if self.team_saves[i][troop.character] and self.team_saves[i][troop.character] > 0 then
                self.team_saves[i][troop.character] = self.team_saves[i][troop.character] - 1
                table.insert(self.teams[i], troop)
            end
        end

        self:refresh_button(i)
    end
end

-- Add hitbox points relative to unit's position
function Helper.Unit:add_point(unit, x, y)
    local point = {
        x = x,
        y = y,
        unit = unit
    }
    table.insert(unit.points, point)
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
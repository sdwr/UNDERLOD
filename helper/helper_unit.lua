Helper.Unit = {}

Helper.Unit.selection = {
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0
}
Helper.Unit.do_draw_selection = false
Helper.Unit.mouse_just_down = false
Helper.Unit.right_mouse_just_down = false
Helper.Unit.new_team_key_just_pressed = false
Helper.Unit.number_of_teams = 0

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
    unit.selected = false

    Helper.Unit.add_default_state_change_functions(unit)
    Helper.Unit.add_default_state_always_run_functions(unit)

    if is_in_list(Helper.Unit.get_list(true), unit) then
        unit.is_troop = true
    else
        unit.is_troop = false
    end
end

function Helper.Unit.claim_target(unit, target)
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

function Helper.Unit.unclaim_target(unit)
    if unit.have_target then
        table.remove(unit.claimed_target.targeted_by, find_in_list(unit.claimed_target.targeted_by, unit))
        unit.have_target = false
    end
end

function Helper.Unit.can_cast(unit)
    return unit.state == unit_states['normal'] and not unit.have_target
    and Helper.Time.time - unit.last_attack_finished > unit.cooldownTime
    and Helper.Spell.there_is_target_in_range(unit, unit.attack_sensor.rs)
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
    local time_since_cast = Helper.Time.time - (unit.last_attack_finished or 0)
    if unit.cooldownTime and time_since_cast < unit.cooldownTime then
        return true
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
end



function Helper.Unit:select()
    if main.selectedCharacter == 'selection' then
        if love.mouse.isDown(1) then
            if not mouse_just_down then
                self.x1 = Helper.mousex
                self.y1 = Helper.mousey
                self.do_draw_selection = true
            end

            self.x2 = Helper.mousex
            self.y2 = Helper.mousey
            
            for i, unit in ipairs(self.get_list(true)) do
                if Helper.Geometry.is_inside_rectangle(unit.x, unit.y, self.x1, self.y1, self.x2, self.y2) then
                    unit.selected = true
                else
                    unit.selected = false
                end
            end

            mouse_just_down = true
        else
            if mouse_just_down then
                self.do_draw_selection = false
            end
            mouse_just_down = false

            if love.mouse.isDown(2) then
                if not self.right_mouse_just_down then
                    for i, unit in ipairs(self.get_list(true)) do
                        if unit.selected then
                            unit.target_pos = {x = Helper.mousex, y = Helper.mousey}
                            unit.state = unit_states['rallying']
                        end
                    end
                end
                self.right_mouse_just_down = true
            else
                self.right_mouse_just_down = false
            end
        end
    end

    -- if love.keyboard.isDown( "t" ) then
    --     if not self.new_team_key_just_pressed then
    --         local b = HotbarButton{group = self.ui, x = 50 , y = 50, force_update = true, button_text = 'selection', fg_color = 'white', bg_color = 'bg', action = function() self:select_character('team' .. self.number_of_teams + 1) end}
    --         Arena:add_hotbar_button(b)
    --         self.number_of_teams = self.number_of_teams + 1
    --     end
    --     self.new_team_key_just_pressed = true
    -- else
    --     self.new_team_key_just_pressed = false
    -- end
end

function Helper.Unit:draw_selection()
    if self.do_draw_selection then
        Helper.Graphics.draw_dashed_rectangle(Helper.Color.white, 2, 8, 4, Helper.Time.time * 80, self.x1, self.y1, self.x2, self.y2)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    for i, unit in ipairs(self.get_list(true)) do
        if unit.selected then
            love.graphics.circle('line', unit.x, unit.y, 5)
        end
    end
end
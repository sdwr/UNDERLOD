Helper.Unit = {}

Helper.Unit.cast_flash_duration = 0.08
Helper.Unit.do_draw_points = false

function Helper.Unit:clear_all_target_flags()
    -- Clear target flags from all enemies
    local enemies = self:get_list(false) -- false = get enemies
    for _, enemy in ipairs(enemies) do
        enemy.is_targeted = false
    end
end

function Helper.Unit:get_list(troop_list)
    if troop_list == nil then
        return {}
    end

    --will not work with subclasses for troop
    --the Group:get_objects_by_class method is efficient
    --and searching by self.is_troop will be slow
    --can maybe make a list of all troop types, but that kinda sucks
    --

    local class_list = {}
    if troop_list then
        class_list = main.current.friendlies
    else
        class_list = main.current.enemies
    end

    if not class_list then
        return {}
    end

    return main.current.main:get_objects_by_classes(class_list)
end

function Helper.Unit:sort_by_distance(unit_list, unit)
    local units_and_distances = {}
    for i, target in ipairs(unit_list) do
        table.insert(units_and_distances, {unit = target, distance = Helper.Geometry:distance(unit.x, unit.y, target.x, target.y)})
    end
    table.sort(units_and_distances, function(a, b) return a.distance < b.distance end)
    local sorted_units = {}
    for i, unit_and_distance in ipairs(units_and_distances) do
        table.insert(sorted_units, unit_and_distance.unit)
    end
    return sorted_units
end

function Helper.Unit:get_closest_unit(team, location)
    if not team then return nil, nil end

    local closest_unit = nil
    local closest_distance = 999999

    for _, troop in ipairs(team.troops) do
        if troop and not troop.dead then
            local dist = Helper.Geometry:distance(location.x, location.y, troop.x, troop.y)
            if dist < closest_distance then
                closest_unit = troop
                closest_distance = dist
            end
        end
    end
    return closest_unit, closest_distance
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

function Helper.Unit:all_troops_are_dead()
    for i, unit in ipairs(Helper.Unit:get_list(true)) do
        if unit.is and unit:is(Troop) and not unit.dead then
            return false
        end
    end
    return true
end

function Helper.Unit:add_custom_variables_to_unit(unit)

    unit.state_change_functions = {}
    unit.state_always_run_functions = {}
    unit.last_attack_started = -999999
    unit.last_attack_finished = -999999
    unit.ignore_cooldown = false
    unit.death_function = function()

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

function Helper.Unit:state_allows_movement(unit, state)
    local states_can_move = unit.is_troop and unit_states_can_move or unit_states_enemy_can_move

    if not table.contains(states_can_move, state) then
        return false
    end

    if unit.is_troop and unit.being_knocked_back and Helper.Unit:block_troop_movement() then
        return false
    end

    return true
end

function Helper.Unit:set_state(unit, state)

    --dont change state if troops cant move
    if unit.is_troop and not Helper.Unit:state_allows_movement(unit, state) then
        return
    end

    local previous_state = unit.state
    unit.state = state

    if previous_state ~= state then
        Helper.Unit:reset_animations(unit)
        if unit.state_change_functions and unit.state_change_functions[state] then
            unit.state_change_functions[state](unit)
        end
    end
end

-- looks like this is for "least targeted" targeting
function Helper.Unit:claim_target(unit, target)
    if target ~= -1 then
        if unit.target then
            if unit.target == target then
                return
            end
        end
        unit:set_target(target)
    end
end

--this should remove the target from the unit as well?
function Helper.Unit:unclaim_target(unit)
    --only clear my target, not assigned target
    if unit.target then
        unit:clear_my_target()
    end
end

--doesnt check target points, just center
function Helper.Unit:target_out_of_range(unit, target)
    return target and Helper.Geometry:distance(unit.x, unit.y, target.x, target.y) > unit.attack_sensor.rs
end

function Helper.Unit:in_range_of_rally_point(unit)
    if not unit.target_pos then 
        return false
    end
    return math.distance(unit.x, unit.y, unit.target_pos.x, unit.target_pos.y) < RALLY_CIRCLE_STOP_DISTANCE
end

function Helper.Unit:cast_off_cooldown(unit)
    return unit.attack_cooldown_timer <= 0
end

function Helper.Unit:cast_off_cooldown_distance_multiplier(unit, target)
    if target and target.x and target.y and unit.x and unit.y then
        -- Calculate distance multiplier based on actual target, not closest enemy
        local distance_multiplier = Helper.Target:get_distance_multiplier(unit, target)

        local adjusted_cooldown = unit.attack_cooldown * distance_multiplier

        local elapsed_cooldown
        if unit.attack_cooldown_timer > 0 then
            elapsed_cooldown = unit.attack_cooldown - unit.attack_cooldown_timer
        else
            elapsed_cooldown = math.abs(unit.attack_cooldown * -1 + unit.attack_cooldown_timer)
        end

        return adjusted_cooldown <= elapsed_cooldown
    else
        return Helper.Unit:cast_off_cooldown(unit)
    end
end

function Helper.Unit:can_cast(unit, target)
    -- We can only cast if we have a valid target in the first place.
    if unit and not unit.castObject and target then
        if not table.any(unit_states_can_cast, function(v) return unit.state == v end) then
            return false
        end
        return Helper.Unit:cast_off_cooldown(unit)
    end
    return false
end


function Helper.Unit:start_casting(unit)
    if unit then
        Helper.Unit:set_state(unit, unit_states['casting'])
        unit.last_attack_started = Helper.Time.time
    end
end

function Helper.Unit:finish_casting(unit)
    if unit then
        if unit.end_cast then
            unit:end_cast()
        end
        unit.last_attack_finished = Helper.Time.time
        if unit.state == unit_states['casting'] then
            Helper.Unit:set_state(unit, unit_states['idle'])
        end
    end
end

function Helper.Unit:add_default_state_change_functions(unit)
    unit.state_change_functions['normal'] = function(self) 
        self.state_change_functions['regain_control'](self)
    end
    unit.state_change_functions['idle'] = function(self) 
        self.state_change_functions['regain_control'](self)
        self.idleTimer = self.baseIdleTimer or 1.5
        self.idleTimer = self.idleTimer * random:float(0.8, 1.2)
    end
    unit.state_change_functions['moving'] = function(self) 
        self.state_change_functions['regain_control'](self)
    end
    unit.state_change_functions['frozen'] = function() end
    unit.state_change_functions['casting'] = function() end
    unit.state_change_functions['casting_blocked'] = function() end
    unit.state_change_functions['channeling'] = function() end
    unit.state_change_functions['stopped'] = function() end
    unit.state_change_functions['knockback'] = function(self)
        self.being_pushed = true
        self.steering_enabled = false
        --self:interrupt_cast()
    end
    unit.state_change_functions['following'] = function(self) 
        self.state_change_functions['regain_control'](self)
    end
    
    unit.state_change_functions['regain_control'] = function(self)
        self.being_pushed = false
        self.steering_enabled = true
    end
    unit.state_change_functions['death'] = function() end
    unit.state_change_functions['target_death'] = function() end
end

function Helper.Unit:add_default_state_always_run_functions(unit)
    unit.state_always_run_functions['normal'] = function(self) 
        self.state_always_run_functions['normal_or_stopped'](self)
    end
    unit.state_always_run_functions['idle'] = function(self) end 
    unit.state_always_run_functions['moving'] = function(self) end
    unit.state_always_run_functions['frozen'] = function() end
    unit.state_always_run_functions['stunned'] = function() end
    unit.state_always_run_functions['casting'] = function() end
    unit.state_always_run_functions['casting_blocked'] = function() end
    unit.state_always_run_functions['channeling'] = function() end
    unit.state_always_run_functions['knockback'] = function() end
    unit.state_always_run_functions['stopped'] = function(self) 
        self.state_always_run_functions['normal_or_stopped'](self)
    end
    unit.state_always_run_functions['following'] = function(self) end

    unit.state_always_run_functions['normal_or_stopped'] = function() end
    unit.state_always_run_functions['always_run'] = function() end
end

function Helper.Unit:reset_animations(unit)
    if unit.spritesheet and not unit.single_animation then
        for k, v in pairs(unit.spritesheet) do
            v[1]:gotoFrame(1)
        end
    end
end

function Helper.Unit:run_state_always_run_functions()
    for i, unit in ipairs(Helper.Unit:get_list(true)) do
        if unit.state_always_run_functions[unit.state] then
            unit.state_always_run_functions[unit.state](unit)
        else
            print('no state always run function for state', unit.state)
        end
        if unit.state_always_run_functions['always_run'] then
            unit.state_always_run_functions['always_run'](unit)
        end
    end
    for i, unit in ipairs(Helper.Unit:get_list(false)) do
        if unit.state_always_run_functions[unit.state] then
            unit.state_always_run_functions[unit.state](unit)
        else
            print('no state always run function for state', unit.state)
        end
        if unit.state_always_run_functions['always_run'] then
            unit.state_always_run_functions['always_run'](unit)
        end
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
-- Helper.Unit.selected_team_index = 0
Helper.Unit.selected_team_index = 1
Helper.Unit.flagged_enemy = -1
Helper.Unit.number_of_troop_types = 0
Helper.Unit.troop_type_button_width = 0
Helper.Unit.team_button_width = 0

function Helper.Unit:get_survivor_damage_boost(unit)
    -- local team = Helper.Unit:get_team_by_index(unit.team)
    -- if team then
    --     return team:get_survivor_damage_boost()
    -- end
    return 1
end

function Helper.Unit:get_survivor_size_boost(unit)
    -- local team = Helper.Unit:get_team_by_index(unit.team)
    -- if team then
    --     return team:get_survivor_size_boost()
    -- end
    return 1
end


function Helper.Unit:get_team_by_index(index)
    if index == nil or index < 1 or index > #Helper.Unit.teams then
        return nil
    end
    return Helper.Unit.teams[index]
end

function Helper.Unit:select_team(index)
    Helper.Unit:deselect_all_troops()
    local team = Helper.Unit:get_team_by_index(index)
    if team then
        team:select()
    end
end

function Helper.Unit:clear_all_rally_points()
    for i, team in ipairs(Helper.Unit.teams) do
        team:clear_rally_point()
    end
end


--target ring fns
function Helper.Unit:set_target_ring(target)
    if target then
        local targetBuff = {name = 'player_target', duration = 9999, color = Helper.Color.yellow}
        target:add_buff(targetBuff)
    end
end

function Helper.Unit:clear_target_ring(target)
    --clear the targeting ring around the target, if no other team is targeting it
    if not Helper.Unit:is_a_team_target(target) then
        if target then
            target:remove_buff('player_target')
        end
    end
end

function Helper.Unit:is_a_team_target(target)
    if target == nil then
        return false
    end

    for i, team in ipairs(Helper.Unit.teams) do
        if team.target == target then
            return true
        end
    end
    return false
end

function Helper.Unit:all_teams_target_flagged_enemy(enemy)
    for i, team in ipairs(Helper.Unit.teams) do
        team:clear_team_target()
        team:clear_rally_point()
        team:set_team_target(enemy)
    end
end

function Helper.Unit:all_teams_set_rally_point(x, y)
    for i, team in ipairs(Helper.Unit.teams) do
        team:clear_team_target()
        team:clear_rally_point()
        team:set_rally_point(x, y)
    end
end

function Helper.Unit:block_troop_movement()
    arena_states_cant_move = {
        'arena_start',
        'suction_to_targets',
    }
    if main and main.current and main.current.current_arena and 
    main.current.current_arena.spawn_manager then
        local state = main.current.current_arena.spawn_manager.state
        return table.any(arena_states_cant_move, function(v) return state == v end)
    end
end

function Helper.Unit:disable_unit_controls()
    Helper.disable_unit_controls = true
end

function Helper.Unit:enable_unit_controls()
    Helper.disable_unit_controls = false
end

function Helper.Unit:set_player_attack_location()
    Helper.player_attack_location = {x = Helper.mousex, y = Helper.mousey}
end

function Helper.Unit:reset_player_attack_location()
    Helper.player_attack_location = nil
end

--select + target from input
function Helper.Unit:select()
    if not Helper.disable_unit_controls then
        local flag = false
        --should be on key release, not press? or at least only check the first press

        if input['m1'].down then
            Helper.Unit:set_player_attack_location()
        else
            Helper.Unit:reset_player_attack_location()
        end
        
        local wasd_held = Helper.Unit.wasd_down

        Helper.Unit.movement_target = Helper.Unit:get_player_location()
        Helper.Unit.wasd_down = false
        Helper.Unit.wasd_pressed = false --this is only set to true if the key is pressed, not held
        Helper.Unit.wasd_released = false

        local key_to_direction = {
            ['w'] = {x = 0, y = -1},
            ['a'] = {x = -1, y = 0},
            ['s'] = {x = 0, y = 1},
            ['d'] = {x = 1, y = 0},
        }
        for key, direction in pairs(key_to_direction) do
            if input[key].down then
                Helper.Unit.wasd_down = true
                Helper.Unit.movement_target.x = Helper.Unit.movement_target.x + direction.x * 50
                Helper.Unit.movement_target.y = Helper.Unit.movement_target.y + direction.y * 50
            end
        end
        if not wasd_held and Helper.Unit.wasd_down then
            Helper.Unit.wasd_pressed = true
        end

        if wasd_held and not Helper.Unit.wasd_down then
            Helper.Unit.wasd_released = true
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

    -- for i = 1, #main.current.units do
    --     if input[tostring(i)].pressed and main.current.hotbar.hotbar_by_index[i] then
    --         main.current.hotbar.hotbar_by_index[i]:action_animation()
    --         main.current.hotbar:select_by_index(i)
    --     end

    --     if input[tostring(i)].released and main.current.hotbar.hotbar_by_index[i] then
    --         --unnecessary, leave here for now
    --     end
    -- end
end

function Helper.Unit:draw_selection()
    if self.do_draw_selection then
        Helper.Graphics:draw_dashed_rectangle(Helper.Color.white, 2, 8, 4, Helper.Time.time * 80, self.x1, self.y1, self.x2, self.y2)
    end
    love.graphics.setColor(1, 1, 1, 1)

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

function Helper.Unit:update_player_location()

    local player_location = {x = 0, y = 0}
    local number_of_alive_troops = 0
    for i, team in ipairs(Helper.Unit.teams) do
        for j, troop in ipairs(team.troops) do
            if not troop.dead then
                player_location.x = player_location.x + troop.x
                player_location.y = player_location.y + troop.y
                number_of_alive_troops = number_of_alive_troops + 1
            end
        end
    end
    if number_of_alive_troops > 0 then
        player_location.x = player_location.x / number_of_alive_troops
        player_location.y = player_location.y / number_of_alive_troops
    else
        player_location.x = gw / 2
        player_location.y = gh / 2
    end

    self.player_location = player_location
end

function Helper.Unit:get_player_location()
    return self.player_location
end

function Helper.Unit:in_range_of_player_location(unit, range)
    range = range or ARENA_RADIUS
    return math.distance(unit.x, unit.y, self.player_location.x, self.player_location.y) < range
end

function Helper.Unit:create_distance_tier_effects(tier)
    local troops = self:get_all_troops()
    for _, troop in ipairs(troops) do
        troop:create_distance_tier_effect(tier)
    end
end
    

function Helper.Unit:update_enemy_distance_tier()
    self.last_closest_enemy_distance_tier = self.closest_enemy_distance_tier or 999
    self.closest_enemy_distance_tier = get_distance_effect_tier(self.closest_enemy_distance)

    -- if self.closest_enemy_distance_tier and self.closest_enemy_distance_tier < self.last_closest_enemy_distance_tier then            --play tier effects
    --     if not self.tier_effect_debounce then
    --         self.tier_effect_debounce = {}
    --         for i = 1, #TIER_TO_DISTANCE do
    --             self.tier_effect_debounce[i] = 0
    --         end
    --     end
    --     --debounce to prevent spamming
    --     if self.tier_effect_debounce[self.closest_enemy_distance_tier] < Helper.Time.time then
    --         Helper.Sound:play_distance_multiplier_sound(self.closest_enemy_distance_tier)
    --         Helper.Unit:create_distance_tier_effects(self.closest_enemy_distance_tier)
    --         self.tier_effect_debounce[self.closest_enemy_distance_tier] = Helper.Time.time + 0.5
    --     end
    -- end

end

function Helper.Unit:update_closest_enemy()
    local closest_enemy = nil
    local closest_distance = 999999
    for i, enemy in ipairs(self:get_list(false)) do
        local distance = math.distance(enemy.x, enemy.y, self.player_location.x, self.player_location.y)
        local enemy_size = math.max(enemy.shape and enemy.shape.w or 0, enemy.shape and enemy.shape.h or 0)

        distance = distance - enemy_size / 2

        if distance < closest_distance then
            closest_enemy = enemy
            closest_distance = distance
        end
    end

    if closest_enemy then
        self.closest_enemy = closest_enemy
        self.closest_enemy_distance = closest_distance
        -- This global closest_enemy_distance_multiplier is now unused - cast_off_cooldown_distance_multiplier calculates per-target instead
        self.closest_enemy_distance_multiplier = Helper.Target:get_distance_multiplier(self.player_location, closest_enemy)
    else
        self.closest_enemy = nil
        self.closest_enemy_distance = nil
        self.closest_enemy_distance_multiplier = nil
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

function Helper.Unit:set_knockback_variables(unit)
    unit.being_knocked_back = true
    unit.steering_enabled = false
end

function Helper.Unit:reset_knockback_variables(unit)
    unit.being_knocked_back = false
    unit.steering_enabled = true
end

function Helper.Unit:apply_knockback(unit, force, angle)

    unit:apply_impulse(force * math.cos(angle), force * math.sin(angle))
    unit:apply_angular_impulse(random:table{random:float(-2*math.pi, -0.5*math.pi), random:float(0.5*math.pi, 2*math.pi)})
end

function Helper.Unit:apply_area_size_multiplier(unit, base_size)
    if unit and unit.area_size_m then
        return base_size * unit.area_size_m
    end
    return base_size
end

function Helper.Unit:apply_cooldown_reduction(proc, base_cooldown)
    -- For team-based procs, we need to find a troop to get the cooldown reduction from
    local unit = proc.unit
    if not unit then
        if proc.team then
            unit = proc.team:get_first_alive_troop()
        end
    end
    
    if unit and unit.cooldown_reduction then
        return base_cooldown * (1 - unit.cooldown_reduction)
    end
    return base_cooldown
end

-- ===================================================================
-- PERK PROCESSING HELPER FUNCTION
-- This function processes perk names based on unit type to determine
-- which stats should be applied to which unit types.
-- ===================================================================
function Helper.Unit:process_perk_name(stat, unit)
    -- Determine which stats to process based on unit type
    if unit:is(Troop) then
        -- Troops process stats without any prefix
        if not (string.sub(stat, 1, 6) == "enemy_" or 
               string.sub(stat, 1, 8) == "critter_" or 
               string.sub(stat, 1, 12) == "enemycritter_") then
            return stat -- Return the stat name unchanged
        end
        return false
    elseif unit:is(Critter) then
        -- Friendly critters process stats with "critter_" prefix
        if string.sub(stat, 1, 8) == "critter_" then
            return string.sub(stat, 9) -- Remove "critter_" prefix
        end
        return false
    elseif unit:is(EnemyCritter) then
        -- Enemy critters process stats with "enemycritter_" prefix
        if string.sub(stat, 1, 12) == "enemycritter_" then
            return string.sub(stat, 13) -- Remove "enemycritter_" prefix
        end
        return false
    elseif unit:is(Enemy) then
        -- Enemies process stats with "enemy_" prefix
        if string.sub(stat, 1, 6) == "enemy_" then
            return string.sub(stat, 7) -- Remove "enemy_" prefix
        end
        return false
    else
        print('no unit type for perk', stat, unit, unit.type, unit.class)
        return false
    end
end

-- ===================================================================
-- COMBAT DATA UPDATE FUNCTION
-- This function updates saved units with combat data from teams
-- ===================================================================
function Helper.Unit:update_units_with_combat_data(arena)
    if not arena then
        print('error saving combat stats: no arena')
        return
    end

  -- Update the saved units with combat data from teams
  for i, saved_unit in ipairs(arena.units) do
    -- Find the corresponding team by character and position
    for j, team in ipairs(Helper.Unit.teams) do
      if team.unit.character == saved_unit.character and j == i then
        -- Save combat data from team to saved unit
        team:save_combat_data_to_unit()
        break
      end
    end
  end
end

function Helper.Unit:update_unit_colors()
    local previous_teams = {}
    for _, team in pairs(Helper.Unit.teams) do
        if previous_teams[team.unit.character] then
            local color = character_colors[team.unit.character] or fg[0]
            color = color:clone():lighten(0.12 * previous_teams[team.unit.character])
            team.unit.color = color
            previous_teams[team.unit.character] = previous_teams[team.unit.character] + 1
        else
            local color = character_colors[team.unit.character] or fg[0]
            team.unit.color = color:clone()
            previous_teams[team.unit.character] = 1
        end

        for _, troop in pairs(team.troops) do
            troop.color = team.unit.color
        end
    end
end

function Helper.Unit:save_all_teams_hps()
    for _, team in pairs(Helper.Unit.teams) do
        local troop_hps = {}
        for _, troop in pairs(team.troops) do
          if troop.dead then
            table.insert(troop_hps, 0)
          else
            table.insert(troop_hps, troop.hp)
          end
        end
        team.unit.troop_hps = troop_hps
    end
end

function Helper.Unit:restore_all_teams_hps()
    for _, team in pairs(Helper.Unit.teams) do
        team.unit.troop_hps = nil
    end
end

function Helper.Unit:heal_all_teams_to_full()
  -- Cast a max strength max bounce healing wave to heal all units
  for _, team in pairs(Helper.Unit.teams) do
    local first_troop = team:get_first_alive_troop()
    if first_troop then
      -- Cast a powerful healing wave with maximum parameters
      ChainHeal{
        group = main.current.main,
        is_troop = first_troop.is_troop,
        parent = first_troop,
        target = first_troop,
        heal_amount = 999, -- Max healing amount
        max_chains = 20, -- Maximum bounces
        range = 600, -- Large range to hit all units
        color = green[0], -- Bright green healing color
      }
      break
    end
  end
end

function Helper.Unit:kill_all_teams()
    for _, team in pairs(Helper.Unit.teams) do
        team:die()
    end
end

function Helper.Unit:resurrect_all_teams()
    local tries_remaining = 20
    
    local resurrect_trigger = main.current.t:every(0.2, function()
        -- Check if there are any dead troops left
        local has_dead_troops = false
        for _, team in pairs(Helper.Unit.teams) do
            for _, troop in ipairs(team.troops) do
                if troop.dead then
                    has_dead_troops = true
                    local success = Helper.Unit:try_resurrect_troop(team, troop)
                    if success then
                        break
                    end
                end
            end
            if has_dead_troops then
                break
            end
        end
        if not has_dead_troops then
            main.current.t:cancel('resurrect_all_teams')
        end
    end, 20, nil, 'resurrect_all_teams')
end

-- ===================================================================
-- TROOP RESURRECTION HELPER FUNCTION
-- This function handles resurrecting a troop at a given location
-- ===================================================================
function Helper.Unit:try_resurrect_troop(team, troop)
    if not troop.dead then
        return false
    end
    
    -- Find a valid spawn location
    local spawn_attempts = 20
    local location = team:get_center()
    for i = 1, spawn_attempts do
        location.x = location.x + random:float(-10, 10)
        location.y = location.y + random:float(-10, 10)
        local spawn_circle = Circle(location.x, location.y, 3)
        local objects_in_spawn_area = main.current.main:get_objects_in_shape(spawn_circle, main.current.all_unit_classes)
        if #objects_in_spawn_area == 0 then
            -- Resurrect the troop at the valid location
            return Helper.Unit:resurrect_troop(team, troop, location, 0)
        end
    end
    print('failed to find spawn location for troop', troop)
    return false
end


function Helper.Unit:resurrect_troop(team, troop, location, invulnerable_duration, color)
  if not team then
    return nil
  end

  -- Remove the dead troop from the team if it exists
  if troop then
    for i, t in ipairs(team.troops) do
        if t == troop then
            table.remove(team.troops, i)
            removed_troop = true
        end
    end
  end
  
  local troop = team:add_troop(location.x, location.y)
  troop:set_invulnerable(invulnerable_duration or 0)
  
  Area{
    group = main.current.effects,
    x = location.x, y = location.y,
    pick_shape = 'circle',
    damage = 0,
    r = 6, duration = 0.4, color = color or white[0],
    is_troop = troop.is_troop,
    unit = troop,
    follow_unit = true,
  }
  
  holylight:play{pitch = random:float(0.8, 1.2), volume = 1.8}
  
  return troop
end

function Helper.Unit:find_available_inventory_slot(units, item)
  local slot_index = ITEM_SLOTS[item.slot].index

  if not slot_index then
    print('ERROR: cannot find slot for item type', item.slot)
    return nil, nil
  end

  for _, unit in ipairs(units) do
    if Helper.Unit:unit_has_open_inventory_slot(unit, slot_index) then
      return unit, slot_index
    end
  end
  return nil, nil
end

function Helper.Unit:unit_has_open_inventory_slot(unit, slot_index)
  if not unit.items[slot_index] then
    return true
  end
  return false
end

function Helper.Unit:get_all_troops()
    local troop_list = {}
    for _, team in pairs(Helper.Unit.teams) do
        for _, troop in pairs(team.troops) do
            table.insert(troop_list, troop)
        end
    end
    return troop_list
end

function Helper.Unit:all_troops_done_suction()
    for _, troop in pairs(Helper.Unit:get_all_troops()) do
        if troop.being_knocked_back then
            return false
        end
    end
    return true
end

function Helper.Unit:all_troops_begin_suction()
    for _, troop in pairs(Helper.Unit:get_all_troops()) do
        Helper.Unit:set_knockback_variables(troop)
        troop.max_v = SpawnGlobals.SUCTION_MAX_V
    end
end

function Helper.Unit:all_troops_end_suction()
    for _, team in pairs(Helper.Unit.teams) do
        team:clear_spawn_marker()
    end
    for _, troop in pairs(Helper.Unit:get_all_troops()) do
       Helper.Unit:troop_end_suction(troop)
    end
end

function Helper.Unit:troop_end_suction(troop)
    if troop.being_knocked_back then
        Helper.Unit:reset_knockback_variables(troop)
        troop.max_v = troop.mvspd
        troop:set_damping(get_damping_by_unit_class(troop.class))
    end
end

function Helper.Unit:get_unit_set_count(unit, setName)
  local set_counts = Helper.Unit:count_unit_set_pieces(unit)
  return set_counts[setName] or 0
end

function Helper.Unit:count_unit_set_pieces(unit)
  local set_counts = {}
  
  if not unit.items then 
    return set_counts 
  end

  for _, item in pairs(unit.items) do
    if item.sets and #item.sets > 0 then
      for _, setName in pairs(item.sets) do
        set_counts[setName] = (set_counts[setName] or 0) + 1
      end
    end
  end

  return set_counts
end

function Helper.Unit:clear_automatic_target(target)
    if target then
        target:remove_buff('automatic_targeted')
    end
end

function Helper.Unit:decrement_automatic_target(target)
    if target then
        local buff = target:get_buff('automatic_targeted')
        if buff then
            buff.count = buff.count - 1
            if buff.count <= 0 then
                target:remove_buff('automatic_targeted')
            end
        end
    end
end

function Helper.Unit:clear_manual_target()
    if Helper.manually_targeted_enemy then
        Helper.manually_targeted_enemy:remove_buff('manual_targeted')

        Helper.Unit:clear_automatic_target(Helper.manually_targeted_enemy)
        Helper.manually_targeted_enemy = nil
    end
end

function Helper.Unit:set_manual_target(target)
    Helper.Unit:clear_manual_target()
    Helper.manually_targeted_enemy = nil
    if not target or target.dead then
        return
    end

    Helper.manually_targeted_enemy = target
    --clear automatic target display (manual is bigger)
    Helper.Unit:clear_automatic_target(target)
    target:add_buff({name = 'manual_targeted', color = yellow[0], display_size = 2, duration = 9999})
end

function Helper.Unit:set_automatic_target(target)
    if not target or target.dead then return end

    if target:has_buff('manual_targeted') then
        return
    end

    local buff = target:get_buff('automatic_targeted')
    if buff then
        buff.count = buff.count + 1
    else
        buff = {name = 'automatic_targeted', color = yellow[0], count = 1, duration = 2}
        target:add_buff(buff)
    end    
end

-- Cycle through potential targets for manual targeting
function Helper.Unit:cycle_target()
    if not Helper.cycle_targets or #Helper.cycle_targets == 0 then
        return
    end

    local current_index = 0
    for i, target in ipairs(Helper.cycle_targets) do
        if target == Helper.manually_targeted_enemy then
            current_index = i
            break
        end
    end
  
  -- Cycle to next target
  local next_index = (current_index % #Helper.cycle_targets) + 1
  local new_target = Helper.cycle_targets[next_index]
  
  -- Set the new target with visual feedback
  Helper.Unit:set_manual_target(new_target)
  
  return new_target
end

-- Handle right-click for manual targeting
function Helper.Unit:try_target_enemy_with_right_click()
  -- Get mouse position in world coordinates
  local mouse_x = Helper.mousex
  local mouse_y = Helper.mousey
  
  -- Create a small detection area at mouse position to find enemies
  local detection_size = 20  -- Size of detection rectangle
  local detection_shape = Rectangle(mouse_x, mouse_y, detection_size, detection_size)
  
  -- Get all enemies in the detection area
  local enemies_in_area = main.current.main:get_objects_in_shape(detection_shape, main.current.enemies)
  
  -- Find the closest enemy among those detected
  local clicked_enemy = nil
  local min_distance = math.huge
  
  for _, enemy in ipairs(enemies_in_area) do
    if not enemy.dead and enemy.x and enemy.y then
      local dist = math.distance(enemy.x, enemy.y, mouse_x, mouse_y)
      if dist < min_distance then
        min_distance = dist
        clicked_enemy = enemy
      end
    end
  end
  
  -- Set or clear the target
  if clicked_enemy then
    Helper.Unit:set_manual_target(clicked_enemy)
    return true
  else
    return false
  end

end
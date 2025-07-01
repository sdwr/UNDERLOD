-- MainMenuAutoBattle.lua
-- Manages the autobattle system in the main menu background

MainMenuAutoBattle = Object:extend()
MainMenuAutoBattle:implement(GameObject)

function MainMenuAutoBattle:init(args)
    self:init_game_object(args)
    self.group = args.group or main.current.main
    self.floor = args.floor or main.current.floor
    
    -- Battle state
    self.battle_active = false
    
    -- Spawning settings
    self.team_spawn_timer = 0
    self.team_spawn_interval = 8 -- seconds between team spawns
    self.enemy_spawn_timer = 0
    self.enemy_spawn_interval = 3 -- seconds between enemy spawns
    
    -- Team and enemy lists
    self.teams = {}
    self.enemies = {}
    
    -- Unit tracking for Get_Random_Item function
    self.units = {}
    
    -- Spawn areas
    self.team_spawn_area = {
        x = gw/2 - 100,
        y = gh/2,
        w = 50,
        h = 100
    }
    
    self.enemy_spawn_area = {
        x = gw/2 + 100,
        y = gh/2,
        w = 50,
        h = 100
    }
    
    -- Available teams for spawning
    self.available_teams = {
        {character = 'archer', level = 1},
        {character = 'laser', level = 1},
    }
    
    self.available_enemies = {
        'seeker',
        'boomerang'
    }

    Reset_Global_Proc_List()
    
    self:start_battle()
end

function MainMenuAutoBattle:update(dt)
    if not self.battle_active then return end
    
    if #self.enemies < 3 then
      self:spawn_enemy()
    end

    if all_troops_dead(main.current) then
      self:spawn_team()
    end
    
    -- Clean up dead units
    self:cleanup_dead_units()
end

function MainMenuAutoBattle:draw()
    -- This object doesn't need to draw anything itself
    -- It just manages the battle system
end

function MainMenuAutoBattle:start_battle()
    self.battle_active = true
    self.battle_timer = 0
    self.team_spawn_timer = 0
    self.enemy_spawn_timer = 0
    
    -- Clear existing units
    self:clear_all_units()
    
    -- Spawn initial teams
    for i = 1, 2 do
        self:spawn_team(i)
    end
    
    -- Spawn initial enemies
    for i = 1, 2 do
        self:spawn_enemy()
    end
end

function MainMenuAutoBattle:end_battle()
    self.battle_active = false
    self:clear_all_units()
    
    -- Restart battle after a short delay
    self.t:after(2, function()
        self:start_battle()
    end)
end

function MainMenuAutoBattle:spawn_team(index)
    local team_data = random:table(self.available_teams)
    local x = self.team_spawn_area.x + random:float(-self.team_spawn_area.w/2, self.team_spawn_area.w/2)
    local y = self.team_spawn_area.y + random:float(-self.team_spawn_area.h/2, self.team_spawn_area.h/2)
    
    -- Generate random items for the team
    local items = self:generate_random_items()
    
    -- Create team with random items
    local team = Team(index, {
        group = self.group,
        x = x,
        y = y,
        character = team_data.character,
        level = team_data.level,
    })

    team:set_troop_data({
        group = self.group,
        x = x,
        y = y,
        character = team_data.character,
        level = team_data.level,
        items = items,
        passives = {}
    })
    
    if team then
        -- Add troops to the team
        for row_offset = 0, 4 do
            local troop_x = x + (0 * 20) -- Single column
            local troop_y = y + (row_offset * 10)
            team:add_troop(troop_x, troop_y)
        end
        
        -- Apply item procs to the team
        team:apply_item_procs()
        
        -- Add unit data to self.units for Get_Random_Item function
        local unit_data = {
            character = team_data.character,
            level = team_data.level,
            reserve = {0, 0},
            items = items,
            numItems = 6,
            team = team -- Store reference to team for cleanup
        }
        table.insert(self.units, unit_data)
        
        table.insert(self.teams, team)
    end
end

function MainMenuAutoBattle:generate_random_items()
    local items = {}
    
    -- Generate 2-4 random items
    local num_items = random:int(2, 4)
    for i = 1, num_items do
        local item = Get_Random_Item(3, main.current.units, nil)
        table.insert(items, item)
    end
    
    return items
end

function MainMenuAutoBattle:spawn_enemy()
    local enemy_type = random:table(self.available_enemies)
    local x = self.enemy_spawn_area.x + random:float(-self.enemy_spawn_area.w/2, self.enemy_spawn_area.w/2)
    local y = self.enemy_spawn_area.y + random:float(-self.enemy_spawn_area.h/2, self.enemy_spawn_area.h/2)
        
    local enemy = Spawn_Enemy(main.current, enemy_type, {x = x, y = y})
    if enemy then
        Spawn_Enemy_Effect(main.current, enemy)
        table.insert(self.enemies, enemy)
    end
end

function MainMenuAutoBattle:cleanup_dead_units()
    -- Clean up dead teams
    for i = #self.teams, 1, -1 do
        local team = self.teams[i]
        local all_dead = true
        for _, troop in ipairs(team.troops) do
            if not troop.dead then
                all_dead = false
                break
            end
        end
        if all_dead then
            -- Remove corresponding unit data from self.units
            for j = #self.units, 1, -1 do
                if self.units[j].team == team then
                    table.remove(self.units, j)
                    break
                end
            end
            table.remove(self.teams, i)
        end
    end
    
    -- Clean up dead enemies
    for i = #self.enemies, 1, -1 do
        if self.enemies[i].dead then
            table.remove(self.enemies, i)
        end
    end
end

function MainMenuAutoBattle:clear_all_units()
    -- Remove all teams
    for _, team in ipairs(self.teams) do
        if team then
            team:die()
        end
    end
    self.teams = {}
    
    -- Remove all enemies
    for _, enemy in ipairs(self.enemies) do
        if enemy and not enemy.dead then
            enemy:die()
        end
    end
    self.enemies = {}
end

function MainMenuAutoBattle:stop()
    self.battle_active = false
    self:clear_all_units()
end

function MainMenuAutoBattle:resume()
    if not self.battle_active then
        self:start_battle()
    end
end 
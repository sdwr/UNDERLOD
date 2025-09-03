--wave has a list {{enemy, #, nil}, {enemy, #, 'random'}, ...}
--enemy is the name of the enemy, # is the number to spawn
-- and random is where to spawn them relative to the last group

--each wave will be independent when it comes to spawn location

Wave_Types = {}

function Get_Random_Ranged_Enemy(tier)
  return 'burst'
  -- local enemy = random:table(special_enemy_by_tier[tier])
  -- while table.contains(special_enemy_by_tier_melee[tier], enemy) do
  --   enemy = random:table(special_enemy_by_tier[tier])
  -- end
  -- return enemy
end

function Get_Random_Special_Enemy(tier)
  return 'burst'
  -- local enemy = random:table(special_enemy_by_tier[tier])
  -- while table.contains(special_enemy_by_tier_melee[tier], enemy) do
  --   enemy = random:table(special_enemy_by_tier[tier])
  -- end
  -- return enemy
end

_last_group_type = 1

function Get_Next_Group(level)
  local tier = LEVEL_TO_TIER(level) or 1

  local chances = {20, 40, 100, 40}
  chances[_last_group_type] = chances[_last_group_type] / 2

  local options = {
    [1] = {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'},
    [2] = {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'scatter'},
    [3] = {'GROUP', 'boulder', 1, 'nil'},
    [4] = {'GROUP', Get_Random_Special_Enemy(tier), 1, 'nil'},
  }

  local choice = random:weighted_pick(unpack(chances))
  _last_group_type = choice
  return options[choice]
end


function Wave_Types:Create_Normal_Wave(level)
  local tier = LEVEL_TO_TIER(level)
  local num_special_enemies_left = get_num_special_enemies_by_level(level)
  local wave = {}

  --first set
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  --if only 1 speical enemy, save for round 2
  if num_special_enemies_left > 1 then
    table.insert(wave, {'GROUP', Get_Random_Special_Enemy(tier), 1, 'nil'})
    num_special_enemies_left = num_special_enemies_left - 1
  end
  table.insert(wave, {'DELAY', 1})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})

  table.insert(wave, {'DELAY', 3})

  --second set
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  if num_special_enemies_left > 0 then
    table.insert(wave, {'GROUP', Get_Random_Special_Enemy(tier), 1, 'close'})
    num_special_enemies_left = num_special_enemies_left - 1
  end
  if level == 2 then
    table.insert(wave, {'GROUP', 'archer', 1, 'close'})
  end

  if level <= 3 then return wave end

  table.insert(wave, {'DELAY', 1})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})

  if level <=3 then return wave end

  table.insert(wave, {'DELAY', 3})

  --third set
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'scatter'})
  if num_special_enemies_left > 0 then
    table.insert(wave, {'GROUP', Get_Random_Special_Enemy(tier), 1, 'nil'})
    num_special_enemies_left = num_special_enemies_left - 1
  end


  if num_special_enemies_left > 0 then
    table.insert(wave, {'DELAY', 3})
  end
  
  while num_special_enemies_left > 0 do
    table.insert(wave, {'DELAY', 2})
    table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
    if num_special_enemies_left > 0 then
      table.insert(wave, {'GROUP', Get_Random_Special_Enemy(tier), 1, 'close'})
      num_special_enemies_left = num_special_enemies_left - 1
    end
  end

  return wave
end

function Wave_Types:Create_Swarmer_Wave(level)
  local tier = LEVEL_TO_TIER(level)
  local wave = {}
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'scatter'})
  table.insert(wave, {'DELAY', 4})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'scatter'})
  table.insert(wave, {'DELAY', 2})
  local enemy = Get_Random_Ranged_Enemy(tier)
  table.insert(wave, {'GROUP', enemy, 2, 'last'})
  table.insert(wave, {'DELAY', 4})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'scatter'})
  table.insert(wave, {'DELAY', 4})
  local enemy = Get_Random_Ranged_Enemy(tier)
  table.insert(wave, {'GROUP', enemy, 2, 'last'})
  table.insert(wave, {'DELAY', 4})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'scatter'})

  return wave
end

-- function Wave_Types:Create_Ranged_Wave(level)
--   local tier = LEVEL_TO_TIER(level)

--   local RANGED_SPAWN_OFFSET = 50
--   local ranged_spawn_locations = {
--     {x = RANGED_SPAWN_OFFSET, y = RANGED_SPAWN_OFFSET},
--     {x = gw - RANGED_SPAWN_OFFSET, y = RANGED_SPAWN_OFFSET},
--     {x = RANGED_SPAWN_OFFSET, y = gh - RANGED_SPAWN_OFFSET},
--     {x = gw - RANGED_SPAWN_OFFSET, y = gh - RANGED_SPAWN_OFFSET},
--   }

--   local wave = {}
--   local enemy = Get_Random_Ranged_Enemy(tier)

--   table.insert(wave, {'GROUP', enemy, 1, 'location', ranged_spawn_locations[1]})
--   table.insert(wave, {'GROUP', enemy, 1, 'location', ranged_spawn_locations[2]})
--   table.insert(wave, {'GROUP', enemy, 1, 'location', ranged_spawn_locations[3]})
--   table.insert(wave, {'GROUP', enemy, 1, 'location', ranged_spawn_locations[4]})

--   return wave
-- end

function Wave_Types:Create_Close_Wave(level)
  local tier = LEVEL_TO_TIER(level)

  local wave = {}
  local enemy = random:table(special_enemy_by_tier[tier])

  table.insert(wave, {'GROUP', enemy, 2, 'nil'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  table.insert(wave, {'DELAY', 5})
  local enemy = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', enemy, 2, 'nil'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  local enemy = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', enemy, 2, 'nil'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  return wave
end

function Wave_Types:Create_Kicker_Wave(level)
  local tier = LEVEL_TO_TIER(level)
  local wave = {}
  local enemy = random:table(special_enemy_by_tier[tier])
  local enemy2 = random:table(special_enemy_by_tier[tier])

  table.insert(wave, {'GROUP', enemy2, 1, 'scatter'})
  table.insert(wave, {'GROUP', enemy2, 1, 'scatter'})
  table.insert(wave, {'DELAY', 5})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  table.insert(wave, {'GROUP', enemy2, 2, 'scatter'})
  table.insert(wave, {'GROUP', enemy2, 1, 'scatter'})
  table.insert(wave, {'DELAY', 5})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})

  return wave
end

function Wave_Types:Get_Waves(level)
  local waves = {}
  local wave = {}
  
  -- Calculate target power for this level
  local target_power = ROUND_POWER_BY_LEVEL(level) or 3000
  local current_power = 0
  local power_budget = target_power - current_power
  
  -- Determine tier for this level
  local tier = LEVEL_TO_TIER(level)

  for i = 1, WAVES_PER_LEVEL(level) do
    local wave_type = 'Create_Swarmer_Wave'
    if level == 1 or level ==3 then
      wave_type = 'Create_Normal_Wave'
    end

    local wave = self[wave_type](self, level)

    table.insert(waves, wave)
  end
  
  return waves
end

--helper fns
function Wave_Types:Get_Round_Power(waves)
  local power = 0
  for i, wave in ipairs(waves) do
    power = power + self:Get_Wave_Power(wave)
  end
  return power
end

function Wave_Types:Get_Waves_Power(waves)
  local power = 0
  local waves_power = {}
  for i, wave in ipairs(waves) do
    waves_power[i] = self:Get_Wave_Power(wave)
  end
  return waves_power
end

function Wave_Types:Get_Wave_Power(wave)
  local power = 0
  for i, instruction in ipairs(wave) do
    if instruction[1] == 'GROUP' then
      local enemy = instruction[2]
      local number = instruction[3]
      power = power + enemy_to_round_power[enemy] * number
    elseif instruction[1] == 'DELAY' then
      power = power + 0
    else
      power = power + 0
    end
  end
  return power
end

function Wave_Types:Get_Group_Power(group)
  local enemy = group[2]
  local number = group[3]
  local power = enemy_to_round_power[enemy] * number

  return power
end

function Wave_Types:Find_First_Special(waves)
  for i, wave in ipairs(waves) do
    local special = Wave_Types:Find_First_Special_In_Wave(wave)
    if special then
      return special
    end
  end
end

function Wave_Types:Find_First_Special_In_Wave(wave)
  for i, instruction in ipairs(wave) do
    if instruction[1] == 'GROUP' then
      local enemy = instruction[2]
      if enemy_to_round_power[enemy] and enemy_to_round_power[enemy] > 100 then
        return instruction
      end
    end
  end
end


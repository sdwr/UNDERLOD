--wave has a list {{enemy, #, nil}, {enemy, #, 'random'}, ...}
--enemy is the name of the enemy, # is the number to spawn
-- and random is where to spawn them relative to the last group

--each wave will be independent when it comes to spawn location

Wave_Types = {}

function Get_Random_Ranged_Enemy(tier)
  local enemy = random:table(special_enemy_by_tier[tier])
  while table.contains(special_enemy_by_tier_melee[tier], enemy) do
    enemy = random:table(special_enemy_by_tier[tier])
  end
  return enemy
end

function Wave_Types:Create_Swarmer_Wave(level)
  local tier = LEVEL_TO_TIER(level)
  local wave = {}
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'distant'})
  table.insert(wave, {'DELAY', 4})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'distant'})
  table.insert(wave, {'DELAY', 2})
  local enemy = Get_Random_Ranged_Enemy(tier)
  table.insert(wave, {'GROUP', enemy, 2, 'last'})
  table.insert(wave, {'DELAY', 4})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'distant'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'distant'})
  table.insert(wave, {'DELAY', 4})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'distant'})
  table.insert(wave, {'DELAY', 2})
  local enemy = Get_Random_Ranged_Enemy(tier)
  table.insert(wave, {'GROUP', enemy, 3, 'last'})
  table.insert(wave, {'DELAY', 4})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'distant'})

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
  table.insert(wave, {'GROUP', enemy, 2, 'nil'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  table.insert(wave, {'GROUP', enemy, 2, 'nil'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  table.insert(wave, {'DELAY', 5})
  table.insert(wave, {'GROUP', enemy, 3, 'nil'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  table.insert(wave, {'GROUP', enemy, 3, 'nil'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  table.insert(wave, {'DELAY', 5})
  table.insert(wave, {'GROUP', enemy, 3, 'nil'})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  return wave
end

function Wave_Types:Create_Kicker_Wave(level)
  local tier = LEVEL_TO_TIER(level)
  local wave = {}
  local enemy = random:table(special_enemy_by_tier[tier])
  local enemy2 = random:table(special_enemy_by_tier[tier])

  table.insert(wave, {'GROUP', enemy, 2, 'scatter'})
  table.insert(wave, {'GROUP', enemy, 2, 'scatter'})
  table.insert(wave, {'GROUP', enemy2, 1, 'scatter'})
  table.insert(wave, {'GROUP', enemy2, 1, 'scatter'})
  table.insert(wave, {'DELAY', 5})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})
  table.insert(wave, {'GROUP', enemy, 3, 'scatter'})
  table.insert(wave, {'GROUP', enemy, 3, 'scatter'})
  table.insert(wave, {'GROUP', enemy2, 2, 'scatter'})
  table.insert(wave, {'GROUP', enemy2, 2, 'scatter'})
  table.insert(wave, {'DELAY', 5})
  table.insert(wave, {'GROUP', 'swarmer', SWARMERS_PER_LEVEL(level), 'nil'})

  return wave
end

function Wave_Types:Get_Waves(level)
  local waves = {}
  local wave = {}
  
  -- Calculate target power for this level
  local target_power = ROUND_POWER_BY_LEVEL[level] or 3000
  local current_power = 0
  local power_budget = target_power - current_power
  
  -- Determine tier for this level
  local tier = LEVEL_TO_TIER(level)

  for i = 1, WAVES_PER_LEVEL(level) do
    local wave_type = random:table({
      'Create_Swarmer_Wave',
      'Create_Close_Wave',
      'Create_Kicker_Wave',
    })

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


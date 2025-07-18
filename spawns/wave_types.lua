--wave has a list {{enemy, #, nil}, {enemy, #, 'random'}, ...}
--enemy is the name of the enemy, # is the number to spawn
-- and random is where to spawn them relative to the last group

--each wave will be independent when it comes to spawn location

Wave_Types = {}

function Wave_Types:Add_Special_Enemy(wave, power_budget, tier)
  local special_enemy = random:table(special_enemy_by_tier[tier])
  local max_num_enemies_in_budget = math.floor(power_budget / (enemy_to_round_power[special_enemy] or 300))
  local max_enemies_in_group = math.min(max_num_enemies_in_budget, MAX_SPECIAL_ENEMY_GROUP_SIZE_BY_TIER[tier])
  local num_enemies_in_group = math.random(1, max_enemies_in_group)
  table.insert(wave, {'GROUP', special_enemy, num_enemies_in_group, 'nil'})
  return (enemy_to_round_power[special_enemy] or 300) * num_enemies_in_group
end

function Wave_Types:Add_Normal_Enemy(wave, power_budget, tier)
  local normal_enemy = random:table(normal_enemy_by_tier[tier])
  local max_num_enemies_in_budget = math.floor(power_budget / (enemy_to_round_power[normal_enemy] or 100))
  local max_enemies_in_group = math.min(max_num_enemies_in_budget, MAX_NORMAL_ENEMY_GROUP_SIZE_BY_TIER[tier])
  local num_enemies_in_group = math.random(1, max_enemies_in_group)
  table.insert(wave, {'GROUP', normal_enemy, num_enemies_in_group, 'nil'})
  return (enemy_to_round_power[normal_enemy] or 100) * num_enemies_in_group
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
  
  -- Step 1: Add a special enemy from the correct tier
  current_power = current_power + self:Add_Special_Enemy(wave, power_budget, tier)
  power_budget = target_power - current_power

  while power_budget > 0 do
    if math.random() < CHANCE_OF_SPECIAL_VS_NORMAL_ENEMY then
      current_power = current_power + self:Add_Special_Enemy(wave, power_budget, tier)
    else
      current_power = current_power + self:Add_Normal_Enemy(wave, power_budget, tier)
    end
    power_budget = target_power - current_power
  end
  
  table.insert(waves, wave)
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


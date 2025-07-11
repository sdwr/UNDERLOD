--wave has a list {{enemy, #, nil}, {enemy, #, 'random'}, ...}
--enemy is the name of the enemy, # is the number to spawn
-- and random is where to spawn them relative to the last group

--each wave will be independent when it comes to spawn location

Wave_Types = {}


function Wave_Types:Get_Waves(level)
  local waves = {}
  local wave = {}
  
  -- Calculate target power for this level
  local target_power = 500 + (level - 1) * 200
  local current_power = 0
  
  -- Determine tier for this level
  local tier = 1
  if level <= 5 then
    tier = 1
  elseif level <= 10 then
    tier = 1.5
  elseif level <= 15 then
    tier = 2
  else
    tier = 2.5
  end

  if level == 1 then
    table.insert(wave, {'GROUP', 'seeker', 1, 'random'})
    table.insert(wave, {'GROUP', 'chaser', 2, 'random'})
    table.insert(wave, {'GROUP', 'goblin_archer', 2, 'random'})
    table.insert(waves, wave)
    return waves
  end
  
  if level == 2 then
    table.insert(wave, {'GROUP', 'seeker', 2, 'random'})
    table.insert(wave, {'GROUP', 'selfburst', 2, 'random'})
    table.insert(wave, {'GROUP', 'turret', 1, 'random'})
    table.insert(waves, wave)
    return waves
  end

  if level == 3 then
    table.insert(wave, {'GROUP', 'chaser', 2, 'random'})
    table.insert(wave, {'GROUP', 'snakearrow', 2, 'random'})
    table.insert(wave, {'GROUP', 'selfburst', 1, 'random'})
    table.insert(waves, wave)
    return waves
  end

  if level == 4 then
    table.insert(wave, {'GROUP', 'seeker', 2, 'random'})
    table.insert(wave, {'GROUP', 'goblin_archer', 2, 'random'})
    table.insert(wave, {'GROUP', 'cleaver', 1, 'random'})
    table.insert(waves, wave)
    return waves
  end
  
  -- Step 1: Add a special enemy from the correct tier
  local special_enemy = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', special_enemy, 1, 'nil'})
  current_power = current_power + (enemy_to_round_power[special_enemy] or 300)
  
  -- Step 2: If we have room, add a second special enemy (different type)
  if current_power + 500 <= target_power then
    local special_enemy2 = random:table(special_enemy_by_tier[tier])
    -- Make sure it's a different type
    while special_enemy2 == special_enemy do
      special_enemy2 = random:table(special_enemy_by_tier[tier])
    end
    table.insert(wave, {'GROUP', special_enemy2, 1, 'random'})
    current_power = current_power + (enemy_to_round_power[special_enemy2] or 300)
  end
  
  -- Step 3: Fill remaining power with normal enemies
  local remaining_power = target_power - current_power
  local normal_enemy_power = 100 -- Normal enemies are 100 power each
  
  if remaining_power >= normal_enemy_power then
    -- Add normal enemies to fill the remaining power
    local num_normal_enemies = math.floor(remaining_power / normal_enemy_power)
    
    if num_normal_enemies >= 2 then
      -- Decide on distribution: 2 of same type, or 2 of same + 1 different
      local distribution = random:table{1, 2} -- 1 = 2 same type, 2 = 2 same + 1 different
      
      if distribution == 1 then
        -- 2 of the same type
        local normal_enemy = random:table(normal_enemy_by_tier[tier])
        table.insert(wave, {'GROUP', normal_enemy, 2, 'random'})
      else
        -- 2 of same type + 1 different type
        local normal_enemy1 = random:table(normal_enemy_by_tier[tier])
        local normal_enemy2 = random:table(normal_enemy_by_tier[tier])
        -- Make sure they're different
        while normal_enemy2 == normal_enemy1 do
          normal_enemy2 = random:table(normal_enemy_by_tier[tier])
        end
        
        table.insert(wave, {'GROUP', normal_enemy1, 2, 'random'})
        table.insert(wave, {'GROUP', normal_enemy2, 1, 'random'})
      end
    else
      -- Just 1 normal enemy
      local normal_enemy = random:table(normal_enemy_by_tier[tier])
      table.insert(wave, {'GROUP', normal_enemy, 1, 'random'})
    end
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


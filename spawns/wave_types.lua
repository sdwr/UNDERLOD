
--wave has a list {{enemy, #, nil}, {enemy, #, 'close'}, ...}
--enemy is the name of the enemy, # is the number to spawn
-- and close is where to spawn them relative to the last group

--each wave will be independent when it comes to spawn location

Wave_Types = {}

function Wave_Types:Basic(tier)
  local wave = {}
  local enemy = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {enemy, 5, nil})
  return wave
end

function Wave_Types:Basic_Plus_One_Special(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {normal, 5, nil})
  table.insert(wave, {special, 1, 'close'})
  return wave
end

function Wave_Types:Basic_Plus_Two_Special(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {normal, 5, nil})
  table.insert(wave, {special, 1, 'close'})
  table.insert(wave, {special, 1, 'close'})
  return wave
end

function Wave_Types:Three_Lasers()
  local wave = {}
  table.insert(wave, {'laser', 1, nil})
  table.insert(wave, {'laser', 1, 'far'})
  table.insert(wave, {'laser', 1, 'random'})
  return wave
end

function Wave_Types:Mortar_And_Arc()
  local wave = {}
  table.insert(wave, {'mortar', 1, nil})
  table.insert(wave, {'arcspread', 1, 'random'})
  return wave
end

function Wave_Types:Get_Waves(level)
  local waves = {}
  local wave = nil
  if level == 1 then
    wave = self:Basic(1)
    table.insert(waves, wave)
  elseif level == 2 then
    wave = self:Basic_Plus_One_Special(1)
    table.insert(waves, wave)
  elseif level == 3 then
    wave = self:Basic_Plus_One_Special(1)
    table.insert(waves, wave)
    wave = self:Basic_Plus_Two_Special(1)
    table.insert(waves, wave)
    wave = self:Three_Lasers()
    table.insert(waves, wave)
  elseif level == 4 then
    wave = self:Three_Lasers()
    table.insert(waves, wave)
    wave = self:Three_Lasers()
    table.insert(waves, wave)
    wave = self:Three_Lasers()
    table.insert(waves, wave)
  else
    wave = self:Basic_Plus_One_Special(2)
    table.insert(waves, wave)
    wave = self:Basic_Plus_Two_Special(2)
    table.insert(waves, wave)
    wave = self:Mortar_And_Arc()
    table.insert(waves, wave)
  end
  return waves
end

--helper fns
function Wave_Types:Get_Round_Power(waves)
  local power = 0
  for i, wave in ipairs(waves) do
    for j, group in ipairs(wave) do
      local enemy = group[1]
      local number = group[2]
      power = power + enemy_to_round_power[enemy] * number
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
  for i, group in ipairs(wave) do
    local enemy = group[1]
    if enemy_to_round_power[enemy] and enemy_to_round_power[enemy] > 100 then
      return group
    end
  end
end

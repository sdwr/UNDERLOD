--wave has a list {{enemy, #, nil}, {enemy, #, 'random'}, ...}
--enemy is the name of the enemy, # is the number to spawn
-- and random is where to spawn them relative to the last group

--each wave will be independent when it comes to spawn location

Wave_Types = {}

function Wave_Types:Generic(tier, basic, special)
  local wave = {}
  local basics_in_a_row = 0
  while basic > 0 or special > 0 do
    if basic >= special then
      local enemy = random:table(normal_enemy_by_tier[tier])
      table.insert(wave, {enemy, NORMAL_ENEMIES_PER_GROUP, nil})
      basic = basic - 1
      basics_in_a_row = basics_in_a_row + 1
    elseif basics_in_a_row >= 2 and special > 0 then
      local enemy = random:table(special_enemy_by_tier[tier])
      table.insert(wave, {enemy, 1, 'random'})
      special = special - 1
      basics_in_a_row = 0
    else
      local enemy = random:table(special_enemy_by_tier[tier])
      table.insert(wave, {enemy, 1, 'random'})
      special = special - 1
      basics_in_a_row = 0
    end
  end
  return wave
end

function Wave_Types:Basic(tier)
  local wave = {}
  local enemy = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {enemy, NORMAL_ENEMIES_PER_GROUP, nil})
  return wave
end

function Wave_Types:Two_Basic(tier)
  local wave = {}
  local enemy = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {enemy, NORMAL_ENEMIES_PER_GROUP, nil})
  enemy = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {enemy, NORMAL_ENEMIES_PER_GROUP, nil})
  return wave
end

function Wave_Types:Basic_Plus_One_Special(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {normal, NORMAL_ENEMIES_PER_GROUP, nil})
  table.insert(wave, {special, 1, 'random'})
  return wave
end

function Wave_Types:Basic_Plus_Two_Special(tier)
  local wave = {}
  -- local special = random:table(special_enemy_by_tier[tier])
  local special = 'laser'
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {normal, NORMAL_ENEMIES_PER_GROUP, nil})
  table.insert(wave, {special, 1, 'close'})
  table.insert(wave, {special, 1, 'close'})
  return wave
end

function Wave_Types:Basic_Special_Basic(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {normal, NORMAL_ENEMIES_PER_GROUP, nil})
  table.insert(wave, {special, 1, 'random'})
  table.insert(wave, {normal, 5, 'random'})
  return wave
end

function Wave_Types:Two_Basic_Three_Special(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {special, 1, nil})
  table.insert(wave, {normal, 2, 'random'})
  table.insert(wave, {special, 1, 'random'})
  table.insert(wave, {normal, 2, 'random'})
  table.insert(wave, {special, 1, 'random'})
  return wave
end

function Wave_Types:Amount_Special(amount, tier)
  local wave = {}
  
  for i = 1, amount-1 do
    local special = random:table(special_enemy_by_tier[tier])
    table.insert(wave, {special, 1, nil})
    local normal = random:table(normal_enemy_by_tier[tier])
    table.insert(wave, {normal, 1, 'random'})
  end

  local special = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {special, 1, nil})


  return wave
end

function Wave_Types:One_Cleaver()
  local wave = {}
  table.insert(wave, {'cleaver', 1, nil})
  return wave
end

function Wave_Types:Two_Cleavers()
  local wave = {}
  table.insert(wave, {'cleaver', 2, nil})
  return wave
end

function Wave_Types:Two_Cleavers_Plus_One_Special(tier)
  local wave = {}
  table.insert(wave, {'cleaver', 2, 'close'})
  local special = random:table(special_enemy_by_tier[tier])
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

function Wave_Types:Two_Basic_Two_Firewall(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {normal, NORMAL_ENEMIES_PER_GROUP, nil})
  table.insert(wave, {'firewall_caster', 1, 'random'})
  table.insert(wave, {'firewall_caster', 1, 'random'})
  return wave
end

function Wave_Types:Basic_Plus_Two_Burst(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {normal, NORMAL_ENEMIES_PER_GROUP, nil})
  table.insert(wave, {'burst', 1, 'random'})
  table.insert(wave, {'burst', 1, 'random'})
  return wave
end

function Wave_Types:Basic_Plus_Two_Boomerang(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {normal, NORMAL_ENEMIES_PER_GROUP, nil})
  table.insert(wave, {'boomerang', 1, 'random'})
  table.insert(wave, {'boomerang', 1, 'random'})
  return wave
end

function Wave_Types:Add_Group(wave, group)
  table.insert(wave, group)
end

function Wave_Types:Get_Waves(level)
  local waves = {}
  local wave = nil
  if level == 1 then
    wave = self:One_Cleaver()
    table.insert(waves, wave)
    wave = self:Two_Cleavers()
    table.insert(waves, wave)
  elseif level == 2 then
    wave = self:Two_Cleavers()
    table.insert(waves, wave)
    wave = self:Basic_Plus_One_Special(1)
    table.insert(waves, wave)
  elseif level == 3 then
    wave = self:Basic_Plus_Two_Special(1)
    self:Add_Group(wave, {'burst', 1, 'kicker'})
    table.insert(waves, wave)
    wave = self:Two_Cleavers_Plus_One_Special(1)
    table.insert(waves, wave)
  elseif level == 4 then
    wave = self:Basic_Plus_Two_Burst(1)
    table.insert(waves, wave)
    wave = self:Generic(1, 2, 2)
    table.insert(waves, wave)
  elseif level == 5 then
    wave = self:Basic_Plus_Two_Boomerang(1)
    table.insert(waves, wave)
    wave = self:Two_Basic_Three_Special(1)
    table.insert(waves, wave)
  elseif level == 7 then
    wave = self:Mortar_And_Arc()
    table.insert(waves, wave)
    wave = self:Two_Basic_Three_Special(2)
    table.insert(waves, wave)
  elseif level == 8 then
    wave = self:Two_Basic_Three_Special(2)
    table.insert(waves, wave)
    wave = self:Two_Basic_Three_Special(2)
    table.insert(waves, wave)
  elseif level == 9 then
    wave = self:Two_Basic_Two_Firewall(2)
    table.insert(waves, wave)
    wave = self:Two_Basic_Two_Firewall(2)
    table.insert(waves, wave)
    --when there are lots of enemies, they should all be spawning far
  else
    wave = self:Generic(1, 2, 4)
    table.insert(waves, wave)
    wave = self:Generic(1, 2, 4)
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
  for i, group in ipairs(wave) do
    local enemy = group[1]
    local number = group[2]
    power = power + enemy_to_round_power[enemy] * number
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


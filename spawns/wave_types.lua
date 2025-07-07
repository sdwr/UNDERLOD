--wave has a list {{enemy, #, nil}, {enemy, #, 'random'}, ...}
--enemy is the name of the enemy, # is the number to spawn
-- and random is where to spawn them relative to the last group

--each wave will be independent when it comes to spawn location

Wave_Types = {}

function Wave_Types:Generic(tier, basic, special)
  local wave = {}
  local basics_in_a_row = 0
  local first_group = true
  
  while basic > 0 or special > 0 do
    if basic >= special then
      local enemy = random:table(normal_enemy_by_tier[tier])
      local spawn_location = first_group and 'nil' or 'random'
      table.insert(wave, {'GROUP', enemy, NORMAL_ENEMIES_PER_GROUP, spawn_location})
      basic = basic - 1
      basics_in_a_row = basics_in_a_row + 1
      first_group = false
    elseif basics_in_a_row >= 2 and special > 0 then
      local enemy = random:table(special_enemy_by_tier[tier])
      local spawn_location = first_group and 'nil' or 'random'
      table.insert(wave, {'GROUP', enemy, 1, spawn_location})
      special = special - 1
      basics_in_a_row = 0
      first_group = false
    else
      local enemy = random:table(special_enemy_by_tier[tier])
      local spawn_location = first_group and 'nil' or 'random'
      table.insert(wave, {'GROUP', enemy, 1, spawn_location})
      special = special - 1
      basics_in_a_row = 0
      first_group = false
    end
  end
  return wave
end

function Wave_Types:Basic(tier)
  local wave = {}
  local enemy = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', enemy, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  return wave
end

function Wave_Types:Two_Basic(tier)
  local wave = {}
  local enemy = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', enemy, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  enemy = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', enemy, NORMAL_ENEMIES_PER_GROUP, 'random'})
  return wave
end

function Wave_Types:Basic_Plus_One_Special(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', special, 1, 'random'})
  return wave
end

function Wave_Types:Basic_Plus_Two_Special(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local special2 = random:table(special_enemy_by_tier[tier])
  --1.5 is for mortars
  if tier == 1.5 then
    tier = 1
  end
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', special, 1, 'close'})
  table.insert(wave, {'GROUP', special2, 1, 'close'})
  return wave
end

function Wave_Types:Basic_Special_Basic(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', special, 1, 'random'})
  table.insert(wave, {'GROUP', normal, 5, 'random'})
  return wave
end

function Wave_Types:Two_Basic_Three_Special(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', special, 1, 'nil'})
  table.insert(wave, {'GROUP', normal, 5, 'random'})
  table.insert(wave, {'GROUP', special, 1, 'random'})
  table.insert(wave, {'GROUP', normal, 5, 'random'})
  table.insert(wave, {'GROUP', special, 1, 'random'})
  return wave
end

function Wave_Types:Basic_Plus_Three_Special(tier)
  local wave = {}
  local special = random:table(special_enemy_by_tier[tier])
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', special, 1, 'random'})
  special = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', special, 1, 'random'})
  special = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', special, 1, 'random'})
  return wave
end

function Wave_Types:Amount_Special(amount, tier)
  local wave = {}
  
  for i = 1, amount-1 do
    local special = random:table(special_enemy_by_tier[tier])
    local spawn_location = (i == 1) and 'nil' or 'random'
    table.insert(wave, {'GROUP', special, 1, spawn_location})
    local normal = random:table(normal_enemy_by_tier[tier])
    table.insert(wave, {'GROUP', normal, 1, 'random'})
  end

  local special = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', special, 1, 'random'})

  return wave
end

function Wave_Types:One_Cleaver()
  local wave = {}
  table.insert(wave, {'GROUP', 'cleaver', 1, 'nil'})
  return wave
end

function Wave_Types:Two_Cleavers()
  local wave = {}
  table.insert(wave, {'GROUP', 'cleaver', 2, 'nil'})
  return wave
end

function Wave_Types:One_Basic_One_Cleaver(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', 'cleaver', 1, 'close'})
  return wave
end

function Wave_Types:One_Basic_Cleaver_One_Special(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  local special = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', special, 1, 'close'})
  table.insert(wave, {'GROUP', 'cleaver', 1, 'far'})
  return wave
end

function Wave_Types:Two_Cleavers_Plus_One_Special(tier)
  local wave = {}
  table.insert(wave, {'GROUP', 'cleaver', 2, 'close'})
  local special = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', special, 1, 'close'})
  return wave
end

function Wave_Types:Three_Lasers()
  local wave = {}
  table.insert(wave, {'GROUP', 'laser', 1, 'nil'})
  table.insert(wave, {'GROUP', 'laser', 1, 'far'})
  table.insert(wave, {'GROUP', 'laser', 1, 'random'})
  return wave
end

function Wave_Types:Mortar_And_Arc()
  local wave = {}
  table.insert(wave, {'GROUP', 'mortar', 1, 'nil'})
  table.insert(wave, {'GROUP', 'arcspread', 1, 'random'})
  return wave
end

function Wave_Types:Two_Basic_Two_Firewall(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', 'firewall_caster', 1, 'random'})
  table.insert(wave, {'GROUP', 'firewall_caster', 1, 'random'})
  return wave
end

function Wave_Types:Basic_Plus_Two_Burst(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', 'burst', 1, 'random'})
  table.insert(wave, {'GROUP', 'burst', 1, 'random'})
  return wave
end

function Wave_Types:Basic_Plus_Two_Boomerang(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', 'boomerang', 1, 'random'})
  table.insert(wave, {'GROUP', 'boomerang', 1, 'random'})
  return wave
end

function Wave_Types:One_Cleaver_One_Special_One_Basic(tier)
  local wave = {}
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'nil'})
  table.insert(wave, {'GROUP', 'cleaver', 1, 'nil'})
  local special = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', special, 1, 'random'})

  return wave
end

function Wave_Types:Add_Group(wave, group)
  table.insert(wave, group)
end

function Wave_Types:Add_Random_Kicker(wave, tier)
  local normal = random:table(normal_enemy_by_tier[tier])
  table.insert(wave, {'DELAY', 5.0})
  table.insert(wave, {'GROUP', normal, NORMAL_ENEMIES_PER_GROUP, 'random'})
  local special = random:table(special_enemy_by_tier[tier])
  table.insert(wave, {'GROUP', special, 1, 'random'})
  if math.random() < 0.5 then
    special = random:table(special_enemy_by_tier[tier])
    table.insert(wave, {'GROUP', special, 1, 'random'})
  end
  return wave
end

function Wave_Types:Get_Waves(level)
  local waves = {}
  local wave = nil
  if level == 1 then
    wave = self:One_Cleaver()
    table.insert(wave, {'GROUP', 'seeker', 4, 'random'})
    table.insert(waves, wave)
    local wave2 = {}
    table.insert(wave2, {'GROUP', 'cleaver', 1, 'nil'})
    table.insert(wave2, {'GROUP', 'cleaver', 1, 'far'})
    table.insert(waves, wave2)
  elseif level == 2 then
    wave = self:One_Basic_One_Cleaver(1)
    table.insert(waves, wave)
    wave = self:One_Basic_Cleaver_One_Special(1)
    table.insert(waves, wave)
  elseif level == 3 then
    -- Wave 1
    local wave1 ={
        {'GROUP', 'seeker', NORMAL_ENEMIES_PER_GROUP, 'nil'},
      {'GROUP', 'selfburst', 1, 'far'},
        {'GROUP', 'snakearrow', 1, 'random'},
    }
    -- Wave 2
    local wave2 = {
        {'GROUP', 'seeker', NORMAL_ENEMIES_PER_GROUP, 'nil'},
        {'GROUP', 'big_goblin_archer', 2, 'random'},
        {'GROUP', 'singlemortar', 1, 'random'},
    }
    table.insert(waves, wave1)
    table.insert(waves, wave2)
  elseif level == 4 then
    local wave1 = self:Basic_Plus_Two_Special(1)
    table.insert(waves, wave1)

    local special = random:table(special_enemy_by_tier[1])
    local wave2 = {
      {'GROUP', 'seeker', NORMAL_ENEMIES_PER_GROUP, 'nil'},
      {'GROUP', 'mortar', 1, 'random'},
      {'GROUP', special, 1, 'random'},
    }
    table.insert(waves, wave2)
  elseif level == 5 then
    wave = self:Basic_Plus_Two_Special(1)
    table.insert(waves, wave)
    local special = random:table(special_enemy_by_tier[1.5])
    local wave2 = {
      {'GROUP', 'mortar', 1, 'random'},
      {'GROUP', 'seeker', NORMAL_ENEMIES_PER_GROUP, 'random'},
      {'DELAY', 5.0},
      {'GROUP', 'seeker', NORMAL_ENEMIES_PER_GROUP, 'scatter'},
      {'GROUP', special, 1, 'random'}
    }
    table.insert(waves, wave2)
  elseif level == 7 then
    wave = self:Mortar_And_Arc()
    table.insert(wave, {'GROUP', 'shooter', NORMAL_ENEMIES_PER_GROUP, 'far'})
    table.insert(waves, wave)
    wave = self:Basic_Plus_Three_Special(2)
    table.insert(waves, wave)
  elseif level == 8 then
    wave = self:Basic_Plus_Three_Special(2)
    table.insert(waves, wave)
    wave = self:Basic_Plus_Two_Special(2)
    table.insert(wave, {'GROUP', 'seeker', NORMAL_ENEMIES_PER_GROUP, 'random'})
    table.insert(waves, wave)
  elseif level == 9 then
    wave = self:Two_Basic_Two_Firewall(2)
    table.insert(wave, {'DELAY', 2.0})
    table.insert(wave, {'GROUP', 'seeker', NORMAL_ENEMIES_PER_GROUP, 'random'})
    table.insert(waves, wave)
    wave = self:Two_Basic_Two_Firewall(2)
    table.insert(wave, {'DELAY', 5.0})
    table.insert(wave, {'GROUP', 'shooter', NORMAL_ENEMIES_PER_GROUP, 'random'})
    special = random:table(special_enemy_by_tier[2])
    table.insert(wave, {'GROUP', special, 1, 'random'})
    table.insert(waves, wave)
  else
    wave = self:Generic(1, 2, 4)
    table.insert(waves, wave)
    wave = self:Generic(1, 2, 4)
    if math.random() < 0.5 then
      wave = self:Add_Random_Kicker(wave, 1)
    end
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


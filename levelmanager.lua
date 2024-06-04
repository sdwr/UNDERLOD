
--not good but level round power calculated here
local round_power = 0


local function number_of_waves(level)
  if level <= 2  then
    return 1
  elseif level < 6 then
    return 2
  else 
    return 3
  end
end

local function special_enemy_tiers(level)
  if level == 1 then
    return {}
  elseif level < 4 then
    return {1}
  elseif level < 10 then
    return {1, 2}
  elseif level < 16 then
    return {1, 2, 3}
  else
    return {1, 2, 3, 2}
  end
end

local function boss_level(level)
  if level == 6 then
    return 'stompy'
  elseif level == 11 then
    return 'dragon'
  elseif level == 16 then
    return 'heigan'
  else
    return nil
  end
end

--only change 1 special enemy per wave, so we can have a mix of enemies
local function pick_special_enemies(level, previous)
  local tiers = special_enemy_tiers(level)
  local special_enemies = {}


  --make a new list
  if not previous or #previous == 0 then
    for i, tier in ipairs(tiers) do
      local enemies = special_enemy_by_tier[tier]
      local enemy = random:table(enemies)
      table.insert(special_enemies, enemy)
    end
    return special_enemies
  end
  --or switch out one enemy from the previous wave
  local swap_index = random:int(1, #previous)
  local swap_tier = find_tier_of_special_enemy(previous[swap_index])

  --keep swapping until we get a different enemy
  local new_enemy = random:table(special_enemy_by_tier[swap_tier])
  while new_enemy == previous[swap_index] do
    new_enemy = random:table(special_enemy_by_tier[swap_tier])
  end

  --swap out the enemy
  previous[swap_index] = new_enemy

  return previous
end


local function find_special_in_wave(wave)
  for i, enemy in ipairs(wave) do
    if enemy_to_round_power[enemy] and enemy_to_round_power[enemy] > 100 then
      return enemy
    end
  end
end

local function find_first_special(waves)
  for i, wave in ipairs(waves) do
    local special = find_special_in_wave(wave)
    if special then
      return special
    end
  end
end

function Build_Level_List(max_level)
  local level_list = {}
  for i = 1, max_level do
      level_list[i] = {level = i, waves = {}, round_power = 0, color = grey[0], environmental_hazards = {}}
  end

  for i = 1, max_level do
    if boss_level(i) then
      level_list[i].boss = boss_level(i)
      level_list[i].color = black[0]
      level_list[i].round_power = BOSS_ROUND_POWER

    else
      local waves = Decide_on_Spawns(i)
      level_list[i].waves = waves

      --find the first special enemy in the wave
      -- to use as the level color on the buy screen
      local first_special = find_first_special(waves)
      if first_special then
        level_list[i].color = enemy_to_color[first_special]
      end

      local environmental_hazards = Decide_on_Environmental_Hazards(i)
      level_list[i].environmental_hazards = environmental_hazards

      --calculate the round power for the level
      level_list[i].round_power = round_power
    end
  end

  return level_list
end

function Decide_on_Environmental_Hazards(level)
  if level % 4 == 0 then
    return {type = 'laser', level = level / 4}
  else
    return {}
  end
end

-- decide what to spawn based on level power
-- will need to be random but deterministic
-- so it can be added to the buy screen
-- (or just precalculated at the start of the game)

-- also need to spawn enemies in the right order
-- probably small small big small small big

-- ways to scale:
-- 1. number of enemies
-- 2. number of types of special enemy
-- 3. enemy power (tiers or flat mult by round?)

-- enemies should have tiered levels that are visible to the player
-- but ignore this for now

function Decide_on_Spawns(level)
  -- local round_power = level_to_round_power[level]
  local waves = {}
  local wave = {}

  local previous = nil
  for i = 1, number_of_waves(level) do
    wave, previous = Build_Wave(level, previous)
    table.insert(waves, wave)
  end

  return waves
end

function Build_Wave(level, previous)
  local wave = {}

  --get the special enemies for this level
  local special_enemies = pick_special_enemies(level, previous)
  --make a copy of the list so we can modify it
  local previous = {}
  for i, enemy in ipairs(special_enemies) do
    table.insert(previous, enemy)
  end
  


  --intersperse special enemies with normal enemies
  while #special_enemies > 0 do
    local index = random:int(1, #special_enemies)
    local special = table.remove(special_enemies, index)

    local enemy = random:table(normal_enemy_by_tier[1])
    Add_Enemy_To_Wave(wave, enemy)
    Add_Enemy_To_Wave(wave, special)
  end

  if #wave == 0 then
    local enemy = random:table(normal_enemy_by_tier[1])
    Add_Enemy_To_Wave(wave, enemy)
  end

  return wave, previous
end

function Add_Enemy_To_Wave(wave, enemy)
  --calc round power
  local power = enemy_to_round_power[enemy] or 0
  if enemy == 'shooter' or enemy == 'seeker' then
    power = power * SPAWNS_IN_GROUP
  end
  round_power = round_power + power
  --add to wave
  table.insert(wave, enemy)
end
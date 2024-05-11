


local function find_special_in_wave(wave)
  for i, enemy in ipairs(wave) do
    if special_enemy_to_round_power[enemy] then
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
      level_list[i] = {level = i, waves = {}, color = grey[0]}
  end

  for i = 1, max_level do
    local waves = Decide_on_Spawns(i)
    level_list[i].waves = waves
    --find the first special enemy in the wave
    -- to use as the level color on the buy screen
    local first_special = find_first_special(waves)
    if first_special then
      level_list[i].color = enemy_to_color[first_special]
    end
  end

  return level_list
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
  local round_power = level_to_round_power[level]
  local waves = {}
  local wave = {}

  while round_power > 0 do
    wave, round_power = Build_Wave(round_power)
    table.insert(waves, wave)
  end

  return waves
end

function Build_Wave(round_power)
  --pick a enemy type that we can afford
  local wave = {}
  for k, v in pairs(special_enemy_to_round_power) do
    if v < round_power then
      table.insert(wave, k)
    end
  end

  --pick a special enemy out of the ones we can afford
  local selected_enemy = random:table(wave)
  
  --add special enemy to list
  --we need to check for nil because we might not have enough power for any special enemies
  if selected_enemy then
    round_power = round_power - special_enemy_to_round_power[selected_enemy]
  end

  --add up to 3 normal enemies
  local num_normal_enemies = random:int(1, 3)

  for i=1, num_normal_enemies do
    if round_power < 1 then break end
    local enemy = random:table({'shooter', 'seeker'})
    table.insert(wave, enemy)
    round_power = round_power - normal_enemy_to_round_power[enemy]
  end

  --we need to make the normal enemies spawn first
  --so add the special enemy to the end of the list
  if selected_enemy then
    table.insert(wave, selected_enemy)
  end

  return wave, round_power
end

function Is_Boss_Level(level)
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

-- Continuous-spawn config per level. Each level picks a basic enemy that fills
-- the field on a steady clump cadence and one or more special pools that each
-- fire on their own jittered timer (skip-on-cap, not queued). LEVEL_SPAWN_POOLS
-- is indexed by level; non-boss levels beyond the table fall back to the
-- highest defined entry.
LEVEL_SPAWN_POOLS = {
  [1] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      {type = 'brute', interval = 10, max_alive = 2},
    },
  },
  [2] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      {type = 'brute', interval = 14, max_alive = 1},
      {type = 'roach', interval = 14, max_alive = 6, group_size = function() return random:int(2, 3) end},
    },
  },
  [3] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      {type = 'roach', interval = 12, max_alive = 4, group_size = 2},
      {type = 'sniper', interval = 20, max_alive = 1},
    },
  },
  [4] = {
    basic = {type = 'swarmer', interval = 3},
    specials = {
      {type = 'brute', interval = 14, max_alive = 1},
      {type = 'orb', interval = 15, max_alive = 2},
    },
  },
  [5] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      {type = 'snakearrow', interval = 14, max_alive = 2},
      {type = 'cleaver', interval = 10, max_alive = 2},
      {type = 'mortar', interval = 18, max_alive = 1},
    },
  },
  -- 6 is stompy boss
  [7] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      {type = 'mortar', interval = 14, max_alive = 2},
      {type = 'charger', interval = 12, max_alive = 2},
      {type = 'burst', interval = 16, max_alive = 1},
    },
  },
}

local function get_spawn_config_for_level(level)
  if LEVEL_SPAWN_POOLS[level] then return LEVEL_SPAWN_POOLS[level] end
  -- Pick the highest defined level <= this one as a fallback so later levels
  -- aren't empty if they haven't been authored yet.
  local best = nil
  for i = 1, level do
    if LEVEL_SPAWN_POOLS[i] then best = LEVEL_SPAWN_POOLS[i] end
  end
  return best or LEVEL_SPAWN_POOLS[1]
end

function Build_Level_List(max_level)
  local level_list = {}
  for i = 1, max_level do
      level_list[i] = {level = i, round_power = 0, color = grey[0], environmental_hazards = {}}
  end

  for i = 1, max_level do
    if Is_Boss_Level(i) then
      level_list[i].boss = Is_Boss_Level(i)
      level_list[i].color = black[0]
      level_list[i].round_power = BOSS_ROUND_POWER

    else
      level_list[i].spawn_config = get_spawn_config_for_level(i)

      if LEVEL_TO_PERKS[i] then
        level_list[i].color = orange[5]
      end

      local environmental_hazards = Decide_on_Environmental_Hazards(i)
      level_list[i].environmental_hazards = environmental_hazards

      -- round_power = total kill power for gold-per-kill (each kill grants
      -- its enemy_to_round_power as a fraction of this total). kill_quota is
      -- the level-completion gate. Base bumped +500 so even level 1 has
      -- meaningful length; multiplier ramps 1.5 -> 1.5 + 0.10*(level-1).
      level_list[i].round_power = (ROUND_POWER_BY_LEVEL[i] or 2000) + 500
      local quota_mult = 1.5 + 0.10 * (i - 1)
      level_list[i].kill_quota = math.ceil(level_list[i].round_power * quota_mult)
      level_list[i].waves_power = {level_list[i].kill_quota}
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

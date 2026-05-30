
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
-- Every special-pool spawn waits 17s before its first fire so the player gets
-- a uniform breathing-room window at level start before specials begin
-- pressuring them.
LEVEL_SPECIAL_FIRST_FIRE = 17

-- Special-pool entries can be either:
--   {type, at = 0.3, group_size?}         - one-shot at this fraction of the
--                                            level's kill_quota progress
--   {type, interval, max_alive, ...}      - recurring timer-based pool
-- Mix freely. The basic pool is always timer-based (continuous filler).
LEVEL_SPAWN_POOLS = {
  [1] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {},
  },
  [2] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      -- Timer-based pool: a slime arrives ~every 15s (jittered by
      -- SPECIAL_SPAWN_JITTER), starting at the 10s mark, with at most 2 alive
      -- on the field at once.
      {type = 'slime', interval = 15, max_alive = 2, first_fire = 10},
    },
  },
  [3] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      {type = 'roach', at = 0.3, group_size = function() return random:int(2, 3) end},
      {type = 'sniper', at = 0.55},
      {type = 'roach', at = 0.8, group_size = function() return random:int(2, 3) end},
    },
  },
  [4] = {
    basic = {type = 'swarmer', interval = 4},
    specials = {
      {type = 'brute', at = 0.2},
      {type = 'orb', at = 0.45},
      {type = 'brute', at = 0.7},
      {type = 'orb', at = 0.9},
    },
  },
  [5] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      {type = 'cleaver', at = 0.15},
      {type = 'snakearrow', at = 0.35},
      {type = 'mortar', at = 0.55},
      {type = 'cleaver', at = 0.75},
      {type = 'snakearrow', at = 0.9},
    },
  },
  -- 6 is stompy boss
  [7] = {
    basic = {type = 'swarmer', interval = BASIC_CLUMP_INTERVAL},
    specials = {
      {type = 'charger', at = 0.15},
      {type = 'mortar', at = 0.35},
      {type = 'burst', at = 0.55},
      {type = 'charger', at = 0.75},
      {type = 'mortar', at = 0.9},
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
      -- meaningful length; multiplier ramps 1.5 -> 1.5 + 0.10*(level-1) and
      -- gets a flat +35% from level 2 onward to lengthen mid/late levels
      -- without inflating the gold-per-kill denominator.
      level_list[i].round_power = (ROUND_POWER_BY_LEVEL[i] or 2000) + 500
      local quota_mult = 1.5 + 0.10 * (i - 1)
      if i >= 2 then quota_mult = quota_mult * 1.35 end
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

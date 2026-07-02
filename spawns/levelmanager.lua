
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

-- Per-level spawn config. Each level has:
--   basic        - the continuous swarmer clump filler (+ optional tank
--                  substitution via replace_type/replace_every).
--   special_pool - a flat list of special enemy types. The SpawnManager draws
--                  one at random each time the dynamic cadence fires (see
--                  SPECIAL_CADENCE_* in game_constants). Omit/empty for no
--                  specials. Per-type group sizes are handled centrally by
--                  Special_Cadence_Group_Size (roach in 2-3s, linker as a
--                  tethered pair, everything else single).
-- Boss levels are handled separately and have no entry here.
-- (The legacy timer/`at`-event `specials` field is still honored by the
-- SpawnManager and is used by the debug arena, but campaign levels use
-- special_pool exclusively.)

-- BENCHED: specials are being reworked into larger one-per-level miniboss
-- style enemies (see pulsar); no level draws from this pool right now. Kept
-- for reference / the debug arena still spawns one of each special.
-- Old T2 draw pool (L7-L10): 'snakearrow', 'mortar', 'cleaver', 'brute',
-- 'orb', 'boomerang', 'sniper', 'plasma', 'splitter', 'pulse_walker',
-- 'drone_carrier'.

-- D: per-level spawn_director configs. setpoints = ideal alive count per slot
-- (swarmer / tank / small_archer / special category). The director maintains
-- these, paced by power; tuning falls back to the SPAWN_DIRECTOR_* globals.
-- Non-swarmer setpoints are hard caps: those slots never spawn above them.
-- Optional per-level overrides: fill_time (seconds for the swarmer lane to
-- fill to SWARMER_LANE_TARGET_FILL of setpoint — lower = hotter opening),
-- ramp = {from=, to=} (swarmer lane only; front-load with from > to). See
-- documentation/spawn_tuning.md.
LEVEL_SPAWN_POOLS = {
  [1] = {
    spawn_director = {
      -- small_archer from the very start (after the opening grace window) so
      -- even L1 has one thing a kiting archer can't ignore.
      setpoints = { swarmer = 15, tank = 1, small_archer = 1 },
    },
  },
  [2] = {
    spawn_director = {
      setpoints = { swarmer = 15, tank = 2, small_archer = 1 },
    },
    -- One-shot miniboss-style special: fires once at 30% kill progress.
    -- Spawns offscreen and walks to a nearby park point.
    specials = {
      {type = 'pulsar', at = 0.3},
    },
  },
  [3] = {
    spawn_director = {
      setpoints = { swarmer = 20, tank = 2 },
    },
  },
  [4] = {
    spawn_director = {
      setpoints = { swarmer = 22, tank = 1, small_archer = 2 },
    },
  },
  [5] = {
    spawn_director = {
      setpoints = { swarmer = 22, tank = 2, small_archer = 2 },
    },
  },
  -- 6 is stompy boss. 7-10 (T2) are built below.
}

-- T2 levels: specials removed pending the miniboss-special rework (pulsar);
-- swarmer/tank/small_archer lanes only for now.
for _, lvl in ipairs({7, 8, 9, 10}) do
  LEVEL_SPAWN_POOLS[lvl] = {
    spawn_director = {
      setpoints = { swarmer = 48, tank = 2, small_archer = 3 },
    },
  }
end

-- Per-type spawn group size for the dynamic cadence. Each group member counts
-- toward the cadence's "specials on screen" increment.
function Special_Cadence_Group_Size(enemy_type)
  if enemy_type == 'roach' then return random:int(2, 3) end
  -- Linkers spawn as a tethered pair so the beam has two endpoints.
  if enemy_type == 'linker' then return 2 end
  return 1
end

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

-- Debug arena: a non-shipping level for inspecting every special enemy in
-- isolation. Reachable via the "debug" button on the main menu. Nothing spawns
-- on a timer; instead the player presses DEBUG_SPAWN_KEY to spawn the next
-- enemy in a randomized "one of each special" queue, one at a time, with an
-- on-screen prompt telling them which key to press and what spawns next.
DEBUG_LEVEL_NUMBER = 30
DEBUG_SPAWN_KEY = 'f5'

local DEBUG_SPECIAL_TYPES = {
  -- Roughly the order of appearance in the normal campaign, then the
  -- unused-but-functional specials, then the four custom additions.
  'slime', 'roach', 'sniper', 'brute', 'orb', 'cleaver', 'snakearrow', 'mortar',
  'bomb', 'selfburst', 'burst', 'arcspread', 'aim_spread',
  'singlemortar', 'line_mortar', 'boomerang', 'plasma',
  'archer', 'goblin_archer', 'big_goblin_archer',
  'firewall_caster', 'turret', 'shooter', 'spawner', 'tank', 'pulsar',
  -- Custom specials added in this pass:
  'splitter', 'pulse_walker', 'drone_carrier', 'linker',
}

function Build_Debug_Level_Entry()
  local queue = {}
  local total_power = 0
  -- One of each special, in a random order each run (shuffle a copy so the
  -- source list keeps its documented ordering). These are spawned manually,
  -- one queue entry per DEBUG_SPAWN_KEY press, rather than on timers.
  local spawn_order = table.shuffle(table.copy(DEBUG_SPECIAL_TYPES))
  for _, t in ipairs(spawn_order) do
    local count = 1
    if t == 'linker' then
      -- Linkers pair up at spawn time; deploy two so the tether is visible.
      count = 2
    end
    table.insert(queue, {type = t, count = count})

    -- Tally the round_power this entry contributes when its members die.
    -- kill_quota = sum across the queue so the level only completes once the
    -- player has actually spawned and cleared every special.
    total_power = total_power + (enemy_to_round_power[t] or 0) * count
    if t == 'splitter' then
      -- Splitter bursts into 3 swarmers on death — include their power so
      -- the quota only completes after the splits are cleared too.
      total_power = total_power + 3 * (enemy_to_round_power['swarmer'] or 0)
    end
  end

  return {
    level = DEBUG_LEVEL_NUMBER,
    -- round_power is the divisor for gold-per-kill (each kill grants its
    -- enemy_to_round_power as a fraction of this total). Match it to the
    -- kill_quota so gold-per-kill curves like a normal level.
    round_power = total_power,
    color = grey[0],
    environmental_hazards = {},
    -- No auto pools: the SpawnManager spawns straight from debug_spawn_queue
    -- on key press instead, so the arena stays empty until the player acts.
    spawn_config = {specials = {}},
    debug_spawn_queue = queue,
    -- Quota = exact sum of every expected enemy's round_power, so the
    -- progress bar fills naturally as the player clears the field and the
    -- level only completes when the last expected enemy is dead.
    kill_quota = total_power,
    waves_power = {total_power},
  }
end

function Build_Level_List(max_level)
  local level_list = {}
  for i = 1, max_level do
      level_list[i] = {level = i, round_power = 0, color = grey[0], environmental_hazards = {}}
  end
  -- Inject the debug entry so WorldManager can index level_list[DEBUG_LEVEL_NUMBER]
  -- when the run is started via Start_Debug_Run. Harmless for normal play (the
  -- level_map only iterates 1..NUMBER_OF_ROUNDS).
  level_list[DEBUG_LEVEL_NUMBER] = Build_Debug_Level_Entry()

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
      -- the level-completion gate. round_power (the gold-per-kill denominator)
      -- still ramps per level; only the enemy COUNT below is flattened early.
      level_list[i].round_power = (ROUND_POWER_BY_LEVEL[i] or 2000) + 500

      -- Enemy count (kill_quota). Levels 1-3 all use level 1's count so the
      -- opening stays gentle; the per-level +15% lengthening and the L4 trim
      -- both start at level 4. Multiplier ramps 1.5 -> 1.5 + 0.10*(level-1).
      local quota_level = (i <= 3) and 1 or i
      local quota_round_power = (ROUND_POWER_BY_LEVEL[quota_level] or 2000) + 500
      local quota_mult = 1.5 + 0.10 * (quota_level - 1)
      if quota_level >= 4 then quota_mult = quota_mult * 1.15 end
      -- L4+ kill quotas were rising too fast; trim 35% off L4 and every
      -- subsequent non-boss level (uniform, so the L4+ ramp is preserved).
      local quota_scale = (quota_level >= 4) and 0.65 or 1.0
      level_list[i].kill_quota = math.ceil(quota_round_power * quota_mult * 1.5 * quota_scale)
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

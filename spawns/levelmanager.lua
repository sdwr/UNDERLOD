
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

-- Per-level spawn config. Campaign levels use spawn_director:
--   length   - seconds over which the level's roster is released.
--   swarmer  - {cap, total}: at most `cap` alive (ramped 0.8x -> 1.2x over
--              length); `total` spawn over the level. Opens with a burst to
--              cap, then an even drip; leftovers spill after length as the
--              cap frees up.
--   timeline - {type = total | {total, group}}: specials. No alive cap; each
--              type is spread evenly over length and merged into one schedule,
--              so a level's composition is fixed no matter what the player
--              kills first.
--   clustered_only - every swarmer clump is clustered (no scatter roll).
-- Optional `specials = {{type=, at=}}` events fire once at a time fraction
-- of length, bypassing everything. Boss levels have no entry here.
-- kill_quota (the finite spawn budget, and the progress bar's total) is
-- derived from the roster: see Director_Spawn_Quota.
-- documentation/spawn_tuning.md has the full model.

-- BENCHED: specials are being reworked into larger one-per-level miniboss
-- style enemies (see pulsar); no level draws from this pool right now. Kept
-- for reference / the debug arena still spawns one of each special.
-- Old T2 draw pool (L7-L10): 'snakearrow', 'mortar', 'cleaver', 'brute',
-- 'orb', 'boomerang', 'sniper', 'plasma', 'splitter', 'pulse_walker',
-- 'drone_carrier'.

LEVEL_SPAWN_POOLS = {
  -- Swarmers only: L1 is the pure clump-fighting tutorial.
  [1] = {
    spawn_director = {
      length = 20,
      swarmer = { cap = 15, total = 45 },
    },
  },
  -- First tanks and small archers, one pair in each half of the level.
  [2] = {
    spawn_director = {
      length = 25,
      swarmer = { cap = 15, total = 55 },
      timeline = { tank = 2, small_archer = 2 },
    },
  },
  -- Thin swarm, clumps only, and a steady stream of archers making the edges
  -- hostile.
  [3] = {
    spawn_director = {
      length = 30,
      swarmer = { cap = 10, total = 40 },
      timeline = { small_archer = 6 },
      clustered_only = true,
    },
  },
  [4] = {
    spawn_director = {
      length = 35,
      swarmer = { cap = 22, total = 70 },
      timeline = { tank = 2, small_archer = 4, dart = 2 },
    },
  },
  [5] = {
    spawn_director = {
      length = 40,
      swarmer = { cap = 22, total = 80 },
      timeline = { tank = 3, small_archer = 5, dart = 3 },
    },
  },
  -- 6 is stompy boss. 7-10 (T2) are built below.
}

-- T2 levels (7-10; 11 is the dragon). Each introduces one ranged special on
-- top of the T1 cast, then L10 stacks them all.
-- L7 Skirmish line: roach pairs rush in behind the tanks and spam close-range
--   shots; first ranged pressure that closes distance.
LEVEL_SPAWN_POOLS[7] = {
  spawn_director = {
    length = 45,
    swarmer = { cap = 26, total = 100 },
    timeline = { tank = 4, small_archer = 4, dart = 3, roach = { total = 4, group = 2 } },
  },
}
-- L8 Overwatch: thinner swarm so the laser's charge-and-lock beam is the
--   thing to watch; archers and darts punish standing still to dodge it.
LEVEL_SPAWN_POOLS[8] = {
  spawn_director = {
    length = 50,
    swarmer = { cap = 22, total = 90 },
    timeline = { laser = 2, small_archer = 4, dart = 4, tank = 2 },
  },
}
-- L9 Bombardment: mortars zone the ground while roach pairs and darts force
--   movement through the shell pattern.
LEVEL_SPAWN_POOLS[9] = {
  spawn_director = {
    length = 55,
    swarmer = { cap = 26, total = 110 },
    timeline = { mortar = 2, roach = { total = 6, group = 2 }, tank = 3, dart = 4 },
  },
}
-- L10 Combined arms: everything, densest swarm, before the dragon.
LEVEL_SPAWN_POOLS[10] = {
  spawn_director = {
    length = 60,
    swarmer = { cap = 26, total = 120 },
    timeline = {
      laser = 2, mortar = 2, roach = { total = 6, group = 2 },
      tank = 3, small_archer = 4, dart = 5,
    },
  },
}

-- Spawn budget implied by a level's roster: every swarmer, every timeline
-- special and every scripted event, priced by enemy_to_round_power. Doubles
-- as the progress bar's total.
function Director_Spawn_Quota(spawn_config)
  local d = spawn_config and spawn_config.spawn_director
  if not d then return nil end
  assert(enemy_to_round_power, 'Director_Spawn_Quota needs enemy_to_round_power')
  local function power(etype)
    return assert(enemy_to_round_power[etype], 'no round power for ' .. etype)
  end
  local total = 0
  if d.swarmer then total = total + (d.swarmer.total or 0) * power('swarmer') end
  for etype, spec in pairs(d.timeline or {}) do
    local n = (type(spec) == 'table') and (spec.total or 0) or spec
    total = total + n * power(etype)
  end
  for _, ev in ipairs(spawn_config.specials or {}) do
    local gs = ev.group_size or 1
    if type(gs) == 'function' then gs = gs() end
    total = total + gs * power(ev.type)
  end
  return total
end

-- Per-type spawn group size for the legacy special cadence (non-director
-- levels only).
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
  'splitter', 'pulse_walker', 'drone_carrier', 'linker', 'dart',
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

-- Per-level gold pacing, one row per non-boss level (6/11/16/21/25 are
-- bosses). round_power: gold-per-kill denominator — each kill grants its
-- enemy_to_round_power as a fraction of this total. The spawn budget
-- (kill_quota) is derived from the roster, see Director_Spawn_Quota.
LEVEL_PACING = {
  [1]  = { round_power = 900 },
  [2]  = { round_power = 1100 },
  [3]  = { round_power = 1300 },
  [4]  = { round_power = 1600 },
  [5]  = { round_power = 1800 },
  [7]  = { round_power = 2200 },
  [8]  = { round_power = 2400 },
  [9]  = { round_power = 2600 },
  [10] = { round_power = 2800 },
}
-- Fallback for any level past the authored rows.
LEVEL_PACING_DEFAULT = { round_power = 2800 }

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

      local pacing = LEVEL_PACING[i] or LEVEL_PACING_DEFAULT
      level_list[i].round_power = pacing.round_power
      local quota = Director_Spawn_Quota(level_list[i].spawn_config)
      level_list[i].kill_quota = quota
      level_list[i].waves_power = {quota}
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

-- Level replay stats: when state.save_replays is on (main menu toggle), each
-- combat level writes a JSON file to <repo>/replays/ (gitignored; open
-- replays/viewer.html to chart them). Fused builds can't locate the repo so
-- they fall back to <save_dir>/replays/. Each file contains:
--   * 5s time series: alive round power on the field, cumulative killed power,
--     enemies alive onscreen vs offscreen, distance from the closest troop to
--     the closest enemy, and total troop hp
--   * per-unit dps / damage / kills / idle time (idle = any state that isn't
--     casting or channeling), with per-troop idle breakdown
--   * player loadout (units + all items + perks), level duration, outcome
-- Everything is defensive (pcall around the write path) so a recording bug can
-- never take down a run.

ReplayRecorder = {}

ReplayRecorder.SAMPLE_INTERVAL = 5
local DIR = 'replays'

-- Absolute path to <repo>/replays when running from source (love .), where
-- love.filesystem can't write — plain io is used instead. nil when fused.
local function repo_replay_dir()
  local ok, fused = pcall(love.filesystem.isFused)
  if not ok or fused then return nil end
  local ok2, src = pcall(love.filesystem.getSource)
  if not ok2 or type(src) ~= 'string' or src == '' then return nil end
  return src .. '/' .. DIR
end

local function write_replay(fname, json)
  local dir = repo_replay_dir()
  if dir then
    local path = dir .. '/' .. fname
    local f = io.open(path, 'w')
    if not f then
      -- folder missing (it ships with viewer.html, but be safe): mkdir, retry
      if love.system and love.system.getOS and love.system.getOS() == 'Windows' then
        os.execute('mkdir "' .. dir:gsub('/', '\\') .. '" 2>nul')
      else
        os.execute('mkdir -p "' .. dir .. '" 2>/dev/null')
      end
      f = io.open(path, 'w')
    end
    if f then
      f:write(json)
      f:close()
      return true
    end
  end
  love.filesystem.createDirectory(DIR)
  return love.filesystem.write(DIR .. '/' .. fname, json)
end

local function round1(x)
  return math.floor((x or 0) * 10 + 0.5) / 10
end

function ReplayRecorder.is_enabled()
  return state and state.save_replays == true
end

local function troop_is_idle(troop)
  return troop.state ~= unit_states['casting'] and troop.state ~= unit_states['channeling']
end

-- Called every unpaused Arena:update tick. Lazily starts recording once the
-- spawn manager leaves its pre-combat states so duration measures combat time.
function ReplayRecorder.update(arena, dt)
  if not arena or arena.level == 0 then return end

  local rec = arena.replay
  if not rec then
    if not ReplayRecorder.is_enabled() then return end
    local sm = arena.spawn_manager
    if not sm or sm.state == 'arena_start' or sm.state == 'suction_to_targets' then return end
    rec = {elapsed = 0, next_sample_at = 0, samples = {}, finalized = false}
    arena.replay = rec
  end
  if rec.finalized then return end

  rec.elapsed = rec.elapsed + dt

  if Helper and Helper.Unit and Helper.Unit.teams then
    for _, team in ipairs(Helper.Unit.teams) do
      for _, troop in ipairs(team.troops) do
        if troop and not troop.dead and troop_is_idle(troop) then
          troop.replay_idle_time = (troop.replay_idle_time or 0) + dt
        end
      end
    end
  end

  if rec.elapsed >= rec.next_sample_at then
    rec.next_sample_at = rec.next_sample_at + ReplayRecorder.SAMPLE_INTERVAL
    ReplayRecorder.take_sample(arena, rec)
  end
end

function ReplayRecorder.take_sample(arena, rec)
  local sample = {t = round1(rec.elapsed)}

  local enemies = {}
  if arena.main and main.current and main.current.enemies then
    enemies = arena.main:get_objects_by_classes(main.current.enemies) or {}
  end

  local onscreen, offscreen, alive_power = 0, 0, 0
  for _, e in ipairs(enemies) do
    if not e.dead then
      local off = e.offscreen
      if off == nil and Helper.Target and Helper.Target.is_in_camera_bounds then
        off = not Helper.Target:is_in_camera_bounds(e.x, e.y)
      end
      if off then offscreen = offscreen + 1 else onscreen = onscreen + 1 end
      alive_power = alive_power + ((enemy_to_round_power and enemy_to_round_power[e.type]) or 0)
    end
  end
  sample.enemies_onscreen = onscreen
  sample.enemies_offscreen = offscreen
  sample.alive_round_power = alive_power
  sample.killed_round_power = (arena.spawn_manager and arena.spawn_manager.wave_kill_power) or 0

  local total_hp, closest = 0, nil
  if Helper and Helper.Unit and Helper.Unit.teams then
    for _, team in ipairs(Helper.Unit.teams) do
      for _, troop in ipairs(team.troops) do
        if troop and not troop.dead then
          total_hp = total_hp + (troop.hp or 0)
          for _, e in ipairs(enemies) do
            if not e.dead then
              local d = math.distance(troop.x, troop.y, e.x, e.y)
              if not closest or d < closest then closest = d end
            end
          end
        end
      end
    end
  end
  sample.player_hp = math.floor(total_hp + 0.5)
  -- json null when there are no enemies or no troops alive
  sample.closest_enemy_distance = closest and round1(closest) or nil

  table.insert(rec.samples, sample)
end

-- Full item detail, unlike CrashLog.snapshot_units which reports set labels.
local function snapshot_loadout(units)
  local out = {}
  for i, u in ipairs(units or {}) do
    if type(u) == 'table' then
      local items = {}
      if type(u.items) == 'table' then
        for _, it in pairs(u.items) do
          if type(it) == 'table' then
            items[#items + 1] = {
              name = it.name or it.key or '?',
              sets = (type(it.sets) == 'table') and table.concat(it.sets, ',') or '',
              colors = (type(it.colors) == 'table') and table.concat(it.colors, ',') or '',
            }
          end
        end
      end
      out[#out + 1] = {character = u.character, level = u.level, items = items}
    end
  end
  return out
end

local function build_payload(arena, rec, outcome)
  -- reuse the same save path the game uses for end-of-round unit stats
  pcall(function() Helper.Unit:update_units_with_combat_data(arena) end)

  local units = {}
  for _, team in ipairs((Helper and Helper.Unit and Helper.Unit.teams) or {}) do
    local troops, team_idle = {}, 0
    for _, troop in ipairs(team.troops) do
      local idle = round1(troop.replay_idle_time)
      team_idle = team_idle + idle
      troops[#troops + 1] = {idle_time = idle, died = troop.dead and true or false}
    end
    units[#units + 1] = {
      character = team.unit.character,
      level = team.unit.level,
      dps = round1(team.unit.last_round_dps),
      damage_dealt = math.floor(team.total_damage_dealt or 0),
      kills = team.kills or 0,
      idle_time = round1(team_idle),
      troops = troops,
    }
  end

  local level_data = arena.level_list and arena.level_list[arena.level]
  return {
    version = CrashLog and CrashLog.GAME_VERSION or nil,
    run = (CrashLog and CrashLog.current_run_id and CrashLog.current_run_id()) or nil,
    saved_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    level = arena.level,
    loop = arena.loop,
    ng_plus = current_new_game_plus,
    difficulty = state and state.difficulty,
    outcome = outcome, -- 'win', 'loss', 'run_complete'
    success = outcome ~= 'loss',
    duration = round1(rec.elapsed),
    sample_interval = ReplayRecorder.SAMPLE_INTERVAL,
    kill_quota = level_data and level_data.kill_quota or nil,
    gold = gold,
    loadout = snapshot_loadout(arena.units),
    perks = arena.perks,
    units = units,
    samples = rec.samples,
  }
end

-- Ends the recording and writes the replay file. Safe to call more than once
-- (level_clear, quit and die can overlap); only the first outcome wins.
function ReplayRecorder.finalize(arena, outcome)
  local rec = arena and arena.replay
  if not rec or rec.finalized then return end
  rec.finalized = true

  pcall(function()
    ReplayRecorder.take_sample(arena, rec)
    local payload = build_payload(arena, rec, outcome)
    local json = CrashLog and CrashLog.encode and CrashLog.encode(payload)
    if not json then return end
    local fname = string.format('replay_%s_L%s_%s.json',
      os.date('!%Y%m%d_%H%M%S'), tostring(arena.level or 0), outcome)
    write_replay(fname, json)
  end)
end

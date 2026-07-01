-- Telemetry: crash reports + run events.
--   * Crashes always written to a local crash.log in the save directory.
--   * If the user consented, crashes + run events are queued and flushed to
--     CrashLog.URL on next launch in a background thread.
--   * Consent is a single toggle covering both: state.telemetry_enabled, with
--     state.telemetry_prompted tracking whether we've shown the prompt.
--   * Legacy state.crash_logging_* keys are migrated to telemetry_*.

CrashLog = {}

-- ============================================================
-- CONFIG: set the upload endpoint when your worker/server is live.
-- Leave nil to disable uploads (local crash.log still works).
-- HTTPS endpoints require the lua-https library (https.dll/so) shipped with
-- the LÖVE build. Without it, http:// endpoints work via luasocket.
-- ============================================================
CrashLog.URL = "https://underlod-logging.sdwr.workers.dev/ingest"
CrashLog.GAME_VERSION = "0.1.0"

local LOG_FILE = "crash.log"
local QUEUE_FILE = "telemetry_queue.ndjson"
local MAX_LOG_BYTES = 256 * 1024
local MAX_QUEUE_BYTES = 1 * 1024 * 1024  -- drop the oldest if queue grows past this

-- ============================================================
-- Sanitization + JSON
-- ============================================================

local function sanitize_string(s)
  s = tostring(s)
  local save_dir = love.filesystem.getSaveDirectory()
  if save_dir and save_dir ~= "" then
    local pattern = save_dir:gsub("([^%w])", "%%%1")
    s = s:gsub(pattern, "<save>")
  end
  s = s:gsub("[A-Za-z]:[/\\][Uu]sers[/\\][^/\\]+", "<user>")
  s = s:gsub("/home/[^/]+", "/home/<user>")
  s = s:gsub("/Users/[^/]+", "/Users/<user>")
  return s
end

local function json_escape(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\")
  s = s:gsub('"', '\\"')
  s = s:gsub("\n", "\\n")
  s = s:gsub("\r", "\\r")
  s = s:gsub("\t", "\\t")
  s = s:gsub("[%z\1-\31]", "")
  return s
end

local encode  -- forward decl

local function is_array(t)
  local n = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then return false end
    n = n + 1
  end
  return n == #t
end

encode = function(v, depth)
  depth = depth or 0
  if depth > 8 then return '"<deep>"' end
  local tv = type(v)
  if v == nil then return "null" end
  if tv == "boolean" then return v and "true" or "false" end
  if tv == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    return tostring(v)
  end
  if tv == "string" then return '"' .. json_escape(sanitize_string(v)) .. '"' end
  if tv == "table" then
    local parts = {}
    if is_array(v) then
      for i = 1, #v do parts[#parts + 1] = encode(v[i], depth + 1) end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      for k, val in pairs(v) do
        if type(k) == "string" or type(k) == "number" then
          parts[#parts + 1] = '"' .. json_escape(tostring(k)) .. '":' .. encode(val, depth + 1)
        end
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  end
  return '"<' .. tv .. '>"'
end

-- Shared JSON encoder (also used by ReplayRecorder).
CrashLog.encode = function(v) return encode(v) end

-- ============================================================
-- Consent + persistence
-- ============================================================

local function migrate()
  if not state then return end
  if state.crash_logging_enabled ~= nil and state.telemetry_enabled == nil then
    state.telemetry_enabled = state.crash_logging_enabled
  end
  if state.crash_logging_prompted ~= nil and state.telemetry_prompted == nil then
    state.telemetry_prompted = state.crash_logging_prompted
  end
end

function CrashLog.is_enabled() return state and state.telemetry_enabled == true end
function CrashLog.has_prompted() return state and state.telemetry_prompted == true end

function CrashLog.set_enabled(enabled)
  state.telemetry_enabled = enabled and true or false
  state.crash_logging_enabled = state.telemetry_enabled  -- mirror for back-compat
  if system and system.save_state then system.save_state() end
end

function CrashLog.set_prompted()
  state.telemetry_prompted = true
  state.crash_logging_prompted = true
  if system and system.save_state then system.save_state() end
end

-- A single anonymous id per install. Lets you correlate events from the same
-- run without identifying the user. Regenerates if cleared.
local function ensure_install_id()
  if state and not state.telemetry_install_id then
    state.telemetry_install_id = string.format("%x-%x-%x",
      os.time(), love.timer.getTime() * 1000000, math.random(0, 0xffffff))
    if system and system.save_state then system.save_state() end
  end
end

-- A short, stable, random "player" hash per install. Distinct from the longer
-- install_id: it's a compact tag (8 hex chars) included on every event so the
-- dashboard can group/sort runs by player.
local function ensure_player_hash()
  if state and not state.telemetry_player_hash then
    state.telemetry_player_hash = string.format("%08x", math.random(0, 0xffffffff))
    if system and system.save_state then system.save_state() end
  end
end

-- A run id rolled at run start (Start_New_Run) so all events from one playthrough
-- can be stitched together server-side. Stored on state so it survives
-- buy_screen <-> arena transitions.
function CrashLog.new_run_id()
  state.telemetry_run_id = string.format("%x-%x",
    os.time(), math.random(0, 0xffffffff))
  return state.telemetry_run_id
end

function CrashLog.current_run_id()
  if not state.telemetry_run_id then CrashLog.new_run_id() end
  return state.telemetry_run_id
end

-- ============================================================
-- Event envelope
-- ============================================================

local function envelope(event_type, payload)
  local major, minor, revision = 0, 0, 0
  if love.getVersion then major, minor, revision = love.getVersion() end
  return {
    type = event_type,
    game = "UNDERLOD",
    version = CrashLog.GAME_VERSION,
    install = state and state.telemetry_install_id or "anon",
    player = state and state.telemetry_player_hash or "anon",
    run = (state and state.telemetry_run_id) or nil,
    time = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    os = (love.system and love.system.getOS and love.system.getOS()) or "unknown",
    love_version = string.format("%d.%d.%d", major, minor, revision),
    data = payload or {},
  }
end

-- ============================================================
-- Queue management
-- ============================================================

local function truncate_log_if_huge()
  local info = love.filesystem.getInfo(LOG_FILE)
  if info and info.size and info.size > MAX_LOG_BYTES then
    pcall(love.filesystem.write, LOG_FILE, "[truncated]\n")
  end
end

local function cap_queue()
  local info = love.filesystem.getInfo(QUEUE_FILE)
  if info and info.size and info.size > MAX_QUEUE_BYTES then
    -- queue grew too big (probably offline for a long time). drop it.
    pcall(love.filesystem.remove, QUEUE_FILE)
  end
end

local function enqueue(env)
  cap_queue()
  pcall(love.filesystem.append, QUEUE_FILE, encode(env) .. "\n")
end

-- ============================================================
-- Snapshot helpers
-- ============================================================

-- Compact, safe summary of the player's units. Each unit contributes:
--   character, level, items[1..6] = name, item_colors[1..6] = csv of colors.
-- Keeping arrays dense so the JSON encoder treats them as arrays.
-- The item's identity is its set (e.g. "Frost"), not its slot (e.g. "amulet").
-- Report the set's display name, joining if an item somehow has several, and
-- fall back to the slot name only when an item has no set. Guarded so a missing
-- ITEM_SETS can never break telemetry.
local function item_label(it)
  if type(it.sets) == "table" and #it.sets > 0 then
    local names = {}
    for _, set_key in ipairs(it.sets) do
      local set_def = ITEM_SETS and ITEM_SETS[set_key]
      names[#names + 1] = (set_def and set_def.name) or set_key
    end
    if #names > 0 then return table.concat(names, "+") end
  end
  return it.name or it.key or "?"
end

function CrashLog.snapshot_units(units)
  local out = {}
  if type(units) ~= "table" then return out end
  for i, u in ipairs(units) do
    if type(u) == "table" then
      local items, item_colors = {}, {}
      if type(u.items) == "table" then
        for s = 1, 6 do
          local it = u.items[s]
          if type(it) == "table" then
            items[s] = item_label(it)
            if type(it.colors) == "table" then
              item_colors[s] = table.concat(it.colors, ",")
            else
              item_colors[s] = ""
            end
          else
            items[s] = ""
            item_colors[s] = ""
          end
        end
      else
        for s = 1, 6 do items[s] = ""; item_colors[s] = "" end
      end
      out[i] = {
        character = u.character,
        level = u.level,
        items = items,
        item_colors = item_colors,
      }
    end
  end
  return out
end

-- Team-wide meta state: per-color item counts, active tier (0..N) per color,
-- and effective stat bonuses. Pulled from items_v2 helpers if present, with
-- safe fallbacks so a refactor of that file can't break telemetry.
function CrashLog.snapshot_meta(units)
  local out = { colors = {}, tiers = {}, bonuses = {} }
  if type(units) ~= "table" then return out end

  -- color counts
  if count_team_meta_colors then
    local ok, counts = pcall(count_team_meta_colors, units)
    if ok and type(counts) == "table" then out.colors = counts end
  end

  -- active tier (index into META_THRESHOLDS) per color
  if META_THRESHOLDS and out.colors then
    for color, n in pairs(out.colors) do
      local tier = 0
      for ti, t in ipairs(META_THRESHOLDS) do
        if n >= t.count then tier = ti end
      end
      out.tiers[color] = tier
    end
  end

  -- effective stat bonuses (e.g. {dmg=0.2, aspd=0.1})
  if get_team_meta_stats then
    local ok, stats = pcall(get_team_meta_stats, units)
    if ok and type(stats) == "table" then out.bonuses = stats end
  end

  return out
end

-- Snapshot the arena/level state for level-end events. Pulls just the
-- fields we want to ship — never the live combat objects.
function CrashLog.snapshot_level(arena, outcome, extra)
  local units = arena and arena.units
  local payload = {
    outcome = outcome, -- "win", "loss", "run_complete"
    level = arena and arena.level,
    loop = arena and arena.loop,
    ng_plus = current_new_game_plus,
    difficulty = state and state.difficulty,
    time_elapsed = arena and arena.time_elapsed,
    gold = gold,
    units = CrashLog.snapshot_units(units),
    meta = CrashLog.snapshot_meta(units),
    damage_dealt = arena and arena.damage_dealt,
    damage_taken = arena and arena.damage_taken,
  }
  if type(extra) == "table" then
    for k, v in pairs(extra) do payload[k] = v end
  end
  return payload
end

-- ============================================================
-- Public API
-- ============================================================

-- Log a run/gameplay event. No-op when consent is off. Triggers an upload
-- of the current queue (cheap: one POST per call, runs in a thread, no
-- effect on the main loop).
function CrashLog.log_event(event_type, payload)
  if not CrashLog.is_enabled() then return end
  local ok, env = pcall(envelope, event_type, payload)
  if ok and env then
    pcall(enqueue, env)
    pcall(CrashLog.flush_queue)
  end
end

-- Called by love.errorhandler. Never throws.
function CrashLog.handle_error(msg, traceback)
  local payload = {
    message = tostring(msg),
    traceback = tostring(traceback),
  }
  pcall(truncate_log_if_huge)
  pcall(love.filesystem.append, LOG_FILE,
    string.format("[%s] %s\n%s\n\n",
      os.date("!%Y-%m-%dT%H:%M:%SZ"), payload.message, payload.traceback))

  if CrashLog.is_enabled() then
    local ok, env = pcall(envelope, "crash", payload)
    if ok and env then pcall(enqueue, env) end
  end
end

-- ============================================================
-- Background upload
-- ============================================================

local UPLOAD_THREAD_SRC = [[
  local url, payload = ...
  local ok_https, https = pcall(require, "https")
  if ok_https and https and url:sub(1, 5) == "https" then
    pcall(https.request, url, {
      method = "POST",
      data = payload,
      headers = { ["Content-Type"] = "application/x-ndjson" },
    })
    return
  end
  if url:sub(1, 5) == "http:" then
    local ok_h, http = pcall(require, "socket.http")
    local ok_l, ltn12 = pcall(require, "ltn12")
    if ok_h and ok_l then
      pcall(http.request, {
        url = url,
        method = "POST",
        headers = {
          ["Content-Type"] = "application/x-ndjson",
          ["Content-Length"] = tostring(#payload),
        },
        source = ltn12.source.string(payload),
        sink = ltn12.sink.null(),
      })
    end
  end
]]

function CrashLog.flush_queue()
  if not CrashLog.URL then return end
  if not CrashLog.is_enabled() then return end
  if not love.filesystem.getInfo(QUEUE_FILE) then return end

  local payload = love.filesystem.read(QUEUE_FILE)
  if not payload or payload == "" then
    pcall(love.filesystem.remove, QUEUE_FILE)
    return
  end

  -- delete optimistically; we prefer dropping over retrying indefinitely.
  pcall(love.filesystem.remove, QUEUE_FILE)

  local ok, thread = pcall(love.thread.newThread, UPLOAD_THREAD_SRC)
  if ok and thread then
    pcall(function() thread:start(CrashLog.URL, payload) end)
  end
end

-- One-time init: install error handler, default settings, flush queue.
function CrashLog.init()
  if state then
    migrate()
    if state.telemetry_enabled == nil then state.telemetry_enabled = false end
    ensure_install_id()
    ensure_player_hash()
  end

  -- In some LÖVE 11.x builds only love.errhand is defined here (the renamed
  -- love.errorhandler is still nil at this point). Fall back to it, otherwise
  -- our wrapper returns nil and LÖVE's boot loop quits silently with no error
  -- screen. Wrap both names so whichever boot prefers chains to the original.
  local default_handler = love.errorhandler or love.errhand
  local function handler(msg)
    local tb = debug.traceback(tostring(msg), 2)
    pcall(CrashLog.handle_error, msg, tb)
    if default_handler then return default_handler(msg) end
  end
  love.errorhandler = handler
  love.errhand = handler

  pcall(CrashLog.flush_queue)
end

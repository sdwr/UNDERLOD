--achivements have 2 sources of truth
-- steam and local

--to be able to play offline, local needs to be saved in the save file
--to be able to get steam achievements, steam needs to be loaded

-- should load from local, then compare vs steam
-- and update steam if there are any differences (and local)

--also need to store game stats in local
--to trigger achievements (# of levels complete, etc)

-- game data is saved in save_game.lua

function Check_All_Achievements()
  Update_Max_Meta_Counts()
  Check_Achievements(ACHIEVEMENTS_INDEX)
end

function Check_Achievements(achieves)
  if type(achieves) == 'string' then
    achieves = {achieves}
  end

  for _, name in ipairs(achieves) do
    local entry = ACHIEVEMENTS_TABLE[name]
    -- Defensive: legacy call sites (Stats_Total_Rerolls etc.) still reference
    -- removed achievement names. Skip silently instead of crashing.
    if entry and not ACHIEVEMENTS_UNLOCKED[name] then
      if entry.check and entry.check() then
        Unlock_Achievement(name)
      end
    end
  end
end

-- Walks the current team and bumps USER_STATS.max_meta_<color> so meta
-- achievements track the highest concentration ever held across runs.
function Update_Max_Meta_Counts()
  if not count_team_meta_colors or not USER_STATS then return end
  local units = (get_team_units and get_team_units()) or nil
  if not units then return end
  local counts = count_team_meta_colors(units)
  for color, count in pairs(counts) do
    local key = 'max_meta_' .. color
    if (USER_STATS[key] or 0) < count then
      USER_STATS[key] = count
    end
  end
end

function Load_Steam_State()
  if steam then
    --steam.userStats.requestCurrentStats()
  end
end

if steam then
--this is the callback function for when the stats are loaded
  function steam.userStats.onUserStatsReceived()
    for k, v in pairs(ACHIEVEMENTS_TABLE) do
      --local success, achieved = --steam.userStats.getAchievement(k)
      -- ACHIEVEMENTS_TABLE[k].unlocked = achieved
    end
  end
end

--disable achievements for now
function Unlock_Achievement(name)
  if steam then
    --steam.userStats.setAchievement(name)
    --steam.userStats.storeStats()
  end
  ACHIEVEMENTS_UNLOCKED[name] = true

  level_up1:play{volume=0.5}
  -- ui_top in BuyScreen, world_ui in WorldManager, ui as last resort. The
  -- chosen group lives outside the camera so the toast stays fixed on screen.
  local group = (main and main.current and (main.current.ui_top or main.current.world_ui or main.current.ui)) or nil
  if group and ACHIEVEMENTS_TABLE[name] then
    AchievementToast{group = group, achievement = ACHIEVEMENTS_TABLE[name], duration = 5}
  end
end

-- =====================================================================
-- AchievementToast: top-right pop-up shown when an achievement unlocks.
-- Stacks vertically when multiple unlock together; fades in and out.
-- =====================================================================
ACHIEVEMENT_TOAST_QUEUE = ACHIEVEMENT_TOAST_QUEUE or {}

AchievementToast = Object:extend()
AchievementToast.__class_name = 'AchievementToast'
AchievementToast:implement(GameObject)

local TOAST_W = 220
local TOAST_H = 38
local TOAST_BOTTOM = 26
local TOAST_GAP = 6
local TOAST_FADE_IN = 0.3
local TOAST_FADE_OUT = 0.5

function AchievementToast:init(args)
  self:init_game_object(args)
  self.force_update = true
  self.achievement = args.achievement
  self.duration = args.duration or 5
  self.elapsed = 0
  self.w = TOAST_W
  self.h = TOAST_H
  table.insert(ACHIEVEMENT_TOAST_QUEUE, self)
  self:refresh_positions()
end

function AchievementToast:refresh_positions()
  for i, t in ipairs(ACHIEVEMENT_TOAST_QUEUE) do
    t.slot = i
  end
end

function AchievementToast:update(dt)
  self:update_game_object(dt)
  self.elapsed = self.elapsed + dt
  if self.elapsed >= self.duration then
    for i, t in ipairs(ACHIEVEMENT_TOAST_QUEUE) do
      if t == self then table.remove(ACHIEVEMENT_TOAST_QUEUE, i); break end
    end
    self:refresh_positions()
    self.dead = true
  end
end

function AchievementToast:draw()
  local slot = self.slot or 1
  -- Anchor to bottom-right; newest toast at the bottom, older ones stack up.
  local y = gh - TOAST_BOTTOM - (slot - 1) * (self.h + TOAST_GAP) - self.h / 2
  local x = gw - self.w / 2 - 14
  self.x, self.y = x, y

  local alpha = 1
  if self.elapsed < TOAST_FADE_IN then
    alpha = self.elapsed / TOAST_FADE_IN
  elseif self.elapsed > self.duration - TOAST_FADE_OUT then
    alpha = math.max(0, (self.duration - self.elapsed) / TOAST_FADE_OUT)
  end

  local bg_color = bg[-2]:clone(); bg_color.a = 0.9 * alpha
  local border_color = yellow[0]:clone(); border_color.a = alpha
  graphics.rectangle(x, y, self.w, self.h, 4, 4, bg_color)
  graphics.rectangle(x, y, self.w, self.h, 4, 4, border_color, 1)

  local title_color = yellow[0]:clone(); title_color.a = alpha
  local name_color = fg[0]:clone(); name_color.a = alpha
  local desc_color = fg_alt[0]:clone(); desc_color.a = alpha * 0.9

  local text_x = x - self.w / 2 + 8
  local text_top = y - self.h / 2 + 4
  graphics.print('achievement unlocked', pixul_font, text_x, text_top, 0, 1, 1, 0, 0, title_color)
  graphics.print(self.achievement.name or '', pixul_font, text_x, text_top + 11, 0, 1, 1, 0, 0, name_color)
  graphics.print(self.achievement.desc or '', pixul_font, text_x, text_top + 22, 0, 1, 1, 0, 0, desc_color)
end

function Reset_All_Achievements()
  if steam then
    --steam.userStats.resetAllStats(true)
    --steam.userStats.storeStats()
  end

  Reset_User_Stats()

  for k, v in pairs(ACHIEVEMENTS_UNLOCKED) do
    ACHIEVEMENTS_UNLOCKED[k] = false
  end
end
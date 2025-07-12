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
  local achieves = ACHIEVEMENTS_INDEX
  Check_Achievements(achieves)
end

function Check_Achievements(achieves)
  if type(achieves) == 'string' then
    achieves = {achieves}
  end

  for _, name in ipairs(achieves) do
    if not ACHIEVEMENTS_UNLOCKED[name] then
      if ACHIEVEMENTS_TABLE[name].check and ACHIEVEMENTS_TABLE[name].check() then
        Unlock_Achievement(name)
      end
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
  print('unlocking!!!', name)
  if steam then
    --steam.userStats.setAchievement(name)
    --steam.userStats.storeStats()
  end
  ACHIEVEMENTS_UNLOCKED[name] = true

  level_up1:play{volume=0.5}
  local group = main.current.ui_top or main.current.ui
  --AchievementToast{group = group, achievement = ACHIEVEMENTS_TABLE[name], duration = 5}
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
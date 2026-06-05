require('achievements/achievement_unlocks')

ACH_CATEGORY_PROGRESSION = 'progression'
ACH_CATEGORY_COMBAT = 'combat'
ACH_CATEGORY_ITEM = 'item'

ACHIEVEMENT_CATEGORIES = {
  ACH_CATEGORY_PROGRESSION,
  ACH_CATEGORY_COMBAT,
  ACH_CATEGORY_ITEM,
}

-- Source-of-truth lists for the three achievement families. Adjusting these
-- regenerates the ACHIEVEMENTS_INDEX/_TABLE/_UNLOCKED tables below.
local META_LIST = {'red', 'yellow', 'blue', 'brown', 'purple'}
local META_THRESHOLD_LIST = {3, 6, 8}

local BOSS_LIST = {
  {id = 'kill_stompy', stat = 'stompy_defeated', name = 'Stompy Slayer',     desc = 'Defeat Stompy',     icon = 'stompydefeated'},
  {id = 'kill_dragon', stat = 'dragon_defeated', name = 'Dragon Hunter',     desc = 'Defeat the Dragon', icon = 'dragondefeated'},
  {id = 'kill_heigan', stat = 'heigan_defeated', name = 'Heigan Vanquisher', desc = 'Defeat Heigan',     icon = 'heigandefeated'},
}

local NG_PLUS_MAX = 7

ACHIEVEMENTS_INDEX = {}
ACHIEVEMENTS_UNLOCKED = {}
ACHIEVEMENTS_TABLE = {}

local function register(id, data)
  table.insert(ACHIEVEMENTS_INDEX, id)
  ACHIEVEMENTS_UNLOCKED[id] = false
  ACHIEVEMENTS_TABLE[id] = data
end

-- 5 colors x 3 thresholds = 15 meta achievements.
for _, color in ipairs(META_LIST) do
  for _, count in ipairs(META_THRESHOLD_LIST) do
    local id = 'meta_' .. color .. '_' .. count
    -- META_COLOR_LABEL is defined in items_v2.lua and may not be loaded yet
    -- when this file is first required; resolve lazily inside check/name.
    local function label()
      return (META_COLOR_LABEL and META_COLOR_LABEL[color]) or color
    end
    register(id, {
      name = string.format('%s x%d', label(), count),
      desc = string.format('Equip %d %s items across the team', count, label()),
      icon = 'meta_' .. color,
      category = ACH_CATEGORY_ITEM,
      check = function()
        return (USER_STATS['max_meta_' .. color] or 0) >= count
      end,
    })
  end
end

-- One per boss in the campaign.
for _, b in ipairs(BOSS_LIST) do
  register(b.id, {
    name = b.name,
    desc = b.desc,
    icon = b.icon,
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return (USER_STATS[b.stat] or 0) >= 1 end,
  })
end

-- NG+0 through NG+7. Completion is recorded by Arena:on_run_complete via
-- USER_STATS.max_ng_plus_completed (highest tier ever beaten).
for ng = 0, NG_PLUS_MAX do
  local id = 'ng_plus_' .. ng
  register(id, {
    name = 'NG+' .. ng .. ' Complete',
    desc = 'Finish a run on NG+' .. ng,
    icon = 'ng_plus_' .. ng,
    category = ACH_CATEGORY_PROGRESSION,
    check = function()
      return (USER_STATS.max_ng_plus_completed or -1) >= ng
    end,
  })
end

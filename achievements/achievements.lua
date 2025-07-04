require('achievements/achievement_unlocks')

ACHIEVEMENTS_INDEX = {
  'stompydefeated',
  'dragondefeated',
  'heigandefeated',
  'finalbossdefeated',
  'stompydefeated_hard',
  'dragondefeated_hard',
  'heigandefeated_hard',
  'finalbossdefeated_hard',
  'crushed',
  'handlethem',
  'safetydance',
  'finalbossperfect',
  'survivor',
  'passivewin',
  'healer',
  'stackecon',
  'reroll100',
  'sell100items',
  'lightningkiller',
  'aspdcap',
  'glasscannon',
  'dotaequip',
  'expensiveequip',
  'wowequip',
  'finalbosssameunit',
  'finalbossdifferentunits',
  'finalbossonlyoneunit',
  'finalboss50mods',
  'finalbossallmods',
  'finalbosstime',
  'finalbossnolosstroops',
  'finalbossnoreroll',
  'finalbossnoitem10',
  'finalbossallxchars',
}

ACHIEVEMENTS_UNLOCKED = {
  ['stompydefeated'] = false,
  ['dragondefeated'] = false,
  ['heigandefeated'] = false,
  ['finalbossdefeated'] = false,
  ['stompydefeated_hard'] = false,
  ['dragondefeated_hard'] = false,
  ['heigandefeated_hard'] = false,
  ['finalbossdefeated_hard'] = false,
  ['crushed'] = false,
  ['handlethem'] = false,
  ['safetydance'] = false,
  ['finalbossperfect'] = false,
  ['survivor'] = false,
  ['passivewin'] = false,
  ['healer'] = false,
  ['shieldstacker'] = false,
  ['stackecon'] = false,
  ['reroll100'] = false,
  ['sell100items'] = false,
  ['consume100potions'] = false,
  ['4potioneffects'] = false,
  ['lightningkiller'] = false,
  ['aspdcap'] = false,
  ['glasscannon'] = false,
  ['dotaequip'] = false,
  ['expensiveequip'] = false,
  ['wowequip'] = false,
  ['finalbosssameunit'] = false,
  ['finalbossmelee'] = false,
  ['finalboss50mods'] = false,
  ['finalbossallmods'] = false,
  ['finalbosstime'] = false,
  ['finalbossnolosstroops'] = false,
  ['finalbossnoreroll'] = false,
  ['finalbossnoitem10'] = false,
  ['finalbossallxchars'] = false,
}

ACH_CATEGORY_PROGRESSION = 'progression'
ACH_CATEGORY_COMBAT = 'combat'
ACH_CATEGORY_ITEM = 'item'

ACHIEVEMENT_CATEGORIES = {
  ACH_CATEGORY_PROGRESSION,
  ACH_CATEGORY_COMBAT,
  ACH_CATEGORY_ITEM,
}

ACHIEVEMENTS_TABLE = {

  --boss progression achievements
  ['stompydefeated'] = {
    name = 'Stompy Slayer',
    desc = 'Defeat Stompy',
    icon = 'stompydefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.stompy_defeated >= 1 end,
  },
  ['dragondefeated'] = {
    name = 'Dragon Hunter',
    desc = 'Defeat the Dragon',
    icon = 'dragondefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.dragon_defeated >= 1 end,
  },
  ['heigandefeated'] = {
    name = 'Heigan Vanquisher',
    desc = 'Defeat Heigan',
    icon = 'heigandefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.heigan_defeated >= 1 end,
  },
  ['finalbossdefeated'] = {
    name = 'Final Conqueror',
    desc = 'Defeat the Final Boss',
    icon = 'finalbossdefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.final_boss_defeated >= 1 end,
  },

  ['stompydefeated_hard'] = {
    name = 'Stompy Slayer Hard',
    desc = 'Defeat Stompy on hard mode',
    icon = 'stompydefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.stompy_defeated_hard >= 1 end,
  },
  ['dragondefeated_hard'] = {
    name = 'Dragon Hunter Hard',
    desc = 'Defeat the Dragon on hard mode',
    icon = 'dragondefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.dragon_defeated_hard >= 1 end,
  },
  ['heigandefeated_hard'] = {
    name = 'Heigan Vanquisher Hard',
    desc = 'Defeat Heigan on hard mode',
    icon = 'heigandefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.heigan_defeated_hard >= 1 end,
  },
  ['finalbossdefeated_hard'] = {
    name = 'Final Conqueror Hard',
    desc = 'Defeat the Final Boss on hard mode',
    icon = 'finalbossdefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.final_boss_defeated_hard >= 1 end,
  },

  --perfect run achievements
  ['crushed'] = {
    name = 'Crushed',
    desc = 'Defeat Stompy without taking damage from falling rocks',
    icon = 'crushed',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.stompy_perfect > 0 end,
  },
  ['handlethem'] = {
    name = 'Handle Them',
    desc = 'Defeat the Dragon without letting any eggs hatch',
    icon = 'handlethem',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.dragon_no_eggs > 0 end,
  },
  ['safetydance'] = {
    name = 'Safety Dance',
    desc = 'Defeat Heigan without taking damage from the floor',
    icon = 'safetydance',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.heigan_no_floor > 0 end,
  },
  ['finalbossperfect'] = {
    name = 'The Final Countdown',
    desc = 'Defeat the final boss without taking damage',
    icon = 'finalbossperfect',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.final_boss_perfect > 0 end,
  },

  --combat achievements
  ['survivor'] = {
    name = 'Lone Survivor',
    desc = 'Survive a level with 1 troop remaining',
    icon = 'survivor',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.current_run_least_troops_alive == 1 end,
  },
  ['passivewin'] = {
    name = 'Pacifist',
    desc = 'Beat a level without moving',
    icon = 'passivewin',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.current_run_least_times_moved == 0 end,
  },
  ['healer'] = {
    name = 'Healer',
    desc = 'Have a troop survive after being at 1 hp',
    icon = 'healer',
    category = ACH_CATEGORY_COMBAT,
  },

  --econ achivements
  ['stackecon'] = {
    name = 'Economic Powerhouse',
    desc = 'Have over 50 gold during a run',
    icon = 'stackecon', 
    category = ACH_CATEGORY_ITEM,
    check = function() return USER_STATS.max_gold >= 50 end,
  },
  ['reroll100'] = {
    name = 'Reroll Enthusiast',
    desc = 'Reroll 100 times',
    icon = 'reroll100',
    category = ACH_CATEGORY_ITEM,
    check = function() return USER_STATS.total_rerolls >= 100 end,
  },
  ['sell100items'] = {
    name = 'Merchant',
    desc = 'Sell 50 items',
    icon = 'sell100items',
    category = ACH_CATEGORY_ITEM,
    check = function() return USER_STATS.total_items_sold >= 50 end,

  },

  --item achievements
  ['lightningkiller'] = {
    name = 'Lightning Killer',
    desc = 'Kill an enemy entirely with lightning procs',
    icon = 'lightningkiller',
    category = ACH_CATEGORY_COMBAT,
  },
  ['aspdcap'] = {
    name = 'Speed Demon',
    desc = 'Reach attack speed cap on a unit',
    icon = 'aspdcap',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.max_aspd >= 3 end,
  },
  ['glasscannon'] = {
    name = 'Glass Cannon',
    desc = 'Reach +200% damage on a unit',
    icon = 'glasscannon',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.max_dmg_without_hp >= 3 end,
  },
  ['dotaequip'] = {
    name = 'Dota Fan',
    desc = 'Fully equip a unit with Dota references',
    icon = 'dotaequip',
    category = ACH_CATEGORY_ITEM,
  },
  ['expensiveequip'] = {
    name = 'Big Spender',
    desc = 'Fully equip a unit with items costing 15 or more',
    icon = 'expensiveequip',
    category = ACH_CATEGORY_ITEM,
  },
  ['wowequip'] = {
    name = 'WoW Fan',
    desc = 'Fully equip a unit with WoW references',
    icon = 'wowequip',
    category = ACH_CATEGORY_ITEM,
  },

  --final boss achievements
  ['finalbosssameunit'] = {
    name = 'Clone Army',
    desc = 'Beat the final boss with 3 of the same unit',
    icon = 'finalbosssameunit',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalbossdifferentunits'] = {
    name = 'Different Units',
    desc = 'Beat the final boss with 3 different units',
    icon = 'finalbossdifferentunits',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalbossonlyoneunit'] = {
    name = 'Melee Mastery',
    desc = 'Beat the final boss with only 1 unit',
    icon = 'finalbossonlyoneunit',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalboss50mods'] = {
    name = 'Halfway Hero',
    desc = 'Beat the final boss with 50% mods enabled',
    icon = 'finalboss50mods',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalbossallmods'] = {
    name = 'Ultimate Challenger',
    desc = 'Beat the final boss with all mods enabled',
    icon = 'finalbossallmods',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalbosstime'] = {
    name = 'Speedrunner',
    desc = 'Beat the final boss in under XX minutes',
    icon = 'finalbosstime',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalbossnolosstroops'] = {
    name = 'Perfect Victory',
    desc = 'Beat the final boss without ever losing a troop',
    icon = 'finalbossnolosstroops',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalbossnoreroll'] = {
    name = 'No Rerolls',
    desc = 'Beat the final boss without rerolling the shop',
    icon = 'finalbossnoreroll',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalbossnoitem10'] = {
    name = 'Frugal Fighter',
    desc = 'Beat the final boss without ever purchasing an item costing >10',
    icon = 'finalbossnoitem10',
    category = ACH_CATEGORY_COMBAT,
  },
  ['finalbossallxchars'] = {
    name = 'Unified Forces',
    desc = 'Beat the final boss with all X characters (base, bonus, bonus2...)',
    icon = 'finalbossallxchars',
    category = ACH_CATEGORY_COMBAT,
  },
}

require('achievements/achievement_unlocks')

ACHIEVEMENTS_INDEX = {
  'stompydefeated',
  'dragondefeated',
  'heigandefeated',
  'finalbossdefeated',
  'crushed',
  'handlethem',
  'safetydance',
  'finalbossperfect',
  'survivor',
  'passivewin',
  'healer',
  'shieldstacker',
  'stackecon',
  'reroll100',
  'sell100items',
  'consume100potions',
  '4potioneffects',
  'lightningkiller',
  'aspdcap',
  'glasscannon',
  'dotaequip',
  'expensiveequip',
  'wowequip',
  'finalboss',
  'finalbosssameunit',
  'finalbossmelee',
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
  ['finalboss'] = false,
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
    desc = 'Defeat Stompy for the first time',
    icon = 'stompydefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.stompy_defeated >= 1 end,
  },
  ['dragondefeated'] = {
    name = 'Dragon Hunter',
    desc = 'Defeat the Dragon for the first time',
    icon = 'dragondefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.dragon_defeated >= 1 end,
  },
  ['heigandefeated'] = {
    name = 'Heigan Vanquisher',
    desc = 'Defeat Heigan for the first time',
    icon = 'heigandefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.heigan_defeated >= 1 end,
  },
  ['finalbossdefeated'] = {
    name = 'Final Conqueror',
    desc = 'Defeat the Final Boss for the first time',
    icon = 'finalbossdefeated',
    category = ACH_CATEGORY_PROGRESSION,
    check = function() return USER_STATS.final_boss_defeated >= 1 end,
  },

  --perfect run achievements
  ['crushed'] = {
    name = 'Crushed',
    desc = 'Defeat Stompy without taking damage',
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
    desc = 'Beat a level without attacking',
    icon = 'passivewin',
    category = ACH_CATEGORY_COMBAT,
    check = function() return USER_STATS.current_run_level_times_attacked == 0 end,
  },
  ['healer'] = {
    name = 'Healer',
    desc = 'Heal a unit to full hp from 1 hp',
    icon = 'healer',
    category = ACH_CATEGORY_COMBAT,
  },
  ['shieldstacker'] = {
    name = 'Shield Stacker',
    desc = 'Stack 200 shield on a single unit',
    icon = 'shieldstacker',
    category = ACH_CATEGORY_COMBAT,
  },

  --econ achivements
  ['stackecon'] = {
    name = 'Economic Powerhouse',
    desc = 'Have over 100 gold during a run',
    icon = 'stackecon', 
    category = ACH_CATEGORY_ITEM,
    check = function() return USER_STATS.max_gold >= 100 end,
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
    desc = 'Sell 100 items',
    icon = 'sell100items',
    category = ACH_CATEGORY_ITEM,
    check = function() return USER_STATS.total_items_sold >= 100 end,

  },
  ['consume100potions'] = {
    name = 'Potion Master',
    desc = 'Consume 100 potions',
    icon = 'consume100potions',
    category = ACH_CATEGORY_ITEM,
    check = function() return USER_STATS.total_items_consumed >= 100 end,
  },
  ['4potioneffects'] = {
    name = 'Alchemist',
    desc = 'Have 4 potion effects on a single unit',
    icon = '4potioneffects',
    category = ACH_CATEGORY_ITEM,
    check = function() return USER_STATS.max_potion_effects >= 4 end,
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
    desc = 'Reach 300% damage on a unit without any +hp',
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
    desc = 'Fully equip a unit with items costing >20',
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
  ['finalbossmelee'] = {
    name = 'Melee Mastery',
    desc = 'Beat the final boss with all melee units',
    icon = 'finalbossmelee',
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

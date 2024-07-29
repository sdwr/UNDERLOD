require('achievements/achievement_unlocks')

ACHIEVEMENTS_INDEX = {
  'firstblood',
  'heatingup',
  'fiftyfifty',
  'unstoppable',
  'legendary',
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
  'firestacker',
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
  ['firstblood'] = false,
  ['heatingup'] = false,
  ['fiftyfifty'] = false,
  ['unstoppable'] = false,
  ['legendary'] = false,
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
  ['firestacker'] = false,
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

ACHIEVEMENTS_TABLE = {

  --complete level achievements
  ['firstblood'] = {
    name = 'First Blood',
    desc = 'Complete your first level',
    icon = 'firstblood',
    check = function() return USER_STATS.levels_complete >= 1 end,
  },
  ['heatingup'] = {
    name = 'Heating Up',
    desc = 'Complete 5 levels',
    icon = 'heatingup',
    check = function() return USER_STATS.levels_complete >= 5 end,
  },  
  ['fiftyfifty'] = {
    name = 'Fifty Fifty',
    desc = 'Complete 50 levels',
    icon = 'fiftyfifty',
    check = function() return USER_STATS.levels_complete >= 50 end,
  },
  ['unstoppable'] = {
    name = 'Unstoppable',
    desc = 'Complete 200 levels',
    icon = 'unstoppable',
    check = function() return USER_STATS.levels_complete >= 200 end,
  },
  ['legendary'] = {
    name = 'Legendary',
    desc = 'Complete 500 levels',
    icon = 'legendary',
    check = function() return USER_STATS.levels_complete >= 500 end,
  },

  --perfect run achievements
  ['crushed'] = {
    name = 'Crushed',
    desc = 'Defeat Stompy without taking damage',
    icon = 'crushed',
    check = function() return USER_STATS.stompy_perfect > 0 end,
  },
  ['handlethem'] = {
    name = 'Handle Them',
    desc = 'Defeat the Dragon without letting any eggs hatch',
    icon = 'handlethem',
    check = function() return USER_STATS.dragon_no_eggs > 0 end,
  },
  ['safetydance'] = {
    name = 'Safety Dance',
    desc = 'Defeat Heigan without taking damage from the floor',
    icon = 'safetydance',
    check = function() return USER_STATS.heigan_no_floor > 0 end,
  },
  ['finalbossperfect'] = {
    name = 'The Final Countdown',
    desc = 'Defeat the final boss without taking damage',
    icon = 'finalbossperfect',
    check = function() return USER_STATS.final_boss_perfect > 0 end,
  },

  --combat achievements
  ['survivor'] = {
    name = 'Lone Survivor',
    desc = 'Survive a level with 1 troop remaining',
    icon = 'survivor',
    check = function() return USER_STATS.current_run_least_troops_alive == 1 end,
  },
  ['passivewin'] = {
    name = 'Pacifist',
    desc = 'Beat a level without attacking',
    icon = 'passivewin',
    check = function() return USER_STATS.current_run_level_times_attacked == 0 end,
  },
  ['healer'] = {
    name = 'Healer',
    desc = 'Heal a unit to full hp from 1 hp',
    icon = 'healer',
  },
  ['shieldstacker'] = {
    name = 'Shield Stacker',
    desc = 'Stack 200 shield on a single unit',
    icon = 'shieldstacker',
  },

  --econ achivements
  ['stackecon'] = {
    name = 'Economic Powerhouse',
    desc = 'Have over 100 gold during a run',
    icon = 'stackecon',
    check = function() return USER_STATS.max_gold >= 100 end,
  },
  ['reroll100'] = {
    name = 'Reroll Enthusiast',
    desc = 'Reroll 100 times',
    icon = 'reroll100',
    check = function() return USER_STATS.total_rerolls >= 100 end,
  },
  ['sell100items'] = {
    name = 'Merchant',
    desc = 'Sell 100 items',
    icon = 'sell100items',
    check = function() return USER_STATS.total_items_sold >= 100 end,

  },
  ['consume100potions'] = {
    name = 'Potion Master',
    desc = 'Consume 100 potions',
    icon = 'consume100potions',
    check = function() return USER_STATS.total_items_consumed >= 100 end,
  },
  ['4potioneffects'] = {
    name = 'Alchemist',
    desc = 'Have 4 potion effects on a single unit',
    icon = '4potioneffects',
    check = function() return USER_STATS.max_potion_effects >= 4 end,
  },

  --item achievements
  ['firestacker'] = {
    name = 'Fire Stacker',
    desc = 'Stack fire on an enemy up to 20 stacks',
    icon = 'firestacker',
    check = function() return USER_STATS.max_fire_stacks >= 20 end,
  },
  ['lightningkiller'] = {
    name = 'Lightning Killer',
    desc = 'Kill an enemy entirely with lightning procs',
    icon = 'lightningkiller',
  },
  ['aspdcap'] = {
    name = 'Speed Demon',
    desc = 'Reach attack speed cap on a unit',
    icon = 'aspdcap',
    check = function() return USER_STATS.max_aspd >= 3 end,
  },
  ['glasscannon'] = {
    name = 'Glass Cannon',
    desc = 'Reach 300% damage on a unit without any +hp',
    icon = 'glasscannon',
    check = function() return USER_STATS.max_dmg_without_hp >= 3 end,
  },
  ['dotaequip'] = {
    name = 'Dota Fan',
    desc = 'Fully equip a unit with Dota references',
    icon = 'dotaequip',
  },
  ['expensiveequip'] = {
    name = 'Big Spender',
    desc = 'Fully equip a unit with items costing >20',
    icon = 'expensiveequip',
  },
  ['wowequip'] = {
    name = 'WoW Fan',
    desc = 'Fully equip a unit with WoW references',
    icon = 'wowequip',
  },

  --final boss achievements
  ['finalboss'] = {
    name = 'Final Conqueror',
    desc = 'Beat the final boss',
    icon = 'finalboss',
  },
  ['finalbosssameunit'] = {
    name = 'Clone Army',
    desc = 'Beat the final boss with 3 of the same unit',
    icon = 'finalbosssameunit',
  },
  ['finalbossmelee'] = {
    name = 'Melee Mastery',
    desc = 'Beat the final boss with all melee units',
    icon = 'finalbossmelee',
  },
  ['finalboss50mods'] = {
    name = 'Halfway Hero',
    desc = 'Beat the final boss with 50% mods enabled',
    icon = 'finalboss50mods',
  },
  ['finalbossallmods'] = {
    name = 'Ultimate Challenger',
    desc = 'Beat the final boss with all mods enabled',
    icon = 'finalbossallmods',
  },
  ['finalbosstime'] = {
    name = 'Speedrunner',
    desc = 'Beat the final boss in under XX minutes',
    icon = 'finalbosstime',
  },
  ['finalbossnolosstroops'] = {
    name = 'Perfect Victory',
    desc = 'Beat the final boss without ever losing a troop',
    icon = 'finalbossnolosstroops',
  },
  ['finalbossnoreroll'] = {
    name = 'No Rerolls',
    desc = 'Beat the final boss without rerolling the shop',
    icon = 'finalbossnoreroll',
  },
  ['finalbossnoitem10'] = {
    name = 'Frugal Fighter',
    desc = 'Beat the final boss without ever purchasing an item costing >10',
    icon = 'finalbossnoitem10',
  },
  ['finalbossallxchars'] = {
    name = 'Unified Forces',
    desc = 'Beat the final boss with all X characters (base, bonus, bonus2...)',
    icon = 'finalbossallxchars',
  },
}

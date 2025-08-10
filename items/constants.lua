
ITEM_SLOT = {
  HEAD = 'head',
  BODY = 'body',
  WEAPON = 'weapon',
  OFFHAND = 'offhand',
  FEET = 'feet',
  AMULET = 'amulet'
}

ITEM_SLOTS = {
  [ITEM_SLOT.HEAD] = {
    name = 'head',
    icon = 'helmet',
    index = 1,
  },
  [ITEM_SLOT.BODY] = {
    name = 'body',
    icon = 'simplearmor',
    index = 2,
  },
  [ITEM_SLOT.WEAPON] = {
    name = 'weapon',
    icon = 'sword',
    index = 3,
  },
  [ITEM_SLOT.OFFHAND] = {
    name = 'offhand',
    icon = 'simpleshield',
    index = 4,
  },
  [ITEM_SLOT.FEET] = {
    name = 'feet',
    icon = 'simpleboots',
    index = 5,
  },
  [ITEM_SLOT.AMULET] = {
    name = 'amulet',
    icon = 'orb',
    index = 6,
  },
}

ITEM_SLOTS_BY_INDEX = {
  [1] = ITEM_SLOT.HEAD,
  [2] = ITEM_SLOT.BODY,
  [3] = ITEM_SLOT.WEAPON,
  [4] = ITEM_SLOT.OFFHAND,
  [5] = ITEM_SLOT.FEET,
  [6] = ITEM_SLOT.AMULET,
}


-- Item type definitions with preferred stats
ITEM_SLOTS_PREFERRED_STATS = {
  [ITEM_SLOT.HEAD] = {
    preferred_stats = {'aspd', 'hp'},
    preferred_chance = 1
  },
  [ITEM_SLOT.BODY] = {
    preferred_stats = {'hp', 'aspd'},
    preferred_chance = 1
  },
  [ITEM_SLOT.WEAPON] = {
    preferred_stats = {'dmg'},
    preferred_chance = 1
  },
  [ITEM_SLOT.OFFHAND] = {
    preferred_stats = {'dmg', 'aspd'},
    preferred_chance = 1
  },
  [ITEM_SLOT.FEET] = {
    preferred_stats = {'mvspd', 'aspd'},
    preferred_chance = 1
  },
  [ITEM_SLOT.AMULET] = {
    preferred_stats = {'crit_chance', 'cooldown_reduction', 'repeat_attack_chance'},
    preferred_chance = 1
  }
}
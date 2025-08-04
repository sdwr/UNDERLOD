
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
    name = 'Head',
    icon = helmet,
    index = 1,
  },
  [ITEM_SLOT.BODY] = {
    name = 'Body',
    icon = simplearmor,
    index = 2,
  },
  [ITEM_SLOT.WEAPON] = {
    name = 'Weapon',
    icon = sword,
    index = 3,
  },
  [ITEM_SLOT.OFFHAND] = {
    name = 'Offhand',
    icon = simpleboots,
    index = 4,
  },
  [ITEM_SLOT.FEET] = {
    name = 'Feet',
    icon = simpleboots,
    index = 5,
  },
  [ITEM_SLOT.AMULET] = {
    name = 'Amulet',
    icon = orb,
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
    preferred_stats = {'hp', 'flat_def', 'crit_chance'},
    preferred_chance = 0.5 -- 70% chance to roll preferred stats
  },
  [ITEM_SLOT.BODY] = {
    preferred_stats = {'hp', 'flat_def', 'area_size'},
    preferred_chance = 0.5
  },
  [ITEM_SLOT.WEAPON] = {
    preferred_stats = {'dmg', 'aspd', 'range', 'crit_chance'},
    preferred_chance = 0.5
  },
  [ITEM_SLOT.OFFHAND] = {
    preferred_stats = {'flat_def', 'hp', 'crit_chance'},
    preferred_chance = 0.5
  },
  [ITEM_SLOT.FEET] = {
    preferred_stats = {'mvspd', 'aspd'},
    preferred_chance = 0.5
  },
  [ITEM_SLOT.AMULET] = {
    preferred_stats = {'crit_chance'},
    preferred_chance = 0.5
  }
}
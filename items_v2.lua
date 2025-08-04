-- Items V2 System
-- Modern item generation with types, rarities, sets, and random stats

-- Item Types
ITEM_TYPE = {
  HEAD = 'head',
  BODY = 'body', 
  WEAPON = 'weapon',
  OFFHAND = 'offhand',
  FEET = 'feet',
  AMULET = 'amulet'
}

-- Item Rarities
ITEM_RARITY = {
  COMMON = 'common',
  RARE = 'rare',
  EPIC = 'epic',
  LEGENDARY = 'legendary'
}

-- Item Sets
ITEM_SET = {
  COLD = 'cold',
  FROST_NOVA = 'frost_nova',
  FIRE = 'fire',
  BLAZIN = 'blazin',
  METEOR = 'meteor',
  SHOCK = 'shock',
  LIGHTNING_BALL = 'lightning_ball',
  CURSE = 'curse',
  ATTACK_EFFECTS = 'attack_effects',
  LASER = 'laser',
  BLOODLUST = 'bloodlust',
  SPLASH = 'splash',
  DAMAGE = 'damage',
  SUPPORT = 'support',
  SHIELD = 'shield',
  REFLECT = 'reflect',
  REPEAT = 'repeat',
  STUN = 'stun'
}

-- Stat definitions
ITEM_STATS = {
  -- Core stats
  ['dmg'] = { name = 'dmg', min = 1, max = 5, increment = 0.1 },
  ['aspd'] = { name = 'aspd', min = 1, max = 5, increment = 0.05 },
  ['hp'] = { name = 'hp', min = 1, max = 5, increment = 0.2 },
  ['mvspd'] = { name = 'mvspd', min = 1, max = 5, increment = 0.05 },
  
  -- Defensive stats
  ['flat_def'] = { name = 'flat_def', min = 1, max = 5, increment = 0.1 },
  
  -- Special stats
  ['area_size'] = { name = 'area_size', min = 1, max = 5, increment = 0.1 },
  ['vamp'] = { name = 'vamp', min = 1, max = 5, increment = 0.05 },
  ['ghost'] = { name = 'ghost', min = 1, max = 5, increment = 0.05 },
  ['slow'] = { name = 'slow', min = 1, max = 5, increment = 0.1 },
  ['thorns'] = { name = 'thorns', min = 1, max = 5, increment = 0.1 },
  ['range'] = { name = 'range', min = 1, max = 5, increment = 0.05 },
  ['repeat_attack_chance'] = { name = 'repeat_attack_chance', min = 1, max = 5, increment = 0.1 },
  ['gold'] = { name = 'gold', min = 1, max = 5, increment = 1 },
  ['heal'] = { name = 'heal', min = 1, max = 5, increment = 0.05 },
  
  -- Elemental stats
  ['fire_damage'] = { name = 'fire_damage', min = 1, max = 5, increment = 0.1 },
  ['lightning_damage'] = { name = 'lightning_damage', min = 1, max = 5, increment = 0.1 },
  ['cold_damage'] = { name = 'cold_damage', min = 1, max = 5, increment = 0.1 },
  
  -- Advanced stats
  ['crit_chance'] = { name = 'crit_chance', min = 1, max = 5, increment = 0.1 },
  ['stun_chance'] = { name = 'stun_chance', min = 1, max = 5, increment = 0.1 },
  ['cooldown_reduction'] = { name = 'cooldown_reduction', min = 1, max = 5, increment = 0.1 },
}

--oof, this is a hack
ITEM_STATS_THAT_CAN_ROLL_ON_ITEMS = {
  -- Core stats
  ['dmg'] = { name = 'dmg', min = 1, max = 5, increment = 0.1 },
  ['aspd'] = { name = 'aspd', min = 1, max = 5, increment = 0.05 },
  ['hp'] = { name = 'hp', min = 1, max = 5, increment = 0.2 },
  ['mvspd'] = { name = 'mvspd', min = 1, max = 5, increment = 0.05 },

  
  ['flat_def'] = { name = 'flat_def', min = 1, max = 5, increment = 0.1 },
  
  -- Special stats
  ['area_size'] = { name = 'area_size', min = 1, max = 5, increment = 0.1 },
  ['range'] = { name = 'range', min = 1, max = 5, increment = 0.05 },
  ['repeat_attack_chance'] = { name = 'repeat_attack_chance', min = 1, max = 5, increment = 0.1 },

  
  --advanced stats
  ['crit_chance'] = { name = 'crit_chance', min = 1, max = 5, increment = 0.1 },
}

ITEM_STATS_DAMAGE_STATS = {
  ['dmg'] = { name = 'dmg', min = 1, max = 5, increment = 0.1 },
  ['aspd'] = { name = 'aspd', min = 1, max = 5, increment = 0.1 },
  ['range'] = { name = 'range', min = 1, max = 5, increment = 0.05 },
  ['crit_chance'] = { name = 'crit_chance', min = 1, max = 5, increment = 0.1 },
  ['repeat_attack_chance'] = { name = 'repeat_attack_chance', min = 1, max = 5, increment = 0.1 },
}

-- Item type definitions with preferred stats
ITEM_TYPES = {
  [ITEM_TYPE.HEAD] = {
    name = 'Helmet',
    icon = 'helmet', -- Using orb for head items
    preferred_stats = {'hp', 'flat_def', 'crit_chance'},
    preferred_chance = 0.5 -- 70% chance to roll preferred stats
  },
  [ITEM_TYPE.BODY] = {
    name = 'Armor',
    icon = 'simplearmor',
    preferred_stats = {'hp', 'flat_def', 'area_size'},
    preferred_chance = 0.5
  },
  [ITEM_TYPE.WEAPON] = {
    name = 'Weapon',
    icon = 'sword',
    preferred_stats = {'dmg', 'aspd', 'range', 'crit_chance'},
    preferred_chance = 0.5
  },
  [ITEM_TYPE.OFFHAND] = {
    name = 'Offhand',
    icon = 'simpleshield',
    preferred_stats = {'flat_def', 'hp', 'crit_chance'},
    preferred_chance = 0.5
  },
  [ITEM_TYPE.FEET] = {
    name = 'Boots',
    icon = 'simpleboots',
    preferred_stats = {'mvspd', 'aspd'},
    preferred_chance = 0.5
  },
  [ITEM_TYPE.AMULET] = {
    name = 'Amulet',
    icon = 'potion2', -- Using potion for amulet items
    preferred_stats = {'crit_chance'},
    preferred_chance = 0.5
  }
}

ITEM_SET_POWER_BUDGET = 1

-- Set definitions with bonuses
ITEM_SETS = {
  [ITEM_SET.COLD] = {
    name = 'Frost Set',
    color = 'blue',
    bonuses = {
      [1] = { stats = {['cold_damage'] = 1} },
      [2] = { stats = {['cold_damage'] = 1}, procs = {'frostfield'} }, -- freezing an enemy creates a frostfield
      [4] = { stats = {['cold_damage'] = 2}, procs = {'shatterlance'} } -- attacking a frozen target shatters them
    }
  },
  [ITEM_SET.FROST_NOVA] = {
    name = 'Frost Nova Set',
    color = 'blue',
    bonuses = {
      [1] = { stats = {}, procs = {'frostnova'} } -- creates a frost nova when enemies get close
    }
  },
  [ITEM_SET.FIRE] = {
    name = 'Inferno Set',
    color = 'red',
    bonuses = {
        [1] = { stats = {['fire_damage'] = 1} },
        [2] = { stats = {['fire_damage'] = 1}, procs = {'burnexplode'} }, --burning enemies explode (remove from current fire effect)
        [4] = { stats = {['fire_damage'] = 2}, procs = {'volcano'} } -- burning enemies create a volcano on death
    }
  },
  [ITEM_SET.BLAZIN] = {
    name = 'Blazin Set',
    color = 'red',
    bonuses = {
      [1] = { stats = {}, procs = {'blazin'} } -- increases attack speed per burning enemy
    }
  },
  [ITEM_SET.METEOR] = {
    name = 'Meteor Set',
    color = 'red',
    bonuses = {
      [1] = { procs = {'meteor'} }, --periodically summon meteors
      [2] = { procs = {'meteorSizeBoost'} }, --meteors have a larger radius
      [4] = { procs = {'meteorDamageBoost'} } --meteors deal more damage
    }
  },
  [ITEM_SET.SHOCK] = {
    name = 'Storm Set',
    color = 'yellow',
          bonuses = {
        [1] = { stats = {['lightning_damage'] = 1} },
        [2] = { stats = {['lightning_damage'] = 1}, procs = {'shock'} }, --lightning shocks enemies, increasing damaage taken
        [4] = { stats = {['lightning_damage'] = 2} }
      }
  },
  [ITEM_SET.LIGHTNING_BALL] = {
    name = 'Lightning Ball Set',
    color = 'yellow',
    bonuses = {
      [1] = { procs = {'lightningball'} } --chance to creating a lightning ball when attacking
    }
  },
  [ITEM_SET.CURSE] = {
    name = 'Curse Set',
    color = 'purple',
    bonuses = {
      [1] = { procs = {'curse'} }, --curses nearby enemies, increasing damage taken
      [2] = { procs = {'curseHeal'} }, --heal from damage dealt to cursed enemies 
      [4] = { procs = {'curseDamageLink'} } --cursed enemies share damage taken
    }
  },
  [ITEM_SET.ATTACK_EFFECTS] = {
    name = 'Attack Effects Set',
    color = 'purple',
    bonuses = {
      [1] = { stats = {['attack_effects'] = 1} }, --every 4th attack is a critical hit
      [2] = { stats = {['crit_chance'] = 2} }, --every 3rd attack is a critical hit
      [4] = { stats = {['crit_chance'] = 4} } --every 2nd attack is a critical hit
    }
  },
  -- [ITEM_SET.LASER] = {
  --   name = 'Laser Set',
  --   color = 'purple',
  --   bonuses = {
  --     [1] = { stats = {['laser'] = 1} }, --a laser attacks nearby enemies periodically
  --     [2] = { stats = {['range'] = 2} }, --laser pierces through enemies
  --     [4] = { stats = {['range'] = 4} } --get a second laser
  --   }
  -- },
  [ITEM_SET.BLOODLUST] = {
    name = 'Bloodlust Set',
    color = 'purple',
    bonuses = {
      [1] = { procs = {'bloodlust'} }, --gain stacking attack speed when you kill an enemy
      [2] = { procs = {'bloodlustSpeedBoost'} }, --bloodlust grants movement speed as well
      [4] = { procs = {'bloodlustMaxStacks'} } --bloodlust can stack up to 10 times
    }
  },
  [ITEM_SET.SPLASH] = {
    name = 'Splash Set',
    color = 'brown',
    bonuses = {
      [1] = { procs = {'splash'} }, --attacks do splash damage to nearby enemies
      [2] = { stats = {['area_size'] = 2} }, --splash damage applies elemental effects
    }
  },
  [ITEM_SET.DAMAGE] = {
    name = 'Damage Set',
    color = 'red',
    bonuses = {
      [1] = { stats = {['dmg'] = 1} },
      [2] = { stats = {['dmg'] = 2} },
      [4] = { stats = {['dmg'] = 5} }
    }
  },
  -- [ITEM_SET.SUPPORT] = {
  --   name = 'Support Set',
  --   color = 'green',
  --   bonuses = {
  --     [1] = { stats = {['heal'] = 1} }, -- global attack speed
  --     [2] = { stats = {['heal'] = 2} },
  --     [4] = { stats = {['heal'] = 5} }
  --   }
  -- },
  [ITEM_SET.SHIELD] = {
    name = 'Shield Set',
    color = 'green',
    bonuses = {
      [1] = { procs = {'shield'} }, --shields you periodically, blocking damage
      [2] = { procs = {'shieldexplode'} }, --shield explodes when destroyed, knocking back nearby enemies
    }
  },
  [ITEM_SET.REFLECT] = {
    name = 'Mirror Set',
    color = 'green',
    bonuses = {
      [1] = { procs = {'retaliate'} }, --retaliate with an attack when hit
      [2] = { procs = {'elementalRetaliate'} }, --retaliate applies elemental effects
      [4] = { procs = {'retaliateNearby'} }, --retaliate hits all nearby enemies
    }
  },
  [ITEM_SET.REPEAT] = {
    name = 'Repeat Set',
    color = 'green',
    bonuses = {
      [1] = { stats = {['repeat_attack_chance'] = 1} },
      [2] = { stats = {['crit_chance'] = 2} }
    }
  },
  [ITEM_SET.STUN] = {
    name = 'Stun Set',
    color = 'black',
    bonuses = {
      [1] = { stats = {['stun_chance'] = 1} },
      [2] = { stats = {['dmg'] = 2} },
      [4] = { stats = {['dmg'] = 4} }
    }
  }
}

-- Rarity definitions
ITEM_RARITIES = {
  [ITEM_RARITY.COMMON] = {
    name = 'Common',
    cost = 4,
    min_stat_value = 0,
    max_stat_value = 0,
    set_chance = 1,
    color = 'grey'
  },
  [ITEM_RARITY.RARE] = {
    name = 'Rare',
    cost = 6,
    min_stat_value = 1,
    max_stat_value = 2,
    set_chance = 1,
    color = 'blue'
  },
  [ITEM_RARITY.EPIC] = {
    name = 'Epic',
    cost = 10,
    min_stat_value = 3,
    max_stat_value = 4,
    set_chance = 1,
    color = 'purple'
  },
  [ITEM_RARITY.LEGENDARY] = {
    name = 'Legendary',
    cost = 15,
    min_stat_value = 5,
    max_stat_value = 6,
    set_chance = 1,
    color = 'orange'
  }
}

-- Helper function to get random item type
function get_random_item_type()
  local types = {ITEM_TYPE.HEAD, ITEM_TYPE.BODY, ITEM_TYPE.WEAPON, ITEM_TYPE.OFFHAND, ITEM_TYPE.FEET, ITEM_TYPE.AMULET}
  return types[math.random(1, #types)]
end

-- Helper function to get random rarity
function get_random_rarity()
  local rarities = {ITEM_RARITY.COMMON, ITEM_RARITY.RARE, ITEM_RARITY.EPIC, ITEM_RARITY.LEGENDARY}
  local weights = {0.6, 0.3, 0.08, 0.02} -- 60% common, 30% rare, 8% epic, 2% legendary
  
  -- Simple weighted random selection
  local total_weight = 0
  for _, weight in ipairs(weights) do
    total_weight = total_weight + weight
  end
  
  local roll = math.random() * total_weight
  
  local current_weight = 0
  
  for i, weight in ipairs(weights) do
    current_weight = current_weight + weight
    if roll <= current_weight then
      return rarities[i]
    end
  end
  
  return rarities[1] -- Fallback to common
end

-- Helper function to get random set
function get_random_set()
  local set_keys = {}
  for set_name, _ in pairs(ITEM_SETS) do
    table.insert(set_keys, set_name)
  end
  return random:table(set_keys)
end

-- Helper function to roll a stat for an item type
function roll_stat_for_type(item_type)
  local type_def = ITEM_TYPES[item_type]
  local all_stats = {}
  for stat, _ in pairs(ITEM_STATS_THAT_CAN_ROLL_ON_ITEMS) do
    table.insert(all_stats, stat)
  end
  
  -- Check if we should roll a preferred stat
  if random:float(0, 1) < type_def.preferred_chance then
    -- Roll from preferred stats
    return random:table(type_def.preferred_stats)
  else
    -- Roll from all stats
    return random:table(all_stats)
  end
end

-- Main function to create a random item
function create_random_item(tier, max_cost)
  -- Debug: Check if random is available
  if not random then
    print("ERROR: random object is not available!")
    return nil
  end
  
  local item_type = get_random_item_type()
  if not item_type then
    print("ERROR: Failed to get random item type!")
    return nil
  end
  
  local rarity = get_random_rarity()
  if not rarity then
    print("ERROR: Failed to get random rarity!")
    return nil
  end
  
  local rarity_def = ITEM_RARITIES[rarity]
  if not rarity_def then
    print("ERROR: rarity_def is nil for rarity:", rarity)
    return nil
  end
  
  -- Create the item
  local item = {
    name = ITEM_TYPES[item_type].name,
    type = item_type,
    rarity = rarity,
    tier = tier or 1,
    icon = ITEM_TYPES[item_type].icon,
    stats = {},
    sets = {},
    cost = rarity_def.cost,
    procs = {}, -- Empty procs for compatibility with existing system
    tags = {} -- Empty tags for compatibility with existing system
  }

  -- Determine if item has sets
  if random:float(0, 1) < rarity_def.set_chance then
    -- Add 1-2 sets for higher rarities
    local set_count = rarity == ITEM_RARITY.LEGENDARY and 2 or 1
    for i = 1, set_count do
      local set_key = get_random_set()
      if not table.contains(item.sets, set_key) then
        table.insert(item.sets, set_key)
      end
    end
  end
  
  if rarity_def.min_stat_value > 0 then
    local stat_name = roll_stat_for_type(item_type)
    
    -- Generate stat
    local stat_value = math.random(rarity_def.min_stat_value, rarity_def.max_stat_value)

    item.stats[stat_name] = stat_value + (item.stats[stat_name] or 0)
  end
  
  -- Set colors based on sets only (rarity color is used as tier color)
  item.colors = {}
  
  -- Add set colors if item has sets
  if #item.sets > 0 then
    for _, set_key in ipairs(item.sets) do
      local set_def = ITEM_SETS[set_key]
      if set_def and set_def.color then
        table.insert(item.colors, set_def.color)
      end
    end
  end
  
  return item
end

-- Function to convert V2 item to legacy format for compatibility
function convert_v2_item_to_legacy(v2_item)
  local legacy_item = {
    name = v2_item.name,
    icon = v2_item.icon,
    cost = v2_item.cost,
    colors = v2_item.colors,
    stats = v2_item.stats,
    procs = v2_item.procs or {},
    tags = v2_item.tags or {},
    -- Add any other fields needed for legacy compatibility
  }
  return legacy_item
end
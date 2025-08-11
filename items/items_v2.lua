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
  STUN = 'stun',
  MULTI_SHOT = 'multi_shot',
  --elemental transformation
  FIRE_TO_LIGHTNING = 'fire_to_lightning',
  COLD_TO_FIRE = 'cold_to_fire',
  LIGHTNING_TO_COLD = 'lightning_to_cold',
  --elemental boosts
  STONE_COLD = 'stone_cold',
  BLAZIN = 'blazin',
  --lightning one?
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
  ['repeat_attack_chance'] = { name = 'repeat_attack_chance', min = 1, max = 5, increment = 0.2 },
  ['gold'] = { name = 'gold', min = 1, max = 5, increment = 1 },
  ['heal'] = { name = 'heal', min = 1, max = 5, increment = 0.05 },
  
  -- Elemental stats
  ['fire_damage'] = { name = 'fire_damage', min = 1, max = 5, increment = 0.1 },
  ['lightning_damage'] = { name = 'lightning_damage', min = 1, max = 5, increment = 0.1 },
  ['cold_damage'] = { name = 'cold_damage', min = 1, max = 5, increment = 0.1 },
  
  -- Advanced stats
  ['crit_chance'] = { name = 'crit_chance', min = 1, max = 5, increment = 0.1 },
  ['stun_chance'] = { name = 'stun_chance', min = 1, max = 5, increment = 0.2 },
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
  ['repeat_attack_chance'] = { name = 'repeat_attack_chance', min = 1, max = 5, increment = 0.2 },

  
  --advanced stats
  ['crit_chance'] = { name = 'crit_chance', min = 1, max = 5, increment = 0.1 },
  -- ['crit_damage'] = { name = 'crit_damage', min = 1, max = 5, increment = 0.1 },
  ['cooldown_reduction'] = { name = 'cooldown_reduction', min = 1, max = 5, increment = 0.1 },
}

ITEM_STATS_DAMAGE_STATS = {
  ['dmg'] = { name = 'dmg', min = 1, max = 5, increment = 0.1 },
  ['aspd'] = { name = 'aspd', min = 1, max = 5, increment = 0.1 },
  ['range'] = { name = 'range', min = 1, max = 5, increment = 0.05 },
  ['crit_chance'] = { name = 'crit_chance', min = 1, max = 5, increment = 0.1 },
  -- ['crit_damage'] = { name = 'crit_damage', min = 1, max = 5, increment = 0.1 },
  ['repeat_attack_chance'] = { name = 'repeat_attack_chance', min = 1, max = 5, increment = 0.2 },
}

ITEM_SET_POWER_BUDGET = 1

-- Set definitions with bonuses
ITEM_SETS = {
  [ITEM_SET.COLD] = {
    name = 'Frost',
    color = 'blue',
    bonuses = {
      [1] = { stats = {['cold_damage'] = 1} },
      [2] = { stats = {['cold_damage'] = 1}, procs = {'frostfield'} },
      [3] = { stats = {['cold_damage'] = 2}, procs = {'shatterlance'} }
    },
    descriptions = {
      [1] = 'Adds cold damage to attacks',
      [2] = 'Freezing an enemy creates a frostfield',
      [3] = 'Attacking a frozen target shatters them'
    }
  },
  [ITEM_SET.FROST_NOVA] = {
    name = 'Frost Nova',
    color = 'blue',
    bonuses = {
      [1] = { stats = {}, procs = {'frostnova'} }
    },
    descriptions = {
      [1] = 'Creates a frost nova when enemies get close'
    }
  },
  [ITEM_SET.COLD_TO_FIRE] = {
    name = 'Frostfire',
    color = 'blue',
    bonuses = {
      [1] = { stats = {}, procs = {'coldToFire'} }
    },
    descriptions = {
      [1] = 'Your cold damage also burns enemies'
    }
  },
  [ITEM_SET.FIRE] = {
    name = 'Inferno',
    color = 'red',
    bonuses = {
        [1] = { stats = {['fire_damage'] = 1} },
        [2] = { stats = {['fire_damage'] = 1}, procs = {'burnexplode'} },
        [3] = { stats = {['fire_damage'] = 2}, procs = {'volcano'} }
    },
    descriptions = {
      [1] = 'Adds fire damage to attacks',
      [2] = 'Burning enemies explode',
      [3] = 'Burning enemies create a volcano on death'
    }
  },
  [ITEM_SET.BLAZIN] = {
    name = 'Blazing',
    color = 'red',
    bonuses = {
      [1] = { stats = {}, procs = {'blazin'} }
    },
    descriptions = {
      [1] = 'Increases attack speed per burning enemy'
    }
  },
  [ITEM_SET.STONE_COLD] = {
    name = 'Stone Cold',
    color = 'blue',
    bonuses = {
      [1] = { procs = {'stonecold'} }
    },
    descriptions = {
      [1] = 'You deal more damage to chilled enemies'
    }
  },
  [ITEM_SET.FIRE_TO_LIGHTNING] = {
    name = 'Fire Bolt',
    color = 'red',
    bonuses = {
      [1] = { procs = {'fireToLightning'} }
    },
    descriptions = {
      [1] = 'Your fire damage also shocks enemies'
    }
  },
  [ITEM_SET.METEOR] = {
    name = 'Meteor',
    color = 'red',
    bonuses = {
      [1] = { procs = {'meteor'} },
      [2] = { procs = {'meteorSizeBoost'} },
      [3] = { procs = {'meteorDamageBoost'} }
    },
    descriptions = {
      [1] = 'Periodically summon meteors',
      [2] = 'Meteors have a larger radius',
      [3] = 'Meteors deal more damage'
    }
  },
  [ITEM_SET.SHOCK] = {
    name = 'Storm',
    color = 'yellow',
    bonuses = {
      [1] = { stats = {['lightning_damage'] = 1} },
      [2] = { stats = {['lightning_damage'] = 1}, procs = {'shock'} },
      [3] = { stats = {['lightning_damage'] = 2} }
    },
    descriptions = {
      [1] = 'Adds lightning damage to attacks',
      [2] = 'Lightning shocks enemies, increasing damage taken',
      [3] = 'Adds more lightning damage to attacks'
    }
  },
  [ITEM_SET.LIGHTNING_BALL] = {
    name = 'Lightning',
    color = 'yellow',
    bonuses = {
      [1] = { procs = {'lightningball'} }
    },
    descriptions = {
      [1] = 'Chance to create a lightning ball on attack'
    }
  },
  [ITEM_SET.LIGHTNING_TO_COLD] = {
    name = 'Frost Jolt',
    color = 'yellow',
    bonuses = {
      [1] = { procs = {'lightningToCold'} }
    },
    descriptions = {
      [1] = 'Your lightning damage also chills enemies'
    }
  },
  [ITEM_SET.CURSE] = {
    name = 'Curse',
    color = 'purple',
    bonuses = {
      [1] = { procs = {'curse'} },
      [2] = { procs = {'curseHeal'} },
      [3] = { procs = {'curseDamageLink'} }
    },
    descriptions = {
      [1] = 'Curses nearby enemies, increasing damage taken',
      [2] = 'Heal a percentage of damage dealt to cursed enemies',
      [3] = 'Cursed enemies share damage taken'
    }
  },
  -- [ITEM_SET.ATTACK_EFFECTS] = {
  --   name = 'Critical',
  --   color = 'purple',
  --   bonuses = {
  --     [1] = { stats = {['attack_effects'] = 1} },
  --     [2] = { stats = {['crit_chance'] = 2} },
  --     [3] = { stats = {['crit_chance'] = 4} }
  --   },
  --   descriptions = {
  --     [1] = 'Every 4th attack is a critical hit',
  --     [2] = 'Every 3rd attack is a critical hit',
  --     [3] = 'Every 2nd attack is a critical hit'
  --   }
  -- },
  -- [ITEM_SET.LASER] = {
  --   name = 'Laser Set',
  --   color = 'purple',
  --   bonuses = {
  --     [1] = { stats = {['laser'] = 1} }, --a laser attacks nearby enemies periodically
  --     [2] = { stats = {['range'] = 2} }, --laser pierces through enemies
  --     [3] = { stats = {['range'] = 4} } --get a second laser
  --   }
  -- },
  [ITEM_SET.BLOODLUST] = {
    name = 'Bloodlust',
    color = 'purple',
    bonuses = {
      [1] = { procs = {'bloodlust'} },
      [2] = { procs = {'bloodlustSpeedBoost'} },
      -- [3] = { procs = {'bloodlustMaxStacks'} }
    },
    descriptions = {
      [1] = 'Gain stacking attack speed when you kill an enemy',
      [2] = 'Bloodlust grants movement speed as well',
      -- [3] = 'Bloodlust can stack up to 10 times'
    }
  },
  [ITEM_SET.SPLASH] = {
    name = 'Splash',
    color = 'brown',
    bonuses = {
      [1] = { procs = {'splash'} },
      [2] = { procs = {'splashSizeBoost'} },
      -- [3] = { procs = {'splashSizeBoost2'} }
    },
    descriptions = {
      [1] = 'Attacks do splash damage to nearby enemies',
      [2] = 'Attacks splash in a larger area',
      -- [3] = 'Attacks splash in an even larger area'
    }
  },
  [ITEM_SET.DAMAGE] = {
    name = 'Damage',
    color = 'red',
    bonuses = {
      [1] = { stats = {['dmg'] = 1} },
      [2] = { stats = {['dmg'] = 2} },
      [3] = { stats = {['dmg'] = 5} }
    },
    descriptions = {
      [1] = 'Gain damage',
      [2] = 'Gain more damage',
      [3] = 'Gain even more damage'
    }
  },
  -- [ITEM_SET.SUPPORT] = {
  --   name = 'Support Set',
  --   color = 'green',
  --   bonuses = {
  --     [1] = { stats = {['heal'] = 1} }, -- global attack speed
  --     [2] = { stats = {['heal'] = 2} },
  --     [3] = { stats = {['heal'] = 5} }
  --   }
  -- },
  [ITEM_SET.SHIELD] = {
    name = 'Radiance',
    color = 'red',
    bonuses = {
      [1] = { procs = {'shield', 'radiance'} },
      -- [2] = { procs = {'shieldexplode'} },
    },
    descriptions = {
      [1] = 'Grants you a shield and damage aura',
      -- [2] = 'Shield explodes when destroyed, knocking back nearby enemies'
    }
  },
  [ITEM_SET.REFLECT] = {
    name = 'Reflect',
    color = 'green',
    bonuses = {
      [1] = { procs = {'retaliate'} },
      [2] = { procs = {'elementalRetaliate'} },
      [3] = { procs = {'retaliateNearby'} },
    },
    descriptions = {
      [1] = 'Retaliate with an attack when hit',
      [2] = 'Retaliate applies elemental effects',
      [3] = 'Retaliate hits all nearby enemies'
    }
  },
  [ITEM_SET.REPEAT] = {
    name = 'Repeat',
    color = 'green',
    bonuses = {
      [1] = { stats = {['repeat_attack_chance'] = 1} },
      [2] = { stats = {['repeat_attack_chance'] = 2} },
      [3] = { stats = {['repeat_attack_chance'] = 4} }
    },
    descriptions = {
      [1] = '20% chance to repeat your attacks',
      [2] = '40% chance to repeat your attacks',
      [3] = '80% chance to repeat your attacks'
    }
  },
  [ITEM_SET.MULTI_SHOT] = {
    name = 'Multi-Shot',
    color = 'green',
    bonuses = {
      [1] = { procs = {'multishot'} },
      [2] = { procs = {'multishotFullDamage'} },
      [3] = { procs = {'extraMultishot'} }
    },
    descriptions = {
      [1] = 'Shoot extra attacks at an angle (for 25% damage)',
      [2] = 'Your multi-shot attacks deal 50% damage',
      [3] = 'Shoot an extra 2 attacks'
    }
  },
  -- [ITEM_SET.STUN] = {
  --   name = 'Stun',
  --   color = 'black',
  --   bonuses = {
  --     [1] = { stats = {['stun_chance'] = 1} },
  --     [2] = { stats = {['stun_chance'] = 2} },
  --     [3] = { stats = {['stun_chance'] = 4} }
  --   },
  --   descriptions = {
  --     [1] = '20% chance to stun an enemy',
  --     [2] = '40% chance to stun an enemy',
  --     [3] = '80% chance to stun an enemy'
  --   }
  -- }
}

-- Rarity definitions
ITEM_RARITIES = {
  [ITEM_RARITY.COMMON] = {
    name = 'Common',
    cost = 2,
    min_stat_value = 1,
    max_stat_value = 2,
    set_chance = 0,
    color = 'grey'
  },
  [ITEM_RARITY.RARE] = {
    name = 'Rare',
    cost = 4,
    min_stat_value = 0,
    max_stat_value = 0,
    set_chance = 1,
    color = 'blue'
  },
  [ITEM_RARITY.EPIC] = {
    name = 'Epic',
    cost = 6,
    min_stat_value = 2,
    max_stat_value = 4,
    set_chance = 1,
    second_set_chance = 0,
    color = 'purple'
  },
  [ITEM_RARITY.LEGENDARY] = {
    name = 'Legendary',
    cost = 10,
    min_stat_value = 3,
    max_stat_value = 4,
    set_chance = 1,
    color = 'orange'
  }
}

-- Helper function to get random item type
function get_random_item_slot()
  local slots = {}
  for _, slot in pairs(ITEM_SLOTS_BY_INDEX) do
    table.insert(slots, slot)
  end
  return slots[math.random(1, #slots)]
end

-- Helper function to get random rarity
function get_random_rarity(level, exclude_rarity)
  local tier = LEVEL_TO_TIER(level)

  local rarities = {ITEM_RARITY.COMMON, ITEM_RARITY.RARE, ITEM_RARITY.EPIC, ITEM_RARITY.LEGENDARY}
  local weights = TIER_TO_ITEM_RARITY_WEIGHTS[tier] or {1, 0, 0, 0}

  if exclude_rarity then
   local rarity_index = table.find(rarities, exclude_rarity)
    weights = table.copy(weights)
    weights[rarity_index] = 0
  end

  if not weights then
    print("ERROR: weights is nil for tier:", tier)
    return nil
  end

  return rarities[random:weighted_pick(unpack(weights))] or rarities[1]
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
  local type_def = ITEM_SLOTS_PREFERRED_STATS[item_type]
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

function create_random_items(level)
  local items = {}
  for i = 1, 3 do
    table.insert(items, create_random_item(level))
  end

  --pity roll
  if table.all(items, function(item) return item.rarity == ITEM_RARITY.COMMON end) then
    local item_index = random:int(1, 3)
    items[item_index] = create_random_item(level, ITEM_RARITY.COMMON)
  end

  return items
end


-- Main function to create a random item
function create_random_item(level, exclude_rarity)
  
  local item_slot = get_random_item_slot()
  if not item_slot then
    print("ERROR: Failed to get random item slot!")
    return nil
  end
  
  local rarity =  get_random_rarity(level, exclude_rarity)
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
    name = ITEM_SLOTS[item_slot].name,
    slot = item_slot,
    rarity = rarity,
    tier = tier or 1,
    icon = ITEM_SLOTS[item_slot].icon,
    stats = {},
    sets = {},
    cost = rarity_def.cost,
    procs = {}, -- Empty procs for compatibility with existing system
    tags = {} -- Empty tags for compatibility with existing system
  }

  -- Determine if item has sets
  if random:float(0, 1) < rarity_def.set_chance then
    -- Add 1-2 sets for higher rarities
    local set_count = 1
    if rarity_def.second_set_chance and random:float(0, 1) < rarity_def.second_set_chance then
      set_count = 2
    end

    for i = 1, set_count do
      local set_key = get_random_set()
      if not table.contains(item.sets, set_key) then
        table.insert(item.sets, set_key)
      end
    end
  end
  
  if rarity_def.max_stat_value > 0 and #item.sets < 2 
  and not (rarity == ITEM_RARITY.RARE and level <= 3) then
    local stat_name = roll_stat_for_type(item_slot)
    
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
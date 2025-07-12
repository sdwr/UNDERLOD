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
  FIRE = 'fire', 
  SHOCK = 'shock',
  CURSE = 'curse',
  REFLECT = 'reflect'
}

-- Stat definitions
ITEM_STATS = {
  -- Core stats
  ['dmg'] = { name = 'damage', min = 1, max = 5, increment = 0.05 },
  ['aspd'] = { name = 'aspeed', min = 1, max = 5, increment = 0.05 },
  ['hp'] = { name = 'hp', min = 1, max = 5, increment = 0.05 },
  ['mvspd'] = { name = 'move', min = 1, max = 5, increment = 0.05 },
  
  -- Defensive stats
  ['flat_def'] = { name = 'def', min = 1, max = 5, increment = 0.05 },
  
  -- Special stats
  ['area_size'] = { name = 'area', min = 1, max = 5, increment = 0.05 },
  ['vamp'] = { name = 'lifesteal', min = 1, max = 5, increment = 0.05 },
  ['ghost'] = { name = 'ghost', min = 1, max = 5, increment = 0.05 },
  ['slow'] = { name = 'slow', min = 1, max = 5, increment = 0.05 },
  ['thorns'] = { name = 'reflect', min = 1, max = 5, increment = 0.05 },
  ['range'] = { name = 'range', min = 1, max = 5, increment = 0.05 },
  ['repeat_attack_chance'] = { name = 'repeat', min = 1, max = 5, increment = 0.05 },
  ['gold'] = { name = 'gold', min = 1, max = 5, increment = 1 },
  ['heal'] = { name = 'heal', min = 1, max = 5, increment = 0.05 },
  
  -- Elemental stats
  ['fire_damage'] = { name = 'fire', min = 1, max = 5, increment = 0.05 },
  ['lightning_damage'] = { name = 'shock', min = 1, max = 5, increment = 0.05 },
  ['cold_damage'] = { name = 'cold', min = 1, max = 5, increment = 0.05 },
  
  -- Advanced stats
  ['crit_chance'] = { name = 'crit', min = 1, max = 5, increment = 0.05 },
  ['stun_chance'] = { name = 'stun', min = 1, max = 5, increment = 0.05 },
  ['cooldown_reduction'] = { name = 'cdr', min = 1, max = 5, increment = 0.05 },
}

-- Item type definitions with preferred stats
ITEM_TYPES = {
  [ITEM_TYPE.HEAD] = {
    name = 'Helmet',
    icon = 'orb', -- Using orb for head items
    preferred_stats = {'hp', 'flat_def', 'crit_chance', 'stun_chance'},
    preferred_chance = 0.7 -- 70% chance to roll preferred stats
  },
  [ITEM_TYPE.BODY] = {
    name = 'Armor',
    icon = 'simplearmor',
    preferred_stats = {'hp', 'flat_def', 'area_size', 'thorns'},
    preferred_chance = 0.7
  },
  [ITEM_TYPE.WEAPON] = {
    name = 'Weapon',
    icon = 'sword',
    preferred_stats = {'dmg', 'aspd', 'range', 'crit_chance', 'bash'},
    preferred_chance = 0.7
  },
  [ITEM_TYPE.OFFHAND] = {
    name = 'Offhand',
    icon = 'simpleshield',
    preferred_stats = {'flat_def', 'thorns'},
    preferred_chance = 0.7
  },
  [ITEM_TYPE.FEET] = {
    name = 'Boots',
    icon = 'simpleboots',
    preferred_stats = {'mvspd', 'slow'},
    preferred_chance = 0.7
  },
  [ITEM_TYPE.AMULET] = {
    name = 'Amulet',
    icon = 'potion2', -- Using potion for amulet items
    preferred_stats = {'crit_chance'},
    preferred_chance = 0.7
  }
}

-- Set definitions with bonuses
ITEM_SETS = {
  [ITEM_SET.COLD] = {
    name = 'Frost Set',
    color = 'blue',
          bonuses = {
        [2] = { desc = '+2 Cold Damage', stats = {['cold_damage'] = 2} },
        [4] = { desc = '+4 Cold Damage, +2 Slow', stats = {['cold_damage'] = 4, ['slow'] = 2} },
        [6] = { desc = '+6 Cold Damage, +3 Slow, Freeze on Hit', stats = {['cold_damage'] = 6, ['slow'] = 3} }
      }
  },
  [ITEM_SET.FIRE] = {
    name = 'Inferno Set',
    color = 'red',
          bonuses = {
        [2] = { desc = '+2 Fire Damage', stats = {['fire_damage'] = 2} },
        [4] = { desc = '+4 Fire Damage, +2 Burn', stats = {['fire_damage'] = 4, ['burn_chance'] = 2} },
        [6] = { desc = '+6 Fire Damage, +3 Burn, Explosion on Kill', stats = {['fire_damage'] = 6} }
      }
  },
  [ITEM_SET.SHOCK] = {
    name = 'Storm Set',
    color = 'yellow',
          bonuses = {
        [2] = { desc = '+2 Lightning Damage', stats = {['lightning_damage'] = 2} },
        [4] = { desc = '+4 Lightning Damage, +2 Chain', stats = {['lightning_damage'] = 4} },
        [6] = { desc = '+6 Lightning Damage, +3 Chain, Stun on Hit', stats = {['lightning_damage'] = 6} }
      }
  },
  [ITEM_SET.CURSE] = {
    name = 'Shadow Set',
    color = 'purple',
    bonuses = {
      [2] = { desc = '+15% Curse Damage', stats = {['curse_damage'] = 0.15} },
      [4] = { desc = '+30% Curse Damage, +10% DoT', stats = {['curse_damage'] = 0.30} },
      [6] = { desc = '+50% Curse Damage, +20% DoT, Death Mark', stats = {['curse_damage'] = 0.50} }
    }
  },
  [ITEM_SET.REFLECT] = {
    name = 'Mirror Set',
    color = 'green',
    bonuses = {
      [2] = { desc = '+15% Reflect Damage', stats = {['reflect_damage'] = 0.15} },
      [4] = { desc = '+30% Reflect Damage, +10% Block', stats = {['reflect_damage'] = 0.30} },
      [6] = { desc = '+50% Reflect Damage, +20% Block, Counter Attack', stats = {['reflect_damage'] = 0.50} }
    }
  }
}

-- Rarity definitions
ITEM_RARITIES = {
  [ITEM_RARITY.COMMON] = {
    name = 'Common',
    stat_count = 1,
    set_chance = 0.3, -- 10% chance to have a set
    color = 'grey'
  },
  [ITEM_RARITY.RARE] = {
    name = 'Rare',
    stat_count = 2,
    set_chance = 0.5, -- 30% chance to have a set
    color = 'blue'
  },
  [ITEM_RARITY.EPIC] = {
    name = 'Epic',
    stat_count = 3,
    set_chance = 0.7, -- 60% chance to have a set
    color = 'purple'
  },
  [ITEM_RARITY.LEGENDARY] = {
    name = 'Legendary',
    stat_count = 4,
    set_chance = 1.0, -- 100% chance to have a set
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
  local sets = {ITEM_SET.COLD, ITEM_SET.FIRE, ITEM_SET.SHOCK, ITEM_SET.CURSE, ITEM_SET.REFLECT}
  return sets[math.random(1, #sets)]
end

-- Helper function to roll a stat for an item type
function roll_stat_for_type(item_type)
  local type_def = ITEM_TYPES[item_type]
  local all_stats = {}
  for stat, _ in pairs(ITEM_STATS) do
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

-- Helper function to generate random stat value
function generate_stat_value(stat_name)
  local stat_def = ITEM_STATS[stat_name]
  if not stat_def then return 0 end
  
  return math.random(stat_def.min, stat_def.max)
end

-- Main function to create a random item
function create_random_item(tier)
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
    cost = tier * (rarity_def.stat_count * 2), -- Cost based on tier and stat count
    procs = {}, -- Empty procs for compatibility with existing system
    tags = {} -- Empty tags for compatibility with existing system
  }
  
  -- Determine if item has sets
  if random:float(0, 1) < rarity_def.set_chance then
    -- Add 1-2 sets for higher rarities
    local set_count = rarity == ITEM_RARITY.LEGENDARY and 2 or 1
    for i = 1, set_count do
      local set = get_random_set()
      if not table.contains(item.sets, set) then
        table.insert(item.sets, set)
      end
    end
  end
  
  -- Generate stats
  local used_stats = {}
  for i = 1, rarity_def.stat_count do
    local stat_name
    repeat
      stat_name = roll_stat_for_type(item_type)
    until not table.contains(used_stats, stat_name)
    
    table.insert(used_stats, stat_name)
    item.stats[stat_name] = generate_stat_value(stat_name)
  end
  
  -- Set colors based on sets only (rarity color is used as tier color)
  item.colors = {}
  
  -- Add set colors if item has sets
  if #item.sets > 0 then
    for _, set_name in ipairs(item.sets) do
      local set_def = ITEM_SETS[set_name]
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

-- Function to create item with specific parameters
function create_item_v2(item_type, rarity, tier)
  local item = create_random_item(tier)
  item.type = item_type
  item.rarity = rarity
  item.name = ITEM_TYPES[item_type].name
  item.icon = ITEM_TYPES[item_type].icon
  
  -- Regenerate stats for the specific type and rarity
  local rarity_def = ITEM_RARITIES[rarity]
  item.stats = {}
  local used_stats = {}
  
  for i = 1, rarity_def.stat_count do
    local stat_name
    repeat
      stat_name = roll_stat_for_type(item_type)
    until not table.contains(used_stats, stat_name)
    
    table.insert(used_stats, stat_name)
    item.stats[stat_name] = generate_stat_value(stat_name)
  end
  
  return item
end 
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
}

-- Item Sets. Removed sets keep their keys so old saves still resolve.
ITEM_SET = {
  DAMAGE = 'damage',
  ASPD = 'aspd',
  RANGE = 'range_set',
  CRIT = 'crit',
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
  SUPPORT = 'support',
  SHIELD = 'shield',
  REPEAT = 'repeat',
  STUN = 'stun',
  MULTI_SHOT = 'multi_shot',
  HEFT = 'heft',
  TREASURY = 'treasury',
  RESONANCE = 'resonance',
  ORBITAL = 'orbital',
  MEND = 'mend',
  TURRET = 'turret',
  MOBILE = 'mobile',
  VOLT = 'volt',
  VITALITY = 'vitality',
  PIERCE = 'pierce',
  FOCUS = 'focus',
  RICOCHET = 'ricochet',
  RECOIL = 'recoil',
}

-- Stat definitions
ITEM_STATS = {
  -- Core stats
  ['dmg'] = { name = 'dmg', min = 1, max = 5, increment = 0.1 },
  ['flat_dmg'] = { name = 'flat_dmg', min = 1, max = 5, increment = 1 },
  ['aspd'] = { name = 'aspd', min = 1, max = 5, increment = 0.05 },
  ['hp'] = { name = 'hp', min = 1, max = 5, increment = 0.2 },

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
  
  -- Elemental stats (flat damage; sets are the only source)
  ['fire_damage'] = { name = 'fire_damage', min = 1, max = 5, increment = 1 },
  ['lightning_damage'] = { name = 'lightning_damage', min = 1, max = 5, increment = 1 },
  ['cold_damage'] = { name = 'cold_damage', min = 1, max = 5, increment = 1 },
  
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

  -- Special stats
  ['area_size'] = { name = 'area_size', min = 1, max = 5, increment = 0.1 },
  ['range'] = { name = 'range', min = 1, max = 5, increment = 0.05 },
  ['repeat_attack_chance'] = { name = 'repeat_attack_chance', min = 1, max = 5, increment = 0.2 },

  --advanced stats
  ['crit_chance'] = { name = 'crit_chance', min = 1, max = 5, increment = 0.1 },
  -- ['crit_damage'] = { name = 'crit_damage', min = 1, max = 5, increment = 0.1 },
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

-- Set definitions with bonuses. Each set is tagged with `rarity` (common or
-- rare) and optionally `min_tier` (default 1). Items roll a set from the pool
-- matching their own rarity whose min_tier is at or below the current item
-- tier. Bonus tiers stack: a 3-piece set applies [1], [2] and [3] together,
-- so descriptions list cumulative totals.
--
-- Commons are 3-piece stat sets with a linear curve. Rares are 1 or 2 pieces:
-- a specific rare set is ~2% of any roll, so 3-piece rares never completed.
-- `disabled` keeps a definition loadable for old saves but out of the roll
-- pool.
ITEM_SETS = {
  [ITEM_SET.DAMAGE] = {
    name = 'Power',
    summary = '+%damage',
    color = 'red',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['dmg'] = 2} },
      [2] = { stats = {['dmg'] = 2} },
      [3] = { stats = {['dmg'] = 2} },
    },
    descriptions = {
      [1] = '+20% damage',
      [2] = '+40% damage',
      [3] = '+60% damage',
    }
  },
  [ITEM_SET.ASPD] = {
    name = 'Swift',
    summary = '+%attack speed',
    color = 'yellow',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['aspd'] = 2} },
      [2] = { stats = {['aspd'] = 2} },
      [3] = { stats = {['aspd'] = 2} },
    },
    descriptions = {
      [1] = '+10% attack speed',
      [2] = '+20% attack speed',
      [3] = '+30% attack speed',
    }
  },
  [ITEM_SET.CRIT] = {
    name = 'Precision',
    summary = '+crit chance',
    color = 'blue',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['crit_chance'] = 1.5} },
      [2] = { stats = {['crit_chance'] = 1.5} },
      [3] = { stats = {['crit_chance'] = 1.5} },
    },
    descriptions = {
      [1] = '+15% crit chance (crits deal double damage)',
      [2] = '+30% crit chance',
      [3] = '+45% crit chance',
    }
  },
  [ITEM_SET.FIRE] = {
    name = 'Inferno',
    summary = '+fire damage',
    color = 'red',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['fire_damage'] = 6} },
      [2] = { stats = {['fire_damage'] = 6} },
      [3] = { stats = {['fire_damage'] = 6} },
    },
    descriptions = {
      [1] = '+6 fire damage per hit; fire burns enemies over time',
      [2] = '+12 fire damage per hit',
      [3] = '+18 fire damage per hit',
    }
  },
  [ITEM_SET.COLD] = {
    name = 'Frost',
    summary = '+cold damage',
    color = 'blue',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['cold_damage'] = 6} },
      [2] = { stats = {['cold_damage'] = 6} },
      [3] = { stats = {['cold_damage'] = 6} },
    },
    descriptions = {
      [1] = '+6 cold damage per hit; cold slows enemies',
      [2] = '+12 cold damage per hit',
      [3] = '+18 cold damage per hit',
    }
  },
  -- Third element so Resonance can see burn, chill and shock together.
  [ITEM_SET.VOLT] = {
    name = 'Volt',
    summary = '+lightning damage',
    color = 'yellow',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['lightning_damage'] = 6} },
      [2] = { stats = {['lightning_damage'] = 6} },
      [3] = { stats = {['lightning_damage'] = 6} },
    },
    descriptions = {
      [1] = '+6 lightning damage per hit; lightning shocks enemies',
      [2] = '+12 lightning damage per hit',
      [3] = '+18 lightning damage per hit',
    }
  },
  -- The only defensive stat set. Contact damage scales with enemy hp now, so
  -- raw hp is the counter.
  [ITEM_SET.VITALITY] = {
    name = 'Vitality',
    summary = '+%hp',
    color = 'green',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['hp'] = 1} },
      [2] = { stats = {['hp'] = 1} },
      [3] = { stats = {['hp'] = 1} },
    },
    descriptions = {
      [1] = '+20% max hp',
      [2] = '+40% max hp',
      [3] = '+60% max hp',
    }
  },

  -- ---------------------------------------------------------------- rares
  [ITEM_SET.SHOCK] = {
    name = 'Storm',
    summary = 'chain lightning',
    color = 'yellow',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'shock'} },
      [2] = { procs = {'shock2'} },
    },
    descriptions = {
      [1] = '25% chance on hit to chain lightning through 3 enemies, shocking each',
      [2] = '35% chance, chains through 5 enemies',
    }
  },
  [ITEM_SET.LIGHTNING_BALL] = {
    name = 'Lightning',
    summary = 'lightning ball',
    color = 'yellow',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'lightningball'} }
    },
    descriptions = {
      [1] = '20% chance on hit to launch a lightning ball that zaps nearby enemies'
    }
  },
  -- Ricochet: a hit has a chance to fire a bolt at another nearby enemy.
  [ITEM_SET.RICOCHET] = {
    name = 'Ricochet',
    summary = 'hits bounce',
    color = 'yellow',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'ricochet'} }
    },
    descriptions = {
      [1] = '30% chance on hit to fire a bolt at a nearby enemy for 60% damage'
    }
  },
  [ITEM_SET.REPEAT] = {
    name = 'Repeat',
    summary = 'repeat chance',
    color = 'yellow',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { stats = {['repeat_attack_chance'] = 1.5} },
      [2] = { stats = {['repeat_attack_chance'] = 2} },
    },
    descriptions = {
      [1] = '30% chance to repeat your attacks',
      [2] = '70% chance to repeat your attacks',
    }
  },
  [ITEM_SET.FROST_NOVA] = {
    name = 'Frost Nova',
    summary = 'frost nova',
    color = 'blue',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'frostnova'} }
    },
    descriptions = {
      [1] = 'Pulse a chilling nova when enemies get close (every 5s)'
    }
  },
  [ITEM_SET.ORBITAL] = {
    name = 'Orbit',
    summary = 'damaging orbs',
    color = 'blue',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'orbital'} },
      [2] = { procs = {'orbitalPower'} },
    },
    descriptions = {
      [1] = 'Two damaging orbs rotate around you',
      [2] = 'Orbs are larger and hit harder',
    }
  },
  [ITEM_SET.SHIELD] = {
    name = 'Radiance',
    summary = 'burn aura',
    color = 'red',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'radiance'} },
    },
    descriptions = {
      [1] = 'Enemies near you catch fire',
    }
  },
  [ITEM_SET.METEOR] = {
    name = 'Meteor',
    summary = 'meteors',
    color = 'red',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'meteor'} },
      [2] = { procs = {'meteorSizeBoost', 'meteorDamageBoost'} },
    },
    descriptions = {
      [1] = 'A meteor strikes a nearby enemy every 4s',
      [2] = 'Meteors are larger and deal double damage',
    }
  },
  -- Focus: repeated hits on one target ramp damage. The anti-tank tool.
  [ITEM_SET.FOCUS] = {
    name = 'Focus',
    summary = 'ramping damage',
    color = 'red',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'focus'} },
    },
    descriptions = {
      [1] = 'Each hit on the same enemy deals +6% more, up to +48%; resets after 2s without a hit',
    }
  },
  [ITEM_SET.SPLASH] = {
    name = 'Splash',
    summary = 'attacks splash',
    color = 'brown',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'splash'} },
      [2] = { procs = {'splashSizeBoost'} },
    },
    descriptions = {
      [1] = 'Attacks deal 40% splash damage to nearby enemies',
      [2] = 'Splash covers a 50% larger area',
    }
  },
  [ITEM_SET.MULTI_SHOT] = {
    name = 'Multi-Shot',
    summary = 'extra shots',
    color = 'brown',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'multishot', 'multishotFullDamage'} },
      [2] = { procs = {'extraMultishot'} },
    },
    descriptions = {
      [1] = 'Fire 2 extra shots at an angle for 50% damage',
      [2] = 'Fire 2 more extra shots',
    }
  },
  -- Pierce: projectiles pass through enemies; the laser loses its falloff.
  [ITEM_SET.PIERCE] = {
    name = 'Pierce',
    summary = 'projectiles pierce',
    color = 'brown',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'pierce'} },
      [2] = { procs = {'pierce2'} },
    },
    descriptions = {
      [1] = 'Projectiles pierce 1 extra enemy; lasers lose no damage through enemies',
      [2] = 'Projectiles pierce 3 extra enemies',
    }
  },
  [ITEM_SET.TURRET] = {
    name = 'Garrison',
    summary = 'deploy turrets',
    color = 'brown',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'turret'} },
      [2] = { procs = {'turret3'} },
    },
    descriptions = {
      [1] = 'Deploy a turret every 6s (max 2; replaces the oldest)',
      [2] = 'Deploy up to 4 turrets',
    }
  },
  [ITEM_SET.BLOODLUST] = {
    name = 'Bloodlust',
    summary = '+aspeed on kill',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'bloodlust'} },
      [2] = { procs = {'bloodlustSpeedBoost'} },
    },
    descriptions = {
      [1] = 'Kills grant +8% attack speed for 5s, stacking up to 4 times',
      [2] = 'Bloodlust also grants +5% move speed per stack',
    }
  },
  -- Recoil: hits shove enemies back hard, specials included.
  [ITEM_SET.RECOIL] = {
    name = 'Recoil',
    summary = 'hits knock back',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'recoil'} },
    },
    descriptions = {
      [1] = 'Hits knock enemies back 3x harder, special enemies too',
    }
  },
  [ITEM_SET.RESONANCE] = {
    name = 'Resonance',
    summary = '+%damage per element',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'resonance'} },
    },
    descriptions = {
      [1] = '+15% damage per element afflicting the target (burn/chill/shock)',
    }
  },
  [ITEM_SET.MOBILE] = {
    name = 'Skirmisher',
    summary = 'attack while moving',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'mobilefire'} },
    },
    descriptions = {
      [1] = 'Attack while moving',
    }
  },
  [ITEM_SET.MEND] = {
    name = 'Mend',
    summary = 'heal allies',
    color = 'green',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'chainheal'} },
      [2] = { procs = {'chainhealBoost'} },
    },
    descriptions = {
      [1] = 'Every 5s a healing chain jumps through up to 3 injured allies',
      [2] = 'Heals for double and reaches 5 allies',
    }
  },

  -- ------------------------------------------------------------- disabled
  -- Kept so items from older saves still resolve; never rolled.
  [ITEM_SET.HEFT] = {
    name = 'Heft',
    color = 'red',
    rarity = ITEM_RARITY.COMMON,
    disabled = true,
    bonuses = {
      [1] = { stats = {['flat_dmg'] = 3} },
      [2] = { stats = {['flat_dmg'] = 5} },
      [3] = { stats = {['flat_dmg'] = 8} },
    },
    descriptions = {
      [1] = '+3 flat damage to every hit',
      [2] = '+8 flat damage to every hit',
      [3] = '+16 flat damage to every hit',
    }
  },
  [ITEM_SET.RANGE] = {
    name = 'Reach',
    color = 'brown',
    rarity = ITEM_RARITY.COMMON,
    disabled = true,
    bonuses = {
      [1] = { stats = {['range'] = 1} },
      [2] = { stats = {['range'] = 3} },
      [3] = { stats = {['range'] = 5} },
    },
    descriptions = {
      [1] = '+5% range',
      [2] = '+20% range',
      [3] = '+45% range',
    }
  },
  [ITEM_SET.CURSE] = {
    name = 'Curse',
    summary = 'curse enemies',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    disabled = true,
    bonuses = {
      [1] = { procs = {'curse'} }
    },
    descriptions = {
      [1] = 'Curses nearby enemies, increasing damage taken'
    }
  },
  [ITEM_SET.TREASURY] = {
    name = 'Treasury',
    summary = '+1 gold/round',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    disabled = true,
    bonuses = {
      [1] = { procs = {'treasury'} },
    },
    descriptions = {
      [1] = 'Gain 1 extra gold at the end of each round',
    }
  },
}

-- Rarity definitions
ITEM_RARITIES = {
  [ITEM_RARITY.COMMON] = {
    name = 'Common',
    cost = 2,
    min_stat_value = 1,
    max_stat_value = 2,
    set_chance = 1,
    color = 'grey'
  },
  [ITEM_RARITY.RARE] = {
    name = 'Rare',
    cost = 2,
    min_stat_value = 0,
    max_stat_value = 0,
    set_chance = 1,
    color = 'blue'
  },
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
  local tier = ITEM_LEVEL_TO_TIER(level)

  local rarities = {ITEM_RARITY.COMMON, ITEM_RARITY.RARE}
  local weights = TIER_TO_ITEM_RARITY_WEIGHTS[tier] or TIER_TO_ITEM_RARITY_WEIGHTS[1]

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

-- Helper function to get random set. Pass `rarity` to constrain the pool to
-- sets tagged with that rarity; nil returns any set (legacy). Pass `tier` to
-- exclude sets whose min_tier is above it — lower-tier sets stay in the pool.
-- Pass `exclude_sets` (keyed by set name) to drop specific sets from the pool.
function get_random_set(rarity, tier, exclude_sets)
  local set_keys = {}
  for set_name, set_def in pairs(ITEM_SETS) do
    if not set_def.disabled
      and (not rarity or set_def.rarity == rarity)
      and (not tier or (set_def.min_tier or 1) <= tier)
      and not (exclude_sets and exclude_sets[set_name]) then
      table.insert(set_keys, set_name)
    end
  end
  return random:table(set_keys)
end

-- Collect the 1/1 sets (single-bonus sets where extra copies do nothing)
-- present in a list of items, keyed by set name. Used to keep the same 1/1
-- set from appearing twice in one roll of shop/floor items.
function get_one_piece_sets(items)
  local found = {}
  for _, item in pairs(items or {}) do
    if item and item.sets then
      for _, set_key in ipairs(item.sets) do
        local set_def = ITEM_SETS[set_key]
        if set_def and #set_def.bonuses == 1 then found[set_key] = true end
      end
    end
  end
  return found
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
    local item = create_random_item(level, nil, get_one_piece_sets(items))
    if item then
      table.insert(items, item)
    end
  end
  return items
end


-- Main function to create a random item
function create_random_item(level, exclude_rarity, exclude_sets)
  
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

  local tier = ITEM_LEVEL_TO_TIER(level or 1)

  -- Create the item
  local item = {
    name = ITEM_SLOTS[item_slot].name,
    slot = item_slot,
    rarity = rarity,
    tier = tier,
    icon = ITEM_SLOTS[item_slot].icon,
    stats = {},
    sets = {},
    cost = rarity_def.cost,
    procs = {}, -- Empty procs for compatibility with existing system
    tags = {} -- Empty tags for compatibility with existing system
  }

  -- Items roll at most one set, drawn from the pool matching this item's
  -- rarity (common items get common sets, rare items get rare sets) and tier.
  if random:float(0, 1) < rarity_def.set_chance then
    local candidate = get_random_set(rarity, tier, exclude_sets)
    if candidate then
      table.insert(item.sets, candidate)
    end
  end
  
  -- Items no longer roll flat stats on top of sets; sets are the entire payload.

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

-- ============================================================
-- Team meta color system
-- Items of a given color, totalled across every troop on the
-- team, grant a team-wide stat multiplier at fixed thresholds.
-- Bonus applies to every unit unconditionally.
-- ============================================================
META_COLORS = {'red', 'yellow', 'blue', 'brown', 'purple', 'green'}

META_COLOR_TO_STAT = {
  red    = 'dmg',
  yellow = 'aspd',
  blue   = 'crit_chance',
  brown  = 'area_size',
  purple = 'mvspd',
  green  = 'hp',
}

META_COLOR_LABEL = {
  red    = 'damage',
  yellow = 'attack speed',
  blue   = 'crit',
  brown  = 'area size',
  purple = 'move speed',
  green  = 'hp',
}

META_THRESHOLDS = {
  {count = 3, bonus = 0.10},
  {count = 6, bonus = 0.20},
  {count = 8, bonus = 0.40},
}

function get_team_units()
  if main and main.current and main.current.units then
    return main.current.units
  end
  if buyScreen and buyScreen.units then
    return buyScreen.units
  end
  return {}
end

-- A set counts once per unit: two items carrying the same set on one troop
-- add one, the same set on two troops adds two.
function count_team_meta_colors(units)
  local counts = {}
  for _, color in ipairs(META_COLORS) do counts[color] = 0 end
  if not units then return counts end
  local function add(color)
    if counts[color] ~= nil then counts[color] = counts[color] + 1 end
  end
  for _, u in ipairs(units) do
    if u and u.items then
      local seen = {}
      for _, item in pairs(u.items) do
        if item and item.sets and #item.sets > 0 then
          for _, set_key in ipairs(item.sets) do
            local set_def = ITEM_SETS[set_key]
            if not seen[set_key] and set_def and set_def.color then
              seen[set_key] = true
              add(set_def.color)
            end
          end
        elseif item and item.colors and not seen[item.name] then
          -- Legacy items without set keys: dedupe by name instead.
          seen[item.name] = true
          for _, color in ipairs(item.colors) do add(color) end
        end
      end
    end
  end
  return counts
end

function get_meta_bonus_for_count(count)
  local bonus = 0
  for _, t in ipairs(META_THRESHOLDS) do
    if count >= t.count then bonus = t.bonus end
  end
  return bonus
end

function get_team_meta_stats(units)
  local counts = count_team_meta_colors(units)
  local stats = {}
  for _, color in ipairs(META_COLORS) do
    local bonus = get_meta_bonus_for_count(counts[color])
    if bonus > 0 then
      local stat = META_COLOR_TO_STAT[color]
      stats[stat] = (stats[stat] or 0) + bonus
    end
  end
  return stats
end
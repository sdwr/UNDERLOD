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

-- Item Sets
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
-- tier — earlier tiers stay in the pool (one shared pool for now).
ITEM_SETS = {
  [ITEM_SET.DAMAGE] = {
    name = 'Power',
    summary = '+%damage',
    color = 'red',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['dmg'] = 1} },
      [2] = { stats = {['dmg'] = 3} },
      [3] = { stats = {['dmg'] = 5} },
    },
    descriptions = {
      [1] = '+10% damage',
      [2] = '+30% damage',
      [3] = '+50% damage',
    }
  },
  [ITEM_SET.ASPD] = {
    name = 'Swift',
    color = 'yellow',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['aspd'] = 1} },
      [2] = { stats = {['aspd'] = 3} },
      [3] = { stats = {['aspd'] = 5} },
    },
    descriptions = {
      [1] = '+5% attack speed',
      [2] = '+15% attack speed',
      [3] = '+25% attack speed',
    }
  },
  [ITEM_SET.RANGE] = {
    name = 'Reach',
    color = 'brown',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['range'] = 1} },
      [2] = { stats = {['range'] = 3} },
      [3] = { stats = {['range'] = 5} },
    },
    descriptions = {
      [1] = '+5% range',
      [2] = '+15% range',
      [3] = '+25% range',
    }
  },
  [ITEM_SET.CRIT] = {
    name = 'Precision',
    summary = '+crit chance',
    color = 'blue',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['crit_chance'] = 1} },
      [2] = { stats = {['crit_chance'] = 3} },
      [3] = { stats = {['crit_chance'] = 5} },
    },
    descriptions = {
      [1] = '+10% crit chance',
      [2] = '+30% crit chance',
      [3] = '+50% crit chance',
    }
  },
  [ITEM_SET.COLD] = {
    name = 'Frost',
    summary = '+cold damage',
    color = 'blue',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { stats = {['cold_damage'] = 5} },
      [2] = { stats = {['cold_damage'] = 7} },
      [3] = { stats = {['cold_damage'] = 10} }
    },
    descriptions = {
      [1] = '+5 cold damage per hit; cold attacks slow enemies',
      [2] = '+7 cold damage per hit',
      [3] = '+10 cold damage per hit'
    }
  },
  [ITEM_SET.FROST_NOVA] = {
    name = 'Frost Nova',
    summary = 'frost nova',
    color = 'blue',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { stats = {}, procs = {'frostnova'} }
    },
    descriptions = {
      [1] = 'Creates a frost nova when enemies get close'
    }
  },
  [ITEM_SET.FIRE] = {
    name = 'Inferno',
    summary = '+fire damage',
    color = 'red',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
        [1] = { stats = {['fire_damage'] = 5} },
        [2] = { stats = {['fire_damage'] = 7} },
        [3] = { stats = {['fire_damage'] = 10} }
    },
    descriptions = {
      [1] = '+5 fire damage per hit; fire attacks burn enemies over time',
      [2] = '+7 fire damage per hit',
      [3] = '+10 fire damage per hit'
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
    summary = 'chain lightning',
    color = 'yellow',
    rarity = ITEM_RARITY.COMMON,
    bonuses = {
      [1] = { procs = {'shock'} },
      [2] = { procs = {'shock2'} },
      [3] = { procs = {'shock3'} },
    },
    descriptions = {
      [1] = 'Chance on hit to chain lightning to 3 targets, shocking each',
      [2] = 'Chains to more targets, more often',
      [3] = 'Chains to even more targets, more often',
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
      [1] = 'Chance to create a lightning ball on attack'
    }
  },
  [ITEM_SET.CURSE] = {
    name = 'Curse',
    summary = 'curse enemies',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'curse'} }
    },
    descriptions = {
      [1] = 'Curses nearby enemies, increasing damage taken'
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
    summary = '+aspeed on kill',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
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
    summary = 'attacks splash',
    color = 'brown',
    rarity = ITEM_RARITY.RARE,
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
    summary = 'damage aura',
    color = 'red',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'radiance'} },
      -- [2] = { procs = {'shieldexplode'} },
    },
    descriptions = {
      [1] = 'Grants you a damage aura',
      -- [2] = 'Shield explodes when destroyed, knocking back nearby enemies'
    }
  },
  [ITEM_SET.REPEAT] = {
    name = 'Repeat',
    summary = 'repeat chance',
    color = 'yellow',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
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
    summary = 'extra shots',
    color = 'brown',
    rarity = ITEM_RARITY.RARE,
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
  -- Flat physical damage. Unlike Power (a % multiplier), this raises the
  -- per-hit floor, so it shines on fast/multi-hit units early and naturally
  -- tapers off as % scaling takes over. Cumulative totals: +3 / +8 / +16.
  [ITEM_SET.HEFT] = {
    name = 'Heft',
    color = 'red',
    rarity = ITEM_RARITY.COMMON,
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
  -- Economy: flat +1 gold at the end of each round. 1/1 set - extra copies
  -- do nothing, so one piece anywhere on the team is enough.
  [ITEM_SET.TREASURY] = {
    name = 'Treasury',
    summary = '+1 gold/round',
    color = 'purple',
    rarity = ITEM_RARITY.RARE,
    bonuses = {
      [1] = { procs = {'treasury'} },
    },
    descriptions = {
      [1] = 'Gain 1 extra gold at the end of each round',
    }
  },
  -- Elemental synergy: bonus damage per distinct elemental affliction
  -- (burn/chill/shock) on the target, from any ally. Rewards rainbow
  -- elemental teams. 1/1 set.
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
  -- Orbitals: damaging orbs that rotate around the unit. 3-tier: more orbs,
  -- then bigger/harder-hitting orbs.
  [ITEM_SET.ORBITAL] = {
    name = 'Orbit',
    summary = 'damaging orbs',
    color = 'blue',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'orbital'} },
      [2] = { procs = {'orbitalExtra'} },
      [3] = { procs = {'orbitalPower'} },
    },
    descriptions = {
      [1] = 'A damaging orb rotates around you',
      [2] = 'Gain a second orb',
      [3] = 'Orbs are larger and hit harder',
    }
  },
  -- Support: periodically chain-heals injured allies. 2/2 set, tier 2 makes
  -- the heal stronger and bounce further.
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
      [1] = 'Periodically send a healing chain through injured allies',
      [2] = 'Healing chains are stronger and reach more allies',
    }
  },
  -- Summon: periodically drops a stationary turret that shoots enemies and
  -- can be destroyed. 3-tier raises the active cap to 2/3/4; a new drop past
  -- the cap replaces the oldest turret.
  [ITEM_SET.TURRET] = {
    name = 'Garrison',
    summary = 'deploy turrets',
    color = 'brown',
    rarity = ITEM_RARITY.RARE,
    min_tier = 2,
    bonuses = {
      [1] = { procs = {'turret'} },
      [2] = { procs = {'turret2'} },
      [3] = { procs = {'turret3'} },
    },
    descriptions = {
      [1] = 'Periodically deploy turrets (max 2; replaces the oldest)',
      [2] = 'Deploy up to 3 turrets',
      [3] = 'Deploy up to 4 turrets',
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
    if (not rarity or set_def.rarity == rarity)
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
META_COLORS = {'red', 'yellow', 'blue', 'brown', 'purple'}

META_COLOR_TO_STAT = {
  red    = 'dmg',
  yellow = 'aspd',
  blue   = 'crit_chance',
  brown  = 'range',
  purple = 'mvspd',
}

META_COLOR_LABEL = {
  red    = 'damage',
  yellow = 'attack speed',
  blue   = 'crit',
  brown  = 'range',
  purple = 'move speed',
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

function count_team_meta_colors(units)
  local counts = {red = 0, yellow = 0, blue = 0, brown = 0, purple = 0}
  if not units then return counts end
  for _, u in ipairs(units) do
    if u and u.items then
      for _, item in pairs(u.items) do
        if item and item.colors then
          for _, color in ipairs(item.colors) do
            if counts[color] ~= nil then
              counts[color] = counts[color] + 1
            end
          end
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
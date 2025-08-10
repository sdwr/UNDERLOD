--base stats

--used in the spawn manager
--and also used by procs to know when to start buffs
TIME_TO_ROUND_START = 2
SPAWNS_IN_GROUP = 6
NORMAL_ENEMIES_PER_GROUP = 7
SPAWN_CHECKS = 10

--make enemies more difficult after each boss

ROUND_POWER_TO_GOLD = 100

--stat constants
TROOP_HP = 100
TROOP_DAMAGE = 9
TROOP_MS = 45
-- Legacy constants (will be replaced)
TROOP_BASE_COOLDOWN = 1.1
TROOP_SWORDSMAN_BASE_COOLDOWN = 0.8

-- New troop cooldown system
attack_cooldowns = {
  ['very-fast'] = 0.8,
  ['fast'] = 1.1,
  ['medium'] = 1.5,
  ['slow'] = 2.5,
  ['very-slow'] = 4.0
}

troop_attack_cooldowns = {
  ['archer'] = attack_cooldowns['fast'],
  ['laser'] = attack_cooldowns['fast'], 
  ['swordsman'] = attack_cooldowns['very-fast'],
  ['default'] = attack_cooldowns['fast']
}
-- Enemy type to cooldown mapping (replaces magic numbers)
enemy_attack_cooldowns = {
  -- Regular enemies
  ['goblin_archer'] = attack_cooldowns['fast'],
  ['stomper'] = attack_cooldowns['fast'],
  ['plasma'] = attack_cooldowns['fast'], 
  ['spread'] = attack_cooldowns['fast'],
  ['mortar'] = attack_cooldowns['fast'],
  ['arcspread'] = attack_cooldowns['medium'],
  ['cleaver'] = attack_cooldowns['slow'],
  ['charger'] = attack_cooldowns['slow'],
  ['summoner'] = attack_cooldowns['slow'],
  ['seeker'] = attack_cooldowns['very-slow'],
  
  -- Bosses  
  ['stompy'] = attack_cooldowns['fast'],
  ['dragon'] = attack_cooldowns['fast'],
  ['heigan'] = attack_cooldowns['fast'],
  ['heigan_eruption'] = 8.0, -- Special case for boss abilities
  
  -- Static
  ['dragonegg'] = attack_cooldowns['slow'],
  
  -- Default for any enemy not specified
  ['default'] = attack_cooldowns['medium']
}

-- Simplified cast/cooldown system
cast_times = {
  ['instant'] = 0,
  ['short'] = 0.15,
  ['medium'] = 0.37,
  ['long'] = 0.66,
  ['very-long'] = 1.0
}

troop_cast_times = {
  ['archer'] = cast_times['medium'],
  ['laser'] = cast_times['instant'],
  ['swordsman'] = cast_times['short'],
  ['default'] = cast_times['instant']
}

enemy_cast_times = {
  -- Regular enemies with animations
  ['shooter'] = GOBLIN_CAST_TIME,
  ['turret'] = GOBLIN_CAST_TIME,  
  ['goblin_archer'] = GOBLIN2_CAST_TIME,
  ['big_goblin_archer'] = GOBLIN2_CAST_TIME,
  ['archer'] = GOBLIN2_CAST_TIME,
  ['cleaver'] = SLIME_CAST_TIME,
  ['burst'] = LICH_CAST_TIME,
  ['selfburst'] = ROCKSLIME_CAST_TIME,
  ['singlemortar'] = PLANT2_CAST_TIME,
  ['snakearrow'] = GHOST_CAST_TIME,
  ['boomerang'] = ENT_CAST_TIME,
  
  -- Enemies with instant cast (no animation or simple attacks)
  ['stomper'] = cast_times['instant'],
  ['plasma'] = cast_times['instant'],
  ['spread'] = cast_times['instant'],
  ['mortar'] = cast_times['instant'],
  ['arcspread'] = cast_times['instant'],
  ['charger'] = cast_times['instant'],
  ['summoner'] = cast_times['instant'],
  ['seeker'] = cast_times['instant'],
  ['laser'] = cast_times['instant'],
  ['firewall_caster'] = cast_times['instant'],
  ['line_mortar'] = cast_times['instant'],
  ['aim_spread'] = cast_times['instant'],
  ['slowcharger'] = cast_times['instant'],
  
  -- Bosses with longer cast times
  --stompy has short casts and spell duration that matches the 
  --animation
  ['stompy'] = cast_times['short'],
  --dragon has no animation
  ['dragon'] = cast_times['long'], 
  ['heigan'] = BEHOLDER_CAST_TIME,
  
  -- Static enemies
  ['dragonegg'] = cast_times['instant'],
  
  -- Default for any enemy not specified
  ['default'] = cast_times['instant']
}




TROOP_RANGE = 500
TROOP_SWORDSMAN_RANGE = 80

REGULAR_ENEMY_HP = 20
REGULAR_ENEMY_DAMAGE = 15
REGULAR_ENEMY_MS = 32

SPECIAL_ENEMY_HP = 70
SPECIAL_ENEMY_DAMAGE = 20
SPECIAL_ENEMY_MS = 20

MINIBOSS_HP = 400
MINIBOSS_DAMAGE = 20
MINIBOSS_MS = 50

BOSS_HP = 1400
BOSS_DAMAGE = 20
BOSS_MS = 70

REGULAR_PUSH_DAMAGE = 20
SPECIAL_PUSH_DAMAGE = 20
BOSS_PUSH_DAMAGE = 20

STUN_DURATION_CRITTER = 2.5
STUN_DURATION_REGULAR_ENEMY = 2.5
STUN_DURATION_SPECIAL_ENEMY = 1.5
STUN_DURATION_MINIBOSS = 1
STUN_DURATION_BOSS = 0.4

STUN_COOLDOWN = 5

INITIAL_ENEMY_IDLE_TIME = 0.5


--proc constants
MAX_STACKS_FIRE = 5
MAX_STACKS_SLOW = 5
MAX_STACKS_SHOCK = 10
MAX_STACKS_REDSHIELD = 20

SHIELD_EXPLOSION_RADIUS = 50
SHIELD_EXPLOSION_DURATION = 0.25

MAX_STACKS_BLOODLUST = 5
MAX_STACKS_BLOODLUST_WITH_BOOST = 10
BLOODLUST_ASPD_BOOST_PER_STACK = 0.08
BLOODLUST_SPEED_BOOST_PER_STACK = 0.05

CURSE_HEAL_PERCENT_OF_DAMAGE_TAKEN = 0.08
CURSE_DAMAGE_LINK_DAMAGE_PERCENT = 1.0
CURSE_DAMAGE_LINK_RADIUS = 150

BASE_CRIT_MULT = 2

SHOCK_DEF_REDUCTION = -0.2

REPEAT_ATTACK_DELAY = 0.15

BOSS_LEVELS = {6, 11, 16, 21}

LEVELS_AFTER_BOSS_LEVEL = function(level)
  local last_boss_level = GET_LAST_BOSS_LEVEL(level)
  return level - last_boss_level
end

GET_LAST_BOSS_LEVEL = function(level)
  --find the boss level before this one
  local last_boss_level = 0
  for _, boss_level in pairs(BOSS_LEVELS) do
    if level <= boss_level then
      break
    else
      last_boss_level = boss_level
    end
  end
  return last_boss_level
end

LEVEL_TO_TIER = function(level)
  local tier = 1
  if level <= 5 then
    tier = 1
  elseif level <= 10 then
    tier = 1.5
  elseif level <= 15 then
    tier = 2
  else
    tier = 2.5
  end
  return tier
end

TIER_TO_ITEM_RARITY_WEIGHTS = {
  [1] = {0.7, 0.3, 0, 0},
  [1.5] = {0.35, 0.5, 0.15, 0},
  [2] = {0.2, 0.4, 0.3, 0.1},
  [2.5] = {0, 0.25, 0.5, 0.25},
}

CHANCE_OF_SPECIAL_VS_NORMAL_ENEMY = 0.7

get_num_special_enemies_by_level = function(level)
  if level == 1 then return 0 end
  if level == 2 then return 1 end
  if level == 3 then return 2 end
  if level == 4 then return 2 end
  if level == 5 then return 3 end

  local num_special_enemies_by_level = {
    [1] = 4,
    [2] = 4,
    [3] = 5,
    [4] = 5,
    [5] = 5,
    ['default'] = 5,
  }

  local adjusted_level = LEVELS_AFTER_BOSS_LEVEL(level)
  return num_special_enemies_by_level[adjusted_level] 
  or num_special_enemies_by_level['default']
end

load_special_swarmer_data = function(swarmer)
  local data = SPECIAL_SWARMER_DATA[swarmer.special_swarmer_type]
  if not data then
    return
  end

  for k, v in pairs(data) do
    swarmer[k] = v
  end

end

SPECIAL_SWARMER_TYPES = {
  'exploder',
  'poison',
  'exploder',
  'poison',
  'exploder',
  'poison',
}

SPECIAL_SWARMER_DATA = {
  ['exploder'] = {
    radius = 25,
    duration = 0.1,
    num_pieces = 10,
    secondary_speed = 70,
    secondary_distance = 200,
  },
  ['poison'] = {
    radius = 30,
    duration = 8,
    tick_rate = 0.5,
    damage_multi = 0.25,
  },
}


SPECIAL_SWARMER_WEIGHT_BY_TYPE = {
  [1] = {0},
  [2] = {4, 2},
  [3] = {5},
  [4] = {4, 4},
  [5] = {4, 3, 2},
  [6] = {12},
  [7] = {5, 3, 2},
  [8] = {6, 3, 3, 3},
  [9] = {14},
  [10] = {8, 4},
  [11] = {8, 6, 2},
  [12] = {16},
  [13] = {8, 8},
  [14] = {12, 6},
  [15] = {18},
  [16] = {10, 6, 4},
  [17] = {6, 5, 4, 3},
  [18] = {18},
  [19] = {10, 6},
  [20] = {8, 6, 2},
  [21] = {22},
  [22] = {10, 8, 4},
  [23] = {20, 5, 5},
  [24] = {30},
  [25] = {5, 5, 5, 5, 5, 5},
}



ROUND_POWER_BY_LEVEL = {
  [1] = 400,
  [2] = 600,
  [3] = 800,
  [4] = 1100,
  [5] = 1300,
  [6] = 1500,
  [7] = 1700,
  [8] = 1900,
  [9] = 2100,
  [10] = 2300,
  [11] = 2500,
  [12] = 2700,
  [13] = 1500,
  [14] = 1600,
  [15] = 1700,
  [16] = 1800,
  [17] = 1900,
  [18] = 2000,
  [19] = 2100,
  [20] = 2200,
  [21] = 2300,
  [22] = 2400,
  [23] = 2800,
  [24] = 2900,
  [25] = 3000,
}

GOLD_GAINED_BY_LEVEL = {
  [1] = 4,
  [2] = 4,
  [3] = 4,
  [4] = 4,
  [5] = 4,
  [6] = 6,
  [7] = 6,
  [8] = 6,
  [9] = 6,
  [10] = 6,
  [11] = 8,
  [12] = 8,
  [13] = 8,
  [14] = 8,
  [15] = 8,
  [16] = 8,
  [17] = 8,
  [18] = 8,
  [19] = 8,
  [20] = 10,
  [21] = 10,
  [22] = 10,
  [23] = 10,
  [24] = 10,
  [25] = 10,
}

MAX_NORMAL_ENEMY_GROUP_SIZE_BY_TIER = {
  [1] = 3,
  [1.5] = 5,
  [2] = 8,
  [2.5] = 10,
}

MAX_SWARMER_GROUP_SIZE_BY_TIER = {
  [1] = 10,
  [1.5] = 14,
  [2] = 18,
  [2.5] = 22,
}

MAX_SPECIAL_ENEMY_GROUP_SIZE_BY_TIER = {
  [1] = 1,
  [1.5] = 2,
  [2] = 3,
  [2.5] = 4,
}

ENEMY_SCALE_BY_LEVEL = 
{0, 1, 2, 2, 3, 4, 
 5, 6, 7, 8, 9, 10, 
 11, 12, 13, 14, 15, 16, 17, 
 18, 19, 20, 21, 22, 23, 24}

ENEMY_LEVEL_SCALING = function(level)
  local scale = ENEMY_SCALE_BY_LEVEL[level] or 0
  return scale
end

SCALED_ENEMY_HP = function(level, base_hp)
  local scale = ENEMY_SCALE_BY_LEVEL[level]
  return base_hp + (base_hp * 0.2 * scale)
end

SCALED_ENEMY_DAMAGE = function(level, base_dmg)
  local scale = ENEMY_SCALE_BY_LEVEL[level]
  return base_dmg + (base_dmg * 0.1 * scale)
end

SCALED_ENEMY_MS = function(level, base_ms)
  local scale = ENEMY_SCALE_BY_LEVEL[level]
  return base_ms + (base_ms * 0.03 * scale)
end

function SWARMERS_PER_LEVEL(level)
  return math.min(30, 15 + level)
end

function SPECIAL_ENEMIES_PER_LEVEL(level)
  if level == 1 then return 1 end
  if level == 2 then return 1 end

  if level <= 6 then
    return 2
  end

  return 3
end

function WAVES_PER_LEVEL(level)
  return 1
end

function IS_SPECIAL_WAVE(level, wave)
  if level == 4 then return wave == 3 end
  if level == 9 then return wave == 4 end
  if level == 14 then return wave == 5 end
  if level == 19 then return wave == 6 end
  
end



BOSS_SCALE_BY_LEVEL = 
{0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 1,
 0, 0, 0, 0, 0, 0, 0, 2,
 0, 0, 0, 0, 0, 0, 4}

SCALED_BOSS_HP = function(level, base_hp)
  local scale = BOSS_SCALE_BY_LEVEL[level]
  return base_hp + (base_hp * 0.8 * scale)
end

SCALED_BOSS_DAMAGE = function(level, base_dmg)
  local scale = BOSS_SCALE_BY_LEVEL[level]
  return base_dmg + (base_dmg * 0.2 * scale)
end

SCALED_BOSS_MS = function(level, base_ms)
  local scale = BOSS_SCALE_BY_LEVEL[level]
  return base_ms + (base_ms * 0.05 * scale)
end

--also want stat scaling per zone
ZONE_SCALING = function(level)
  -- local zone = LEVEL_TO_TIER(level)
  -- return 1 + (zone * ENEMY_SCALING_PER_ZONE - 1)
  return 1
end

DISTANCE_TO_COOLDOWN_MULTIPLIER = function(distance)
  local mult_values = {
    [0] = 0.24,
    [20] = 0.27,
    [50] = 0.4,
    [75] = 0.6,
    [100] = 0.85,
    [150] = 1.05,
    [200] = 1.25,
    [250] = 1.4,
  }

  if distance < 0 then
    return mult_values[0]
  end

  local p1, p2
  local prev
  for dist, mult in pairs(mult_values) do
    if distance <= dist then
      p1 = prev
      p2 = dist
      break
    end
    prev = dist
  end

  if not p2 then
    return mult_values[#mult_values]
  end

  local scale = (distance - p1) / (p2 - p1)
  return mult_values[p1] + (mult_values[p2] - mult_values[p1]) * scale
end


-- unit stats
unit_classes = {
    ['player'] = 'player',
    ['critter'] = 'critter',
    ['regular_enemy'] = 'regular_enemy',
    ['special_enemy'] = 'special_enemy',
    ['boss'] = 'boss',
}

unit_stat_multipliers = {
    ['swordsman'] = { hp = 1.5, dmg = 1.25, def = 1.25, mvspd = 1 },
    ['laser'] = { hp = 1, aspd = 1, dmg = 1, def = 1, mvspd = 1 },
    ['archer'] = { hp = 1.25, dmg = 1.5, def = 1, mvspd = 1 },

    ['none'] = { hp = 1, dmg = 1, def = 1, mvspd = 1 },
}

enemy_type_to_stats = {
    ['swarmer'] = { dmg = 0.5, hp = 0.6, mvspd = 0.7},

    ['seeker'] = { dmg = 0.25, mvspd = 0.7 },
    ['chaser'] = { dmg = 1, mvspd = 1 },
    ['shooter'] = {},
    
    ['cleaver'] = {  },
    ['big_goblin_archer'] = {  },
    ['goblin_archer'] = {mvspd = 2.5 },
    ['archer'] = {  },
    ['turret'] = {  },

    ['arcspread'] = {  },
    ['assassin'] = {},
    ['laser'] = {},
    ['mortar'] = {  },
    ['rager'] = {  },
    ['spawner'] = {},
    ['stomper'] = {  },
    ['charger'] = {  },
    ['summoner'] = {},
    ['bomb'] = { hp = -0.25 },
    ['firewall_caster'] = {  },
}

-- general values
attack_ranges = {
    ['melee'] = 50,
    ['medium'] = 60,
    ['medium-plus'] = 70,
    ['medium-long'] = 110,
    ['ranged'] = 130,
    ['long'] = 150,
    ['ultra-long'] = 250,
    ['big-archer'] = 500,

    ['whole-map'] = 999,
  }

attack_speeds = {
  ['short-cast'] = 0.15,
  ['medium-cast'] = 0.37,
  ['long-cast'] = 0.66,
  ['ultra-long-cast'] = 1,

  ['buff'] = 0.66,
  ['quick'] = 0.8,
  ['ultra-fast'] = 1,
  ['fast'] = 1.35,
  ['medium-fast'] = 1.75,
  ['medium'] = 2.5,
  ['medium-slow'] = 3.5,
  ['slow'] = 5,
  ['ultra-slow'] = 8
}

move_speeds = {
    ['ultra-fast'] = 2.5,
    ['fast'] = 1.7,
    ['medium'] = 1.4,
    ['regular'] = 1,
  }

unit_size = {
    ['small'] = 4,
    ['medium'] = 8,
    ['medium-plus'] = 10,
    ['large'] = 14,
  }

buff_types = {
    ['dmg'] = 'dmg',
    ['aspd'] = 'aspd',
    ['flat_def'] = 'flat_def',
    ['percent_def'] = 'percent_def',
    ['mvspd'] = 'mvspd',
    ['area_size'] = 'area_size',
    ['hp'] = 'hp',
    ['status_resist'] = 'status_resist',
    ['range'] = 'range',

    ['shield'] = 'shield',

    ['eledmg'] = 'eledmg',
    ['elevamp'] = 'elevamp',
    ['vamp'] = 'vamp',

    ['fire_damage'] = 'fire_damage',
    ['lightning_damage'] = 'lightning_damage',
    ['cold_damage'] = 'cold_damage',
    ['fire_damage_m'] = 'fire_damage_m',
    ['lightning_damage_m'] = 'lightning_damage_m',
    ['cold_damage_m'] = 'cold_damage_m', 

    ['ghost'] = 'ghost',
    ['slow'] = 'slow',
    ['bash'] = 'bash',
    ['heal'] = 'heal',
    ['explode'] = 'explode',

    ['repeat_attack_chance'] = 'repeat_attack_chance',
    ['crit_chance'] = 'crit_chance',
    ['crit_mult'] = 'crit_mult',
    ['stun_chance'] = 'stun_chance',
    ['knockback_resistance'] = 'knockback_resistance',
    ['cooldown_reduction'] = 'cooldown_reduction',
    ['slow_per_element'] = 'slow_per_element',
  }

-- Elemental affliction buff names
elemental_affliction_buffs = {
    'burn',    -- Fire affliction
    'shock',   -- Lightning affliction  
    'chill',   -- Cold affliction
}

-- unit stat functions


_set_unit_base_stats = function(unit)
    
    
    -- error out if unit is not a valid object
    if not unit then
        error('unit is nil')
    end
    
    local level = unit.level or 1
    unit.shielded = 0

    --init base stats
    if unit:is(Player) then
      -- only for intro screen, actual units are is_troop
        unit.base_hp = 100
        unit.baseline_hp = unit.base_hp
        
        unit.base_dmg = 10
        unit.base_mvspd = 50
    elseif unit:is(EnemyCritter) or unit:is(Critter) then
        unit.base_hp = 25
        unit.baseline_hp = unit.base_hp

        unit.base_dmg = 5
        unit.base_mvspd = REGULAR_ENEMY_MS
    elseif unit.is_troop then
        unit.base_hp = TROOP_HP
        unit.baseline_hp = unit.base_hp

        unit.base_dmg = TROOP_DAMAGE
        unit.base_mvspd = TROOP_MS
    elseif unit.class == 'regular_enemy' then
        unit.base_hp = SCALED_ENEMY_HP(level, REGULAR_ENEMY_HP)
        unit.base_dmg = SCALED_ENEMY_DAMAGE(level, REGULAR_ENEMY_DAMAGE)
        unit.base_mvspd = SCALED_ENEMY_MS(level, REGULAR_ENEMY_MS)

        --store baseline for burn max hp calculation
        unit.baseline_hp = unit.base_hp
        
    elseif unit.class == 'special_enemy' then
        unit.base_hp = SCALED_ENEMY_HP(level, SPECIAL_ENEMY_HP)
        unit.base_dmg = SCALED_ENEMY_DAMAGE(level, SPECIAL_ENEMY_DAMAGE)
        unit.base_mvspd = SCALED_ENEMY_MS(level, SPECIAL_ENEMY_MS)
        
        unit.baseline_hp = unit.base_hp

    elseif unit.class == 'miniboss' then
        unit.base_hp = SCALED_ENEMY_HP(level, MINIBOSS_HP)
        unit.base_dmg = SCALED_ENEMY_DAMAGE(level, MINIBOSS_DAMAGE)
        unit.base_mvspd = SCALED_ENEMY_MS(level, MINIBOSS_MS)
        
        unit.baseline_hp = unit.base_hp
        
    elseif unit.class == 'boss' then
        unit.base_hp = SCALED_BOSS_HP(level, BOSS_HP)
        unit.base_dmg = SCALED_BOSS_DAMAGE(level, BOSS_DAMAGE)
        unit.base_mvspd = SCALED_BOSS_MS(level, BOSS_MS)

        unit.baseline_hp = unit.base_hp
    end

    unit.stun_cooldown = 0
end

_set_unit_item_config = function(unit)

  --for enemies
  if not unit.items then
    unit.items = {}
  end

  unit.perks = main.current.perks or {}
  
  --add per-attack procs from items here
  unit.procs = {}

  unit.onTickProcs = {}
  unit.onHitProcs = {}
  unit.onAttackProcs = {}
  unit.onPrimaryHitProcs = {}
  unit.onGotHitProcs = {}
  unit.onKillProcs = {}
  unit.onDeathProcs = {}
  unit.onMoveProcs = {}
  unit.onRoundStartProcs = {}
  unit.staticProcs = {}
end 
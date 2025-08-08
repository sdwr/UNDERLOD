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
TROOP_DAMAGE = 13
TROOP_MS = 45
TROOP_BASE_COOLDOWN = 1.1
TROOP_SWORDSMAN_BASE_COOLDOWN = 0.8

TROOP_RANGE = 500
TROOP_SWORDSMAN_RANGE = 80

REGULAR_ENEMY_HP = 25
REGULAR_ENEMY_DAMAGE = 15
REGULAR_ENEMY_MS = 32

SPECIAL_ENEMY_HP = 70
SPECIAL_ENEMY_DAMAGE = 35
SPECIAL_ENEMY_MS = 25

MINIBOSS_HP = 400
MINIBOSS_DAMAGE = 20
MINIBOSS_MS = 50

BOSS_HP = 700
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
  [1.5] = {0.47, 0.33, 0.2},
  [2] = {0.2, 0.4, 0.3, 0.1},
  [2.5] = {0, 0.25, 0.5, 0.25},
}

CHANCE_OF_SPECIAL_VS_NORMAL_ENEMY = 0.7

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
  return base_dmg + (base_dmg * 0.3 * scale)
end

SCALED_ENEMY_MS = function(level, base_ms)
  local scale = ENEMY_SCALE_BY_LEVEL[level]
  return base_ms + (base_ms * 0.03 * scale)
end

function SWARMERS_PER_LEVEL(level)
  return 5 + math.floor(level / 3)
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

  if level <= 6 then
    return 3
  elseif level <= 11 then
    return 4
  elseif level <= 16 then
    return 4
  elseif level <= 21 then
    return 5
  end

  return 5
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
    ['swarmer'] = { dmg = 0.5, hp = 1},

    ['seeker'] = { dmg = 0.25, mvspd = 0.7 },
    ['chaser'] = { dmg = 1, mvspd = 1 },
    ['shooter'] = {},
    
    ['cleaver'] = { dmg = 1.5 },
    ['big_goblin_archer'] = { dmg = 1.5 },
    ['goblin_archer'] = { dmg = 1.5 },
    ['archer'] = { dmg = 1.3 },
    ['turret'] = { dmg = 1.2 },

    ['arcspread'] = { dmg = 0.5 },
    ['assassin'] = {},
    ['laser'] = {},
    ['mortar'] = { dmg = 1.5 },
    ['rager'] = { dmg = 0.5 },
    ['spawner'] = {},
    ['stomper'] = { dmg = 2.5 },
    ['charger'] = { dmg = 1.5, mvspd  = 0.5 },
    ['summoner'] = {},
    ['bomb'] = { hp = -0.25 },
    ['firewall_caster'] = { dmg = 1.5 },
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

    unit.baseCooldown = unit.baseCooldown or attack_speeds['medium']
    unit.baseCast = unit.baseCast or attack_speeds['medium-cast']
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
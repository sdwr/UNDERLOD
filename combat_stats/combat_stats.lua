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
TROOP_MS = 70
TROOP_BASE_COOLDOWN = 1.1
TROOP_SWORDSMAN_BASE_COOLDOWN = 0.8

TROOP_RANGE = 100
TROOP_SWORDSMAN_RANGE = 50


REGULAR_ENEMY_HP = 60
REGULAR_ENEMY_DAMAGE = 10
REGULAR_ENEMY_MS = 40

SPECIAL_ENEMY_HP = 75
SPECIAL_ENEMY_DAMAGE = 15
SPECIAL_ENEMY_MS = 50

MINIBOSS_HP = 1000
MINIBOSS_DAMAGE = 20
MINIBOSS_MS = 50

BOSS_HP = 2200
BOSS_DAMAGE = 20
BOSS_MS = 70

REGULAR_PUSH_DAMAGE = 10
SPECIAL_PUSH_DAMAGE = 20
BOSS_PUSH_DAMAGE = 30

STUN_DURATION_CRITTER = 2.5
STUN_DURATION_REGULAR_ENEMY = 2.5
STUN_DURATION_SPECIAL_ENEMY = 1.5
STUN_DURATION_MINIBOSS = 1
STUN_DURATION_BOSS = 0.4

STUN_COOLDOWN = 5

INITIAL_ENEMY_IDLE_TIME = 1


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
ENEMY_SCALING_PER_LEVEL = 0.15
ENEMY_SCALING_PER_ZONE = 1


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

CHANCE_OF_SPECIAL_VS_NORMAL_ENEMY = 0.6

ROUND_POWER_BY_LEVEL = {
  [1] = 500,
  [2] = 800,
  [3] = 1000,
  [4] = 1100,
  [5] = 1200,
  [6] = 1300,
  [7] = 1400,
  [8] = 1600,
  [9] = 2000,
  [10] = 2500,
  [11] = 3000,
  [12] = 3500,
  [13] = 4000,
  [14] = 4500,
  [15] = 5000,
  [16] = 5500,
  [17] = 6000,
  [18] = 6500,
  [19] = 7000,
  [20] = 7500,
  [21] = 8000,
  [22] = 8500,
  [23] = 9000,
  [24] = 9500,
  [25] = 10000,
}

MAX_NORMAL_ENEMY_GROUP_SIZE_BY_TIER = {
  [1] = 3,
  [1.5] = 5,
  [2] = 8,
  [2.5] = 10,
}

MAX_SWARMER_GROUP_SIZE_BY_TIER = {
  [1] = 6,
  [1.5] = 8,
  [2] = 10,
  [2.5] = 12,
}

MAX_SPECIAL_ENEMY_GROUP_SIZE_BY_TIER = {
  [1] = 2,
  [1.5] = 3,
  [2] = 4,
  [2.5] = 5,
}

ENEMY_SCALE_BY_LEVEL = 
{2, 2, 3, 4, 5, 6, 
 5, 6, 9, 7, 8, 12, 
 10, 11, 15, 12, 13, 18, 16, 
 17, 21, 17, 20, 24, 25}

ENEMY_LEVEL_SCALING = function(level)
  local scale = ENEMY_SCALE_BY_LEVEL[level] or 30
  return scale
end

SCALED_ENEMY_HP = function(level, base_hp)
  local scale = ENEMY_SCALE_BY_LEVEL[level]
  return base_hp + (base_hp * 0.5 * scale)
end

SCALED_ENEMY_DAMAGE = function(level, base_dmg)
  local scale = ENEMY_SCALE_BY_LEVEL[level]
  return base_dmg + (base_dmg * 0.3 * scale)
end

SCALED_ENEMY_MS = function(level, base_ms)
  local scale = ENEMY_SCALE_BY_LEVEL[level]
  return base_ms + (base_ms * 0.05 * scale)
end

BOSS_SCALE_BY_LEVEL = 
{0, 0, 0, 0, 0, 2,
 0, 0, 0, 0, 0, 4,
 0, 0, 0, 0, 0, 0, 0, 6,
 0, 0, 0, 0, 0, 0, 8}

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
    ['swarmer'] = { dmg = 0.5, mvspd = 0.6, hp = 0.4},

    ['seeker'] = { dmg = 0.25, mvspd = 0.7 },
    ['chaser'] = { dmg = 1, mvspd = 1 },
    ['shooter'] = {},
    
    ['cleaver'] = { dmg = 1.5 },
    ['big_goblin_archer'] = { dmg = 1.5, mvspd = 3 },
    ['goblin_archer'] = { dmg = 1.5, mvspd = 3 },
    ['archer'] = { dmg = 1.8, mvspd = 2.5 },
    ['turret'] = { dmg = 1.2 },

    ['arcspread'] = { dmg = 0.5 },
    ['assassin'] = {},
    ['laser'] = {},
    ['mortar'] = { dmg = 1.5 },
    ['rager'] = { dmg = 0.5, mvspd = 2 },
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

-- round stats

level_to_round_power = {
    [1] = 100,
    [2] = 300,    -- Base round
    [3] = 450,    -- 1.5x base of 300
    [4] = 600,    -- 2x base of 300
    [5] = 800,    -- Next round base
    [6] = 1200,   -- 1.5x base of 800
    [7] = 1600,   -- 2x base of 800
    [8] = 2000,   -- Next round base
    [9] = 3000,   -- 1.5x base of 2000
    [10] = 4000,  -- 2x base of 2000
    [11] = 5000,  -- Next round base
    [12] = 7500,  -- 1.5x base of 5000
    [13] = 10000, -- 2x base of 5000
    [14] = 11000, -- Next round base
    [15] = 16500, -- 1.5x base of 11000
    [16] = 22000, -- 2x base of 11000
    [17] = 20000, -- Next round base
    [18] = 30000, -- 1.5x base of 20000
    [19] = 40000, -- 2x base of 20000
    [20] = 35000, -- Next round base
    [21] = 52500, -- 1.5x base of 35000
    [22] = 70000, -- 2x base of 35000
    [23] = 50000, -- Next round base
    [24] = 75000, -- 1.5x base of 50000
    [25] = 100000 -- 2x base of 50000
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
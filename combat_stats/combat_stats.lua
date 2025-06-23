--base stats

--used in the spawn manager
--and also used by procs to know when to start buffs
TIME_TO_ROUND_START = 2
SPAWNS_IN_GROUP = 6
NORMAL_ENEMIES_PER_GROUP = 6
SPAWN_CHECKS = 10

--make enemies more difficult after each boss


--stat constants
TROOP_HP = 100
TROOP_DAMAGE = 10
TROOP_MS = 50


REGULAR_ENEMY_HP = 70
REGULAR_ENEMY_DAMAGE = 10
REGULAR_ENEMY_MS = 30

SPECIAL_ENEMY_HP = 300
SPECIAL_ENEMY_DAMAGE = 20
SPECIAL_ENEMY_MS = 25

BOSS_HP = 1200
BOSS_DAMAGE = 10
BOSS_MS = 70

REGULAR_PUSH_DAMAGE = 10
SPECIAL_PUSH_DAMAGE = 20

--proc constants
MAX_STACKS_FIRE = 5
MAX_STACKS_SLOW = 5
MAX_STACKS_SHOCK = 10
MAX_STACKS_REDSHIELD = 20
MAX_STACKS_BLOODLUST = 10

SHOCK_DEF_REDUCTION = -0.2

REPEAT_ATTACK_DELAY = 0.7

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

--stat scaling per level in each zone
REGULAR_ENEMY_SCALING = function(level)
  local last_boss_level = GET_LAST_BOSS_LEVEL(level)
  local boss_level_diff = level - last_boss_level
  
  --want enemies up to 75% stronger than the first level of the area
  return 1 + (boss_level_diff * ENEMY_SCALING_PER_LEVEL)
end

SPECIAL_ENEMY_SCALING = function(level)
  local last_boss_level = GET_LAST_BOSS_LEVEL(level)
  local boss_level_diff = level - last_boss_level
  
  --want enemies up to 75% stronger than the first level of the area
  return 1 + (boss_level_diff * ENEMY_SCALING_PER_LEVEL)
end

--also want stat scaling per zone
ZONE_SCALING = function(level)
  local zone = LEVEL_TO_TIER(level)
  return 1 + (zone * ENEMY_SCALING_PER_ZONE - 1)
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

    ['seeker'] = { dmg = 0.25, mvspd = 0.8 },
    ['shooter'] = {},

    ['cleaver'] = { dmg = 1.5 },

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
    ['medium-long'] = 110,
    ['ranged'] = 130,
    ['long'] = 150,
    ['ultra-long'] = 250,

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
    ['flat_def'] = 'flat defence',
    ['percent_def'] = 'percent defence',
    ['mvspd'] = 'mvspd',
    ['area_dmg'] = 'area_dmg',
    ['area_size'] = 'area_size',
    ['hp'] = 'hp',
    ['status_resist'] = 'status_resist',
    ['range'] = 'range',

    ['shield'] = 'shield',

    ['eledmg'] = 'eledmg',
    ['elevamp'] = 'elevamp',
    ['vamp'] = 'vamp',

    ['ghost'] = 'ghost',
    ['slow'] = 'slow',
    ['bash'] = 'bash',
    ['heal'] = 'heal',
    ['explode'] = 'explode',
    ['repeat_attack_chance'] = 'repeat_attack_chance',
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
        unit.base_hp = unit.base_hp or REGULAR_ENEMY_HP
        unit.base_dmg = unit.base_dmg or REGULAR_ENEMY_DAMAGE
        unit.base_mvspd = unit.base_mvspd or REGULAR_ENEMY_MS

        --store baseline for burn max hp calculation
        unit.baseline_hp = unit.base_hp

        unit.base_hp = unit.base_hp * REGULAR_ENEMY_SCALING(level) * ZONE_SCALING(level)
        unit.base_dmg = unit.base_dmg  * REGULAR_ENEMY_SCALING(level) * ZONE_SCALING(level)
        unit.base_mvspd = unit.base_mvspd
    elseif unit.class == 'special_enemy' then

        unit.base_hp = SPECIAL_ENEMY_HP
        unit.baseline_hp = unit.base_hp

        unit.base_hp = unit.base_hp * SPECIAL_ENEMY_SCALING(level) * ZONE_SCALING(level)
        unit.base_dmg = SPECIAL_ENEMY_DAMAGE  * SPECIAL_ENEMY_SCALING(level) * ZONE_SCALING(level)
        unit.base_mvspd = SPECIAL_ENEMY_MS
    elseif unit.class == 'miniboss' then
        unit.base_hp = 1000
        unit.baseline_hp = unit.base_hp

        unit.base_hp = unit.base_hp * SPECIAL_ENEMY_SCALING(level) * ZONE_SCALING(level)
        unit.base_dmg = unit.base_dmg  * SPECIAL_ENEMY_SCALING(level) * ZONE_SCALING(level)
        unit.base_mvspd = 55
    elseif unit.class == 'boss' then
        unit.base_hp = BOSS_HP
        unit.baseline_hp = unit.base_hp

        unit.base_hp = unit.base_hp * ZONE_SCALING(level)
        unit.base_dmg = BOSS_DAMAGE
        unit.base_mvspd = BOSS_MS
    end

    unit.baseCooldown = unit.baseCooldown or attack_speeds['medium']
    unit.baseCast = unit.baseCast or attack_speeds['medium-cast']
end

_set_unit_item_config = function(unit)

  --for enemies
  if not unit.items then
    unit.items = {}
  end

  --add per-attack procs from items here
  unit.procs = {}

  unit.onTickProcs = {}
  unit.onHitProcs = {}
  unit.onAttackProcs = {}
  unit.onGotHitProcs = {}
  unit.onKillProcs = {}
  unit.onDeathProcs = {}
  unit.onMoveProcs = {}
  unit.onRoundStartProcs = {}
end 
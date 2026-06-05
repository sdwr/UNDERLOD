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
TROOP_DAMAGE = 11
-- Troop base movement speed. Bumped 45 -> 65: at 45 the follow command and
-- rally-to-center felt sluggish; 65 reads as "moving with intent" without
-- being twitchy.
TROOP_MS = 55
-- Legacy constants (will be replaced)
TROOP_BASE_COOLDOWN = 1.25
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
  -- SC2 Marine attack period feel (~0.45s on Faster speed).
  ['archer'] = 0.45,
  -- Laser is a global-range piercing beam, so it's paced out with a 'slow'
  -- cooldown to make each shot a deliberate choice instead of spam.
  ['laser'] = attack_cooldowns['slow'],
  ['swordsman'] = attack_cooldowns['very-fast'],
  -- Sword has +50% cooldown vs 'fast' to compensate for the AoE cone hit.
  ['sword'] = attack_cooldowns['fast'] * 1.5,
  -- Shotgun fires 5 pellets per swing, so the cooldown is one step slower
  -- ('medium' = 1.5s) to keep its burst DPS in line with the other ranged units.
  ['shotgun'] = attack_cooldowns['medium'],
  ['default'] = attack_cooldowns['fast']
}
-- Enemy type to cooldown mapping (replaces magic numbers)
enemy_attack_cooldowns = {
  -- Regular enemies
  ['roach'] = attack_cooldowns['very-fast'] * 1.4 * 1.2,
  ['orb'] = attack_cooldowns['very-slow'],
  ['goblin_archer'] = attack_cooldowns['fast'],
  ['stomper'] = attack_cooldowns['fast'],
  ['plasma'] = attack_cooldowns['fast'],
  ['spread'] = attack_cooldowns['fast'],
  -- Mortar's heavy lob is hard to dodge when it spams; +1.5s on top of
  -- 'fast' (1.1s) gives the player a real beat between shells.
  ['mortar'] = attack_cooldowns['fast'] + 1.5,
  ['arcspread'] = attack_cooldowns['medium'],
  ['cleaver'] = attack_cooldowns['slow'],
  ['charger'] = attack_cooldowns['slow'],
  ['summoner'] = attack_cooldowns['slow'],
  ['seeker'] = attack_cooldowns['very-slow'],
  -- Slime pauses ~6s between 8-way pulses so the player has time to leave the
  -- previous pulse's danger zone before the next windup.
  ['slime'] = 6.0,

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
  -- Archer cast time set explicitly to 0.05s (below 'short' 0.15s) so the
  -- arrow leaves the unit almost instantly after target acquisition.
  ['archer'] = 0.05,
  ['laser'] = cast_times['instant'],
  ['swordsman'] = cast_times['short'],
  ['sword'] = cast_times['short'],
  ['shotgun'] = cast_times['short'],
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
  ['roach'] = 0.6,
  ['sniper'] = 3.25,
  ['orb'] = 0.8,
  -- Visible windup before slime pulse fires so the player can read it.
  ['slime'] = 0.5,
  
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




TROOP_RANGE = 400
TROOP_SWORDSMAN_RANGE = 80
TROOP_SWORD_WEAPON_RANGE = 50
-- Shotgun: much shorter than archer (500). Pellets actually fly to
-- TROOP_SHOTGUN_RANGE * 1.3 before disappearing, so there's a small
-- ribbon of "stray hit" range past the engage distance.
TROOP_SHOTGUN_RANGE = 60
TROOP_ARCHER_RANGE = 75

REGULAR_ENEMY_HP = 45
REGULAR_ENEMY_DAMAGE = 15
REGULAR_ENEMY_MS = 20

SPECIAL_ENEMY_HP = 280
SPECIAL_ENEMY_DAMAGE = 20
SPECIAL_ENEMY_MS = 20

MINIBOSS_HP = 400
MINIBOSS_DAMAGE = 20
MINIBOSS_MS = 50

BOSS_HP = 1400

BOSS_HP_MULT_BY_TYPE = {
  ['stompy'] = 4.2,
}
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

ELEMENTAL_CONVERSION_PERCENT = 0.5

ELEMENTAL_HIT_DAMAGE_TYPES = {DAMAGE_TYPE_FIRE, DAMAGE_TYPE_LIGHTNING, DAMAGE_TYPE_COLD}
ELEMENTAL_EFFECT_TYPES = {DAMAGE_TYPE_BURN, DAMAGE_TYPE_LIGHTNING, DAMAGE_TYPE_COLD}

LIGHTNING_FLAT_DAMAGE = 20

-- Burn system constants
BURN_DURATION = 5.0
BURN_TICK_INTERVAL = 0.5
BURN_DAMAGE_PER_TICK_PERCENT = 0.02  -- 2% of max HP per tick
BURN_EXPLOSION_BASE_CHANCE = 0.05    -- 5% base chance per tick
BURN_EXPLOSION_DAMAGE_PERCENT = 0.1  -- 15% of max HP explosion damage

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

-- Weights are {common, rare}.
TIER_TO_ITEM_RARITY_WEIGHTS = {
  [1] = {0.85, 0.15},
  [1.5] = {0.65, 0.35},
  [2] = {0.45, 0.55},
  [2.5] = {0.25, 0.75},
}

CHANCE_OF_SPECIAL_VS_NORMAL_ENEMY = 0.7

get_num_special_enemies_by_level = function(level)
  if level == 1 then return 0 end
  if level == 2 then return 0 end
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
  [2] = {0},
  [3] = {0},
  [4] = {0, 5},
  [5] = {0, 5},
  [6] = {0},
  [7] = {0},
  [8] = {0},
  [9] = {0},
  [10] = {0},
  [11] = {0},
  [12] = {0},
  [13] = {0},
  [14] = {0},
  [15] = {0},
  [16] = {0},
  [17] = {0},
  [18] = {0},
  [19] = {0},
  [20] = {0},
  [21] = {0},
  [22] = {0},
  [23] = {0},
  [24] = {0},
  [25] = {0},
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

-- Total gold dropped by enemies across a round (gold-per-kill is proportional
-- to enemy power / kill_quota). With the kill_quota denominator fix in
-- gold_counter.lua, these values are now ~= actual gold earned per round
-- (plus a small overshoot from the level-clear cascade).
GOLD_GAINED_BY_LEVEL = {
  [1] = 2,
  [2] = 2,
  [3] = 2,
  [4] = 2,
  [5] = 2,
  [6] = 3,
  [7] = 3,
  [8] = 3,
  [9] = 3,
  [10] = 3,
  [11] = 4,
  [12] = 4,
  [13] = 4,
  [14] = 4,
  [15] = 4,
  [16] = 5,
  [17] = 5,
  [18] = 5,
  [19] = 5,
  [20] = 5,
  [21] = 6,
  [22] = 6,
  [23] = 6,
  [24] = 6,
  [25] = 6,
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
{0, 0, 0, 1, 1, 1, 
 2, 2, 2, 3, 3, 3, 
 4, 4, 4, 5, 5, 5, 6, 
 7, 7, 7, 8, 8, 8, 8}

ENEMY_LEVEL_SCALING = function(level)
  local scale = ENEMY_SCALE_BY_LEVEL[level] or 0
  return scale
end

-- Post-boss HP multiplier on top of the per-level scaling: enemies get a
-- step-function bump after each boss is cleared. Both T2 and T3 softened to
-- match the gentler T2 swarmer count scaling; T3 sits just above T2 instead
-- of doubling again.
function POST_BOSS_HP_MULT(level)
  if level >= 12 then return 1.7 end -- after dragon (level 11)
  if level >= 7 then return 1.4 end  -- after stompy (level 6)
  return 1
end

SCALED_ENEMY_HP = function(level, base_hp)
  local scale = ENEMY_SCALE_BY_LEVEL[level]
  return (base_hp + (base_hp * 0.2 * scale)) * POST_BOSS_HP_MULT(level)
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
  local count = math.min(30, 8 + (level * 2))
  -- T2 (between stompy at L6 and dragon at L11) was pushing roughly 2x the
  -- baseline swarmer count, which felt overloaded alongside the new T2
  -- special mix. Scale by 1.4/2.0 so T2 clumps land closer to the intended
  -- 1.4x multiplier of the L1 baseline.
  if level >= 7 and level <= 10 then
    count = math.floor(count * 0.7)
  end
  return count
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
  return (base_hp + (base_hp * 0.8 * scale)) * POST_BOSS_HP_MULT(level)
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

-- Distance-based cooldown buff disabled: troops no longer attack faster when
-- close to the nearest enemy. Restore the old 0.25 / 0.5 / 0.75 values to
-- re-enable. The multiplier mechanism (and the closest_enemy_distance_tier
-- glow + audio hooks) still functions, this just neutralises the cooldown
-- effect.
DISTANCE_TIER_TO_COOLDOWN_MULTIPLIER = {
  [1] = 1,
  [2] = 1,
  [3] = 1,
}

TIER_TO_DISTANCE = {
  [1] = 60,
  [2] = 100,
  [3] = 130,
}

get_distance_effect_multiplier = function(distance)
  local tier = get_distance_effect_tier(distance)
  return DISTANCE_TIER_TO_COOLDOWN_MULTIPLIER[tier] or 1
end

get_distance_effect_tier = function(distance)
  if not distance then return nil end

  for i, tier_distance in ipairs(TIER_TO_DISTANCE) do
    if distance <= tier_distance then
      return i
    end
  end
  return nil
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
    -- Sword: melee AoE cone. With cooldown bumped 50% above 'fast' (cycle
    -- ~1.80s vs archer's ~1.47s) single-target DPS is well below archer
    -- (~7.9 vs ~11.2); the cone hitting 2+ enemies is the real upside,
    -- and the unit stays tankier than archer to justify the melee commit.
    ['sword'] = { hp = 1.4, dmg = 1.3, def = 1.2, mvspd = 1.05 },
    -- Shotgun: 5-pellet random-spread, very short range (100). Dmg multi is
    -- per pellet, so max single-target burst at point-blank is 5 * 0.3 * base
    -- ≈ 16.5 (≈ archer per-shot), with most pellets missing past mid range.
    -- Tankier than archer to make the close engagement viable.
    ['shotgun'] = { hp = 1.2, dmg = 0.3, def = 1, mvspd = 1.05 },

    ['none'] = { hp = 1, dmg = 1, def = 1, mvspd = 1 },
}

enemy_type_to_stats = {
    ['swarmer'] = { dmg = 0.5, hp = 0.6, mvspd = 0.7},
    ['hunter_swarmer'] = { dmg = 0.6, hp = 1.4, mvspd = 1.1 },
    -- Tank: slow, chunky body. No attacks, just contact pressure. hp=0.8
    -- on special_enemy base (280) lands ~625 HP at L7 once level/post-boss
    -- scaling kicks in - a real soak target you have to commit damage to.
    -- Full knockback immunity is set via `knockback_immune` in tank.lua's
    -- init_enemy (knockback_resistance caps at 0.8 so a flag is required).
    ['tank'] = { dmg = 1, hp = 0.8, mvspd = 0.6 },

    ['seeker'] = { dmg = 0.25, mvspd = 0.7 },
    ['chaser'] = { dmg = 1, mvspd = 1 },
    ['brute'] = { dmg = 1, mvspd = 1.5, hp = 1.6 },
    ['roach'] = { dmg = 1, mvspd = 1.6, hp = 1 },
    ['slime'] = { dmg = 1, mvspd = 0.7, hp = 1.4 },
    ['sniper'] = { dmg = 1, mvspd = 1, hp = 1 },
    ['orb'] = { dmg = 1, mvspd = 0.8, hp = 1.8 },
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

        -- Per-boss HP multiplier on top of the generic boss scaling. Stompy
        -- (the first boss) gets 3x because the new ground-pound moveset is
        -- meant to be a longer fight than the old charge/mortar pattern.
        local boss_hp_mult = BOSS_HP_MULT_BY_TYPE[unit.type] or 1
        unit.base_hp = unit.base_hp * boss_hp_mult

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
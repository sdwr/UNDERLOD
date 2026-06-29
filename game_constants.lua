--debug constants
DEBUG_PROCS = false
DEBUG_SPELLS = false
DEBUG_ENEMY_SEEK_TO_RANGE = false
DEBUG_STEERING_VECTORS = false
DEBUG_STEERING_ENEMY_TYPE = 'swarmer'
DEBUG_DISTANCE_MULTI = false

IS_DEMO = false
DEMO_END_LEVEL = 11

-- Fields copied into run.txt on save and back into state on load. level_list
-- is intentionally NOT here - it's fully reconstructible from `level` via
-- Build_Level_List (deterministic given the level number), and including it
-- forced every spawn-config value to be serializable text. Removed so configs
-- can carry functions etc. without breaking save/load.
EXPECTED_SAVE_FIELDS = {
  'level',
  'loop',
  'gold',
  'units',
  'max_units',
  'passives',
  'shop_item_data',
  'locked_state',
  'reroll_shop',
  'times_rerolled',
  'difficulty',
  'perks',
}

USER_STATS = {}
system.load_stats()

--gold
--note that HoG econ check is in arena.lua (gain_gold)
-- Bumped 9 -> 14 (+5) to compensate for unit purchases now costing a flat
-- 10 each (was 5 for the first unit). See buy_card_cost in buy_screen.lua.
STARTING_GOLD = 14.0
-- Per-round end-of-round gold by level band. Combines with the per-kill gold
-- in GOLD_GAINED_BY_LEVEL for total round income. Tuned so the player can't
-- fully equip two units by the first boss (L6).
-- Total per-round income (GOLD_PER_ROUND + GOLD_GAINED_BY_LEVEL):
--   L1-5: 2+2=4    L6-10: 3+3=6    L11-15: 5+4=9    L16-20: 6+5=11    L21+: 8+6=14
GOLD_PER_ROUND = function(level)
  if level <= 5 then return 2 end
  if level <= 10 then return 3 end
  if level <= 15 then return 5 end
  if level <= 20 then return 6 end
  return 8
end
GOLD_FOR_BOSS_ROUND = {10, 15, 20, 25}
INTEREST_AMOUNT = 0.1
MAX_INTEREST = 3

--gold display at end of round
SUM_PLUSGOLD = 0
LAST_PLUSGOLD = 0

STARTING_REROLL_COST = 1
--values should be 1, 2, 3, 4, 5
REROLL_COST = function (times_rerolled)
  -- return math.min(5, times_rerolled + STARTING_REROLL_COST)
  return STARTING_REROLL_COST
end


-- Game currently ends at L11 (dragon, 2nd boss). NG+ unlocks on completion.
-- Most data tables (ROUND_POWER_BY_LEVEL, GOLD_GAINED_BY_LEVEL, etc.) still
-- hold entries up to 25 - those past NUMBER_OF_ROUNDS are simply unreachable.
NUMBER_OF_ROUNDS = 11
BOSS_ROUND_POWER = 1000
BOSS_ROUNDS = {6, 11, 16, 21, 25}
LEVELS_TO_HEAL_ON_CLEAR = BOSS_ROUNDS

MAX_UNITS = 1
MAX_SET_BONUS_PIECES = 6

--disable multiple characters
PICK_SECOND_CHARACTER = 1
PICK_THIRD_CHARACTER = 1

RALLY_DURATION = 3
RALLY_CIRCLE_OVERSHOOT_DISTANCE = 10
RALLY_CIRCLE_STOP_DISTANCE = 5

BOSS_MASS = 10
SPECIAL_ENEMY_MASS = 1
REGULAR_ENEMY_MASS = 1
CRITTER_MASS = 0.5

TROOP_MASS = 1
TROOP_KNOCKBACK_MASS = 50

function get_damping_by_unit_class(unit_class)
  return DAMPING_BY_UNIT_CLASS[unit_class] or 1
end

DAMPING_BY_UNIT_CLASS = {
  ['boss'] = 6,
  ['special_enemy'] = 2,
  ['regular_enemy'] = 1,
  ['critter'] = 1,
  -- Troop damping reverted to 2 (was briefly 8, which throttled steering force
  -- so badly troops couldn't reach the rally point). Explicit idle braking in
  -- Troop:update handles the "stop fast after move" behaviour instead.
  ['troop'] = 2,
}

LAUNCH_DAMPING = 0.1

-- Friction constants
BOSS_FRICTION = 1
ENEMY_FRICTION = 1
TROOP_FRICTION = 1

LAUNCH_PUSH_FORCE_ENEMY = 30
LAUNCH_PUSH_FORCE_SPECIAL_ENEMY = 50
LAUNCH_PUSH_FORCE_BOSS = 70

ENEMY_KNOCKBACK_FORCE_TROOP_COLLISION = 500
ENEMY_KNOCKBACK_VELOCITY_THRESHOLD = 100
ENEMY_KNOCKBACK_CHAIN_VELOCITY_THRESHOLD = 40
ENEMY_KNOCKBACK_CHAIN_DAMAGE = 10
ENEMY_KNOCKBACK_FORCE_CHAIN_MULTIPLIER = 0.8

ENEMY_KNOCKBACK_VELOCITY_REGAIN_CONTROL_THRESHOLD = 30

LAUNCH_PUSH_FORCE_TROOP_ATTACK = 10
KNOCKBACK_DURATION_TROOP_ATTACK = 0.2

KNOCKBACK_DURATION_BOSS = 1
KNOCKBACK_DURATION_ENEMY = 0.6
KNOCKBACK_DURATION_REGULAR_ENEMY = 0.3
KNOCKBACK_DURATION_SPECIAL_ENEMY = 0.6

BOSS_RESTITUTION = 0.1
SPECIAL_ENEMY_RESTITUTION = 0.5
REGULAR_ENEMY_RESTITUTION = 0.5
CRITTER_RESTITUTION = 0.5

TROOP_RESITUTION = 0.5

ENEMY_CHANCE_TO_TARGET_CRITTER = 0.3

MULTISHOT_ANGLE_OFFSET = math.pi / 8

ENEMY_HIT_SCALE = 0.3

HITS_BEFORE_RETARGETING = 3

DISTANCE_MULTIPLIER_THRESHOLD_GLOW = 0.8
DISTANCE_MULTIPLIER_THRESHOLD_SOUND = 0.7


DELAY_BEFORE_SUCTION = 1
TIME_BETWEEN_WAVES = 0.5
WAVE_SPAWN_WARNING_TIME = 1.25
-- Pause after a wave finishes its full instruction list, before cycling back
-- to the start when wave.kill_quota hasn't been met. Gives the player a brief
-- beat of breathing room between spawn rounds.
WAVE_KILL_QUOTA_CYCLE_DELAY = 2

-- Default kill_quota for a wave = sum of all GROUP spawn counts times this
-- multiplier. 1.5 -> the wave's instructions cycle roughly once-and-a-half
-- before advancing, so the player kills more enemies than a single pass.
WAVE_KILL_QUOTA_MULTIPLIER = 1.5

-- Continuous spawn system: ±SPECIAL_SPAWN_JITTER fraction of each pool's
-- interval is rolled per tick so spawns don't feel metronome-regular.
-- 0.2 = each spawn fires somewhere in [interval*0.8, interval*1.2].
SPECIAL_SPAWN_JITTER = 0.2

-- Dynamic special-spawn cadence (campaign levels). The first special of a
-- level arrives SPECIAL_CADENCE_INITIAL seconds in. Each subsequent spawn is
-- scheduled at the moment the current one fires: the delay to the next is
-- SPECIAL_CADENCE_BASE + SPECIAL_CADENCE_INCREMENT * (cycle specials alive,
-- counting the group just queued). So spawns space out as the field fills
-- and tighten back up as the player clears it. Tanks (basic-pool filler) are
-- excluded from the count. Example with base 7 / increment 3:
--   t=5 first; +7+3*1=10 -> t=15; if still alive +7+3*2=13 -> t=28,
--   but if the first died, +7+3*1=10 -> t=25.
SPECIAL_CADENCE_INITIAL = 5
SPECIAL_CADENCE_BASE = 7
SPECIAL_CADENCE_INCREMENT = 3

-- Seconds between swarmer clump spawns in the continuous system. Clump size
-- itself is SWARMERS_PER_LEVEL(level). At 3.1s full-size clumps arrive less
-- often than the original 2.0, thinning sustained swarmer density.
BASIC_CLUMP_INTERVAL = 3.1

-- Density throttle: the basic clump interval stretches as the field fills toward
-- MAX_ALIVE_BASICS so spawns ease off before slamming into the hard cap. At an
-- empty field the multiplier is 1x; at the cap it's (1 + this). 3 => up to
-- 4x the interval (3.1s -> ~12.4s) when the arena is packed.
BASIC_CLUMP_DENSITY_THROTTLE = 3

-- Cinematic level-clear wipe: pre-delay before the first straggler dies,
-- then enemies are spread evenly across LEVEL_CLEAR_CASCADE_DURATION so the
-- wipe is the same length whether 5 or 100 enemies are left. KILL_OFFSET is
-- legacy and unused now.
LEVEL_CLEAR_KILL_DELAY = 0.0
LEVEL_CLEAR_CASCADE_DURATION = 1.5
LEVEL_CLEAR_KILL_OFFSET = 0.04

-- Post-cascade beat before the arena transitions away. Polling in
-- combat_level:level_clear() already waits for the cascade to finish, so this
-- is pure buffer for the wipe/flash to settle.
LEVEL_CLEAR_TRANSITION_DELAY = 0.25

ITEM_SPAWN_DELAY_INITAL = 0.8
ITEM_SPAWN_DELAY_OFFSET = 0.5

DOOR_OPEN_DELAY = 4
ARENA_END_DELAY = 3



LEVEL_TO_TIER = function(level)
  if level <= 6 then
    return 1
  elseif level <= 11 then
    return 2
  elseif level <= 16 then
    return 3
  else
    return 4
  end
end

--disable perks for now
LEVEL_TO_PERKS = {
  [3] = true,
  [8] = true,
  [13] = true,
  [18] = true,
  [23] = true,
}

-- Leveling up unlocks item slots, not troops. Keep troop count flat across levels.
UNIT_LEVEL_TO_NUMBER_OF_TROOPS = {
  [0] = 3,
  [1] = 3,
  [2] = 3,
  [3] = 3,
  [4] = 3,
  [5] = 3,
}

MAX_ITEMS = 6

-- Every unit gets the full six item slots regardless of level.
UNIT_LEVEL_TO_NUMBER_OF_ITEMS = {
  [1] = 6,
  [2] = 6,
  [3] = 6,
  [4] = 6,
  [5] = 6,
}

UNIT_LEVEL_TO_LEVELUP_COST = {
  [1] = 5,
  [2] = 10,
  [3] = 15,
  [4] = 20,
}

NUMBER_OF_TROOPS_TO_CHARACTER_COST = {
  [0] = 5,
  [1] = 10,
  [2] = 15,
}


-- unit constants
MELEE_ATTACK_RANGE = 50

AGGRO_RANGE_BOOST = 100

MIN_DISTANCE_FOR_RANDOM_MOVEMENT = 100

ARENA_RADIUS = 200


-- Steering and Movement constants
SEEK_DECELERATION = 1.1
SEEK_WEIGHT = 1.75

get_seek_weight_by_enemy_type = function(enemy_type)
  return seek_weight_by_enemy_type[enemy_type] or seek_weight_by_enemy_type['default']
end

seek_weight_by_enemy_type = {
  ['goblin_archer'] = 3,
  ['default'] = SEEK_WEIGHT,
}

TROOP_SEPARATION_RADIUS = 8
TROOP_SEPARATION_WEIGHT = 1

TROOP_SEPARATION_RADIUS_SAME_TEAM = 4
TROOP_SEPARATION_WEIGHT_SAME_TEAM = 2

TROOP_COHESION_MIN_DISTANCE = 2
TROOP_COHESION_WEIGHT = 2

TROOP_WANDER_RADIUS = 8
TROOP_WANDER_DISTANCE = 50
TROOP_WANDER_JITTER = 5

-- Enemy steering behavior constants
ENEMY_SEPARATION_RADIUS = 7
ENEMY_SEPARATION_WEIGHT = 10

ENEMY_CRITTER_SEPARATION_RADIUS = 8

-- Enemy wander behavior constants  
ENEMY_WANDER_RADIUS = 50
ENEMY_WANDER_DISTANCE = 100
ENEMY_WANDER_JITTER = 3

WANDER_RADIUS = 30




LOOSE_SEEK_OFFSET = 15
DISTANCE_TO_TARGET_FOR_IDLE = 7

IDLE_DECEL_FORCE = 100
DECELERATION_WEIGHT = 5
-- Troops use a softer brake than enemies (5) so the post-M1 coast is
-- visible-but-short rather than a snap-stop. Raise to 4-5 if too floaty,
-- lower to 1 if you want a longer glide.
TROOP_IDLE_BRAKE_WEIGHT = 2

MAX_BOSS_FORCE = 1000
MAX_ENEMY_FORCE = 1000

MAX_TROOP_FORCE = 1000

LAUNCH_MAX_V = 200


-- UI constants
SCROLL_SPEED = 5
MIN_SCROLL_LOCATION = -95
MAX_SCROLL_LOCATION = 0

ARENA_TRANSITION_TIME = 3

STARTING_WAVE_COUNTDOWN_DURATION = 0.7
TOTAL_STARTING_WAVE_DELAY = (3 * STARTING_WAVE_COUNTDOWN_DURATION)

get_starting_wave_countdown_value = function(seconds_remaining)
  local value = math.ceil(seconds_remaining / STARTING_WAVE_COUNTDOWN_DURATION)
  return value
end

SELECTED_PLAYER_LIGHTEN = -0.2

LEVEL_TEXT_HOVER_HEIGHT = 100

ITEM_CARD_TEXT_HOVER_HEIGHT_OFFSET = 30

CHARACTER_CARD_WIDTH = 100
CHARACTER_CARD_HEIGHT = 135
CHARACTER_CARD_SPACING = 15

-- Item grid sits centered on the card (3 cols x 30px spacing -> spans 60px).
CHARACTER_CARD_ITEM_X = -30
CHARACTER_CARD_ITEM_X_SPACING = 30
CHARACTER_CARD_ITEM_Y = -(CHARACTER_CARD_HEIGHT / 2) + 35
CHARACTER_CARD_ITEM_Y_SPACING = 25

CHARACTER_CARD_PROC_X = -(CHARACTER_CARD_WIDTH / 2) + 20
CHARACTER_CARD_PROC_X_SPACING = 12
CHARACTER_CARD_PROC_Y = (CHARACTER_CARD_HEIGHT / 2) - 115

ARENA_TITLE_TEXT_Y = 60

TRANSITION_DURATION = 1.75
TRANSITION_DURATION_IN_NEW_STATE = 0.9

ITEM_SLOT_LOWER_BOUND = 190
ITEM_SLOT_DISTANCE = 30

ITEM_SLOT_SIZE = 20

ITEM_CARD_WIDTH = 30
ITEM_CARD_HEIGHT = 45

ACHIEVEMENT_SIZE = 50
ACHIEVEMENT_SPACING = 10
ACHIEVEMENTS_PER_ROW = 4

ACH_CLOSE_BUTTON_SIZE = 20

DAMAGE_NUMBERS_SETTING = {
  'off',
  'enemies',
  'friendlies',
  'all',
}
LEFT_BOUND = 0
RIGHT_BOUND = 0
TOP_BOUND = 0
BOTTOM_BOUND = 0

SET_GAME_BOUNDS = function()
  LEFT_BOUND = gw/2 - 0.8*gw/2
  RIGHT_BOUND = gw/2 + 0.8*gw/2
  TOP_BOUND = gh/2 - 0.8*gh/2
  BOTTOM_BOUND = gh/2 + 0.8*gh/2
end

-- Unit constants

MOVEMENT_RANDOM_TIMER = 5
LOOSE_SEEK_RETARGET_TIME = 10
SEEK_TO_RANGE_PLAYER_RADIUS = 130
SEEK_TO_RANGE_ENEMY_MOVEMENT_RADIUS = 100

MOVEMENT_TYPE_SEEK = 'seek'
MOVEMENT_TYPE_LOOSE_SEEK = 'loose_seek'
MOVEMENT_TYPE_SEEK_TO_RANGE = 'seek_to_range'
MOVEMENT_TYPE_RANDOM = 'random'
MOVEMENT_TYPE_FLEE = 'flee'
MOVEMENT_TYPE_WANDER = 'wander'
MOVEMENT_TYPE_NONE = 'none'
-- Walk in a straight line from spawn through the map center to the opposite
-- edge, then despawn. Used by swarmers as a "creep wave" style movement that
-- doesn't actively chase the player.
MOVEMENT_TYPE_PATH_ACROSS = 'path_across'

-- Like PATH_ACROSS but the heading is rotated by a random offset (up to
-- PATH_ACROSS_VARIED_JITTER radians) off the line to center, so a wave of
-- enemies fans out across the arena instead of all funneling through the
-- middle.
MOVEMENT_TYPE_PATH_ACROSS_VARIED = 'path_across_varied'
PATH_ACROSS_VARIED_JITTER = math.pi / 6

-- Maximum simultaneously-alive enemies the spawn manager will allow. Split
-- by class: basics (regular_enemy, e.g. swarmer) and specials (special_enemy,
-- e.g. brute, roach). Each pool's per-type cap is on top of these — a spawn
-- skips on this tick (no queue) when either its class cap or its per-pool
-- cap is full. MAX_ALIVE_ENEMIES kept as a hard sum ceiling for safety.
MAX_ALIVE_BASICS = 180
MAX_ALIVE_SPECIALS = 20
MAX_ALIVE_ENEMIES = MAX_ALIVE_BASICS + MAX_ALIVE_SPECIALS

-- Weighted offscreen spawn placement. Every enemy spawn (basics, specials,
-- events, cadence) picks SPAWN_WEIGHT_CANDIDATES random edge points and chooses
-- one via weighted random, where each candidate's weight is its distance to the
-- nearest of the last SPAWN_WEIGHT_HISTORY spawns raised to SPAWN_WEIGHT_EXPONENT.
-- Higher exponent biases harder toward open space (2 => a candidate twice as far
-- is ~4x as likely); 0 would be pure random.
SPAWN_WEIGHT_HISTORY = 4
SPAWN_WEIGHT_CANDIDATES = 10
SPAWN_WEIGHT_EXPONENT = 2
MOVEMENT_TYPES = {MOVEMENT_TYPE_SEEK, MOVEMENT_TYPE_LOOSE_SEEK, MOVEMENT_TYPE_SEEK_TO_RANGE, MOVEMENT_TYPE_RANDOM, MOVEMENT_TYPE_FLEE, MOVEMENT_TYPE_NONE, MOVEMENT_TYPE_PATH_ACROSS, MOVEMENT_TYPE_PATH_ACROSS_VARIED}

get_movement_type_by_enemy_type = function(enemy_type)
  return enemy_movement_types[enemy_type] or enemy_movement_types['default']
end

-- Enemy fallback animation corner radius by size category
enemy_corner_radius_by_size = {
  ['critter'] = 2,
  ['small'] = 2,
  ['regular'] = 3,
  ['swarmer'] = 3,
  ['regular_big'] = 3,
  ['block'] = 5,
  ['special'] = 3,
  ['large'] = 3,
  ['huge'] = 3,
  ['stompy'] = 10,
  ['heigan'] = 10,
  ['boss'] = 10,
}

-- Get corner radius for enemy fallback animation
get_enemy_corner_radius = function(enemy)
  local size_category = enemy.size or 'regular'
  return enemy_corner_radius_by_size[size_category] or 3
end

-- Enemy movement styles organized by enemy type
enemy_movement_types = {

  ['default'] = MOVEMENT_TYPE_SEEK,
  -- Aggressive seekers - chase players directly
  ['slowcharger'] = MOVEMENT_TYPE_SEEK,
  -- Grey basic swarmers seek the player directly.
  ['swarmer'] = MOVEMENT_TYPE_SEEK,
  ['hunter_swarmer'] = MOVEMENT_TYPE_SEEK,
  ['tank'] = MOVEMENT_TYPE_SEEK,
  ['chaser'] = MOVEMENT_TYPE_SEEK,
  ['brute'] = MOVEMENT_TYPE_SEEK,
  ['roach'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['slime'] = MOVEMENT_TYPE_PATH_ACROSS,
  ['sniper'] = MOVEMENT_TYPE_RANDOM,
  ['orb'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['cleaver'] = MOVEMENT_TYPE_SEEK,
  
  -- Ranged units that maintain distance
  ['big_goblin_archer'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['goblin_archer'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['archer'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['seeker'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['mortar'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['singlemortar'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['line_mortar'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['burst'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['selfburst'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['arcspread'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['aim_spread'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['plasma'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['laser'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['snakearrow'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['summoner'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['spawner'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  ['firewall_caster'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  
  -- Stationary units
  ['turret'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
  
  -- Bosses
  ['stompy'] = MOVEMENT_TYPE_LOOSE_SEEK,
  ['dragon'] = MOVEMENT_TYPE_LOOSE_SEEK,
  ['heigan'] = MOVEMENT_TYPE_SEEK_TO_RANGE,
}

-- Spell constants
LASER_FIRE_TYPES = {'target', 'fixed_angle', 'rotating'}

DAMAGE_TYPE_LIGHTNING = 'lightning'
DAMAGE_TYPE_SHOCK = 'shock'
DAMAGE_TYPE_FIRE = 'fire'
DAMAGE_TYPE_BURN = 'burn'
DAMAGE_TYPE_PHYSICAL = 'physical'
DAMAGE_TYPE_POISON = 'poison'
DAMAGE_TYPE_COLD = 'cold'

DAMAGE_TYPES = {DAMAGE_TYPE_LIGHTNING, DAMAGE_TYPE_FIRE, DAMAGE_TYPE_PHYSICAL, DAMAGE_TYPE_POISON, DAMAGE_TYPE_COLD, DAMAGE_TYPE_BURN, DAMAGE_TYPE_SHOCK, DAMAGE_TYPE_CHILL}
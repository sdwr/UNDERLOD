--debug constants
DEBUG_PROCS = false
DEBUG_SPELLS = false

IS_DEMO = true
DEMO_END_LEVEL = 11

EXPECTED_SAVE_FIELDS = {
  'level',
  'level_list',
  'loop',
  'gold',
  'units',
  'max_units',
  'passives',
  'shop_item_data',
  'locked_state',
  'reroll_shop',
  'times_rerolled',
}

USER_STATS = {}
system.load_stats()

--gold
--note that HoG econ check is in arena.lua (gain_gold)
STARTING_GOLD = 5
GOLD_PER_ROUND = 6
INTEREST_AMOUNT = 0.1
MAX_INTEREST = 3

--gold display at end of round
SUM_PLUSGOLD = 0
LAST_PLUSGOLD = 0

STARTING_REROLL_COST = 1
--values should be 1, 2, 3, 4, 5
REROLL_COST = function (times_rerolled)
  return math.min(5, times_rerolled + STARTING_REROLL_COST)
end


BOSS_ROUND_POWER = 1000
NUMBER_OF_ROUNDS = 25

MAX_UNITS = 3

PICK_SECOND_CHARACTER = 5
PICK_THIRD_CHARACTER = 13

RALLY_DURATION = 3

--used in the spawn manager
--and also used by procs to know when to start buffs
TIME_TO_ROUND_START = 2
SPAWNS_IN_GROUP = 6
SPAWN_CHECKS = 10

--stat constants
REGULAR_ENEMY_HP = 70
REGULAR_ENEMY_DAMAGE = 10
REGULAR_ENEMY_MS = 50

SPECIAL_ENEMY_HP = 175
SPECIAL_ENEMY_DAMAGE = 20
SPECIAL_ENEMY_MS = 40

BOSS_MASS = 100
SPECIAL_ENEMY_MASS = 2
REGULAR_ENEMY_MASS = 1

LEVEL_TO_TIER = function(level)
  if level < 6 then
    return 1
  elseif level < 11 then
    return 2
  elseif level < 16 then
    return 3
  else
    return 4
  end
end

REGULAR_ENEMY_SCALING = function(level) 
  return math.pow(1.1, level) + ((LEVEL_TO_TIER(level) - 1) / 4)
end

SPECIAL_ENEMY_SCALING = function(level) 
  return math.pow(1.1, level) + ((LEVEL_TO_TIER(level) - 1) / 4)
end

--add 0.25 to the scaling for each boss level (boss levels are every 6 levels)
BOSS_HP_SCALING = function(level) return LEVEL_TO_TIER(level) end


--proc constants
MAX_STACKS_FIRE = 5
MAX_STACKS_SLOW = 5
MAX_STACKS_SHOCK = 10
MAX_STACKS_REDSHIELD = 20
MAX_STACKS_BLOODLUST = 10

SHOCK_DEF_REDUCTION = -0.04

-- unit constants
MELEE_ATTACK_RANGE = 50


-- UI constants
SCROLL_SPEED = 5
MIN_SCROLL_LOCATION = -95
MAX_SCROLL_LOCATION = 0

ARENA_TRANSITION_TIME = 3

SELECTED_PLAYER_LIGHTEN = -0.2

LEVEL_TEXT_HOVER_HEIGHT = 100

ITEM_CARD_TEXT_HOVER_HEIGHT_OFFSET = 40

CHARACTER_CARD_WIDTH = 100
CHARACTER_CARD_HEIGHT = 135
CHARACTER_CARD_SPACING = 20

CHARACTER_CARD_ITEM_X = -(CHARACTER_CARD_WIDTH / 2) + 20
CHARACTER_CARD_ITEM_X_SPACING = 30
CHARACTER_CARD_ITEM_Y = (CHARACTER_CARD_HEIGHT / 2) - 40

CHARACTER_CARD_PROC_X = -(CHARACTER_CARD_WIDTH / 2) + 20
CHARACTER_CARD_PROC_X_SPACING = 12
CHARACTER_CARD_PROC_Y = (CHARACTER_CARD_HEIGHT / 2) - 115

ACHIEVEMENT_SIZE = 50
ACHIEVEMENT_SPACING = 10
ACHIEVEMENTS_PER_ROW = 4

ACH_CLOSE_BUTTON_SIZE = 20

-- Unit constants

MOVEMENT_RANDOM_TIMER = 5

MOVEMENT_TYPE_SEEK = 'seek'
MOVEMENT_TYPE_RANDOM = 'random'
MOVEMENT_TYPE_FLEE = 'flee'
MOVEMENT_TYPES = {MOVEMENT_TYPE_SEEK, MOVEMENT_TYPE_RANDOM, MOVEMENT_TYPE_FLEE}

-- Spell constants
LASER_FIRE_TYPES = {'target', 'fixed_angle', 'rotating'}

DAMAGE_TYPE_LIGHTNING = 'lightning'
DAMAGE_TYPE_FIRE = 'fire'
DAMAGE_TYPE_PHYSICAL = 'physical'
DAMAGE_TYPE_POISON = 'poison'
DAMAGE_TYPE_COLD = 'cold'

DAMAGE_TYPES = {DAMAGE_TYPE_LIGHTNING, DAMAGE_TYPE_FIRE, DAMAGE_TYPE_PHYSICAL, DAMAGE_TYPE_POISON, DAMAGE_TYPE_COLD}

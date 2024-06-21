--debug constants
DEBUG_PROCS = false
DEBUG_SPELLS = false

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
}

--gold
--note that HoG econ check is in arena.lua
STARTING_GOLD = 5
GOLD_PER_ROUND = 8
INTEREST_AMOUNT = 0.1

BOSS_ROUND_POWER = 1000
NUMBER_OF_ROUNDS = 25

MAX_UNITS = 3

PICK_SECOND_CHARACTER = 5
PICK_THIRD_CHARACTER = 10

RALLY_DURATION = 3

--used in the spawn manager
--and also used by procs to know when to start buffs
TIME_TO_ROUND_START = 2
SPAWNS_IN_GROUP = 6

--stat constants
REGULAR_ENEMY_HP = 50
REGULAR_ENEMY_DAMAGE = 10
REGULAR_ENEMY_MS = 50

SPECIAL_ENEMY_HP = 175
SPECIAL_ENEMY_DAMAGE = 20
SPECIAL_ENEMY_MS = 40

REGULAR_ENEMY_SCALING = function(level) return math.pow(1.1, level) end
SPECIAL_ENEMY_SCALING = function(level) return math.pow(1.1, level) end

--add 0.25 to the scaling for each boss level (boss levels are every 6 levels)
BOSS_HP_SCALING = function(level) return 1 + ((level / 6) - 1) end


--proc constants
MAX_STACKS_FIRE = 5
MAX_STACKS_SLOW = 5
MAX_STACKS_SHOCK = 10
MAX_STACKS_REDSHIELD = 20
MAX_STACKS_BLOODLUST = 10

SHOCK_DEF_REDUCTION = -0.04


-- UI constants
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

-- Spell constants
LASER_FIRE_TYPES = {'target', 'fixed_angle', 'rotating'}

DAMAGE_TYPE_LIGHTNING = 'lightning'
DAMAGE_TYPE_FIRE = 'fire'
DAMAGE_TYPE_PHYSICAL = 'physical'
DAMAGE_TYPE_POISON = 'poison'
DAMAGE_TYPE_COLD = 'cold'

DAMAGE_TYPES = {DAMAGE_TYPE_LIGHTNING, DAMAGE_TYPE_FIRE, DAMAGE_TYPE_PHYSICAL, DAMAGE_TYPE_POISON, DAMAGE_TYPE_COLD}

-- global state :o
--hack
STORE_ITEMS = {}
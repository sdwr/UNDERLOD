--debug constants
DEBUG_PROCS = false
DEBUG_SPELLS = false

--gold
--note that HoG econ check is in arena.lua
STARTING_GOLD = 0
GOLD_PER_ROUND = 8
INTEREST_AMOUNT = 0.1

BOSS_ROUND_POWER = 1000
NUMBER_OF_ROUNDS = 25

MAX_UNITS = 3

--used in the spawn manager
--and also used by procs to know when to start buffs
TIME_TO_ROUND_START = 2
SPAWNS_IN_GROUP = 6

--stat constants
REGULAR_ENEMY_SCALING = function(level) return math.pow(1.1, level) end
SPECIAL_ENEMY_SCALING = function(level) return math.pow(1.1, level) end

--add 0.25 to the scaling for each boss level (boss levels are every 6 levels)
BOSS_HP_SCALING = function(level) return 1 + ((level / 6) * 0.25) end


--proc constants
MAX_STACKS_FIRE = 5
MAX_STACKS_SLOW = 5
MAX_STACKS_REDSHIELD = 20
MAX_STACKS_BLOODLUST = 10


-- UI constants
ARENA_TRANSITION_TIME = 3

SELECTED_PLAYER_LIGHTEN = 0.3

CHARACTER_CARD_WIDTH = 100
CHARACTER_CARD_HEIGHT = 135
CHARACTER_CARD_SPACING = 20

CHARACTER_CARD_ITEM_X = -(CHARACTER_CARD_WIDTH / 2) + 20
CHARACTER_CARD_ITEM_X_SPACING = 30
CHARACTER_CARD_ITEM_Y = (CHARACTER_CARD_HEIGHT / 2) - 40

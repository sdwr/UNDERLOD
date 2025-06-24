CHILL_SLOW_PERCENT = 0.3
CHILL_DURATION = 4
CHILL_FREEZE_GAUGE_FILL_PER_SECOND = 10

FREEZE_GAUGE_MAX = 70
FREEZE_PER_SECOND = 10
--damage taken is calculated as a % of max hp
--what % of max hp taken as damage fills the freeze gauge
FREEZE_GAUGE_PERCENT_MAX_HP_TO_FILL = 0.5
FREEZE_GAUGE_GAINED_PER_DAMAGE_PERCENT = FREEZE_GAUGE_MAX * FREEZE_GAUGE_PERCENT_MAX_HP_TO_FILL

FREEZE_DURATION = 3
--after being frozen, the unit is immune to freeze gauge for a while
FREEZE_IMMUNITY_DURATION = 5

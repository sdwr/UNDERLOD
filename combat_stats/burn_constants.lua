-- burn system constants
BURN_DAMAGE_PERCENT = 0.02  -- 2% max HP per stack per second
BURN_MAX_STACKS = 5
BURN_DURATION_SECONDS = 5
BURN_EXPLOSION_DAMAGE_PERCENT = 0.15  -- 15% max HP explosion damage
BURN_EXPLOSION_RADIUS = 80
BURN_EXPLOSION_KNOCKBACK = 100

BURN_EXPLOSION_BASE_RADIUS = 20
BURN_EXPLOSION_BASE_KNOCKBACK = LAUNCH_PUSH_FORCE_ENEMY * 2/3
BURN_EXPLOSION_BASE_KNOCKBACK_DURATION = 0.3

BURN_THRESHOLD_FOR_INSTANT_EXPLOSION_PERCENT_OF_HP = 0.1
BURN_MIN_EXPLOSION_THRESHOLD_PERCENT_OF_HP = 0.05
BURN_EXPLOSION_POWER_CAP = 0.5
BURN_CANCEL_IF_DPS_BELOW_PERCENT_OF_HP = 0.01

BURN_DPS_DECAY_RATE = 0.05

BURN_EXPECTED_BASELINE_HP = REGULAR_ENEMY_HP

BURN_QUALITY_INPUT_MIN = 1
BURN_QUALITY_INPUT_MAX = BOSS_HP / REGULAR_ENEMY_HP

BURN_QUALITY_OUTPUT_MIN = 0.5
BURN_QUALITY_OUTPUT_MAX = 1.75

function CALCULATE_BURN_QUALITY_FACTOR(baseline_hp)
  local quality_ratio = (baseline_hp / BURN_EXPECTED_BASELINE_HP)
  local quality_ratio_normalized = (quality_ratio - BURN_QUALITY_INPUT_MIN) / (BURN_QUALITY_INPUT_MAX - BURN_QUALITY_INPUT_MIN)
  local normalized_quality = math.clamp(quality_ratio_normalized, 0, 1)

  -- By taking the square root, we apply a non-linear "ease-out" curve.
  -- This makes the initial increase in quality much more significant.
  local eased_quality = math.sqrt(normalized_quality)
  
  local output_range = BURN_QUALITY_OUTPUT_MAX - BURN_QUALITY_OUTPUT_MIN
  local final_quality_factor = BURN_QUALITY_OUTPUT_MIN + (output_range * eased_quality)

  return final_quality_factor
end

BURN_EFFORT_OUTPUT_MIN = 0.5
BURN_EFFORT_OUTPUT_MAX = 1.25

function CALCULATE_BURN_EFFORT_FACTOR(peak_damage, max_hp)
  -- local effort_ratio = peak_damage / max_hp

  -- local output_range = BURN_EFFORT_OUTPUT_MAX - BURN_EFFORT_OUTPUT_MIN
  -- local final_effort_factor = BURN_EFFORT_OUTPUT_MIN + (effort_ratio * output_range)

  -- return final_effort_factor
  return 0
end

--we want to make sure the burn power never exceeds 3
--so soft cap it as it approaches 3
function NORMALIZE_BURN_POWER(power)
   return math.min(power, 3)
end 
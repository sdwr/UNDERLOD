local DPSCalculator = {}

-- Predicted AOE targets by weapon type
DPSCalculator.WEAPON_AOE_TARGETS = {
  machine_gun = 1,    -- Single target only
  lightning = 4,      -- Chains to 4 targets at full damage
  cannon = 3,         -- Splash hits ~3 enemies
  archer = 1,         -- Single target only
  frost_aoe = 4,      -- Area hits ~4 enemies
  frost = 4,          -- Alias for frost_aoe
  laser = 1,          -- Single target
  swordsman = 1,      -- Single target
}

-- Calculate weapon DPS (both single target and AOE)
function DPSCalculator.calculate_weapon_dps(weapon_name, level)
  level = level or 1

  -- Get weapon stats at the specified level
  local stats = weapon_get_stats(weapon_name, level)
  if not stats then
    return 0, 0
  end

  -- Calculate effective attack rate (attacks per second)
  local total_attack_time = (stats.attack_cooldown or 1) + (stats.cast_time or 0)
  local attacks_per_second = 1 / total_attack_time

  -- Calculate single target DPS
  local single_target_dps = (stats.damage or 0) * attacks_per_second

  -- Calculate AOE DPS based on weapon type
  local aoe_targets = DPSCalculator.WEAPON_AOE_TARGETS[weapon_name] or 1
  local aoe_dps = single_target_dps * aoe_targets  -- Lightning does full damage on chains

  return single_target_dps, aoe_dps
end

-- Calculate total DPS for all weapons owned by player (works with arena or buy_screen)
function DPSCalculator.calculate_player_total_dps(state)
  if not state or not state.units then
    return 0, 0
  end

  local total_single_dps = 0
  local total_aoe_dps = 0

  -- Iterate through all player units and their weapons
  for _, unit in ipairs(state.units) do
    if unit.character then
      local weapon_name = unit.character
      local level = unit.level or 1
      local single_dps, aoe_dps = DPSCalculator.calculate_weapon_dps(weapon_name, level)

      -- Multiply by number of weapons at this level
      local num_weapons = UNIT_LEVEL_TO_NUMBER_OF_WEAPONS[level] or 1
      total_single_dps = total_single_dps + (single_dps * num_weapons)
      total_aoe_dps = total_aoe_dps + (aoe_dps * num_weapons)
    end
  end

  return total_single_dps, total_aoe_dps
end

-- Calculate required DPS for a subwave
function DPSCalculator.calculate_subwave_dps(level, wave_index, subwave_index, total_waves, total_subwaves_per_wave)
  -- Get total round power for this level
  local total_round_power = ROUND_POWER_BY_LEVEL(level) or 3000

  -- Wave power distribution (assuming equal split between waves)
  local wave_power = total_round_power / total_waves

  -- Subwave power percentages from SpawnManager
  -- Use global constant if available, otherwise default
  local subwave_percentages = SpawnGlobals and SpawnGlobals.SUBWAVE_POWER_PERCENTAGES or {0.4, 0.6}
  if total_subwaves_per_wave > 2 then
    -- If more than 2 subwaves, distribute evenly
    subwave_percentages = {}
    for i = 1, total_subwaves_per_wave do
      subwave_percentages[i] = 1 / total_subwaves_per_wave
    end
  end

  local subwave_power = wave_power * (subwave_percentages[subwave_index] or 0.5)

  -- Calculate number of enemies based on round power
  -- Each swarmer costs 25 round power
  local swarmer_round_power = enemy_to_round_power['swarmer'] or 25
  local num_swarmers = subwave_power / swarmer_round_power

  -- Calculate total HP
  local enemy_hp = SCALED_ENEMY_HP(level, REGULAR_ENEMY_HP)
  local total_hp = num_swarmers * enemy_hp

  -- Calculate time available
  -- Travel time + spawn window
  local travel_time = SWARMER_TRAVEL_TIME
  local spawn_window = SpawnGlobals and SpawnGlobals.SUBWAVE_SPAWN_WINDOW or 10  -- Use global constant from SpawnManager
  local total_time = travel_time + spawn_window

  -- Required DPS
  local required_dps = total_hp / total_time

  return {
    wave = wave_index,
    subwave = subwave_index,
    power = subwave_power,
    num_enemies = math.floor(num_swarmers),
    enemy_hp = enemy_hp,
    total_hp = total_hp,
    travel_time = travel_time,
    spawn_window = spawn_window,
    total_time = total_time,
    required_dps = required_dps
  }
end

-- Calculate DPS for all waves in a level
function DPSCalculator.calculate_level_dps(level, num_waves, num_subwaves_per_wave)
  num_waves = num_waves or 1
  num_subwaves_per_wave = num_subwaves_per_wave or 2

  local results = {}

  for wave = 1, num_waves do
    for subwave = 1, num_subwaves_per_wave do
      local dps_info = DPSCalculator.calculate_subwave_dps(level, wave, subwave, num_waves, num_subwaves_per_wave)
      table.insert(results, dps_info)
    end
  end

  return results
end

-- Format DPS information for display
function DPSCalculator.format_dps_info(dps_info)
  local lines = {}

  table.insert(lines, string.format("Wave %d-%d DPS Requirements:", dps_info.wave, dps_info.subwave))
  table.insert(lines, string.format("  Round Power: %.0f", dps_info.power))
  table.insert(lines, string.format("  Enemies: %d swarmers", dps_info.num_enemies))
  table.insert(lines, string.format("  Enemy HP: %.0f each", dps_info.enemy_hp))
  table.insert(lines, string.format("  Total HP: %.0f", dps_info.total_hp))
  table.insert(lines, string.format("  Time: %.1fs travel + %.0fs spawn = %.1fs total",
    dps_info.travel_time, dps_info.spawn_window, dps_info.total_time))
  table.insert(lines, string.format("  Required DPS: %.0f", dps_info.required_dps))

  return table.concat(lines, "\n")
end

-- Display current subwave DPS (for F9 key)
function DPSCalculator.display_current_subwave_dps(arena)
  if not arena or not arena.spawn_manager then
    print("[DPSCalculator] No active arena or spawn manager")
    return
  end

  local sm = arena.spawn_manager
  local level = arena.level or 1
  local current_wave = sm.current_wave_index or 1
  local current_subwave = sm.current_subwave_index or 1
  local total_waves = sm.total_waves or 1
  local subwaves_per_wave = sm.subwaves_per_wave or 2

  local dps_info = DPSCalculator.calculate_subwave_dps(level, current_wave, current_subwave, total_waves, subwaves_per_wave)

  print("\n" .. string.rep("=", 50))
  print("CURRENT SUBWAVE DPS CALCULATION")
  print(string.rep("=", 50))
  print(DPSCalculator.format_dps_info(dps_info))
  print(string.rep("=", 50) .. "\n")
end

-- Display all waves DPS (for F key)
function DPSCalculator.display_all_waves_dps(level, num_waves, num_subwaves_per_wave)
  level = level or 1
  num_waves = num_waves or 1
  num_subwaves_per_wave = num_subwaves_per_wave or 2

  local all_dps = DPSCalculator.calculate_level_dps(level, num_waves, num_subwaves_per_wave)

  print("\n" .. string.rep("=", 50))
  print(string.format("LEVEL %d - ALL WAVES DPS REQUIREMENTS", level))
  print(string.rep("=", 50))

  local total_required_dps = 0
  local max_required_dps = 0

  for _, dps_info in ipairs(all_dps) do
    print(DPSCalculator.format_dps_info(dps_info))
    print("")

    total_required_dps = total_required_dps + dps_info.required_dps
    max_required_dps = math.max(max_required_dps, dps_info.required_dps)
  end

  local avg_required_dps = total_required_dps / #all_dps

  print(string.rep("-", 50))
  print("SUMMARY:")
  print(string.format("  Average Required DPS: %.0f", avg_required_dps))
  print(string.format("  Peak Required DPS: %.0f", max_required_dps))
  print(string.format("  Total Round Power: %d", ROUND_POWER_BY_LEVEL(level) or 3000))
  print(string.rep("=", 50) .. "\n")
end

-- Handle F9 key press
function DPSCalculator.handle_f9_press()
  if main and main.current and main.current.current_arena then
    DPSCalculator.display_current_subwave_dps(main.current.current_arena)
  else
    print("[DPSCalculator] No active arena")
  end
end

-- Handle F4 key press
function DPSCalculator.handle_f4_press()
  -- Always display max DPS for all 25 levels
  print("\n" .. string.rep("=", 60))
  print("MAXIMUM DPS REQUIRED PER LEVEL")
  print(string.rep("=", 60))

  local num_waves = SpawnGlobals and SpawnGlobals.TOTAL_WAVES or 1
  local num_subwaves = SpawnGlobals and SpawnGlobals.SUBWAVES_PER_WAVE or 2

  for level = 1, 25 do
    local all_dps = DPSCalculator.calculate_level_dps(level, num_waves, num_subwaves)
    local max_dps = 0

    -- Find the maximum DPS required across all waves and subwaves
    for _, dps_info in ipairs(all_dps) do
      max_dps = math.max(max_dps, dps_info.required_dps)
    end

    local round_power = ROUND_POWER_BY_LEVEL(level)
    if round_power and round_power > 0 then
      print(string.format("Level %2d: Max DPS = %7.0f (Round Power: %6d)",
        level, max_dps, round_power))
    end
  end

  print(string.rep("=", 60))

  -- Display current weapon DPS from arena or buy_screen
  local current_state = nil
  if main and main.current then
    if main.current.current_arena then
      current_state = main.current.current_arena
    elseif main.current.units then  -- Buy screen or other state with units
      current_state = main.current
    end
  end

  if current_state then
    DPSCalculator.display_weapon_dps_summary(current_state)
  end

  print(string.rep("=", 60) .. "\n")
end

-- Display weapon DPS summary for current state (arena or buy_screen)
function DPSCalculator.display_weapon_dps_summary(state)
  print("\nCURRENT WEAPON DPS")
  print(string.rep("-", 60))

  local total_single = 0
  local total_aoe = 0

  if state.units then
    for _, unit in ipairs(state.units) do
      if unit.character then
        local weapon_name = unit.character
        local level = unit.level or 1
        local single_dps, aoe_dps = DPSCalculator.calculate_weapon_dps(weapon_name, level)
        local num_weapons = UNIT_LEVEL_TO_NUMBER_OF_WEAPONS[level] or 1

        local total_weapon_single = single_dps * num_weapons
        local total_weapon_aoe = aoe_dps * num_weapons

        total_single = total_single + total_weapon_single
        total_aoe = total_aoe + total_weapon_aoe

        local display_name = weapon_definitions[weapon_name] and weapon_definitions[weapon_name].display_name or weapon_name
        print(string.format("%-12s (Lv%d x%d): Single=%6.1f  AOE=%6.1f",
          display_name, level, num_weapons, total_weapon_single, total_weapon_aoe))
      end
    end
  end

  print(string.rep("-", 60))
  print(string.format("TOTAL DPS:               Single=%6.1f  AOE=%6.1f", total_single, total_aoe))

  -- Compare to current level requirements (if in arena)
  if state.level then
    local all_dps = DPSCalculator.calculate_level_dps(state.level, 1, 2)
    local max_required = 0
    for _, dps_info in ipairs(all_dps) do
      max_required = math.max(max_required, dps_info.required_dps)
    end

    print(string.rep("-", 60))
    print(string.format("Required DPS for Level %d: %.1f", state.level, max_required))
    print(string.format("Single Target Coverage: %.1f%%", (total_single / max_required) * 100))
    print(string.format("AOE Coverage: %.1f%%", (total_aoe / max_required) * 100))
  elseif state.next_level_index then
    -- In buy screen, use next_level_index
    local level = state.next_level_index
    local all_dps = DPSCalculator.calculate_level_dps(level, 1, 2)
    local max_required = 0
    for _, dps_info in ipairs(all_dps) do
      max_required = math.max(max_required, dps_info.required_dps)
    end

    print(string.rep("-", 60))
    print(string.format("Required DPS for Next Level (%d): %.1f", level, max_required))
    print(string.format("Single Target Coverage: %.1f%%", (total_single / max_required) * 100))
    print(string.format("AOE Coverage: %.1f%%", (total_aoe / max_required) * 100))
  end
end

return DPSCalculator
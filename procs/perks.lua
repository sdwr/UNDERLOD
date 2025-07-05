-- Perks system
-- Perks are global modifiers that affect game behavior through procs

-- Helper function to create a perk at a given level (1, 2, or 3)
function Create_Perk(perk_key, level)
  local perk_def = PERK_DEFINITIONS[perk_key]
  if not perk_def then
    print("Error: Perk definition not found for", perk_key)
    return nil
  end
  level = math.max(1, math.min(3, level or 1))
  local perk = {
    name = perk_def.name,
    description = perk_def.description,
    rarity = perk_def.rarity,
    level = level,
    stats1 = perk_def.stats1,
    stats2 = perk_def.stats2,
    stats3 = perk_def.stats3,
  }
  return perk
end

function Get_Perk_Stats(perk, level)
  if level == 1 then
    return perk.stats1
  elseif level == 2 then
    return perk.stats2
  elseif level == 3 then
    return perk.stats3
  end
  return nil
end

-- Helper function to get a random perk for selection
function Get_Random_Perk_Choice(player_perks, choices)
  local available_perks = {}
  
  -- Create a set of already chosen perk names for quick lookup
  local chosen_names = {}
  for _, perk in ipairs(choices) do
    chosen_names[perk.name] = true
  end
  
  for perk_key, perk_def in pairs(PERK_DEFINITIONS) do
    if not player_perks[perk_def.name] and not chosen_names[perk_def.name] then
      table.insert(available_perks, perk_key)
    end
  end
  
  if #available_perks == 0 then
    print("No more perks available")
    return nil
  end
  
  local random_index = math.random(1, #available_perks)
  local selected_perk_key = available_perks[random_index]
  return Create_Perk(selected_perk_key, 1)
end

-- Helper function to get multiple random perk choices
function Get_Random_Perk_Choices(player_perks)
  count = 3
  local choices = {}
  for i = 1, count do
    local perk = Get_Random_Perk_Choice(player_perks, choices)
    if perk then
      table.insert(choices, perk)
    else
      break
    end
  end
  return choices
end


PERK_DEFINITIONS = {
  volcano = {
    name = "Volcano",
    description = "Fire explosions deal area damage",
    icon = "volcano",
    rarity = "common",
    stats1 = {chance_to_proc = 0.2, damage = 10, radius = 30, duration = 1.5},
    stats2 = {chance_to_proc = 0.3, damage = 15, radius = 40, duration = 2},
    stats3 = {chance_to_proc = 0.4, damage = 22, radius = 50, duration = 2.5},
    proc_name = "volcano"
  },
  
  flat_mvspd = {
    name = "Swift Movement",
    description = "+1/+2/+3 movement speed to all troops",
    icon = "swift_movement",
    rarity = "common",
    stats1 = {mvspd = 1},
    stats2 = {mvspd = 2},
    stats3 = {mvspd = 3}
  },
  
  fire_mastery = {
    name = "Fire Mastery",
    description = "Fire damage increased by 25%/40%/60%",
    icon = "fire_mastery",
    rarity = "rare",
    stats1 = {fire = 0.25},
    stats2 = {fire = 0.4},
    stats3 = {fire = 0.6}
  },
  
  lucky_strikes = {
    name = "Lucky Strikes",
    description = "5%/10%/15% chance to deal double damage",
    icon = "lucky_strikes",
    rarity = "rare",
    stats1 = {chance_to_proc = 0.05, damage_multiplier = 2.0},
    stats2 = {chance_to_proc = 0.10, damage_multiplier = 2.0},
    stats3 = {chance_to_proc = 0.15, damage_multiplier = 2.0},
    proc_name = "lucky_strikes"
  }
}
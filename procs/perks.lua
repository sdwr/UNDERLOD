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

function Get_Perk_Stats(perk)
  if perk.level == 1 then
    return perk.stats1 or {}
  elseif perk.level == 2 then
    return perk.stats2 or {}
  elseif perk.level == 3 then
    return perk.stats3 or {}
  end
  return {}
end

function Get_Perk_Max_Level(perk)
  if perk.stats3 then
    return 3
  elseif perk.stats2 then
    return 2
  end
  return 1
end

function Can_Perk_Level_Up(perk)
  return perk.level < Get_Perk_Max_Level(perk)
end

function Perk_Level_Up_Cost(perk)
  if perk.level == 1 then
    return 10
  elseif perk.level == 2 then
    return 15
  else 
    return 999
  end
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
  --generic unit perks
  movespeed = {
    name = "Movespeed",
    description = "+10%/15%/20% movement speed",
    icon = "swift_movement",
    rarity = "common",
    stats1 = {mvspd = 0.1},
    stats2 = {mvspd = 0.15},
    stats3 = {mvspd = 0.2},
  },
  health = {
    name = "Health",
    description = "+25%/35%/45% health",
    icon = "health",
    rarity = "common",
    stats1 = {hp = 0.25},
    stats2 = {hp = 0.35},
    stats3 = {hp = 0.45},
  },
  range = {
    name = "Range",
    description = "+10%/15%/20% range",
    icon = "range",
    rarity = "common",
    stats1 = {range = 0.1},
    stats2 = {range = 0.15},
    stats3 = {range = 0.2},
  },
  attack_speed = {
    name = "Attack Speed",
    description = "+10%/15%/20% attack speed",
    icon = "attack_speed",
    rarity = "common",
    stats1 = {aspd = 0.1},
    stats2 = {aspd = 0.15},
    stats3 = {aspd = 0.2},
  },
  double_attack_chance = {
    name = "Double Attack Chance",
    description = "+8%/12%/16% chance to attack twice",
    icon = "double_attack_chance",
    rarity = "common",
    stats1 = {repeat_attack_chance = 0.08},
    stats2 = {repeat_attack_chance = 0.12},
    stats3 = {repeat_attack_chance = 0.16},
  },
  crit_chance = {
    name = "Crit Chance",
    description = "+10%/15%/20% crit chance",
    icon = "crit_chance",
    rarity = "common",
    stats1 = {crit_chance = 0.1},
    stats2 = {crit_chance = 0.15},
    stats3 = {crit_chance = 0.2},
  },
  crit_mult = {
    name = "Crit Damage",
    description = "+25%/35%/50% crit damage",
    icon = "crit_mult",
    rarity = "common",
    stats1 = {crit_mult = 0.25},
    stats2 = {crit_mult = 0.35},
    stats3 = {crit_mult = 0.5},
  },
  stun_chance = {
    name = "Stun Chance",
    description = "+8%/12%/16% stun chance on attack",
    icon = "stun_chance",
    rarity = "common",
    stats1 = {stun_chance = 0.08},
    stats2 = {stun_chance = 0.12},
    stats3 = {stun_chance = 0.16},
  },
  knockback_resistance = {
    name = "Knockback Resistance",
    description = "+30%/45%/60% knockback resistance",
    icon = "knockback_resistance",
    rarity = "common",
    stats1 = {knockback_resistance = 0.3},
    stats2 = {knockback_resistance = 0.45},
    stats3 = {knockback_resistance = 0.6},
  },
  area_size = {
    name = "Area Size",
    description = "+20%/30%/40% area size",
    icon = "area_size",
    rarity = "common",
    stats1 = {area_size = 0.2},
    stats2 = {area_size = 0.3},
    stats3 = {area_size = 0.4},
  },
  area_damage = {
    name = "Area Damage",
    description = "+20%/30%/40% area damage",
    icon = "area_damage",
    rarity = "common",
    stats1 = {area_dmg = 0.2},
    stats2 = {area_dmg = 0.3},
    stats3 = {area_dmg = 0.4},
  },
  cooldown_reduction = {
    name = "Cooldown Reduction",
    description = "Your active abilities recharge 20%/30%/40% faster",
    icon = "cooldown_reduction",
    rarity = "common",
    stats1 = {cooldown_reduction = 0.2},
    stats2 = {cooldown_reduction = 0.3},
    stats3 = {cooldown_reduction = 0.4},
  },
  chain_attack = {
    name = "Chain Attack",
    description = "Your chain attacks chain an additional time",
    icon = "chain_attack",
    rarity = "common",
    stats1 = {extra_chain_attacks = 1},
  },

  --generic enemy perks
  enemy_movespeed = {
    name = "Enemy Movespeed",
    description = "-10%/15%/20% enemy movespeed",
    icon = "enemy_movespeed",
    rarity = "common",
    stats1 = {enemy_mvspd = -0.1},
    stats2 = {enemy_mvspd = -0.15},
    stats3 = {enemy_mvspd = -0.2},
  },
  enemy_health = {
    name = "Enemy Health",
    description = "-10%/15%/20% enemy health",
    icon = "enemy_health",
    rarity = "common",
    stats1 = {enemy_hp = -0.1},
    stats2 = {enemy_hp = -0.15},
    stats3 = {enemy_hp = -0.2},
  },
  enemy_health_flat = {
    name = "Enemy Health",
    description = "-15% enemy health",
    icon = "enemy_health",
    rarity = "common",
    stats1 = {enemy_hp = -0.15},
  },
  enemy_damage = {
    name = "Enemy Damage",
    description = "Enemies take +10%/15%/20% more damage",
    icon = "enemy_damage",
    rarity = "common",
    stats1 = {enemy_dmg = 0.1},
    stats2 = {enemy_dmg = 0.15},
    stats3 = {enemy_dmg = 0.2},
  },
  enemy_knockback_damage = {
    name = "Enemy Knockback Damage",
    description = "+30%/45%/60% enemy knockback damage",
    icon = "enemy_knockback_damage",
    rarity = "common",
    stats1 = {enemy_knockback_dmg = 0.3},
    stats2 = {enemy_knockback_dmg = 0.45},
    stats3 = {enemy_knockback_dmg = 0.6},
  },
  enemy_elemental_slow = {
    name = "Enemy Elemental Slow",
    description = "Enemies are slowed by 8%/12%/16% for each elemental affliction",
    icon = "enemy_elemental_slow",
    rarity = "common",
    stats1 = {enemy_elemental_slow = 0.08},
    stats2 = {enemy_elemental_slow = 0.12},
    stats3 = {enemy_elemental_slow = 0.16},
  },

  --generic weird perks
  the_meek = {
    name = "The Meek",
    description = "Your lowest level troop deals 30%/40%/50% more damage",
    icon = "the_meek",
    rarity = "common",
    stats1 = {the_meek = 0.3},
    stats2 = {the_meek = 0.4},
    stats3 = {the_meek = 0.5},
  },
  critter_explosion = {
    name = "Critter Explosion",
    description = "Friendly critters explode on death",
    icon = "critter_explosion",
    rarity = "common",
    proc_name = "critter_explosion",
  },

  
  --generic active perks
  super_saiyan = {
    name = "Super Saiyan",
    description = "The longer a troop goes without attacking, the more damage they deal on their next attack",
    icon = "super_saiyan",
    rarity = "common",
    stats1 = {super_saiyan = 3},
  },
  selfless = {
    name = "Selfless",
    description = "When a unit dies, heal nearby units for 20%/30%/40% of their max health",
    icon = "selfless",
    rarity = "common",
    stats1 = {selfless = 0.2},
    stats2 = {selfless = 0.3},
    stats3 = {selfless = 0.4},
  },
  kamikaze = {
    name = "Kamikaze",
    description = "When a unit dies, knockback and deal 20%/30%/40% of its max health to nearby enemies",
    icon = "kamikaze",
    rarity = "common",
    stats1 = {kamikaze = 0.2},
    stats2 = {kamikaze = 0.3},
    stats3 = {kamikaze = 0.4},
  },
  inspiration = {
    name = "Inspiration",
    description = "When a unit dies, temporarily give nearby units +10%/15%/20% attack speed",
    icon = "inspiration",
    rarity = "common",
    stats1 = {inspiration = 0.1},
    stats2 = {inspiration = 0.15},
    stats3 = {inspiration = 0.2},
    proc_name = "inspiration",
  },

  --generic elemental perks
  elemental_mastery = {
    name = "Elemental Mastery",
    description = "All elemental damage increased by 10%/20%/30%",
    icon = "elemental_mastery",
    rarity = "rare",
    stats1 = {elemental_damage_m = 0.1},
    stats2 = {elemental_damage_m = 0.2},
    stats3 = {elemental_damage_m = 0.3},
  },
  elemental_volatility = {
    name = "Elemental Volatility",
    description = "Your elemental afflictions react with each other on contact, triggering immediately",
    icon = "elemental_volatility",
    rarity = "rare",
  },

  --fire perks
  fire_mastery = {
    name = "Fire Mastery",
    description = "Fire damage increased by 25%/40%/60%",
    icon = "fire_mastery",
    rarity = "rare",
    stats1 = {fire_damage_m = 0.25},
    stats2 = {fire_damage_m = 0.4},
    stats3 = {fire_damage_m = 0.6},
    prereqs = {"fire"}
  },
  volcano = {
    name = "Volcano",
    description = "Fire explosions linger as an AoE",
    icon = "volcano",
    rarity = "common",
    proc_name = "volcano",
    prereqs = {"fire"}
  },

  --cold perks
  cold_mastery = {
    name = "Cold Mastery",
    description = "Cold damage increased by 25%/40%/60%",
    icon = "cold_mastery",
    rarity = "rare",
    stats1 = {cold_damage_m = 0.25},
    stats2 = {cold_damage_m = 0.4},
    stats3 = {cold_damage_m = 0.6},
    prereqs = {"cold"}
  },
  shatterlance = {
    name = "Shatterlance",
    description = "All attacks on frozen enemies are critical strikes",
    icon = "shatterlance",
    rarity = "rare",
    proc_name = "shatterlance",
    prereqs = {"cold"}
  },
  rimeheart = {
    name = "Rimeheart",
    desc = "Killing a [blue]frozen[fg] enemy creates a [blue]ice prison[fg]",
    icon = "rimeheart",
    rarity = "rare",
    proc_name = "rimeheart",
    prereqs = {"cold"}
  },
  waterelemental = {
    name = "Water Elemental",
    description = "When a chilled enemy dies, have a chance to spawn a water elemental",
    icon = "water_elemental",
    rarity = "rare",
    proc_name = "waterelemental",
    prereqs = {"cold"}
  },

  --lightning perks
  lightning_mastery = {
    name = "Lightning Mastery",
    description = "Lightning damage increased by 25%/40%/60%",
    icon = "lightning_mastery",
    rarity = "rare",
    stats1 = {lightning_damage_m = 0.25},
    stats2 = {lightning_damage_m = 0.4},
    stats3 = {lightning_damage_m = 0.6},
    prereqs = {"lightning"}
  },
  --need to cap the number of these that can spawn
  lightning_ball = {
    name = "Lightning Ball",
    description = "Reapplying shock on enemies has a chance to create a lightning ball",
    icon = "lightning_ball",
    rarity = "rare",
    proc_name = "lightning_ball",
    prereqs = {"lightning"}
  },
  sympathetic_voltage = {
    name = "Sympathetic Voltage",
    description = "Shocked enemies share a % of damage taken with nearby shocked enemies",
    icon = "sympathetic_voltage",
    rarity = "rare",
    proc_name = "sympathetic_voltage",
    prereqs = {"lightning"}
  },

  --curse perks
  curse_mastery = {
    name = "Curse Mastery",
    description = "Curse effect increased by 25%/40%/60%",
    icon = "curse_mastery",
    rarity = "rare",
    stats1 = {curse_damage_m = 0.25},
    stats2 = {curse_damage_m = 0.4},
    stats3 = {curse_damage_m = 0.6},
    prereqs = {"curse"}
  },
  curse_of_doom = {
    name = "Curse of Doom",
    description = "When curse expires or is reapplied, deal damage based on the damage taken during the curse",
    icon = "curse_of_doom",
    rarity = "rare",
    proc_name = "curse_of_doom",
    prereqs = {"curse"}
  },
  curse_of_the_dead = {
    name = "Curse of Agony",
    description = "Enemies that die while cursed spread curse to nearby enemies",
    icon = "curse_of_agony",
    rarity = "rare",
    proc_name = "curse_of_agony",
    prereqs = {"curse"}
  },
  curse_chain = {
    name = "Curse Chain",
    description = "Curse chains to 1/2/3 additional enemies",
    icon = "curse_chain",
    rarity = "rare",
    stats1 = {curse_chain = 1},
    stats2 = {curse_chain = 2},
    stats3 = {curse_chain = 3},
    prereqs = {"curse"}
  },
}
-- Global weapon definitions and shop functions

WEAPON_MAX_LEVEL = 3
WEAPON_COPIES_TO_UPGRADE = 2
MAX_OWNED_WEAPONS = 6

-- Weapon definitions with base stats and costs
weapon_definitions = {
  machine_gun = {
    name = 'machine_gun',
    display_name = 'MG',
    cost = 3,
    tier = 1,
    icon = 'repeater',
    description = 'Rapid fire',
    base_stats = {
      attack_cooldown = 0.2,
      cast_time = 0,
      damage = 5,
      attack_range = 60
    }
  },
  
  lightning = {
    name = 'lightning',
    display_name = 'Bolt',
    cost = 4,
    tier = 1,
    icon = 'lightning',
    description = 'Chain attack',
    base_stats = {
      attack_cooldown = 1.0,
      cast_time = 0.1,
      damage = 12,
      attack_range = 70,
      chain_count = 2
    }
  },
  
  cannon = {
    name = 'cannon',
    display_name = 'Cannon',
    cost = 5,
    tier = 1,
    icon = 'bomb',
    description = 'Explosive',
    base_stats = {
      attack_cooldown = 1.2,
      cast_time = 0.15,
      damage = 25,
      attack_range = 60
    },
    default_items = {{procs = {'splash'}}}
  },
  
  archer = {
    name = 'archer',
    display_name = 'Bow',
    cost = 2,
    tier = 1,
    icon = 'bow',
    description = 'Projectile',
    base_stats = {
      attack_cooldown = 0.6,
      cast_time = 0.1,
      damage = 8,
      attack_range = 80
    }
  },
  
  frost_aoe = {
    name = 'frost_aoe',
    display_name = 'Frost',
    cost = 6,
    tier = 1,
    icon = 'gem',
    description = 'Area freeze',
    base_stats = {
      attack_cooldown = 2.0,
      cast_time = 0.3,
      damage = 15,
      attack_range = 60,
      area_radius = 30
    }
  },
  
  laser = {
    name = 'laser',
    display_name = 'Laser',
    cost = 4,
    tier = 1,
    icon = 'laser',
    description = 'Beam attack',
    base_stats = {
      attack_cooldown = 1.5,
      cast_time = 0,
      damage = 20,
      attack_range = 120
    }
  }
}

-- Get list of all weapon names
function Get_All_Weapon_Names()
  local names = {}
  for name, _ in pairs(weapon_definitions) do
    table.insert(names, name)
  end
  return names
end

-- Get random weapons for shop based on tier weights
function Get_Random_Shop_Weapons(count, exclude_owned)
  count = count or 3
  exclude_owned = exclude_owned or {}
  
  local available = {}
  for name, def in pairs(weapon_definitions) do
    -- Don't exclude owned weapons - players can buy duplicates to upgrade
    table.insert(available, name)
  end
  
  -- Shuffle and pick
  local selected = {}
  for i = 1, math.min(count, #available) do
    local index = random:int(1, #available - i + 1)
    table.insert(selected, available[index])
    table.remove(available, index)
  end
  
  return selected
end

-- Get weapon definition
function Get_Weapon_Definition(weapon_name)
  return weapon_definitions[weapon_name]
end

-- Calculate weapon stats at a given level
function Calculate_Weapon_Stats_At_Level(weapon_name, level)
  local def = weapon_definitions[weapon_name]
  if not def then return {} end
  
  local stats = table.copy(def.base_stats)
  
  -- Level scaling: +25% damage per level, -10% cooldown per level
  if level > 1 then
    local level_mult = level - 1
    stats.damage = stats.damage * (1 + 0.25 * level_mult)
    stats.attack_cooldown = stats.attack_cooldown * (1 - 0.1 * level_mult)
    stats.attack_cooldown = math.max(0.1, stats.attack_cooldown) -- Min cooldown
  end
  
  return stats
end

-- Get cost for a weapon
function Get_Weapon_Cost(weapon_name)
  local def = weapon_definitions[weapon_name]
  if not def then return 999 end
  
  return def.cost
end
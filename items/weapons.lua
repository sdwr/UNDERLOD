require 'items/equipment_tiers'

-- Units retain their levels and equipment when replacing a weapon. Selling
-- any copy still grants unit XP; copies improve that weapon's damage only.
WEAPON_KEYS = {'archer', 'shotgun', 'crossbow', 'cannon', 'radiance', 'orbit', 'laser', 'lightning', 'meteor'}
WEAPON_LEVEL_DMG_MULT = {1, 1.6, 2.2}
WEAPON_ITEM_ROLL_CHANCE = 0.25 -- individual drops; shops always have one weapon
WEAPON_ITEM_COST = EQUIPMENT_WEAPON_COSTS[1]
SHOTGUN_PELLET_COUNT = SHOTGUN_PELLET_COUNT or 5
SHOTGUN_HALF_SPREAD = SHOTGUN_HALF_SPREAD or math.pi / 16
SHOTGUN_PELLET_MAX_DISTANCE_MULT = SHOTGUN_PELLET_MAX_DISTANCE_MULT or 1.3

WEAPON_DEFS = {
  archer = {name = 'Archer', tier = 1, color = 'yellow', description = 'Fast homing arrows',
    range = function() return TROOP_ARCHER_RANGE end, cooldown = 0.6, dmg_mult = 1},
  shotgun = {name = 'Shotgun', tier = 1, color = 'red', description = 'Five close-range pellets',
    range = function() return TROOP_SHOTGUN_RANGE end, cooldown = 1.4, dmg_mult = 0.45},
  crossbow = {name = 'Crossbow', tier = 1, color = 'green', description = 'Heavy bolts pierce 2 extra enemies; slow reload',
    range = function() return TROOP_ARCHER_RANGE * 1.15 end, cooldown = 1.5, dmg_mult = 1.4},
  cannon = {name = 'Cannon', tier = 2, color = 'brown', description = 'Explosive shells hit an area',
    range = function() return TROOP_ARCHER_RANGE end, cooldown = 1.7, dmg_mult = 2, radius = 26},
  radiance = {name = 'Radiance', tier = 2, color = 'red', description = 'Burning pulses; works while moving',
    range = function() return 42 end, cooldown = 0.85, dmg_mult = 0.75, mobile = true, aura = true},
  orbit = {name = 'Orbit', tier = 2, color = 'blue', description = 'Two damage orbs; works while moving',
    range = function() return 32 end, cooldown = 0.5, dmg_mult = 0.65, mobile = true, persistent = true, radius = 6},
  laser = {name = 'Laser', tier = 3, color = 'blue', description = 'Powerful beam pierces every enemy',
    range = function() return TROOP_RANGE * 1.2 end, cooldown = 1.5, dmg_mult = 3},
  lightning = {name = 'Lightning', tier = 3, color = 'yellow', description = 'Lightning ball zaps 3 nearby enemies',
    range = function() return TROOP_ARCHER_RANGE end, cooldown = 1.8, dmg_mult = 0.55, radius = 48},
  meteor = {name = 'Meteor', tier = 3, color = 'orange', description = 'Delayed meteor blasts a large area',
    range = function() return TROOP_ARCHER_RANGE * 1.25 end, cooldown = 2.8, dmg_mult = 4, radius = 38},
}

-- Render colors are independent of the weapon's gameplay/meta color.
local weapon_effect_hex = {
  archer = '#b5dbc1', shotgun = '#efa17e', crossbow = '#e0b66a',
  cannon = '#dda575', radiance = '#f4cc78', orbit = '#b9a0ed',
  laser = '#80d9e5', lightning = '#a7c8ff', meteor = '#f28b70',
}
local weapon_effect_colors = {}
function get_weapon_effect_color(key)
  if not weapon_effect_colors[key] then
    weapon_effect_colors[key] = Color(weapon_effect_hex[key] or '#dadada')
  end
  return weapon_effect_colors[key]
end

function is_weapon_item(item)
  return item and item.weapon and WEAPON_DEFS[item.weapon] and true or false
end

function create_weapon_item(weapon_key)
  local def = WEAPON_DEFS[weapon_key]
  if not def then return nil end
  return {name = def.name, weapon = weapon_key, slot = 'weapon', rarity = 'common',
    tier = def.tier, icon = 'bow', stats = {}, sets = {},
    cost = EQUIPMENT_WEAPON_COSTS[def.tier], procs = {}, tags = {}, colors = {}}
end

function create_random_weapon_item(tier, excluded)
  local candidates = {}
  for _, key in ipairs(WEAPON_KEYS) do
    if WEAPON_DEFS[key].tier == (tier or 1) and not (excluded and excluded['weapon:' .. key]) then
      table.insert(candidates, key)
    end
  end
  if #candidates == 0 then return nil end
  local key = random:table(candidates)
  return key and create_weapon_item(key) or nil
end

function get_unit_weapon_counts(unit, ignore_slot)
  local counts, order, total = {}, {}, 0
  if unit and unit.items then
    for i = 1, (MAX_ITEM_SLOTS or 18) do
      local item = unit.items[i]
      if i ~= ignore_slot and is_weapon_item(item) then
        if not counts[item.weapon] then counts[item.weapon] = 0; table.insert(order, item.weapon) end
        counts[item.weapon] = counts[item.weapon] + 1
        total = total + 1
      end
    end
  end
  return counts, order, total
end

function migrate_unit_to_weapon_items(unit)
  if not unit then return end
  unit.items = unit.items or {}
  -- Preserve owned copies; refresh metadata so old lasers show their real tier.
  for _, item in pairs(unit.items) do
    if is_weapon_item(item) then
      local def = WEAPON_DEFS[item.weapon]
      item.name, item.tier, item.cost = def.name, def.tier, EQUIPMENT_WEAPON_COSTS[def.tier]
    end
  end
  local _, _, total = get_unit_weapon_counts(unit)
  if total == 0 then
    local key = WEAPON_DEFS[unit.character or ''] and unit.character or 'archer'
    for i = 1, (MAX_ITEM_SLOTS or 18) do
      if not unit.items[i] then unit.items[i] = create_weapon_item(key); break end
    end
  end
  unit.character = 'unit'
end

-- Legacy pending shop offers are regenerated on entry, not owned equipment.
function is_current_equipment_offer(item, slot)
  if not item then return true end
  if slot == 3 then
    local def = item.weapon and WEAPON_DEFS[item.weapon]
    return def and item.tier == def.tier and item.cost == EQUIPMENT_WEAPON_COSTS[def.tier]
  end
  local def = item.sets and ITEM_SETS[item.sets[1]]
  return not item.weapon and def and not def.disabled and def.equipment and item.tier == def.tier
    and item.cost == EQUIPMENT_ITEM_COSTS[def.tier]
end

local function projectile_data(troop, damage)
  return {group = main.current.main, spell_duration = 10, bullet_size = 3,
    pierce = troop:get_bonus_pierce(), homing = true, speed = 210, is_troop = true,
    unit = troop, color = get_weapon_effect_color('archer'), damage = damage, volume = 0.6, pitch = 1.4}
end

WEAPON_FIRE = {}
function WEAPON_FIRE.archer(troop, weapon, target, damage_multi, angle)
  local data = projectile_data(troop, weapon.damage * damage_multi)
  if angle then data.angle = angle else data.target = target end
  ArrowProjectile(data)
end

function WEAPON_FIRE.crossbow(troop, weapon, target, damage_multi, angle)
  local data = projectile_data(troop, weapon.damage * damage_multi)
  data.pierce = 2 + troop:get_bonus_pierce()
  data.speed, data.bullet_size, data.color = 160, 5, get_weapon_effect_color('crossbow')
  data.projectile_style = 'crossbow'
  data.max_distance = weapon.range * 1.3
  data.straight_after_hit, data.crit_on_pierce = true, true
  if angle then data.angle = angle else data.target = target end
  ArrowProjectile(data)
end

function WEAPON_FIRE.shotgun(troop, weapon, target, damage_multi, angle)
  local center = angle or math.atan2(target.y - troop.y, target.x - troop.x)
  for _ = 1, SHOTGUN_PELLET_COUNT do
    local data = projectile_data(troop, weapon.damage * damage_multi)
    data.bullet_size, data.homing, data.speed = 2, false, 320
    data.color = get_weapon_effect_color('shotgun')
    data.max_distance = weapon.range * SHOTGUN_PELLET_MAX_DISTANCE_MULT
    data.volume, data.pitch, data.sound_duration = 0.25, 0.95, 0.2
    data.sound_table = {cannoneer1, cannoneer2}
    data.angle = center + random:float(-SHOTGUN_HALF_SPREAD, SHOTGUN_HALF_SPREAD)
    ArrowProjectile(data)
  end
end

function WEAPON_FIRE.laser(troop, weapon, target, damage_multi)
  if not target or target.dead then return end
  Laser_Spell{group = main.current.effects, target = target, unit = troop,
    on_attack_callbacks = false, spell_duration = 0, color = get_weapon_effect_color('laser'),
    aim_color = get_weapon_effect_color('laser'),
    damage = weapon.damage * damage_multi, reduce_pierce_damage = false, weapon_hit = true, length = weapon.range,
    lasermode = 'target', laser_aim_width = 1, laser_width = 8,
    charge_duration = math.max(0.08, 0.3 * troop.aspd_m),
    damage_troops = false, damage_once = true, end_spell_on_fire = false,
    fire_follows_unit = true, fade_fire_draw = true, fade_in_aim_draw = true, silent_charge = true}
end

for _, key in ipairs({'cannon', 'radiance', 'orbit', 'lightning', 'meteor'}) do
  local kind = key
  WEAPON_FIRE[kind] = function(troop, weapon, target, damage_multi)
    local effect = WeaponEffect{group = main.current.main, unit = troop,
      weapon = weapon, kind = kind, target = target, damage_multi = damage_multi or 1}
    if weapon.def.persistent then weapon.effect = effect end
  end
end

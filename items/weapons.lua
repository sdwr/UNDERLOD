-- Weapons are items. A unit's weapons are the weapon items in its inventory:
-- copies of the same weapon stack (MAX_ITEM_STACK deep) and the copy count is
-- the weapon's level. Every weapon fires independently on its own cooldown and
-- range; stats from other items (dmg, aspd, range, procs) apply to all of them.
-- A unit must always hold at least one weapon item.

WEAPON_KEYS = {'archer', 'shotgun', 'laser'}

-- Damage multiplier per weapon level (copies held).
WEAPON_LEVEL_DMG_MULT = {1, 1.6, 2.2}

-- Chance each shop/floor item roll is a weapon instead of a set item.
WEAPON_ITEM_ROLL_CHANCE = 0.25
WEAPON_ITEM_COST = 3

SHOTGUN_PELLET_COUNT = SHOTGUN_PELLET_COUNT or 5
SHOTGUN_HALF_SPREAD = SHOTGUN_HALF_SPREAD or math.pi / 16
SHOTGUN_PELLET_MAX_DISTANCE_MULT = SHOTGUN_PELLET_MAX_DISTANCE_MULT or 1.3

-- dmg_mult is relative to the generic unit's damage (unit_stat_multipliers
-- 'unit' carries the old archer 1.5x), so archer keeps its old numbers.
-- cooldown is the full trigger-to-trigger cycle: the old cast time +
-- cooldown + backswing, since weapons no longer stop the unit to cast.
WEAPON_DEFS = {
  archer = {
    name = 'Archer',
    color = 'yellow',
    description = 'Fast homing arrows',
    range = function() return TROOP_ARCHER_RANGE end,
    cooldown = 0.6,
    dmg_mult = 1,
  },
  shotgun = {
    name = 'Shotgun',
    color = 'red',
    description = SHOTGUN_PELLET_COUNT .. ' pellet short-range blast',
    range = function() return TROOP_SHOTGUN_RANGE end,
    cooldown = 1.75,
    dmg_mult = 0.2,
  },
  laser = {
    name = 'Laser',
    color = 'blue',
    description = 'Slow, charged beam that pierces',
    range = function() return TROOP_RANGE end,
    cooldown = 3.0,
    dmg_mult = 2/3,
  },
}

function is_weapon_item(item)
  return item and item.weapon and WEAPON_DEFS[item.weapon] and true or false
end

function create_weapon_item(weapon_key, tier)
  local def = WEAPON_DEFS[weapon_key]
  if not def then return nil end
  return {
    name = def.name,
    weapon = weapon_key,
    slot = 'weapon',
    rarity = 'common',
    tier = tier or 1,
    icon = 'bow',
    stats = {},
    sets = {},
    cost = WEAPON_ITEM_COST,
    procs = {},
    tags = {},
    colors = {},
  }
end

function create_random_weapon_item(tier)
  return create_weapon_item(WEAPON_KEYS[math.random(1, #WEAPON_KEYS)], tier)
end

-- {weapon_key -> copies}, ordered list of weapon keys (by first slot), total
-- weapon copies. `ignore_slot` leaves that physical index out.
function get_unit_weapon_counts(unit, ignore_slot)
  local counts, order, total = {}, {}, 0
  if unit and unit.items then
    for i = 1, (MAX_ITEM_SLOTS or 18) do
      local item = unit.items[i]
      if i ~= ignore_slot and is_weapon_item(item) then
        if not counts[item.weapon] then
          counts[item.weapon] = 0
          table.insert(order, item.weapon)
        end
        counts[item.weapon] = counts[item.weapon] + 1
        total = total + 1
      end
    end
  end
  return counts, order, total
end

-- Old saves and scripted teams predate weapon items: give them the weapon
-- matching their old character (archer otherwise) and make them generic.
function migrate_unit_to_weapon_items(unit)
  if not unit then return end
  unit.items = unit.items or {}
  local _, _, total = get_unit_weapon_counts(unit)
  if total == 0 then
    local key = WEAPON_DEFS[unit.character or ''] and unit.character or 'archer'
    local slot
    for i = 1, (MAX_ITEM_SLOTS or 18) do
      if not unit.items[i] then slot = i; break end
    end
    if slot then unit.items[slot] = create_weapon_item(key) end
  end
  unit.character = 'unit'
end

-- ------------------------------------------------------------------ firing
-- Each fire function spawns the weapon's attack from `troop` at `target` (or
-- along `angle`). On-attack procs are run by the troop, once per trigger.

local function arrow_spelldata(troop, damage)
  return {
    group = main.current.main,
    spell_duration = 10,
    bullet_size = 3,
    pierce = troop:get_bonus_pierce(),
    homing = true,
    speed = 210,
    is_troop = true,
    unit = troop,
    color = blue[0],
    damage = function() return damage end,
    volume = 0.6,
    pitch = 1.4,
  }
end

local function pellet_spelldata(troop, weapon, damage)
  return {
    group = main.current.main,
    spell_duration = 1.5,
    bullet_size = 2,
    pierce = troop:get_bonus_pierce(),
    homing = false,
    speed = 320,
    is_troop = true,
    unit = troop,
    color = orange[0],
    damage = function() return damage end,
    max_distance = weapon.range * SHOTGUN_PELLET_MAX_DISTANCE_MULT,
    volume = 0.25,
    pitch = 0.95,
    sound_table = {cannoneer1, cannoneer2},
    sound_duration = 0.2,
  }
end

WEAPON_FIRE = {}

function WEAPON_FIRE.archer(troop, weapon, target, damage_multi, angle)
  local data = arrow_spelldata(troop, weapon.damage * damage_multi)
  if angle then data.angle = angle else data.target = target end
  ArrowProjectile(data)
end

function WEAPON_FIRE.shotgun(troop, weapon, target, damage_multi, angle)
  local center = angle or math.atan2(target.y - troop.y, target.x - troop.x)
  for _ = 1, SHOTGUN_PELLET_COUNT do
    local data = pellet_spelldata(troop, weapon, weapon.damage * damage_multi)
    data.angle = center + random:float(-SHOTGUN_HALF_SPREAD, SHOTGUN_HALF_SPREAD)
    ArrowProjectile(data)
  end
end

-- spell_duration 0 keeps the troop out of the channeling state, so the laser
-- charges while the unit keeps moving and firing its other weapons.
function WEAPON_FIRE.laser(troop, weapon, target, damage_multi, angle)
  if not target or target.dead then return end
  local damage = weapon.damage * damage_multi
  Laser_Spell{
    group = main.current.effects,
    target = target,
    on_attack_callbacks = false,
    unit = troop,
    spell_duration = 0,
    color = blue[0],
    damage = function() return damage end,
    reduce_pierce_damage = not Has_Static_Proc(troop, 'pierce'),
    lasermode = 'target',
    laser_aim_width = 1,
    laser_width = 8,
    charge_duration = 0.5,
    damage_troops = false,
    damage_once = true,
    end_spell_on_fire = false,
    fire_follows_unit = true,
    fade_fire_draw = true,
    fade_in_aim_draw = true,
    silent_charge = true,
  }
end

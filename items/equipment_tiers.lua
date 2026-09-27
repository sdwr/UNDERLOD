-- Equipment progression is keyed to the upcoming combat level, not enemy tiers.
EQUIPMENT_TIER_NAMES = {'I', 'II', 'III'}
EQUIPMENT_ITEM_COSTS = {2, 3, 4}
EQUIPMENT_WEAPON_COSTS = {3, 5, 7}
EQUIPMENT_TIER_WEIGHTS = {
  [1] = {100, 0, 0}, [2] = {100, 0, 0}, [3] = {100, 0, 0},
  [4] = {65, 35, 0}, [5] = {45, 55, 0}, [6] = {25, 75, 0},
  [7] = {15, 65, 20}, [8] = {10, 55, 35}, [9] = {5, 45, 50},
  [10] = {0, 30, 70}, [11] = {0, 30, 70},
}

function equipment_tier_weights(level)
  return EQUIPMENT_TIER_WEIGHTS[math.max(1, math.min(11, math.floor(level or 1)))]
end

function roll_equipment_tier(level)
  return random:weighted_pick(unpack(equipment_tier_weights(level)))
end

function equipment_offer_key(item)
  if not item then return nil end
  if item.weapon then return 'weapon:' .. item.weapon end
  return item.sets and item.sets[1]
end

function get_shop_exclusions(items)
  local excluded = {}
  for _, item in pairs(items or {}) do
    local key = equipment_offer_key(item)
    if key then excluded[key] = true end
  end
  return excluded
end

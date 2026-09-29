-- Run from the repository root: luajit tests/item_sets.lua
MAX_ITEM_STACK, MAX_ITEMS, MAX_ITEM_SLOTS = 3, 6, 18
random = {}
function random:float(lo, hi) return lo + (hi - lo) * math.random() end
function random:int(lo, hi) return math.random(lo, hi) end
function random:table(t) return t[self:int(1, #t)] end
function random:weighted_pick(...)
  local weights, sum = {...}, 0
  for _, weight in ipairs(weights) do sum = sum + weight end
  local pick = self:float(0, sum)
  for i, weight in ipairs(weights) do
    if pick < weight then return i end
    pick = pick - weight
  end
end
math.randomseed(7)
dofile('items/items_v2.lua')
dofile('items/weapons.lua')
Helper = {}
dofile('helper/helper_unit.lua')

-- Old saved effects still resolve, but only 5 stat families x 3 tiers roll.
local enabled = 0
for key, def in pairs(ITEM_SETS) do
  if not def.disabled then
    enabled = enabled + 1
    assert(def.equipment and def.tier >= 1 and def.tier <= 3, key)
    assert(#def.bonuses == 3, key .. ' must stack to three copies')
    for _, bonus in ipairs(def.bonuses) do
      assert(bonus.stats and not bonus.procs, key .. ' must be stats only')
      for stat in pairs(bonus.stats) do assert(ITEM_STATS[stat], stat) end
    end
  end
end
assert(enabled == 15)
for _, family in ipairs({'vitality', 'mobility'}) do
  for tier = 1, 3 do
    local key = family .. '_tier_' .. tier
    assert(ITEM_SETS[key].disabled and ITEM_SETS[key].bonuses[1], 'owned ' .. family .. ' must still resolve')
    assert(not is_current_equipment_offer({sets = {key}, tier = tier, cost = EQUIPMENT_ITEM_COSTS[tier]}, 1),
      'saved ' .. family .. ' offers must be replaced')
  end
end
assert(ITEM_SETS[ITEM_SET.SPLASH].disabled and ITEM_SETS[ITEM_SET.SPLASH].bonuses[1])
assert(ITEM_SETS[ITEM_SET.PIERCE].disabled and ITEM_SETS[ITEM_SET.ORBITAL].disabled)

local expected = {
  {100,0,0}, {100,0,0}, {100,0,0}, {65,35,0}, {45,55,0}, {25,75,0},
  {15,65,20}, {10,55,35}, {5,45,50}, {0,30,70}, {0,30,70},
}
for level = 1, 11 do
  local weights = equipment_tier_weights(level)
  for tier = 1, 3 do assert(weights[tier] == expected[level][tier]) end
  local observed = {0,0,0}
  for _ = 1, 1000 do
    local offers, seen = create_random_items(level), {}
    assert(#offers == 3)
    for slot, item in ipairs(offers) do
      assert(is_current_equipment_offer(item, slot), 'invalid offer at ' .. level .. '/' .. slot)
      assert((slot == 3) == is_weapon_item(item), 'slot type changed')
      local key = equipment_offer_key(item)
      assert(not seen[key], 'identical offers'); seen[key] = true
      assert(weights[item.tier] > 0, 'locked or obsolete tier offered')
      observed[item.tier] = observed[item.tier] + 1
      if not item.weapon then
        local def = ITEM_SETS[item.sets[1]]
        assert(not def.disabled and def.min_level <= level)
        assert(item.cost == EQUIPMENT_ITEM_COSTS[item.tier])
      else
        assert(WEAPON_DEFS[item.weapon].tier == item.tier)
        assert(item.cost == EQUIPMENT_WEAPON_COSTS[item.tier])
      end
    end
    -- Simulate a purchased slot refilling beside two retained offers.
    offers[2] = nil
    offers[2] = roll_shop_item(level, get_shop_exclusions(offers), 2)
    assert(offers[2] and not offers[2].weapon)
    assert(equipment_offer_key(offers[1]) ~= equipment_offer_key(offers[2]))
  end
  for tier = 1, 3 do
    assert(math.abs(observed[tier] / 30 - weights[tier]) < 4, 'tier distribution drift')
  end
end

-- Exercise real unit stat aggregation without initializing rendering/physics.
local file = assert(io.open('objects.lua')); local source = file:read('*a'); file:close()
local start = assert(source:find('function Unit:process_set_bonuses_to_stats()', 1, true))
local finish = assert(source:find('function Unit:get_set_procs()', start, true))
Unit = {}; assert(loadstring(source:sub(start, finish - 1)))()
local u = setmetatable({items = {
  {sets = {'power_tier_1'}}, {sets = {'power_tier_2'}}, {sets = {'power_tier_2'}},
  {sets = {'swift_tier_3'}}, {sets = {'mobility_tier_2'}},
}}, {__index = Unit})
local stats = u:process_set_bonuses_to_stats()
assert(math.abs(stats.dmg - 0.90) < 1e-6, 'mixed tiers must add, including copies')
assert(math.abs(stats.aspd - 0.25) < 1e-6)
assert(math.abs(stats.mvspd - 0.08) < 1e-6)
assert(Helper.Unit:unit_distinct_item_count(u) == 4)
assert(Helper.Unit:item_blocked_reason_for_unit(u, {sets = {'power_tier_2'}}) == nil)
u.items[6] = {sets = {'power_tier_2'}}
assert(Helper.Unit:item_blocked_reason_for_unit(u, {sets = {'power_tier_2'}}) == 'stack_full')
local meta = count_team_meta_colors({u})
assert(meta.red == 2, 'different tiers count separately; same-tier copies count once')
local area_unit = {items = {
  {sets = {'area_tier_1'}}, {sets = {'area_tier_1'}}, {sets = {'area_tier_2'}},
}}
assert(count_team_meta_colors({area_unit}).brown == 2)
local other_area_unit = {items = {{sets = {'area_tier_1'}}}}
assert(count_team_meta_colors({area_unit, other_area_unit}).brown == 3)
assert(get_team_meta_stats({area_unit, other_area_unit}).area_size == 0.10,
  'separate tiers and units must activate the three-item meta bonus')

-- Replacements preserve roster identity and refresh old weapon metadata.
local old = {character = 'unit', level = 2, xp = 3, items = {
  {weapon = 'laser', tier = 1, cost = 2}, {sets = {ITEM_SET.SPLASH}},
}}
migrate_unit_to_weapon_items(old)
assert(old.items[1].tier == 3 and old.items[1].cost == 7)
assert(old.level == 2 and old.xp == 3 and old.items[2].sets[1] == ITEM_SET.SPLASH)
assert(not is_current_equipment_offer(old.items[2], 1), 'old shop proc must be replaced')
assert(create_weapon_item('crossbow').cost == 3 and create_weapon_item('crossbow').tier == 1)
assert(create_random_weapon_item(1, {['weapon:archer'] = true, ['weapon:shotgun'] = true}).weapon == 'crossbow')
assert(create_random_weapon_item(1, {['weapon:archer'] = true, ['weapon:shotgun'] = true, ['weapon:crossbow'] = true}) == nil)
print('item_sets: tier odds, slot composition, stacking, stats, and migration passed')

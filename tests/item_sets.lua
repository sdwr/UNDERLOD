-- Run from the repository root: luajit tests/item_sets.lua
-- Sanity checks on the item set table without loading the game.
random = {}
function random:float(lo, hi) return lo + (hi - lo) * math.random() end
function random:int(lo, hi) return math.random(lo, hi) end
function random:table(t) return t[self:int(1, #t)] end
function random:weighted_pick(...) return 1 end
table.find = function(t, v) for i, x in ipairs(t) do if x == v then return i end end end
table.copy = function(t) local o = {} for k, v in pairs(t) do o[k] = v end return o end
math.randomseed(7)
dofile('items/items_v2.lua')

-- Proc names registered in procs.lua, read from the source.
local f = assert(io.open('procs/procs.lua')); local src = f:read('*a'); f:close()
local registry = src:match('proc_name_to_class = (%b{})')
local known_procs = {}
for name in registry:gmatch("%['([%w_]+)'%]%s*=") do known_procs[name] = true end

local colors = {red = true, yellow = true, blue = true, brown = true, purple = true, green = true}
local enabled, commons, rares = 0, 0, 0
for key, def in pairs(ITEM_SETS) do
  assert(def.name, key .. ' has no name')
  assert(colors[def.color], key .. ' has unknown color ' .. tostring(def.color))
  assert(def.rarity == ITEM_RARITY.COMMON or def.rarity == ITEM_RARITY.RARE, key .. ' bad rarity')
  local n = 0
  for i = 1, MAX_SET_BONUS_PIECES or 6 do
    local bonus = def.bonuses[i]
    if bonus then
      n = i
      assert(def.descriptions[i], key .. ' missing description for tier ' .. i)
      for _, proc in ipairs(bonus.procs or {}) do
        assert(known_procs[proc], key .. ' references unknown proc ' .. proc)
      end
      for stat in pairs(bonus.stats or {}) do
        assert(ITEM_STATS[stat], key .. ' references unknown stat ' .. stat)
      end
    end
  end
  assert(n > 0, key .. ' has no bonuses')
  if not def.disabled then
    enabled = enabled + 1
    if def.rarity == ITEM_RARITY.COMMON then
      commons = commons + 1
      assert(n == 3, key .. ': commons are 3-piece stat sets')
      for i = 1, 3 do assert(def.bonuses[i].stats and not def.bonuses[i].procs, key .. ' common tier ' .. i .. ' must be stats only') end
    else
      rares = rares + 1
      assert(n <= 2, key .. ': rares are at most 2 pieces (got ' .. n .. ')')
    end
  end
end
assert(commons == 7, 'expected 7 common sets, got ' .. commons)
assert(rares == 18, 'expected 18 rare sets, got ' .. rares)

-- Disabled sets never roll, at any rarity or tier.
for _ = 1, 2000 do
  local rarity = math.random() < 0.5 and ITEM_RARITY.COMMON or ITEM_RARITY.RARE
  local key = get_random_set(rarity, math.random(1, 2))
  assert(key and not ITEM_SETS[key].disabled, 'rolled disabled set ' .. tostring(key))
  assert(ITEM_SETS[key].rarity == rarity, 'rolled wrong rarity')
end
-- Tier 1 never sees tier-2 sets.
for _ = 1, 500 do
  local key = get_random_set(ITEM_RARITY.RARE, 1)
  assert((ITEM_SETS[key].min_tier or 1) <= 1, 'tier 1 rolled ' .. key)
end

-- Meta colors map to a stat and a label, and counting dedupes per unit.
for _, color in ipairs(META_COLORS) do
  assert(META_COLOR_TO_STAT[color], color .. ' has no meta stat')
  assert(META_COLOR_LABEL[color], color .. ' has no meta label')
end
local units = {
  {items = {{sets = {ITEM_SET.DAMAGE}}, {sets = {ITEM_SET.DAMAGE}}, {sets = {ITEM_SET.VITALITY}}}},
  {items = {{sets = {ITEM_SET.DAMAGE}}, {sets = {ITEM_SET.FOCUS}}}},
}
local counts = count_team_meta_colors(units)
assert(counts.red == 3, 'red should count once per set per unit, got ' .. counts.red)
assert(counts.green == 1, 'green should be 1, got ' .. tostring(counts.green))

-- Cumulative stat totals match the descriptions' headline numbers.
local function total(set, stat, pieces)
  local sum = 0
  for i = 1, pieces do sum = sum + (ITEM_SETS[set].bonuses[i].stats[stat] or 0) * ITEM_STATS[stat].increment end
  return sum
end
local function near(a, b) return math.abs(a - b) < 1e-6 end
assert(near(total(ITEM_SET.DAMAGE, 'dmg', 3), 0.6))
assert(near(total(ITEM_SET.ASPD, 'aspd', 3), 0.3))
assert(near(total(ITEM_SET.CRIT, 'crit_chance', 3), 0.45))
assert(near(total(ITEM_SET.VITALITY, 'hp', 3), 0.6))
assert(near(total(ITEM_SET.VOLT, 'lightning_damage', 3), 18))
assert(near(total(ITEM_SET.REPEAT, 'repeat_attack_chance', 2), 0.7))

print('item set tests passed: ' .. enabled .. ' enabled sets (' .. commons .. ' common, ' .. rares .. ' rare)')

-- Run from the repository root: luajit tests/item_stacking.lua
-- Inventory stacking rules: copies of one item stack up to MAX_ITEM_STACK and
-- count once toward the MAX_ITEMS distinct-item cap.
Helper = {}
dofile('helper/helper_unit.lua')
MAX_ITEMS = 6
MAX_ITEM_STACK = 3
MAX_ITEM_SLOTS = MAX_ITEMS * MAX_ITEM_STACK
-- Set-bonus helpers referenced by find_available_inventory_slot; no 1/1 sets here.
function Helper.Unit:is_one_piece_set(set_key) return set_key == 'one_piece' end

local function item(set) return {name = 'x', sets = set and {set} or {}} end
local function unit(...)
  local u = {level = 1, items = {}}
  for i, it in ipairs({...}) do u.items[i] = it end
  return u
end
local H = Helper.Unit

-- three copies of one set = one distinct entry
local u = unit(item('a'), item('a'), item('a'))
assert(H:unit_distinct_item_count(u) == 1, 'stack counts once')
assert(H:item_blocked_reason_for_unit(u, item('a')) == 'stack_full', '4th copy blocked')
assert(H:item_blocked_reason_for_unit(u, item('b')) == nil, 'new item fits')

-- six distinct entries block a seventh, but not more copies of an existing one
u = unit(item('a'), item('b'), item('c'), item('d'), item('e'), item('f'), item('a'))
assert(H:unit_distinct_item_count(u) == 6)
assert(H:item_blocked_reason_for_unit(u, item('g')) == 'full', '7th distinct blocked')
assert(H:item_blocked_reason_for_unit(u, item('a')) == nil, '3rd copy of a fits at 6/6')
assert(H:first_open_item_slot(u) == 8)

-- set-less items group together
u = unit(item(nil), item(nil), item(nil))
assert(H:item_blocked_reason_for_unit(u, item(nil)) == 'stack_full')

-- ignore_slot: vacating a slot frees its entry
u = unit(item('a'), item('a'), item('a'))
assert(H:item_blocked_reason_for_unit(u, item('a'), 2) == nil, 'swap out one copy, take one in')

-- find_available_inventory_slot: stacking pass piles onto the unit that has most
local u1, u2 = unit(item('a')), unit()
local pick, slot = H:find_available_inventory_slot({u1, u2}, item('a'))
assert(pick == u1 and slot == 2, 'stacks onto existing holder')
u1.items[2], u1.items[3] = item('a'), item('a')
pick, slot = H:find_available_inventory_slot({u1, u2}, item('a'))
assert(pick == u2 and slot == 1, 'full stack falls through to next unit')
-- spread pass counts distinct entries, so a 3/3 unit still looks emptier than 2 singles
u1 = unit(item('a'), item('a'), item('a'))
u2 = unit(item('b'), item('c'))
pick = H:find_available_inventory_slot({u1, u2}, item('z'))
assert(pick == u1, 'spread by distinct count')

-- blocked text
u1 = unit(item('a'), item('a'), item('a'))
u2 = unit(item('a'), item('a'), item('a'))
assert(H:item_blocked_reason({u1, u2}, item('a')) == 'stack_full')
u2 = unit(item('b'), item('c'), item('d'), item('e'), item('f'), item('g'))
assert(H:item_blocked_reason({u1, u2}, item('h')) == 'full')
assert(H:blocked_reason_text('stack_full') == 'already 3/3 of this item')

print('item_stacking: ok')

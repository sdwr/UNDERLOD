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

-- weapons: stack by weapon type, count toward the cap, never drop to zero
dofile('items/weapons.lua')
local function weapon(key) return create_weapon_item(key) end
u = unit(weapon('archer'), weapon('archer'), weapon('shotgun'), item('a'))
assert(H:unit_distinct_item_count(u) == 3, 'weapons group by type')
assert(H:item_group_key(weapon('laser')) == 'weapon:laser')
local counts, order, total = get_unit_weapon_counts(u)
assert(counts.archer == 2 and counts.shotgun == 1 and total == 3 and order[1] == 'archer')
assert(not H:would_leave_no_weapons(u, 1), 'other weapons remain')
assert(not H:would_leave_no_weapons(u, 4), 'non-weapon never blocks')
u = unit(weapon('archer'), item('a'))
assert(H:would_leave_no_weapons(u, 1), 'last weapon blocked')
assert(not H:would_leave_no_weapons(u, 1, weapon('laser')), 'swap for a weapon is fine')
assert(H:would_leave_no_weapons(u, 1, item('b')), 'swap for a non-weapon is blocked')
assert(H:blocked_reason_text('last_weapon') == 'units need at least 1 weapon')
-- auto-buy sends a weapon to the unit holding the most copies of it
u1 = unit(weapon('archer'))
u2 = unit(weapon('laser'), weapon('laser'))
pick = H:find_available_inventory_slot({u1, u2}, weapon('laser'))
assert(pick == u2, 'weapon stacks onto its holder')
pick = H:find_available_inventory_slot({u1, u2}, weapon('shotgun'))
assert(pick == u1, 'new weapon spreads by distinct count')
-- old saves: a unit with no weapon gets its character's weapon
u = {character = 'laser', items = {item('a')}}
migrate_unit_to_weapon_items(u)
assert(u.items[2] and u.items[2].weapon == 'laser' and u.character == 'unit', 'migrated')
u = {character = 'swordsman', items = {}}
migrate_unit_to_weapon_items(u)
assert(u.items[1].weapon == 'archer', 'unknown character falls back to archer')

-- weapons count toward meta colors once per type per unit
dofile('items/items_v2.lua')
local meta = count_team_meta_colors({
  {items = {weapon('archer'), weapon('archer'), weapon('laser')}},
  {items = {weapon('archer'), weapon('shotgun')}},
})
assert(meta.yellow == 2 and meta.blue == 1 and meta.red == 1, 'weapon meta colors')
assert(get_item_meta_colors(weapon('shotgun'))[1] == 'red')

print('item_stacking: ok')

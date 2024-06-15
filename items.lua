

--items are actually created from the data in objects.lua on units
--this is just a way to create them from the shop

function Create_Item(name)
  if not item_to_item_data[name] then
    print('item not found')
    return nil
  end

  return Item(item_to_item_data[name])
end

Item = Object:extend()
function Item:init(data)
  self.name = data.name
  --unit will be nil, because the unit doesn't exist yet (is created in arena)
  self.unit = data.unit or {}
  self.colors = data.colors
  self.cost = data.cost
  self.icon = data.icon
  self.desc = data.desc
  self.stats = data.stats
  self.procs = {}
  --creates procs from the data, but this doesnt work on the unit
  -- (because the unit doesn't exist yet)

  --hack that this loads during combat and in the shop
  --combat expects the unit to exist, but the shop doesn't
  if data.procs then
    for k, v in pairs(data.procs) do
      table.insert(self.procs, Create_Proc(v, nil, nil))
    end
  end
end

function Item:add_proc(unit)
  for i, proc in ipairs(self.procs) do
    local proc_copy = deepcopy(proc)
    table.insert(unit.procs, proc_copy)
  end
end

function Item:sell()
  for i, proc in ipairs(self.procs) do
    proc:onSell()
  end
  self:die()
end

function Item:die()
  for i, proc in ipairs(self.procs) do
    proc:die()
  end
  self.procs = nil
  self.dead = true
end

--TODO: put buy_screen draw in here?
-- or at least change where it gets the item data from

--preqreqs should be inclusive (any of the prereqs) or exclusive (all of the prereqs)??
--should maaaaaybe have tag prereqs (like 'can deal fire damage')

--consumes units as unit_data (probably)
--returns items as item_data
function Get_Random_Item(shop_level, units)
  local available_items = {}
  --TODO: change weighting based on level (item tier)

  --for now, find out which items we have the prerequisites for
  --build a hashtable of the items that are already owned
  local owned_items = {}
  if not units then
    print('no units in Get_Random_Item')
  end

  for i, unit in ipairs(units) do
    if not unit.items then
      print('no items in Get_Random_Item')
    end
    for j, item in ipairs(unit.items) do
      
      owned_items[item.name] = true
      --add item tags as well
      if item.tags then
        for k, tag in ipairs(item.tags) do
          owned_items[tag] = true
        end
      end
    end
  end

  --only add items where all prereqs are owned
  for k, v in pairs(item_to_item_data) do
    if v.prereqs and #v.prereqs > 0 then
      local has_prereqs = true
      for i, prereq in ipairs(v.prereqs) do
        if not owned_items[prereq] then
          has_prereqs = false
          break
        end
      end
      if has_prereqs then
        table.insert(available_items, v)
      end
    else
      table.insert(available_items, v)
    end
  end

  if #available_items == 0 then
    print('no available items')
    return nil
  end

  return get_random_from_table(available_items)
end



--how to trigger consumable items?
  --shop effects (reroll levels)
  --in game effects (heal when < 50% hp)
  --for one level effects (start with a shield)
--in game effects could be a proc that destroys the item when it triggers
--shop effects should trigger on sell (just make sure to get 0 gold back)
item_to_item_data = {

  --consumable items
  
  --rerolls the next level (just the one?)
  --if using level mods, reroll all the mods or just within the same type?
  ['rerollpotion'] = {
    name = 'rerollpotion',
    colors = {},
    cost = 2,
    consumable = true,
    icon = 'flask',
    desc = 'Reroll the upcoming levels when you drink this potion',
    stats = {},
    procs = {'reroll'}
  },
  ['berserkpotion'] = {
    name = 'berserkpotion',
    colors = {},
    cost = 2,
    consumable = true,
    icon = 'potion2',
    desc = 'Gain attack speed and damage for the first 10 seconds of the next round when you drink this potion',
    stats = {},
    procs = {'berserk'}
  },
  --colorless items
  ['craggyvest'] = {
    name = 'craggyvest',
    colors = {},
    cost = 5,
    icon = 'fancyarmor',
    desc = 'A vest that increases armor',
    stats = {hp = 0.25, thorns = 0.2 },
    procs = {'craggy'}
  },
  ['heartofgold'] = {
    name = 'heartofgold',
    colors = {},
    cost = 5,
    icon = 'heartofgold',
    desc = 'A heart that increases health',
    stats = {hp = 0.2, gold = 2}
  },
  ['stockmarket'] = {
    name = 'stockmarket',
    colors = {},
    cost = 5,
    icon = 'linegoesup',
    desc = 'Gain interest on your gold (1 gold per 10 gold)',
    stats = {hp = 0.2, interest = 1}
  },
  ['basher'] = {
  name = 'basher',
    colors = {},
    cost = 10,
    icon = 'mace',
    desc = 'A weapon that stuns enemies',
    stats = {bash = 0.2, dmg = 0.5},
    procs = {'bash'}
  },
  ['healingleaf'] = {
    name = 'healingleaf',
    colors = {},
    cost = 5,
    icon = 'healingleaf',
    desc = 'Heals this unit every 5 seconds',
    stats = {hp = 0.2},
    procs = {'heal'}
  },
  ['overkill'] = {
    name = 'overkill',
    colors = {},
    cost = 10,
    icon = 'overkill',
    desc = 'Enemies that are overkilled explode for a % of their max health',
    stats = {dmg = 0.5},
    procs = {'overkill'}
  },
  ['bloodlust'] = {
    name = 'bloodlust',
    colors = {},
    cost = 5,
    icon = 'bloodlust',
    desc = 'Get attackspeed and movespeed when you kill an enemy',
    stats = {dmg = 0.5},
    procs = {'bloodlust'}
  },
  ['repeater'] = {
    name = 'repeater',
    colors = {},
    cost = 10,
    icon = 'repeater',
    desc = 'Greatly increases attack speed',
    stats = {aspd = 0.5},
    procs = {}
  },

  --yellow items
  ['medbow'] = {
    name = 'medbow',
    colors = {'yellow'},
    cost = 5,
    icon = 'medbow',
    desc = 'A bow that shoots chain lightning',
    stats = {aspd = 0.25},
    procs = {'lightning'},
    tags = {'lightningdmg'}
  },
  ['staticboots'] = {
    name = 'staticboots',
    colors = {'yellow'},
    cost = 5,
    icon = 'simpleboots',
    desc = 'Increase movespeed and charge up lightning attacks',
    stats = {mvspd = 0.15},
    procs = {'static'},
    tags = {'lightningdmg'}
  },
  ['radiance'] = {
    name = 'radiance',
    colors = {'yellow'},
    cost = 5,
    icon = 'sun',
    desc = 'Gain a shield and a damage aura',
    stats = {hp = .1},
    procs = {'radiance', 'shield'}
  },
  --still need to add
  ['bubble'] = {
    name = 'bubble',
    colors = {'yellow'},
    cost = 5,
    icon = 'bubblewand',
    desc = 'Periodically create a bubble shield around you that blocks all damage',
    stats = {hp = 0.1},
    procs = {'bubble'}
  },

  --red items
  ['firesword'] = {
    name = 'firesword',
    colors = {'red'},
    cost = 5,
    icon = 'sword',
    desc = 'A sword that burns enemies',
    stats = {dmg = 0.5},
    procs = {'fire'},
    tags = {'firedmg'}
  },
  ['chainexplosion'] = {
    name = 'chainexplosion',
    colors = {'red'},
    cost = 10,
    icon = 'sun',
    desc = 'Explodes burning enemies when they die for 10% of their max health',
    stats = {dmg = 0.5},
    procs = {'chainexplode'},
    prereqs = {'firedmg'}
  },
  ['firestacker'] = {
    name = 'firestacker',
    colors = {'red'},
    cost = 10,
    icon = 'gem',
    desc = 'A sword that lets fire damage stack',
    stats = {dmg = 0.5},
    procs = {'firestack'},
    prereqs = {'firedmg'}
  },
  ['blazin'] = {
    name = 'blazin',
    colors = {'red'},
    cost = 5,
    icon = 'fire',
    desc = 'Gain aspd per burning enemy',
    stats = {dmg = 0.5},
    procs = {'blazin'},
    prereqs = {'firedmg'}
  },

  --blue items
  ['frostorb'] = {
    name = 'frostorb',
    colors = {'blue'},
    cost = 5,
    icon = 'frostorb',
    desc = 'An orb that slows enemies',
    stats = {dmg = 0.5},
    procs = {'frost'},
    tags = {'frostslow'}
  },
  ['frostfield'] = {
    name = 'frostbomb',
    colors = {'blue'},
    cost = 10,
    icon = 'frostbomb',
    desc = 'Creates a slowing field under enemies every few attacks',
    stats = {dmg = 0.5},
    procs = {'frostfield'},
    tags = {'frostslow'}
  },
  ['reticle'] = {
    name = 'reticle',
    colors = {'blue'},
    cost = 5,
    icon = 'reticle',
    desc = 'A reticle that increases range',
    stats = {attack_range = 0.1, dmg = 0.5},
    procs = {}
  },
  ['holduground'] = {
    name = 'holduground',
    colors = {'blue'},
    cost = 5,
    icon = 'rock',
    desc = 'Increases attackspeed the longer you stand still',
    stats = {},
    procs = {'holduground'}
  },
  ['icenova'] = {
    name = 'icenova',
    colors = {'blue'},
    cost = 5,
    icon = 'turtle',
    desc = 'Damages and slows enemies when they get too close',
    stats = {dmg = 0.5},
    procs = {'icenova'}
  },
  ['icefang'] = {
    name = 'icefang',
    colors = {'blue'},
    cost = 5,
    icon = 'icefang',
    desc = 'Your slows stack to slow enemies to a crawl',
    stats = {dmg = 0.5},
    procs = {'slowstack'},
    prereqs = {'frostslow'}
  },

  --not yet implemented
  --------------------

  --repeated attacks on the same target are faster / do more damage / build vuln

  --burning enemies have a chance to explode for % max hp (global) (+burn dmg, tier 2/3)

  --enemies that are slowed take more damage from all sources (global) (+slow dmg, tier 2/3)

  --enemies that are stunned are vulnerable to all damage (global) (+stun dmg, tier 2/3)
  --enemies that are stunned are slowed when they recover from stun (global) (+stun slow, tier 2/3)




  --multicolor items
  ['twinflame'] = {
    name = 'twinflame',
    colors = {'red', 'blue'},
    cost = 10,
    icon = 'twinflame',
    desc = 'Converts slow to fire damage, and fire damage to slow',
    stats = {dmg = 0.5},
    procs = {'fire'},
    prereqs = {'firedmg', 'frostslow'}
  },
  ['omegastar'] = {
    name = 'omegastar',
    colors = {'red', 'yellow', 'blue'},
    cost = 10,
    icon = 'omegastar',
    desc = 'Increases all elemental damage. You heal for a portion of elemental damage dealt',
    stats = {dmg = 0.5},
    procs = {'eledmg, elevamp'},
    prereqs = {'firedmg', 'frostslow', 'lightningdmg'}
  },
}
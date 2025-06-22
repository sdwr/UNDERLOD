

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

  -- add triggers and damage types to the item from the procs
  self.tags = {}

  --creates procs from the data, but this doesnt work on the unit
  -- (because the unit doesn't exist yet)

  --hack that this loads during combat and in the shop
  --combat expects the unit to exist, but the shop doesn't
  if data.procs then
    for k, v in pairs(data.procs) do
      local proc = Create_Proc(v, nil, nil)
      table.insert(self.procs, proc)

      --add the proc's triggers and damage type to the item
      if proc.damageType then
        table.insert(self.tags, proc.damageType)
      end
      if proc.triggers then
        for _, trigger in ipairs(proc.triggers) do
          table.insert(self.tags, trigger)
        end
      end
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
function Get_Random_Item(shop_level, units, all_items)
  local max_cost = Get_Max_Item_Cost(shop_level)
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
    local has_cost = v.cost <= max_cost
    local has_prereqs = true
    local already_in_shop = false

    --check if the items prereqs are met
    if v.prereqs and #v.prereqs > 0 then
      for i, prereq in ipairs(v.prereqs) do
        if not owned_items[prereq] then
          has_prereqs = false
          break
        end
      end
    end

    --check if the item is already in the shop
    table.any(all_items, function(item)
      if item and item.name == v.name then
        already_in_shop = true
      end
    end)


    if has_cost and has_prereqs and not already_in_shop then
      table.insert(available_items, v)
    end

  end

  if #available_items == 0 then
    print('no available items')
    return nil
  end

  return get_random_from_table(available_items)
end

function Get_Max_Item_Cost(shop_level)
  if shop_level == 1 then
    return 5
  elseif shop_level == 2 then
    return 10
  elseif shop_level == 3 then
    return 15
  else
    return 20
  end
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
  -- ['rerollpotion'] = {
  --   name = 'rerollpotion',
  --   colors = {},
  --   cost = 2,
  --   consumable = true,
  --   icon = 'flask',
  --   desc = 'Reroll the upcoming levels when you drink this potion',
  --   stats = {},
  --   procs = {'reroll'}
  -- },


    --resets the reroll cost of the shop to base
  -- ['resetpotion'] = {
  --   name = 'resetpotion',
  --   colors = {},
  --   cost = 2,
  --   consumable = true,
  --   icon = 'flask',
  --   desc = 'Reset the reroll price of the shop back to ' .. STARTING_REROLL_COST .. ' when you drink this potion,
  --   stats = {},
  --   procs = {'reset'}
  -- },

  -- ['damagepotion'] = {
  --   name = 'damagepotion',
  --   colors = {},
  --   cost = 2,
  --   consumable = true,
  --   icon = 'potion2',
  --   desc = 'Gain attack damage next round when you drink this potion',
  --   stats = {},
  --   procs = {'damagepotion'}
  -- },
  -- ['shieldpotion'] = {
  --   name = 'shieldpotion',
  --   colors = {},
  --   cost = 2,
  --   consumable = true,
  --   icon = 'potion2',
  --   desc = 'Start with a shield next round when you drink this potion',
  --   stats = {},
  --   procs = {'shieldpotion'}
  -- },
  -- ['berserkpotion'] = {
  --   name = 'berserkpotion',
  --   colors = {},
  --   cost = 2,
  --   consumable = true,
  --   icon = 'potion2',
  --   desc = 'Gain attack speed and movespeed next round when you drink this potion',
  --   stats = {},
  --   procs = {'berserkpotion'}
  -- },
  -- ['areapotion'] = {
  --   name = 'areapotion',
  --   colors = {},
  --   cost = 2,
  --   consumable = true,
  --   icon = 'potion2',
  --   desc = 'Gain area size next round when you drink this potion',
  --   stats = {},
  --   procs = {'areapotion'}
  -- },

  --colorless items
  -- ['craggyvest'] = {
  --   name = 'craggyvest',
  --   colors = {},
  --   cost = 5,
  --   icon = 'fancyarmor',
  --   desc = 'Deals [brown]thorns[fg] damage and has a chance to [black]stun[fg] attackers',
  --   stats = {hp = 0.25, thorns = 0.2 },
  --   procs = {'craggy'}
  -- },

  --stat items (brown?)
  ['flimsyboots'] = {
    name = 'flimsyboots',
    colors = {},
    cost = 5,
    icon = 'simpleboots',
    desc = 'A pair of boots that slightly increases your movespeed',
    stats = {mvspd = 0.1},
    procs = {},
  },

  ['shortsword'] = {
    name = 'shortsword',
    colors = {},
    cost = 5,
    icon = 'sword',
    desc = 'A short sword that slightly increases your damage',
    stats = {dmg = 0.2},
    procs = {},
  },
  ['longsword'] = {
    name = 'longsword',
    colors = {},
    cost = 10,
    icon = 'sword',
    desc = 'A sword that increases your damage',
    stats = {dmg = 0.4},
    procs = {},
  },
  ['greatsword'] = {
    name = 'greatsword',
    colors = {},
    cost = 15,
    icon = 'sword',
    desc = 'A sword that greatly increases your damage',
    stats = {dmg = 0.6},
    procs = {},
  },

  ['shortbow'] = {
    name = 'shortbow',
    colors = {},
    cost = 5,
    icon = 'bow',
    desc = 'A dagger that slightly increases your attack speed',
    stats = {aspd = 0.1},
    procs = {},
  }, 
  ['mediumbowr'] = {
    name = 'mediumbowr',
    colors = {},
    cost = 10,
    icon = 'bow',
    desc = 'A rapier that increases your attack speed',
    stats = {aspd = 0.2},
  },
  ['longbow'] = {
    name = 'longbow',
    colors = {},
    cost = 15,
    icon = 'bow',
    desc = 'A bow that greatly increases your attack speed',
    stats = {aspd = 0.4},
  },

  ['spikedcollar'] = {
    name = 'spikedcollar',
    colors = {},
    cost = 10,
    icon = 'spikedcollar',
    desc = 'When hit, deals AoE[brown]thorns[fg] damage with a chance to [brown]stun[fg] enemies',
    stats = {},
    procs = {'spikedcollar'}
  },


  --econ items
  -- ['sackofcash'] = {
  --   name = 'sackofcash',
  --   colors = {},
  --   cost = 5,
  --   icon = 'sackofcash',
  --   desc = 'Special enemies have a chance to drop gold when they die',
  --   stats = {hp = 0.2},
  --   procs = {'sackofcash'}
  -- },
  ['heartofgold'] = {
    name = 'heartofgold',
    colors = {},
    cost = 5,
    icon = 'turtle',
    desc = 'A heart that provides gold every round',
    stats = {hp = 0.1, gold = 2}
  },
  ['stockmarket'] = {
    name = 'stockmarket',
    colors = {},
    cost = 10,
    icon = 'linegoesup',
    desc = 'Gain interest on your gold (1 per ' .. math.floor(1 / INTEREST_AMOUNT).. ', up to ' .. MAX_INTEREST .. ')',
    stats = {hp = 0.2}
  },
  ['basher'] = {
  name = 'basher',
    colors = {},
    cost = 10,
    icon = 'mace',
    desc = 'A weapon that inflicts [black]stun[fg] enemies',
    stats = {bash = 0.2, dmg = 0.25},
    procs = {'bash'}
  },
  ['overkill'] = {
    name = 'overkill',
    colors = {},
    cost = 10,
    icon = 'bomb',
    desc = 'Enemies you kill [red[5]]explode[fg] for part of their max health',
    stats = {dmg = 0.5},
    procs = {'overkill'}
  },
  ['bloodlust'] = {
    name = 'bloodlust',
    colors = {'purple'},
    cost = 5,
    icon = 'bloodlust',
    desc = 'Get a stacking attack and movespeed buff when you kill an enemy',
    stats = {},
    procs = {'bloodlust'}
  },
  ['repeater'] = {
    name = 'repeater',
    colors = {},
    cost = 10,
    icon = 'repeater',
    desc = 'Adds a chance to repeat your attack',
    stats = {repeat_attack_chance = 0.2},
    procs = {}
  },
  -- ['pricklypear'] = {
  --   name = 'pricklypear',
  --   colors = {'green'},
  --   cost = 10,
  --   icon = 'cactus',
  --   desc = 'Chance to instantly attack when hit',
  --   stats = {},
  --   procs = {'retaliate'}
  -- },

  --yellow items
  ['medbow'] = {
    name = 'medbow',
    colors = {'yellow'},
    cost = 5,
    icon = 'bow',
    desc = 'Your attacks trigger [yellow]lightning[fg] on enemies',
    stats = {},
    procs = {'lightning'},
    tags = {'lightningdmg'}
  },
  ['staticboots'] = {
    name = 'staticboots',
    colors = {'yellow'},
    cost = 10,
    icon = 'simpleboots',
    desc = 'Increase movespeed and charge [yellow]lightning[fg] attacks while moving',
    stats = {mvspd = 0.15},
    procs = {'static'},
    tags = {'lightningdmg'}
  },
  ['radiance'] = {
    name = 'radiance',
    colors = {'yellow'},
    cost = 10,
    icon = 'sun',
    desc = 'Gain a shield and a damage aura',
    stats = {},
    procs = {'radiance', 'shield'}
  },
  ['shock'] = {
    name = 'shock',
    colors = {'yellow'},
    cost = 10,
    icon = 'lightning',
    desc = 'Your lightning damage inflicts [yellow]shock[fg] on enemies, increasing their damage taken',
    stats = {aspd = 0.15},
    procs = {'shock'},
    tags = {'shock'},
    prereqs = {'lightningdmg'}
  },

  --still need to add
  -- ['bubble'] = {
  --   name = 'bubble',
  --   colors = {'yellow'},
  --   cost = 5,
  --   icon = 'bubblewand',
  --   desc = 'Periodically create a bubble shield around you that blocks all damage',
  --   stats = {hp = 0.1},
  --   procs = {'bubble'}
  -- },

  --red items
  ['fire'] = {
    name = 'fire',
    colors = {'red'},
    cost = 5,
    icon = 'fire',
    desc = 'Your attacks inflict [red]burn[fg] on enemies',
    stats = {},
    procs = {'fire'},
    tags = {'firedmg'}
  },
  ['lavaman'] = {
    name = 'lavaman',
    colors = {'red'},
    cost = 5,
    icon = 'monster',
    desc = 'Summon [red]burning[fg] minions to fight for you',
    stats = {},
    procs = {'lavaman'},
    tags = {}
  },
  ['lavapool'] = {
    name = 'lavapool',
    colors = {'red'},
    cost = 10,
    icon = 'lavapool',
    desc = 'Your attacks trigger a pool of [red]lava[fg] under enemies',
    stats = {dmg = 0.25},
    procs = {'lavapool'},
    tags = {'firedmg'}
  },
  ['firenova'] = {
    name = 'firenova',
    colors = {'red'},
    cost = 10,
    icon = 'sun',
    desc = 'Your attacks trigger an [red]explosion[fg] on enemies',
    stats = {},
    procs = {'firenova'},
    prereqs = {'firedmg'}
  },
  ['fireexplode'] = {
    name = 'fireexplode',
    colors = {'red'},
    cost = 15,
    icon = 'sun',
    desc = 'Hitting [red]burning[fg] enemy has a chance to [red[5]]explode[fg] for % max health',
    stats = {dmg = 0.5},
    procs = {'fireexplode'},
    prereqs = {'firedmg'}
  },
  ['blazin'] = {
    name = 'blazin',
    colors = {'red'},
    cost = 10,
    icon = 'simpleboots',
    desc = 'Gain attack speed per [red]burning[fg] enemy',
    stats = {dmg = 0.25},
    procs = {'blazin'},
    prereqs = {'firedmg'}
  },
  ['phoenix'] = {
    name = 'phoenix',
    colors = {'red'},
    cost = 10,
    icon = 'cactus',
    desc = 'The first time this unit dies, it is revived with 50% health',
    procs = {'phoenix'}
  },

  --blue items
  ['frostorb'] = {
    name = 'frostorb',
    colors = {'blue'},
    cost = 5,
    icon = 'orb',
    desc = 'Your attacks inflict [blue]frost[fg] on enemies',
    stats = {dmg = 0.1},
    procs = {'frost'},
    tags = {'frostslow'}
  },
  ['frostbomb'] = {
    name = 'frostbomb',
    colors = {'blue'},
    cost = 10,
    icon = 'bomb',
    desc = 'Your attacks trigger a [blue]frostfield[fg] under enemies',
    stats = {dmg = 0.1},
    procs = {'frostfield'},
    tags = {'frostslow'}
  },
  ['reticle'] = {
    name = 'reticle',
    colors = {'blue'},
    cost = 10,
    icon = 'repeater',
    desc = 'A reticle that increases range',
    stats = {range = 0.15, dmg = 0.25},
    procs = {}
  },
  ['holduground'] = {
    name = 'holduground',
    colors = {'blue'},
    cost = 5,
    icon = 'rock',
    desc = 'Standing still stacks an attack speed buff',
    stats = {},
    procs = {'holduground'}
  },
  ['icenova'] = {
    name = 'icenova',
    colors = {'blue'},
    cost = 5,
    icon = 'turtle',
    desc = 'Enemies coming near you trigger a [blue]frostnova[fg]',
    stats = {},
    procs = {'icenova'},
    tags = {'frostslow'}
  },
  ['shatterlance'] = {
    name = 'shatterlance',
    colors = {'blue'},
    cost = 10,
    icon = 'icefang',
    desc = 'Your hits on chilled enemies have a chance to deal extra damage',
    stats = {dmg = 0.1},
    procs = {'shatterlance'},
    prereqs = {'frostslow'}
  },
  ['glaciate'] = {
    name = 'glaciate',
    colors = {'blue'},
    cost = 10,
    icon = 'icefang',
    desc = 'Your attacks on [blue]slowed[fg] have a chance to [blue]freeze[fg] them',
    stats = {dmg = 0.1},
    procs = {'glaciate'},
    prereqs = {'frostslow'}
  },
  ['glacialprison'] = {
    name = 'glacialprison',
    colors = {'blue'},
    cost = 15,
    icon = 'icefang',
    desc = 'Killing a [blue]chilled[fg] enemy creates a [blue]ice prison[fg] that slows enemies',
    stats = {dmg = 0.25},
    procs = {'glacialprison'},
    prereqs = {'frostslow'}
  },
  
  
  --green items
  ['healingleaf'] = {
    name = 'healingleaf',
    colors = {'green'},
    cost = 5,
    icon = 'leaf',
    desc = 'Periodically [green]heal[fg] yourself',
    stats = {},
    procs = {'heal'},
    tags = {'heal'},
  },
  ['sacrificialclam'] = {
    name = 'sacrificialclam',
    colors = {'purple'},
    cost = 10,
    icon = 'clam',
    desc = 'Periodically [purple]sacrifice[fg] health to grant nearby allies attack speed',
    stats = {dmg = 0.25},
    procs = {'sacrificialclam'},
    prereqs = {'heal'},
    tags = {'sacrifice'}
  },
  ['healingwave'] = {
    name = 'healingwave',
    colors = {'green'},
    cost = 10,
    icon = 'gem',
    desc = 'Periodically [green]heal[fg] all nearby allies',
    stats = {hp = 0.4},
    procs = {'healingwave'},
    tags = {'heal'},
  },
  ['curse'] = {
    name = 'curse',
    colors = {'purple'},
    cost = 10,
    icon = 'skull',
    desc = 'Periodically [purple]curse[fg] nearby enemies, causing them to take more damage',
    stats = {dmg = 0.25},
    procs = {'curse'},
  },
  ['entangle'] = {
    name = 'entangle',
    colors = {'green'},
    cost = 10,
    icon = 'root',
    desc = 'Periodically [brown]root[fg] nearby enemies, preventing them from moving',
    stats = {dmg = 0.25},
    procs = {'root'},
  },

  
  --repeated attacks on the same target are faster / do more damage / build vuln

  ['overcharge'] = {
    name = 'overcharge',
    colors = {'yellow'},
    cost = 10,
    icon = 'reticle',
    desc = 'Repeated attacks on the same target increase your attack speed',
    stats = {mvspd = 0.15},
    procs = {'overcharge'}
  },
  ['powercharge'] = {
    name = 'powercharge',
    colors = {'red'},
    cost = 10,
    icon = 'reticle',
    desc = 'Repeated attacks on the same target increase your damage',
    stats = {dmg = 0.25},
    procs = {'powercharge'}
  },
  ['vulncharge'] = {
    name = 'vulncharge',
    colors = {'purple'},
    cost = 10,
    icon = 'reticle',
    desc = 'Repeated attacks on the same target increase the damage they take',
    stats = {dmg = 0.25},
    procs = {'vulncharge'}
  },

  --global stat boosts
  ['strengthtalisman'] = {
    name = 'strengthtalisman',
    colors = {'red'},
    cost = 15,
    icon = 'talisman',
    desc = 'All your units gain a damage buff',
    stats = {hp = 0.25},
    procs = {'strengthtalisman'}
  },

  ['agilitytalisman'] = {
    name = 'agilitytalisman',
    colors = {'yellow'},
    cost = 15,
    icon = 'talisman',
    desc = 'All your units gain an attack speed and movespeed buff',
    stats = {hp = 0.25},
    procs = {'agilitytalisman'}
  },
  ['wisdomtalisman'] = {
    name = 'wisdomtalisman',
    colors = {'blue'},
    cost = 15,
    icon = 'talisman',
    desc = 'All your units gain a range and item cooldown buff',
    stats = {hp = 0.25},
    procs = {'wisdomtalisman'}
  },
  ['vitalitytalisman'] = {
    name = 'vitalitytalisman',
    colors = {'green'},
    cost = 15,
    icon = 'talisman',
    desc = 'All your units gain a health and defense buff',
    stats = {hp = 0.25},
    procs = {'vitalitytalisman'}
  },


  
  --elemental on death effects

  ['firebomb'] = {
    name = 'firebomb',
    colors = {'red'},
    cost = 15,
    icon = 'bomb',
    desc = 'Killing a [red]burning[fg] enemy has a chance to explode for % max health',
    stats = {dmg = 0.5},
    procs = {'firebomb'},
    prereqs = {'firedmg'}
  },
  ['waterelemental'] = {
    name = 'frostbite',
    colors = {'blue'},
    cost = 15,
    icon = 'frost',
    desc = 'Killing a [blue]chilled[fg] enemy has a chance to spawn a water elemental',
    stats = {dmg = 0.5},
    procs = {'waterelemental'},
    prereqs = {'frostslow'}
  },
  ['shockwave'] = {
    name = 'shockwave',
    colors = {'yellow'},
    cost = 15,
    icon = 'lightning',
    desc = 'Killing a [yellow]shocked[fg] enemies has to spread [yellow]shock[fg]',
    stats = {dmg = 0.5},
    procs = {'shockwave'},
    prereqs = {'shock'}
  },

  --not yet implemented
  --------------------
  
  --enemies that are slowed take more damage from all sources (global) (+slow dmg, tier 2/3)

  --enemies that are stunned are vulnerable to all damage (global) (+stun dmg, tier 2/3)
  --enemies that are stunned are slowed when they recover from stun (global) (+stun slow, tier 2/3)


  --expensive items




  --multicolor items
  ['frostfire'] = {
    name = 'frostfire',
    colors = {'red', 'blue'},
    cost = 15,
    icon = 'twinflame',
    desc = 'Makes your [red]fire[fg] damage [blue]slow[fg], and your [blue]frost[fg] damage [red]burn[fg]',
    stats = {dmg = 0.5},
    procs = {'fire'},
    prereqs = {'firedmg', 'frostslow'}
  },
  ['omegastar'] = {
    name = 'omegastar',
    colors = {'red', 'yellow', 'blue'},
    cost = 20,
    icon = 'omegastar',
    desc = 'Increases all elemental damage. You [green]heal[fg] for a portion of elemental damage dealt',
    stats = {dmg = 0.5},
    procs = {'eledmg, elevamp'},
    prereqs = {'firedmg', 'frostslow', 'lightningdmg'}
  },
}
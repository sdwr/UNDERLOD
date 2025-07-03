

--items are actually created from the data in objects.lua on units
--this is just a way to create them from the shop

function Create_Item(name)
  if not item_to_item_data[name] then
    print('item' .. name .. ' not found')
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
    if all_items then
    table.any(all_items, function(item)
      if item and item.name == v.name then
          already_in_shop = true
        end
      end)
    end


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


  -- 5 COST ITEMS
  -----------------------------------------

  --colorless items
  ['heartofgold'] = {
    name = 'heartofgold',
    colors = {},
    cost = 5,
    icon = 'turtle',
    desc = 'A heart that provides gold every round',
    stats = {hp = 0.1, gold = 1}
  },

  ['sword'] = {
    name = 'sword',
    colors = {},
    cost = 5,
    icon = 'sword',
    desc = 'Deal more damage',
    stats = {dmg = 0.25},
    procs = {}
  },

  ['dagger'] = {
    name = 'dagger',
    colors = {},
    cost = 5,
    icon = 'dagger',
    desc = 'Attack more quickly',
    stats = {aspd = 0.2},
    procs = {}
  },
  ['basher'] = {
    name = 'basher',
      colors = {},
      cost = 5,
      icon = 'mace',
      desc = 'Your attacks have a chance to [black]stun[fg] enemies',
      stats = {bash = 0.2, dmg = 0.1},
      procs = {'bash'}
    },

  -- ['spikedcollar'] = {
  --   name = 'spikedcollar',
  --   colors = {},
  --   cost = 5,
  --   icon = 'spikedcollar',
  --   desc = 'When hit, deals AoE[brown]thorns[fg] damage with a chance to [brown]stun[fg] enemies',
  --   stats = {},
  --   procs = {'spikedcollar'}
  -- },

  --5 cost colored items
  ['fire'] = {
    name = 'fire',
    colors = {'red'},
    cost = 5,
    icon = 'fire',
    desc = '[red]Burning[fg] enemies take damage over time and [red]explode[fg]',
    stats = {fire_damage = 0.3},
    procs = {},
    tags = {'fire'}
  },

  ['lightning'] = {
    name = 'lightning',
    colors = {'yellow'},
    cost = 5,
    icon = 'fire',
    desc = '[yellow]Shocked[fg] enemies take more damage',
    stats = {lightning_damage = 0.3},
    procs = {},
    tags = {'lightning'}
  },

  ['cold'] = {
    name = 'cold',
    colors = {'blue'},
    cost = 5,
    icon = 'orb',
    desc = '[blue]Chilled[fg] enemies are slower and [blue]freeze[fg]',
    stats = {cold_damage = 0.3},
    procs = {},
    tags = {'cold'}
  },

  ['frostnova'] = {
    name = 'frostnova',
    colors = {'blue'},
    cost = 5,
    icon = 'turtle',
    desc = 'Enemy proximity triggers a [blue]cold[fg] nova',
    stats = {},
    procs = {'frostnova'},
    tags = {'cold'}
  },

  ['healingwave'] = {
    name = 'healingwave',
    colors = {'green'},
    cost = 5,
    icon = 'gem',
    desc = 'Periodically [green]heal[fg] nearby allies for a % of your max health',
    stats = {},
    procs = {'healingwave'},
    tags = {'heal'},
  },


  --10 COST ITEMS
  -----------------------------------------

  -- ['stockmarket'] = {
  --   name = 'stockmarket',
  --   colors = {},
  --   cost = 10,
  --   icon = 'linegoesup',
  --   desc = 'Gain interest on your gold (1 per ' .. math.floor(1 / INTEREST_AMOUNT).. ', up to ' .. MAX_INTEREST .. ')',
  --   stats = {hp = 0.2}
  -- },
  ['shieldslam'] = {
    name = 'shieldslam',
    colors = {},
    cost = 10,
    icon = 'shield',
    desc = 'Your attacks knock enemies back',
    stats = {dmg = 0.25},
    procs = {'shieldslam'}
  },
  -- ['pricklypear'] = {
  --   name = 'pricklypear',
  --   colors = {'green'},
  --   cost = 10,
  --   icon = 'cactus',
  --   desc = 'Chance to instantly retaliate with an attack when hit',
  --   stats = {},
  --   procs = {'retaliate'}
  -- },
  ['overkill'] = {
    name = 'overkill',
    colors = {},
    cost = 10,
    icon = 'bomb',
    desc = 'Enemies you kill explode, triggering [black]on hit[fg] effects',
    stats = {dmg = 0.5},
    procs = {'overkill'}
  },
  ['bloodlust'] = {
    name = 'bloodlust',
    colors = {'purple'},
    cost = 10,
    icon = 'bloodlust',
    desc = 'Gain a stacking attack and movespeed buff when you kill an enemy',
    stats = {},
    procs = {'bloodlust'}
  },
  ['repeater'] = {
    name = 'repeater',
    colors = {},
    cost = 10,
    icon = 'repeater',
    desc = 'A quick repeater',
    stats = {repeat_attack_chance = 0.25},
    procs = {}
  },
  ['reticle'] = {
    name = 'reticle',
    colors = {'blue'},
    cost = 10,
    icon = 'repeater',
    desc = 'See further',
    stats = {range = 0.15, dmg = 0.25},
    procs = {}
  },
  ['berserker_greaves'] = {
    name = 'berserker_greaves',
    colors = {'yellow'},
    cost = 10,
    icon = 'simpleboots',
    desc = 'Be faster',
    stats = {mvspd = 0.15, aspd = 0.15},
  },
  ['phoenix'] = {
    name = 'phoenix',
    colors = {},
    cost = 10,
    icon = 'cactus',
    desc = 'The first time you die in a round, you are revived',
    procs = {'phoenix'}
  },
  -- ['noblesacrifice'] = {
  --   name = 'noblesacrifice',
  --   colors = {'green'},
  --   cost = 10,
  --   icon = 'skull',
  --   desc = 'Heal all nearby enemies on death',
  --   stats = {},
  --   procs = {'noblesacrifice'},
  -- },

  --10 cost colored items
  ['radiance'] = {
    name = 'radiance',
    colors = {'red'},
    cost = 10,
    icon = 'sun',
    desc = 'Gain a shield and a [red]fire[fg] damage aura',
    stats = {},
    procs = {'radiance', 'shield'},
    tags = {'fire'}
  },
  ['blazin'] = {
    name = 'blazin',
    colors = {'red'},
    cost = 10,
    icon = 'simpleboots',
    desc = 'Gain attack speed per [red]burning[fg] enemy',
    stats = {dmg = 0.25},
    procs = {'blazin'},
    prereqs = {'fire'}
  },
  ['volcano'] = {
    name = 'volcano',
    colors = {'red'},
    cost = 10,
    icon = 'volcano',
    desc = 'Attacking a [red]burning[fg] enemy has a chance to create a [red]lava pool[fg]',
    stats = {dmg = 0.25},
    procs = {'volcano'},
    prereqs = {'fire'}
  },

  ['shatterlance'] = {
    name = 'shatterlance',
    colors = {'blue'},
    cost = 10,
    icon = 'icefang',
    desc = 'Attacking a [blue]frozen[fg] enemy creates a [blue]cold[fg] explosion',
    stats = {dmg = 0.1},
    procs = {'shatterlance'},
    prereqs = {'cold'}
  },
  ['waterelemental'] = {
    name = 'waterelemental',
    colors = {'blue'},
    cost = 10,
    icon = 'cold',
    desc = 'Killing a [blue]chilled[fg] enemy has a chance to spawn a water elemental',
    stats = {dmg = 0.25},
    procs = {'waterelemental'},
    prereqs = {'cold'}
  },


  ['sympatheticvoltage'] = {
    name = 'sympatheticvoltage',
    colors = {'yellow'},
    cost = 10,
    icon = 'lightning',
    desc = 'Attacking a [yellow]shocked[fg] enemy has a chance to create a [yellow]lightning ball[fg]',
    stats = {dmg = 0.25},
    procs = {'sympatheticvoltage'},
    prereqs = {'lightning'}
  },
  ['balllightning'] = {
    name = 'balllightning',
    colors = {'yellow'},
    cost = 10,
    icon = 'lightning',
    desc = 'Hitting a [yellow]shocked[fg] enemy has a chance to spawn a [yellow]lightning ball[fg]',
    stats = {dmg = 0.25},
    procs = {'balllightning'},
    prereqs = {'shock'}
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

    -- ['frostbomb'] = {
  --   name = 'frostbomb',
  --   colors = {'blue'},
  --   cost = 10,
  --   icon = 'bomb',
  --   desc = 'Your attacks create a [blue]frostfield[fg] under enemies',
  --   stats = {dmg = 0.1},
  --   procs = {'frostfield'},
  --   tags = {'cold'}
  -- },
    -- ['glaciate'] = {
  --   name = 'glaciate',
  --   colors = {'blue'},
  --   cost = 10,
  --   icon = 'icefang',
  --   desc = 'Your attacks on [blue]chilled[fg] have a chance to [blue]freeze[fg] them',
  --   stats = {dmg = 0.1},
  --   procs = {'glaciate'},
  --   prereqs = {'cold'},
  --   tags = {'freeze'}
  -- },

  
  -- ['lavaman'] = {
  --   name = 'lavaman',
  --   colors = {'red'},
  --   cost = 5,
  --   icon = 'monster',
  --   desc = 'Summon [red]burning[fg] minions to fight for you',
  --   stats = {},
  --   procs = {'lavaman'},
  --   tags = {}
  -- },
  -- ['fireexplode'] = {
  --   name = 'fireexplode',
  --   colors = {'red'},
  --   cost = 15,
  --   icon = 'sun',
  --   desc = 'Hitting [red]burning[fg] enemy has a chance to [red[5]]explode[fg] for % max health',
  --   stats = {dmg = 0.5},
  --   procs = {'fireexplode'},
  --   prereqs = {'fire'}
  -- },

  ['glacialprison'] = {
    name = 'glacialprison',
    colors = {'blue'},
    cost = 15,
    icon = 'icefang',
    desc = 'Killing a [blue]frozen[fg] enemy creates a [blue]ice prison[fg] that slows enemies',
    stats = {dmg = 0.25},
    procs = {'glacialprison'},
    prereqs = {'cold'}
  },
  
  
  --green items

  ['sacrificialclam'] = {
    name = 'sacrificialclam',
    colors = {'green'},
    cost = 10,
    icon = 'clam',
    desc = 'All nearby allies gain attack speed',
    stats = {dmg = 0.25},
    procs = {'sacrificialclam'},
    prereqs = {'heal'},
    tags = {'sacrifice'}
  },

  
  --repeated attacks on the same target are faster / do more damage / build vuln

  ['overcharge'] = {
    name = 'overcharge',
    colors = {'yellow'},
    cost = 10,
    icon = 'reticle',
    desc = 'Attacks on the same target increase your attack speed',
    stats = {mvspd = 0.15},
    procs = {'overcharge'}
  },
  ['powercharge'] = {
    name = 'powercharge',
    colors = {'red'},
    cost = 10,
    icon = 'reticle',
    desc = 'Attacks on the same target increase your damage',
    stats = {dmg = 0.25},
    procs = {'powercharge'}
  },
  -- ['vulncharge'] = {
  --   name = 'vulncharge',
  --   colors = {'purple'},
  --   cost = 10,
  --   icon = 'reticle',
  --   desc = 'More attacks on the same target increase the damage they take',
  --   stats = {dmg = 0.25},
  --   procs = {'vulncharge'}
  -- },

  --todo items
  ['rimeheart'] = {
    name = 'rimeheart',
    colors = {'blue'},
    cost = 15,
    icon = 'heart',
    desc = 'Attacking a [blue]frozen[fg] enemy is always a critical hit.',
    stats = {dmg = 0.25},
    procs = {'rimeheart'},
    prereqs = {'freeze'}
  },
  --triforce
  ['triforce'] = {
    name = 'triforce',
    colors = {'red', 'blue', 'yellow'},
    cost = 15,
    icon = 'triforce',
    desc = 'Deal more damage to enemies for every elemental effect they have',
    stats = {dmg = 0.25},
    procs = {'triforce'},
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
    prereqs = {'fire', 'cold'}
  },
  ['omegastar'] = {
    name = 'omegastar',
    colors = {'red', 'yellow', 'blue'},
    cost = 20,
    icon = 'omegastar',
    desc = 'Increases all elemental damage. You [green]heal[fg] for a portion of elemental damage dealt',
    stats = {dmg = 0.5},
    procs = {'eledmg, elevamp'},
    prereqs = {'fire', 'cold', 'lightning'}
  },
}
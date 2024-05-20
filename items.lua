
--create with
-- Item{item_to_item_data['craggyvest']}
-- when it's on a unit, the procs will be added to the
-- relevant callbacks in objects.lua
-- and the stats will be added to the unit's stats

--REMEMBER TO DESTROY ITEMS AND PROCS WHEN UNIT DIES (ROUND ENDS!)
-- OR WHEN UNIT/ITEM IS SOLD!!!
-- have to hunt down the onDeath / dead=true, and standardize between
-- troops and enemies

Item = Object:extend()
function Item:init(data)
  self.name = data.name
  self.colors = data.colors
  self.cost = data.cost
  self.icon = data.icon
  self.desc = data.desc
  self.stats = data.stats
  self.procs = data.procs
end

function Item:add_proc(unit)
  for i, proc in ipairs(self.procs) do
    local proc_copy = deepcopy(proc)
    table.insert(unit.procs, proc_copy)
  end
end

function Item:die()
  for i, proc in ipairs(self.procs) do
    proc:die()
  end
  self.dead = true
end

--TODO: put buy_screen draw in here?
-- or at least change where it gets the item data from


item_to_item_data = {

  --consumable items
  --colorless items
  ['craggyvest'] = {
    name = 'craggyvest',
    colors = {},
    cost = 5,
    icon = 'craggyvest',
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
  ['berserk'] = {
    name = 'berserk',
    colors = {},
    cost = 5,
    icon = 'berserk',
    desc = 'Increases damage when low on health',
    stats = {dmg = 0.5},
    procs = {'berserk'}
  },
  ['basher'] = {
  name = 'basher',
    colors = {},
    cost = 5,
    icon = 'basher',
    desc = 'A shield that stuns enemies',
    stats = {bash = 0.2, dmg = 0.5},
    procs = {'bash'}
  },
  ['healingleaf'] = {
    name = 'healingleaf',
    colors = {},
    cost = 5,
    icon = 'healingleaf',
    desc = 'A leaf that heals you',
    stats = {hp = 0.2},
    procs = {'heal'}
  },
  ['overkill'] = {
    name = 'overkill',
    colors = {},
    cost = 5,
    icon = 'overkill',
    desc = 'Enemies that are overkilled explode for the overkill amount of damage',
    stats = {dmg = 0.5},
    procs = {'overkill'}
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
    procs = {'lightning'}
  },
  ['staticboots'] = {
    name = 'staticboots',
    colors = {'yellow'},
    cost = 5,
    icon = 'electricboots',
    desc = 'Increase movespeed and charge up lightning attacks',
    stats = {ms = 0.15},
    procs = {'static'}
  },
  --still need to add
  ['radiance'] = {
    name = 'radiance',
    colors = {'yellow'},
    cost = 5,
    icon = 'radiance',
    desc = 'Gain a shield and a damage aura',
    stats = {hp = .1},
    procs = {'radianceburn', 'shield'}
  },
  --still need to add
  ['phantomdancer'] = {
    name = 'phantomdancer',
    colors = {'yellow'},
    cost = 5,
    icon = 'phantomdancer',
    desc = 'Gain mspd and aspd and phasing',
    stats = {aspd = 0.25, ms = 0.15},
    procs = {'phasing'}
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
    icon = 'firesword',
    desc = 'A sword that burns enemies',
    stats = {dmg = 0.5},
    procs = {'fire'}
  },
  ['redshield'] = {
    name = 'redshield',
    colors = {'red'},
    cost = 5,
    icon = 'redshield',
    desc = 'Gain armor for each hit taken',
    stats = {hp = 0.25},
    procs = {'redshield'}
  },
  ['redsword'] = {
    name = 'redsword',
    colors = {'red'},
    cost = 5,
    icon = 'redsword',
    desc = 'Gain damage based on your armor',
    stats = {dmg = 0.5},
    procs = {'redsword'}
  },
  ['bloodlust'] = {
    name = 'bloodlust',
    colors = {'red'},
    cost = 5,
    icon = 'bloodlust',
    desc = 'Inc aspd and mvspd at start of round',
    stats = {dmg = 0.4},
    procs = {'bloodlust'}
  },
  ['chainexplosion'] = {
    name = 'chainexplosion',
    colors = {'red'},
    cost = 10,
    icon = 'chainexplosion',
    desc = 'Explodes burning enemies when they die',
    stats = {dmg = 0.5},
    procs = {'chainexplode'}
  },
  ['firestacker'] = {
    name = 'firestacker',
    colors = {'red'},
    cost = 10,
    icon = 'firestacker',
    desc = 'A sword that lets fire damage stack',
    stats = {dmg = 0.5},
    procs = {'firestack'}
  },
  ['blazin'] = {
    name = 'blazin',
    colors = {'red'},
    cost = 5,
    icon = 'blazin',
    desc = 'Gain aspd per burning enemy',
    stats = {dmg = 0.5},
    procs = {'blazin'}
  },

  --blue items
  ['frostorb'] = {
    name = 'frostorb',
    colors = {'blue'},
    cost = 5,
    icon = 'frostorb',
    desc = 'An orb that slows enemies',
    stats = {dmg = 0.5},
    procs = {'frost'}
  },
  ['frostfield'] = {
    name = 'frostbomb',
    colors = {'blue'},
    cost = 10,
    icon = 'frostbomb',
    desc = 'Creates a slowing field under enemies every few attacks',
    stats = {dmg = 0.5},
    procs = {'frostfield'}
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
  --save this for later - best example of why procs should have buff-style ticks
  -- right now would have to put in objects.lua as a buff
  ['holduground'] = {
    name = 'holduground',
    colors = {'blue'},
    cost = 5,
    icon = 'holduground',
    desc = 'Increases damage the longer you stand still',
    stats = {},
    procs = {'holduground'}
  },
  ['icenova'] = {
    name = 'icenova',
    colors = {'blue'},
    cost = 5,
    icon = 'icenova',
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
    procs = {'slowstack'}
  },

  --multicolor items
  ['twinflame'] = {
    name = 'twinflame',
    colors = {'red', 'blue'},
    cost = 10,
    icon = 'twinflame',
    desc = 'Converts slow to fire damage, and fire damage to slow',
    stats = {dmg = 0.5},
    procs = {'twinflame'}
  },
  ['omegastar'] = {
    name = 'omegastar',
    colors = {'red', 'yellow', 'blue'},
    cost = 10,
    icon = 'omegastar',
    desc = 'Increases all elemental damage. You heal for a portion of elemental damage dealt',
    stats = {dmg = 0.5},
    procs = {'omegastar'}
  },
}
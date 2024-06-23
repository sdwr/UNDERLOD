require 'engine'
require 'shared'
require 'utils'
require 'game_constants'
require 'save_game'
require 'helper/helper'
require 'ui/ui'
require 'arena'
require 'mainmenu'
require 'procs/procs'
require 'items'
require 'buy_screen_utils'
require 'buy_screen'
require 'objects'
require 'player'
require 'media'
require 'spawns/spawn_includes'
require 'enemies/level_manager'
require 'enemies/enemy_includes'
require 'units/units'
require 'util/fpscounter'

love.profiler = require('util/profiler/profile')
require 'util/runprofiler'



function init()
  shared_init()
  SpawnGlobals.Init()

  math.randomseed(os.time())

  input:bind('move_left', { 'a', 'left', 'dpleft', 'm1' })
  input:bind('move_right', { 'd', 'e', 's', 'right', 'dpright', 'm2' })
  input:bind('enter', { 'space', 'return', 'fleft', 'fdown', 'fright' })

  local s = { tags = { sfx } }
  local s_loop = { loop = true, tags = { sfx } }
  artificer1 = Sound('458586__inspectorj__ui-mechanical-notification-01-fx.ogg', s)
  explosion1 = Sound('Explosion Grenade_04.ogg', s)
  mine1 = Sound('Weapon Swap 2.ogg', s)
  level_up1 = Sound('Buff 4.ogg', s)
  unlock1 = Sound('Unlock 3.ogg', s)
  gambler1 = Sound('Collect 5.ogg', s)
  usurer1 = Sound('Shadow Punch 2.ogg', s)
  orb1 = Sound('Collect 2.ogg', s)
  silence = Sound('Silence.ogg', s)
  gold1 = Sound('Collect 5.ogg', s)
  gold2 = Sound('Coins - Gears - Slot.ogg', s)
  gold3 = Sound('Collect 4.ogg', s)
  psychic1 = Sound('Magical Impact 13.ogg', s)
  fire1 = Sound('Fire bolt 3.ogg', s)
  fire2 = Sound('Fire bolt 5.ogg', s)
  fire3 = Sound('Fire bolt 10.ogg', s)
  earth1 = Sound('Earth Bolt 1.ogg', s)
  earth2 = Sound('Earth Bolt 14.ogg', s)
  earth3 = Sound('Earth Bolt 20.ogg', s)
  illusion1 = Sound('Buff 5.ogg', s)
  thunder1 = Sound('399656__bajko__sfx-thunder-blast.ogg', s)
  flagellant1 = Sound('Whipping Horse 3.ogg', s)
  bard2 = Sound('376532__womb-affliction__flute-trill.ogg', s)
  arcane2 = Sound('Magical Impact 12.ogg', s)
  frost1 = Sound('Frost Bolt 20.ogg', s)
  arcane1 = Sound('Magical Impact 26.ogg', s)
  pyro1 = Sound('Fire bolt 5.ogg', s)
  pyro1_loop = Sound('Fire bolt 5.ogg', s_loop)
  pyro2 = Sound('Explosion Fireworks_01.ogg', s)
  dot1 = Sound('Magical Swoosh 18.ogg', s)
  gun_kata1 = Sound('Pistol Shot_07.ogg', s)
  gun_kata2 = Sound('Pistol Shot_08.ogg', s)
  dual_gunner1 = Sound('Revolver Shot_07.ogg', s)
  dual_gunner2 = Sound('Revolver Shot_08.ogg', s)
  ui_hover1 = Sound('bamboo_hit_by_lord.ogg', s)
  ui_switch1 = Sound('Switch.ogg', s)
  ui_switch2 = Sound('Switch 3.ogg', s)
  ui_transition1 = Sound('Wind Bolt 8.ogg', s)
  ui_transition2 = Sound('Wind Bolt 12.ogg', s)
  headbutt1 = Sound('Wind Bolt 14.ogg', s)
  critter1 = Sound('Critters eating 2.ogg', s)
  critter2 = Sound('Crickets Chirping 4.ogg', s)
  critter3 = Sound('Popping bloody Sac 1.ogg', s)
  force1 = Sound('Magical Impact 18.ogg', s)
  error1 = Sound('Error 2.ogg', s)
  coins1 = Sound('Coins 7.ogg', s)
  coins2 = Sound('Coins 8.ogg', s)
  coins3 = Sound('Coins 9.ogg', s)
  shoot1 = Sound('Shooting Projectile (Classic) 11.ogg', s)
  archer1 = Sound('Releasing Bow String 1.ogg', s)
  wizard1 = Sound('Wind Bolt 20.ogg', s)
  swordsman1 = Sound('Heavy sword woosh 1.ogg', s)
  swordsman2 = Sound('Heavy sword woosh 19.ogg', s)
  scout1 = Sound('Throwing Knife (Thrown) 3.ogg', s)
  scout2 = Sound('Throwing Knife (Thrown) 4.ogg', s)
  arrow_hit_wall1 = Sound('Arrow Impact wood 3.ogg', s)
  arrow_hit_wall2 = Sound('Arrow Impact wood 1.ogg', s)
  hit1 = Sound('Player Takes Damage 17.ogg', s)
  hit2 = Sound('Body Head (Headshot) 1.ogg', s)
  hit3 = Sound('Kick 16_1.ogg', s)
  hit4 = Sound('Kick 16_2.ogg', s)
  sniper_load = Sound('sniper_load.ogg', s)
  proj_hit_wall1 = Sound('Player Takes Damage 2.ogg', s)
  glass_shatter = Sound('Damage 3.ogg', s)
  enemy_die1 = Sound('Bloody punches 7.ogg', s)
  enemy_die2 = Sound('Bloody punches 10.ogg', s)
  magic_area1 = Sound('Fire bolt 10.ogg', s)
  magic_hit1 = Sound('Shadow Punch 1.ogg', s)
  magic_die1 = Sound('Magical Impact 27.ogg', s)
  knife_hit_wall1 = Sound('Shield Impacts Sword 1.ogg', s)
  blade_hit1 = Sound('Sword impact (Flesh) 2.ogg', s)
  player_hit1 = Sound('Body Fall 2.ogg', s)
  player_hit2 = Sound('Body Fall 18.ogg', s)
  player_hit_wall1 = Sound('Wood Heavy 5.ogg', s)
  pop1 = Sound('Pop sounds 10.ogg', s)
  pop2 = Sound('467951__benzix2__ui-button-click.ogg', s)
  pop3 = Sound('258269__jcallison__mouth-pop.ogg', s)
  confirm1 = Sound('80921__justinbw__buttonchime02up.ogg', s)
  heal1 = Sound('Buff 3.ogg', s)
  spawn1 = Sound('Buff 13.ogg', s)
  buff1 = Sound('Buff 14.ogg', s)
  spawn_mark1 = Sound('Bonus 2.ogg', s)
  spawn_mark2 = Sound('Bonus.ogg', s)
  alert1 = Sound('Click.ogg', s)
  elementor1 = Sound('Wind Bolt 18.ogg', s)
  saboteur_hit1 = Sound('Explosion Flesh_01.ogg', s)
  saboteur_hit2 = Sound('Explosion Flesh_02.ogg', s)
  saboteur1 = Sound('Male Jump 1.ogg', s)
  saboteur2 = Sound('Male Jump 2.ogg', s)
  saboteur3 = Sound('Male Jump 3.ogg', s)
  spark1 = Sound('Spark 1.ogg', s)
  spark2 = Sound('Spark 2.ogg', s)
  spark3 = Sound('Spark 3.ogg', s)
  stormweaver1 = Sound('Buff 8.ogg', s)
  cannoneer1 = Sound('Cannon shots 1.ogg', s)
  cannoneer2 = Sound('Cannon shots 7.ogg', s)
  cannon_hit_wall1 = Sound('Cannon impact sounds (Hitting ship) 4.ogg', s)
  pet1 = Sound('Wolf barks 5.ogg', s)
  turret1 = Sound('Sci Fi Machine Gun 7.ogg', s)
  turret2 = Sound('Sniper Shot_09.ogg', s)
  turret_hit_wall1 = Sound('Concrete 6.ogg', s)
  turret_hit_wall2 = Sound('Concrete 7.ogg', s)
  turret_deploy = Sound('321215__hybrid-v__sci-fi-weapons-deploy.ogg', s)
  rogue_crit1 = Sound('Dagger Stab (Flesh) 4.ogg', s)
  rogue_crit2 = Sound('Sword hits another sword 6.ogg', s)

  sweep_sound = Sound('spell_sweep_saber.mp3', s)
  sweep_sound_2 = Sound('spell_sweep_saber_2.mp3', s)

  explosion_new = Sound('explosion_new.wav', s)
  metal_click = Sound('metal_click.wav', s)
  tick_new = Sound('tick_new.wav', s)
  laser_charging = Sound('laser_charging.mp3', s)

  campfire = Sound('campfire.wav', s)



  song1 = Sound('gunnar - 26 hours and I feel Fine.mp3', { tags = { music } })
  song2 = Sound('gunnar - Back On Track.mp3', { tags = { music } })
  song3 = Sound('gunnar - Chrysalis.mp3', { tags = { music } })
  song4 = Sound('gunnar - Fingers.mp3', { tags = { music } })
  song5 = Sound('gunnar - Jam 32 Melancholy.mp3', { tags = { music } })
  song6 = Sound('gunnar - Make It Rain.mp3', { tags = { music } })
  song7 = Sound('gunnar - Mammon.mp3', { tags = { music } })
  song8 = Sound('gunnar - Up To The Brink.mp3', { tags = { music } })

  derp1 = Sound('derp - Negative Space.mp3')
  death_song = nil


  lock_image            = Image('lock')
  speed_booster_elite   = Image('speed_booster_elite')
  exploder_elite        = Image('exploder_elite')
  swarmer_elite         = Image('swarmer_elite')
  forcer_elite          = Image('forcer_elite')
  cluster_elite         = Image('cluster_elite')
  warrior               = Image('warrior')
  ranger                = Image('ranger')
  healer                = Image('healer')
  mage                  = Image('mage')
  buffer                = Image('mage')
  rogue                 = Image('rogue')
  nuker                 = Image('nuker')
  conjurer              = Image('conjurer')
  enchanter             = Image('enchanter')
  psyker                = Image('psyker')
  curser                = Image('curser')
  cursed                = Image('curser')
  forcer                = Image('forcer')
  swarmer               = Image('swarmer')
  voider                = Image('voider')
  sorcerer              = Image('sorcerer')
  mercenary             = Image('mercenary')
  explorer              = Image('explorer')
  star                  = Image('star')
  arrow                 = Image('arrow')
  centipede             = Image('centipede')
  ouroboros_technique_r = Image('ouroboros_technique_r')
  ouroboros_technique_l = Image('ouroboros_technique_l')
  amplify               = Image('amplify')
  resonance             = Image('resonance')
  ballista              = Image('ballista')
  call_of_the_void      = Image('call_of_the_void')
  crucio                = Image('crucio')
  speed_3               = Image('speed_3')
  damage_4              = Image('damage_4')
  shoot_5               = Image('shoot_5')
  death_6               = Image('death_6')
  lasting_7             = Image('lasting_7')
  defensive_stance      = Image('defensive_stance')
  offensive_stance      = Image('offensive_stance')
  kinetic_bomb          = Image('kinetic_bomb')
  porcupine_technique   = Image('porcupine_technique')
  last_stand            = Image('last_stand')
  seeping               = Image('seeping')
  deceleration          = Image('deceleration')
  annihilation          = Image('annihilation')
  malediction           = Image('malediction')
  hextouch              = Image('hextouch')
  whispers_of_doom      = Image('whispers_of_doom')
  tremor                = Image('tremor')
  heavy_impact          = Image('heavy_impact')
  fracture              = Image('fracture')
  meat_shield           = Image('meat_shield')
  hive                  = Image('hive')
  baneling_burst        = Image('baneling_burst')
  blunt_arrow           = Image('blunt_arrow')
  explosive_arrow       = Image('explosive_arrow')
  divine_machine_arrow  = Image('divine_machine_arrow')
  chronomancy           = Image('chronomancy')
  awakening             = Image('awakening')
  divine_punishment     = Image('divine_punishment')
  assassination         = Image('assassination')
  flying_daggers        = Image('flying_daggers')
  ultimatum             = Image('ultimatum')
  magnify               = Image('magnify')
  echo_barrage          = Image('echo_barrage')
  unleash               = Image('unleash')
  reinforce             = Image('reinforce')
  payback               = Image('payback')
  enchanted             = Image('enchanted')
  freezing_field        = Image('freezing_field')
  burning_field         = Image('burning_field')
  gravity_field         = Image('gravity_field')
  magnetism             = Image('magnetism')
  insurance             = Image('insurance')
  dividends             = Image('dividends')
  berserking            = Image('berserking')
  unwavering_stance     = Image('unwavering_stance')
  unrelenting_stance    = Image('unrelenting_stance')
  blessing              = Image('blessing')
  haste                 = Image('haste')
  divine_barrage        = Image('divine_barrage')
  orbitism              = Image('orbitism')
  psyker_orbs           = Image('psyker_orbs')
  psychosense           = Image('psychosense')
  psychosink            = Image('psychosink')
  rearm                 = Image('rearm')
  taunt                 = Image('taunt')
  construct_instability = Image('construct_instability')
  intimidation          = Image('intimidation')
  vulnerability         = Image('vulnerability')
  temporal_chains       = Image('temporal_chains')
  ceremonial_dagger     = Image('ceremonial_dagger')
  homing_barrage        = Image('homing_barrage')
  critical_strike       = Image('critical_strike')
  noxious_strike        = Image('noxious_strike')
  infesting_strike      = Image('infesting_strike')
  kinetic_strike        = Image('kinetic_strike')
  burning_strike        = Image('burning_strike')
  lucky_strike          = Image('lucky_strike')
  healing_strike        = Image('healing_strike')
  stunning_strike       = Image('stunning_strike')
  silencing_strike      = Image('silencing_strike')
  warping_shots         = Image('warping_shots')
  culling_strike        = Image('culling_strike')
  lightning_strike      = Image('lightning_strike')
  psycholeak            = Image('psycholeak')
  divine_blessing       = Image('divine_blessing')
  hardening             = Image('hardening')

  
  ITEM_SIZE_W           = 40
  ITEM_SIZE_H           = 50
  
  --new items
  local d               = 'newItems/'
  skull                 = Image(d .. 'skull-small')
  potion2               = Image(d .. 'potion2')
  fancyarmor            = Image(d .. 'fancyarmor')
  turtle                = Image(d .. 'turtle')
  leaf                  = Image(d .. 'leaf')
  simpleshield          = Image(d .. 'simpleshield')
  linegoesup            = Image(d .. 'linegoesup')
  orb                   = Image(d .. 'orb')
  sword                 = Image(d .. 'sword')
  rock                  = Image(d .. 'rock')
  flask                 = Image(d .. 'flask')
  gem                   = Image(d .. 'gem')
  sun                   = Image(d .. 'sun')
  simpleboots           = Image(d .. 'simpleboots')
  mace                  = Image(d .. 'mace')
  fire                  = Image(d .. 'fire')
  lightning             = Image(d .. 'lightning')
  clam                  = Image(d .. 'clam')

  arrows                = Image(d .. 'arrows')
  bear                  = Image(d .. 'bear')
  bomb                  = Image(d .. 'bomb')
  boots                 = Image(d .. 'boots')
  bow                   = Image(d .. 'bow')
  cactus                = Image(d .. 'cactus')
  cat                   = Image(d .. 'cat2')
  cauldron              = Image(d .. 'cauldron')
  crystalball           = Image(d .. 'crystalball')
  egg                   = Image(d .. 'egg')
  gloves                = Image(d .. 'fingerlessgloves')
  frostorb              = Image(d .. 'frostorb')


-- normal and stopped are tied together for the purpose of attacking
-- rallying and following are tied together for the purpose of moving
  unit_states = {
    ['normal'] = 'normal',
    ['frozen'] = 'frozen',
    ['casting'] = 'casting',
    ['channeling'] = 'channeling',
    ['stopped'] = 'stopped',
    ['rallying'] = 'rallying',
    ['following'] = 'following'
  }

  type_colors = {
    ['warrior'] = yellow[0],
    ['ranger'] = green[0],
    ['healer'] = green[0],
    ['conjurer'] = orange[0],
    ['mage'] = blue[0],
    ['nuker'] = red[0],
    ['rogue'] = red[0],
    ['enchanter'] = blue[0],
    ['psyker'] = fg[0],
    ['curser'] = purple[0],
    ['cursed'] = purple[0],
    ['forcer'] = yellow[0],
    ['swarmer'] = orange[0],
    ['voider'] = purple[0],
    ['sorcerer'] = blue2[0],
    ['mercenary'] = yellow2[0],
    ['explorer'] = fg[0],
    ['buffer'] = brown[0],
  }

  type_color_strings = {
    ['warrior'] = 'yellow',
    ['ranger'] = 'green',
    ['healer'] = 'green',
    ['conjurer'] = 'orange',
    ['mage'] = 'blue',
    ['nuker'] = 'red',
    ['rogue'] = 'red',
    ['enchanter'] = 'blue',
    ['psyker'] = 'fg',
    ['curser'] = 'purple',
    ['forcer'] = 'yellow',
    ['swarmer'] = 'orange',
    ['voider'] = 'purple',
    ['sorcerer'] = 'blue2',
    ['mercenary'] = 'yellow2',
    ['explorer'] = 'fg',
    ['cursed'] = 'purple',
    ['buffer'] = 'brown'
  }

  character_names = {
    ['vagrant'] = 'Vagrant',
    ['swordsman'] = 'Swordsman',
    ['wizard'] = 'Wizard',
    ['magician'] = 'Magician',
    ['pyro'] = 'Pyro',
    ['laser'] = 'Laser',
    ['archer'] = 'Archer',
    ['bomber'] = 'Bomber',
    ['cannon'] = 'Cannon',
    ['sniper'] = 'Sniper',
    ['scout'] = 'Scout',
    ['cleric'] = 'Cleric',
    ['shaman'] = 'Shaman',
    ['druid'] = 'Druid',
    ['necromancer'] = 'Necromancer',
    ['paladin'] = 'Paladin',
    ['bard'] = 'Bard',
    ['outlaw'] = 'Outlaw',
    ['blade'] = 'Blade',
    ['elementor'] = 'Elementor',
    ['saboteur'] = 'Saboteur',
    ['stormweaver'] = 'Stormweaver',
    ['sage'] = 'Sage',
    ['squire'] = 'Squire',
    ['cannoneer'] = 'Cannoneer',
    ['dual_gunner'] = 'Dual Gunner',
    ['hunter'] = 'Hunter',
    ['sentry'] = 'Sentry',
    ['chronomancer'] = 'Chronomancer',
    ['spellblade'] = 'Spellblade',
    ['psykeeper'] = 'Psykeeper',
    ['engineer'] = 'Engineer',
    ['plague_doctor'] = 'Plague Doctor',
    ['barbarian'] = 'Barbarian',
    ['juggernaut'] = 'Juggernaut',
    ['lich'] = 'Lich',
    ['cryomancer'] = 'Cryomancer',
    ['pyromancer'] = 'Pyromancer',
    ['corruptor'] = 'Corruptor',
    ['beastmaster'] = 'Beastmaster',
    ['launcher'] = 'Launcher',
    ['jester'] = 'Jester',
    ['assassin'] = 'Assassin',
    ['host'] = 'Host',
    ['carver'] = 'Carver',
    ['bane'] = 'Bane',
    ['psykino'] = 'Psykino',
    ['barrager'] = 'Barrager',
    ['highlander'] = 'Highlander',
    ['fairy'] = 'Fairy',
    ['priest'] = 'Priest',
    ['infestor'] = 'Infestor',
    ['flagellant'] = 'Flagellant',
    ['arcanist'] = 'Arcanist',
    ['illusionist'] = 'Illusionist',
    ['artificer'] = 'Artificer',
    ['witch'] = 'Witch',
    ['silencer'] = 'Silencer',
    ['vulcanist'] = 'Vulcanist',
    ['warden'] = 'Warden',
    ['psychic'] = 'Psychic',
    ['miner'] = 'Miner',
    ['merchant'] = 'Merchant',
    ['usurer'] = 'Usurer',
    ['gambler'] = 'Gambler',
    ['thief'] = 'Thief',
  }

  character_colors = {
    ['vagrant'] = fg[0],
    ['swordsman'] = orange[0],
    ['wizard'] = blue[0],
    ['magician'] = blue[0],
    ['pyro'] = red[0],
    ['cannon'] = green[0],
    ['sniper'] = green[0],
    ['laser'] = blue[0],
    ['archer'] = yellow[0],
    ['bomber'] = orange[0],
    ['scout'] = red[0],
    ['cleric'] = green[0],
    ['shaman'] = blue[0],
    ['druid'] = green[0],
    ['paladin'] = yellow[0],
    ['bard'] = brown[0],
    ['necromancer'] = purple[0],
    ['outlaw'] = red[0],
    ['blade'] = yellow[0],
    ['elementor'] = blue[0],
    ['saboteur'] = orange[0],
    ['stormweaver'] = blue[0],
    ['sage'] = purple[0],
    ['squire'] = yellow[0],
    ['cannoneer'] = orange[0],
    ['dual_gunner'] = green[0],
    ['hunter'] = green[0],
    ['sentry'] = green[0],
    ['chronomancer'] = blue[0],
    ['spellblade'] = blue[0],
    ['psykeeper'] = fg[0],
    ['engineer'] = orange[0],
    ['plague_doctor'] = purple[0],
    ['barbarian'] = yellow[0],
    ['juggernaut'] = yellow[0],
    ['lich'] = blue[0],
    ['cryomancer'] = blue[0],
    ['pyromancer'] = red[0],
    ['corruptor'] = orange[0],
    ['beastmaster'] = red[0],
    ['launcher'] = yellow[0],
    ['jester'] = red[0],
    ['assassin'] = purple[0],
    ['host'] = orange[0],
    ['carver'] = green[0],
    ['bane'] = purple[0],
    ['psykino'] = fg[0],
    ['barrager'] = green[0],
    ['highlander'] = yellow[0],
    ['fairy'] = green[0],
    ['priest'] = green[0],
    ['infestor'] = orange[0],
    ['flagellant'] = fg[0],
    ['arcanist'] = blue2[0],
    ['illusionist'] = blue2[0],
    ['artificer'] = blue2[0],
    ['witch'] = purple[0],
    ['silencer'] = blue2[0],
    ['vulcanist'] = red[0],
    ['warden'] = yellow[0],
    ['psychic'] = fg[0],
    ['miner'] = yellow2[0],
    ['merchant'] = yellow2[0],
    ['usurer'] = purple[0],
    ['gambler'] = yellow2[0],
    ['thief'] = red[0],
  }

  character_color_strings = {
    ['vagrant'] = 'fg',
    ['swordsman'] = 'orange',
    ['wizard'] = 'blue',
    ['magician'] = 'blue',
    ['pyro'] = 'red',
    ['laser'] = 'blue',
    ['archer'] = 'yellow',
    ['bomber'] = 'orange',
    ['cannon'] = 'green',
    ['sniper'] = 'green',
    ['scout'] = 'red',
    ['cleric'] = 'green',
    ['shaman'] = 'blue',
    ['druid'] = 'green',
    ['necromancer'] = 'purple',
    ['paladin'] = 'yellow',
    ['bard'] = 'orange',
    ['outlaw'] = 'red',
    ['blade'] = 'yellow',
    ['elementor'] = 'blue',
    ['saboteur'] = 'orange',
    ['stormweaver'] = 'blue',
    ['sage'] = 'purple',
    ['squire'] = 'yellow',
    ['cannoneer'] = 'orange',
    ['dual_gunner'] = 'green',
    ['hunter'] = 'green',
    ['sentry'] = 'green',
    ['chronomancer'] = 'blue',
    ['spellblade'] = 'blue',
    ['psykeeper'] = 'fg',
    ['engineer'] = 'orange',
    ['plague_doctor'] = 'purple',
    ['barbarian'] = 'yellow',
    ['juggernaut'] = 'yellow',
    ['lich'] = 'blue',
    ['cryomancer'] = 'blue',
    ['pyromancer'] = 'red',
    ['corruptor'] = 'orange',
    ['beastmaster'] = 'red',
    ['launcher'] = 'yellow',
    ['jester'] = 'red',
    ['assassin'] = 'purple',
    ['host'] = 'orange',
    ['carver'] = 'green',
    ['bane'] = 'purple',
    ['psykino'] = 'fg',
    ['barrager'] = 'green',
    ['highlander'] = 'yellow',
    ['fairy'] = 'green',
    ['priest'] = 'green',
    ['infestor'] = 'orange',
    ['flagellant'] = 'fg',
    ['arcanist'] = 'blue2',
    ['illusionist'] = 'blue2',
    ['artificer'] = 'blue2',
    ['witch'] = 'purple',
    ['silencer'] = 'blue2',
    ['vulcanist'] = 'red',
    ['warden'] = 'yellow',
    ['psychic'] = 'fg',
    ['miner'] = 'yellow2',
    ['merchant'] = 'yellow2',
    ['usurer'] = 'purple',
    ['gambler'] = 'yellow2',
    ['thief'] = 'red',
  }

  character_types = {
    ['swordsman'] = 'warrior',
    ['juggernaut'] = 'warrior',
    ['pyro'] = 'nuker',
    ['cannon'] = 'ranger',
    ['sniper'] = 'ranger',
    ['laser'] = 'mage',
    ['archer'] = 'ranger',
    ['bomber'] = 'nuker',
    ['wizard'] = 'mage',
    ['shaman'] = 'mage',
    ['druid'] = 'healer',
    ['bard'] = 'buffer',
    ['paladin'] = 'warrior',
    ['necromancer'] = 'cursed',
    ['cleric'] = 'healer',
    ['priest'] = 'healer',
  }

  character_type_strings = {
    ['vagrant'] = '[fg]Explorer, Psyker',
    ['swordsman'] = '[orange]Warrior',
    ['wizard'] = '[blue]Mage, [red]Nuker',
    ['magician'] = '[blue]Mage',
    ['pyro'] = '[red]Nuker',
    ['cannon'] = '[green]Ranger',
    ['sniper'] = '[green]Ranger',
    ['laser'] = '[blue]Mage',
    ['archer'] = '[yellow]Warrior, [green]Ranger',
    ['bomber'] = '[red]Nuker, [orange]Builder',
    ['scout'] = '[red]Rogue',
    ['cleric'] = '[green]Healer',
    ['shaman'] = '[blue]Mage',
    ['druid'] = '[green]Healer',
    ['paladin'] = '[yellow]Warrior',
    ['bard'] = '[brown]Buffer',
    ['necromancer'] = '[purple]Cursed',
    ['outlaw'] = '[yellow]Warrior, [red]Rogue',
    ['blade'] = '[yellow]Warrior, [red]Nuker',
    ['elementor'] = '[blue]Mage, [red]Nuker',
    -- ['saboteur'] = '[red]Rogue, [orange]Conjurer, [red]Nuker',
    ['stormweaver'] = '[blue]Enchanter',
    ['sage'] = '[red]Nuker, [yellow]Forcer',
    ['squire'] = '[yellow]Warrior, [blue]Enchanter',
    ['cannoneer'] = '[green]Ranger, [red]Nuker',
    ['dual_gunner'] = '[green]Ranger, [red]Rogue',
    -- ['hunter'] = '[green]Ranger, [orange]Conjurer, [yellow]Forcer',
    ['sentry'] = '[green]Ranger, [orange]Builder',
    ['chronomancer'] = '[blue]Mage, Enchanter',
    ['spellblade'] = '[blue]Mage, [red]Rogue',
    ['psykeeper'] = '[green]Healer, [fg]Psyker',
    ['engineer'] = '[orange]Builder',
    ['plague_doctor'] = '[red]Nuker, [purple]Voider',
    ['barbarian'] = '[purple]Curser, [yellow]Warrior',
    ['juggernaut'] = '[yellow]Forcer, Warrior',
    ['lich'] = '[blue]Mage',
    ['cryomancer'] = '[blue]Mage, [purple]Voider',
    ['pyromancer'] = '[blue]Mage, [red]Nuker, [purple]Voider',
    ['corruptor'] = '[green]Ranger, [orange]Swarmer',
    ['beastmaster'] = '[red]Rogue, [orange]Swarmer',
    ['launcher'] = '[yellow]Forcer, [purple]Curser',
    ['jester'] = '[purple]Curser, [red]Rogue',
    ['assassin'] = '[red]Rogue, [purple]Voider',
    ['host'] = '[orange]Swarmer',
    ['carver'] = '[orange]Builder, [green]Healer',
    ['bane'] = '[purple]Curser, Voider',
    ['psykino'] = '[blue]Mage, [fg]Psyker, [yellow]Forcer',
    ['barrager'] = '[green]Ranger, [yellow]Forcer',
    ['highlander'] = '[yellow]Warrior',
    ['fairy'] = '[blue]Enchanter, [green]Healer',
    ['priest'] = '[green]Healer',
    ['infestor'] = '[purple]Curser, [orange]Swarmer',
    ['flagellant'] = '[fg]Psyker, [blue]Enchanter',
    ['arcanist'] = '[blue2]Sorcerer',
    -- ['illusionist'] = '[blue2]Sorcerer, [orange]Conjurer',
    ['artificer'] = '[blue2]Sorcerer, [orange]Builder',
    ['witch'] = '[blue2]Sorcerer, [purple]Voider',
    ['silencer'] = '[blue2]Sorcerer, [purple]Curser',
    ['vulcanist'] = '[blue2]Sorcerer, [red]Nuker',
    ['warden'] = '[blue2]Sorcerer, [yellow]Forcer',
    ['psychic'] = '[blue2]Sorcerer, [fg]Psyker',
    ['miner'] = '[yellow2]Mercenary',
    ['merchant'] = '[yellow2]Mercenary',
    ['usurer'] = '[purple]Curser, [yellow2]Mercenary, [purple]Voider',
    ['gambler'] = '[yellow2]Mercenary, [blue2]Sorcerer',
    ['thief'] = '[red]Rogue, [yellow2]Mercenary',
  }

  get_character_stat_string = function(character, level)
    local group = Group():set_as_physics_world(32, 0, 0, { 'troop', 'enemy', 'projectile', 'enemy_projectile' })
    local troop_data = { group = group, leader = true, character = character, level = level, follower_index = 1 }
    local troop = Create_Troop(troop_data)
    troop:update(0)
    return '[red]HP: [red]' ..
        troop.max_hp ..
        '[fg], [red]DMG: [red]' ..
        troop.dmg .. '[fg], [green]ASPD: [green]' .. math.round(troop.aspd_m, 2) .. 'x[fg], [blue]AREA: [blue]' ..
        math.round(troop.area_size_m, 2) ..
        'x[fg], [yellow]DEF: [yellow]' ..
        math.round(troop.def, 2) .. '[fg], [green]MVSPD: [green]' .. math.round(troop.v, 2) .. '[fg]'
  end

  get_character_stat = function(character, level, stat)
    local group = Group():set_as_physics_world(32, 0, 0, { 'troop', 'enemy', 'projectile', 'enemy_projectile' })
    local troop_data = { group = group, leader = true, character = character, level = level, follower_index = 1 }
    local troop = Create_Troop(troop_data)
    troop:update(0)
    return math.round(troop[stat], 2)
  end

  get_unit_stats = function(unit)
    local group = Group():set_as_physics_world(32, 0, 0, { 'troop', 'enemy', 'projectile', 'enemy_projectile' })
    local troop_data = { group = group, character = unit.character, level = unit.level, items = unit.items }
    local troop = Create_Troop(troop_data)
    troop:update(0)
    return troop:get_item_stats()
  end

  get_unit_buffs = function(unit)
    local group = Group():set_as_physics_world(32, 0, 0, { 'troop', 'enemy', 'projectile', 'enemy_projectile' })
    local troop_data = { group = group, character = unit.character, level = unit.level, items = unit.items }
    local troop = Create_Troop(troop_data)
    troop:update(0)
    return troop:get_buff_names()
  end

  build_character_info_text = function(unit)
    local item_stats = get_unit_stats(unit)
    local buffs = get_unit_buffs(unit)
    local text_lines = {}

    local next_line = { text = '', font = pixul_font, alignment = 'center' }
    next_line.text = unit.character:capitalize() .. ': '

    table.insert(text_lines, next_line)
    --add item stats
    if #item_stats > 0 then
      next_line = { text = '', font = pixul_font, alignment = 'center' }
      next_line.text = 'Item stats:'
      table.insert(text_lines, next_line)
    end
    for k, v in pairs(item_stats) do
      next_line = { text = '', font = pixul_font, alignment = 'left' }
      next_line.text = '+' .. (v * 100) .. '% ' .. k:capitalize()
      table.insert(text_lines, next_line)
    end
    --add item buffs
    if #buffs > 0 then
      next_line = { text = '', font = pixul_font, alignment = 'center' }
      next_line.text = 'Item buffs:'
      table.insert(text_lines, next_line)
    end
    for k, v in pairs(buffs) do
      next_line = { text = '', font = pixul_font, alignment = 'left' }
      next_line.text = v
      table.insert(text_lines, next_line)
    end

    local info_text = InfoText { group = main.current.ui, force_update = false }
    info_text:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)

    return info_text
  end

  build_character_text = function(unit)
    local item_stats = get_unit_stats(unit)
    local buffs = get_unit_buffs(unit)

    local text_lines = {}
    local next_line = { text = '', font = pixul_font, alignment = 'center' }
    for k, v in pairs(item_stats) do
      next_line = { text = '', font = pixul_font, alignment = 'center' }
      next_line.text = '[yellow[0]]+' .. (v * 100) .. '% ' .. k:capitalize()
      table.insert(text_lines, next_line)
    end

    local text2 = Text2 { group = main.current.ui, x = 0, y = 0,
      lines = text_lines, font = pixul_font, alignment = 'center',
      force_update = false }


    return text2
  end

  character_descriptions = {
    ['vagrant'] = function(lvl) return '[fg]shoots a projectile that deals [yellow]' ..
      get_character_stat('vagrant', lvl, 'dmg') .. '[fg] damage' end,
    ['swordsman'] = function(lvl)
      return '[fg]deals [yellow]' ..
          get_character_stat('swordsman', lvl, 'dmg') .. '[fg] damage in an area, deals extra [yellow]' ..
          math.round(get_character_stat('swordsman', lvl, 'dmg') * 0.15, 2) .. '[fg] damage per unit hit'
    end,
    ['wizard'] = function(lvl) return '[fg]casts Blizzard' end,
    ['magician'] = function(lvl) return '[fg]creates a small area that deals [yellow]' ..
      get_character_stat('magician', lvl, 'dmg') .. ' AoE[fg] damage' end,
    ['pyro'] = function(lvl) return '[fg]uses a flamethrower [yellow]' ..
      get_character_stat('pyro', lvl, 'dmg') .. '[fg] damage and pierces' end,
    ['cannon'] = function(lvl) return '[fg]shoots a cannon ball that deals [yellow]' ..
      get_character_stat('cannon', lvl, 'dmg') .. '[fg] damage and explodes on impact' end,
    ['sniper'] = function(lvl) return 'sniper shootie' end,
    ['laser'] = function(lvl) return 'laser pew pew' end,
    ['archer'] = function(lvl) return '[fg]shoots an arrow that deals [yellow]' ..
      get_character_stat('archer', lvl, 'dmg') .. '[fg] damage' end,
    ['scout'] = function(lvl) return '[fg]throws a knife that deals [yellow]' ..
      get_character_stat('scout', lvl, 'dmg') .. '[fg] damage and chains [yellow]3[fg] times' end,
    ['cleric'] = function(lvl) return '[fg]heals allied units' end,
    ['shaman'] = function(lvl) return '[fg]casts chain lightning' end,
    ['druid'] = function(lvl) return '[fg]casts a heal over time spell on allies' end,
    ['bard'] = function(lvl) return '[fg]dunno yet, buffs something' end,
    ['necromancer'] = function(lvl) return '[fg]creates up to [yellow]3[fg] skeletons' end,
    ['paladin'] = function(lvl) return '[fg]protects hurt allies with an invulnerable bubble' end,
    ['outlaw'] = function(lvl) return '[fg]throws a fan of [yellow]5[fg] knives, each dealing [yellow]' ..
      get_character_stat('outlaw', lvl, 'dmg') .. '[fg] damage' end,
    ['blade'] = function(lvl) return '[fg]throws multiple blades that deal [yellow]' ..
      get_character_stat('blade', lvl, 'dmg') .. ' AoE[fg] damage' end,
    ['elementor'] = function(lvl) return '[fg]deals [yellow]' ..
      get_character_stat('elementor', lvl, 'dmg') .. ' AoE[fg] damage in a large area centered on a random target' end,
    ['saboteur'] = function(lvl) return '[fg]calls [yellow]2[fg] saboteurs to seek targets and deal [yellow]' ..
      get_character_stat('saboteur', lvl, 'dmg') .. ' AoE[fg] damage' end,
    ['bomber'] = function(lvl) return '[fg]plants a bomb, when it explodes it deals [yellow]' ..
      2 * get_character_stat('bomber', lvl, 'dmg') .. ' AoE[fg] damage' end,
    ['stormweaver'] = function(lvl) return
      '[fg]infuses projectiles with chain lightning that deals [yellow]20%[fg] damage to [yellow]2[fg] enemies' end,
    ['sage'] = function(lvl) return '[fg]shoots a slow projectile that draws enemies in' end,
    ['squire'] = function(lvl) return '[yellow]+20%[fg] damage and defense to all allies' end,
    ['cannoneer'] = function(lvl) return '[fg]shoots a projectile that deals [yellow]' ..
      2 * get_character_stat('cannoneer', lvl, 'dmg') .. ' AoE[fg] damage' end,
    ['dual_gunner'] = function(lvl) return '[fg]shoots two parallel projectiles, each dealing [yellow]' ..
      get_character_stat('dual_gunner', lvl, 'dmg') .. '[fg] damage' end,
    ['hunter'] = function(lvl) return '[fg]shoots an arrow that deals [yellow]' ..
      get_character_stat('hunter', lvl, 'dmg') .. '[fg] damage and has a [yellow]20%[fg] chance to summon a pet' end,
    ['sentry'] = function(lvl) return
      '[fg]spawns a rotating turret that shoots [yellow]4[fg] projectiles, each dealing [yellow]' ..
      get_character_stat('sentry', lvl, 'dmg') .. '[fg] damage' end,
    ['chronomancer'] = function(lvl) return '[yellow]+20%[fg] attack speed to all allies' end,
    ['spellblade'] = function(lvl) return '[fg]throws knives that deal [yellow]' ..
      get_character_stat('spellblade', lvl, 'dmg') .. '[fg] damage, pierce and spiral outwards' end,
    ['psykeeper'] = function(lvl) return
      '[fg]creates [yellow]3[fg] healing orbs every time the psykeeper takes [yellow]25%[fg] of its max HP in damage' end,
    ['engineer'] = function(lvl) return '[fg]drops turrets that shoot bursts of projectiles, each dealing [yellow]' ..
      get_character_stat('engineer', lvl, 'dmg') .. '[fg] damage' end,
    ['plague_doctor'] = function(lvl) return '[fg]creates an area that deals [yellow]' ..
      get_character_stat('plague_doctor', lvl, 'dmg') .. '[fg] damage per second' end,
    ['barbarian'] = function(lvl) return '[fg]deals [yellow]' ..
      get_character_stat('barbarian', lvl, 'dmg') .. '[fg] AoE damage and stuns enemies hit for [yellow]4[fg] seconds' end,
    ['juggernaut'] = function(lvl) return '[fg]deals [yellow]' ..
      get_character_stat('juggernaut', lvl, 'dmg') .. '[fg] AoE damage and pushes enemies away with a strong force' end,
    ['lich'] = function(lvl) return '[fg]launches a slow projectile that jumps [yellow]7[fg] times, dealing [yellow]' ..
      2 * get_character_stat('lich', lvl, 'dmg') .. '[fg] damage per hit' end,
    ['cryomancer'] = function(lvl) return '[fg]nearby enemies take [yellow]' ..
      get_character_stat('cryomancer', lvl, 'dmg') .. '[fg] damage per second' end,
    ['pyromancer'] = function(lvl) return '[fg]nearby enemies take [yellow]' ..
      get_character_stat('pyromancer', lvl, 'dmg') .. '[fg] damage per second' end,
    ['corruptor'] = function(lvl) return '[fg]shoots an arrow that deals [yellow]' ..
      get_character_stat('corruptor', lvl, 'dmg') .. '[fg] damage, spawn [yellow]3[fg] critters if it kills' end,
    ['beastmaster'] = function(lvl) return '[fg]throws a knife that deals [yellow]' ..
      get_character_stat('beastmaster', lvl, 'dmg') .. '[fg] damage, spawn [yellow]2[fg] critters if it crits' end,
    ['launcher'] = function(lvl) return '[fg]all nearby enemies are pushed after [yellow]4[fg] seconds, taking [yellow]' ..
      2 * get_character_stat('launcher', lvl, 'dmg') .. '[fg] damage on wall hit' end,
    ['jester'] = function(lvl) return
      "[fg]curses [yellow]6[fg] nearby enemies for [yellow]6[fg] seconds, they will explode into [yellow]4[fg] knives on death" end,
    ['assassin'] = function(lvl)
      return '[fg]throws a piercing knife that deals [yellow]' ..
          get_character_stat('assassin', lvl, 'dmg') .. '[fg] damage + [yellow]' ..
          get_character_stat('assassin', lvl, 'dmg') / 2 .. '[fg] damage per second'
    end,
    ['host'] = function(lvl) return '[fg]periodically spawn [yellow]1[fg] small critter' end,
    ['carver'] = function(lvl) return
      '[fg]carves a statue that creates [yellow]1[fg] healing orb every [yellow]6[fg] seconds' end,
    ['bane'] = function(lvl) return
      '[fg]curses [yellow]6[fg] nearby enemies for [yellow]6[fg] seconds, they will create small void rifts on death' end,
    ['psykino'] = function(lvl) return '[fg]pulls enemies together for [yellow]2[fg] seconds' end,
    ['barrager'] = function(lvl) return '[fg]shoots a barrage of [yellow]3[fg] arrows, each dealing [yellow]' ..
      get_character_stat('barrager', lvl, 'dmg') .. '[fg] damage and pushing enemies' end,
    ['highlander'] = function(lvl) return '[fg]deals [yellow]' ..
      5 * get_character_stat('highlander', lvl, 'dmg') .. '[fg] AoE damage' end,
    ['fairy'] = function(lvl) return
      '[fg]creates [yellow]1[fg] healing orb and grants [yellow]1[fg] unit [yellow]+100%[fg] attack speed for [yellow]6[fg] seconds' end,
    ['priest'] = function(lvl) return '[fg]shields allies' end,
    ['infestor'] = function(lvl) return
      '[fg]curses [yellow]8[fg] nearby enemies for [yellow]6[fg] seconds, they will release [yellow]2[fg] critters on death' end,
    ['flagellant'] = function(lvl) return '[fg]deals [yellow]' ..
      2 * get_character_stat('flagellant', lvl, 'dmg') ..
      '[fg] damage to self and grants [yellow]+4%[fg] damage to all allies per cast' end,
    ['arcanist'] = function(lvl) return '[fg]launches a slow moving orb that launches projectiles, each dealing [yellow]' ..
      get_character_stat('arcanist', lvl, 'dmg') .. '[fg] damage' end,
    ['illusionist'] = function(lvl) return '[fg]launches a projectile that deals [yellow]' ..
      get_character_stat('illusionist', lvl, 'dmg') .. '[fg] damage and creates copies that do the same' end,
    ['artificer'] = function(lvl) return '[fg]spawns an automaton that shoots a projectile that deals [yellow]' ..
      get_character_stat('artificer', lvl, 'dmg') .. '[fg] damage' end,
    ['witch'] = function(lvl) return '[fg]creates an area that ricochets and deals [yellow]' ..
      get_character_stat('witch', lvl, 'dmg') .. '[fg] damage per second' end,
    ['silencer'] = function(lvl) return
      '[fg]curses [yellow]5[fg] nearby enemies for [yellow]6[fg] seconds, preventing them from using special attacks' end,
    ['vulcanist'] = function(lvl) return
      '[fg]creates a volcano that explodes the nearby area [yellow]4[fg] times, dealing [yellow]' ..
      get_character_stat('vulcanist', lvl, 'dmg') .. ' AoE [fg]damage' end,
    ['warden'] = function(lvl) return
      '[fg]creates a force field around a random unit that prevents enemies from entering' end,
    ['psychic'] = function(lvl) return '[fg]creates a small area that deals [yellow]' ..
      get_character_stat('psychic', lvl, 'dmg') .. ' AoE[fg] damage' end,
    ['miner'] = function(lvl) return
      '[fg]picking up gold releases [yellow]4[fg] homing projectiles that each deal [yellow]' ..
      get_character_stat('miner', lvl, 'dmg') .. ' [fg]damage' end,
    ['merchant'] = function(lvl) return
      '[fg]gain [yellow]+1[fg] interest for every [yellow]10[fg] gold, up to a max of [yellow]+10[fg] from the merchant' end,
    ['usurer'] = function(lvl) return '[fg]curses [yellow]3[fg] nearby enemies indefinitely with debt, dealing [yellow]' ..
      get_character_stat('usurer', lvl, 'dmg') .. '[fg] damage per second' end,
    ['gambler'] = function(lvl) return
      '[fg]deal [yellow]2X[fg] damage to a single random enemy where X is how much gold you have' end,
    ['thief'] = function(lvl) return '[fg]throws a knife that deals [yellow]' ..
      2 * get_character_stat('thief', lvl, 'dmg') .. '[fg] damage and chains [yellow]5[fg] times' end,
  }

  character_effect_names = {
    ['vagrant'] = '[fg]Experience',
    ['swordsman'] = '[orange]Cleave',
    ['wizard'] = '[blue]',
    ['magician'] = '[blue]Quick Cast',
    ['pyro'] = '[red]Flamethrower',
    ['sniper'] = '[green]Snipe',
    ['cannon'] = '[green]Cannon Ball',
    ['laser'] = '[blue]Laser',
    ['archer'] = '[yellow]Arrow',
    ['scout'] = '[red]Dagger Resonance',
    ['cleric'] = '[green]Heal',
    ['shaman'] = '[blue]Chain Lightning',
    ['druid'] = '[green]Regrowth',
    ['bard'] = '[brown]Attack Dmg buff',
    ['necromancer'] = '[purple]Reanimate Dead',
    ['paladin'] = '[yellow]Divine Protection',
    ['outlaw'] = '[red]Flying Daggers',
    ['blade'] = '[yellow]Blade Resonance',
    ['elementor'] = '[blue]Windfield',
    ['saboteur'] = '[orange]Demoman',
    ['bomber'] = '[orange]Demoman',
    ['stormweaver'] = '[blue]Wide Lightning',
    ['sage'] = '[purple]Dimension Compression',
    ['squire'] = '[yellow]Shiny Gear',
    ['cannoneer'] = '[orange]Cannon Barrage',
    ['dual_gunner'] = '[green]Gun Kata',
    ['hunter'] = '[green]Feral Pack',
    ['sentry'] = '[green]Sentry Barrage',
    ['chronomancer'] = '[blue]Quicken',
    ['spellblade'] = '[blue]Spiralism',
    ['psykeeper'] = '[fg]Crucio',
    ['engineer'] = '[orange]Upgrade!!!',
    ['plague_doctor'] = '[purple]Black Death Steam',
    ['barbarian'] = '[yellow]Seism',
    ['juggernaut'] = '[yellow]Brutal Impact',
    ['lich'] = '[blue]Chain Frost',
    ['cryomancer'] = '[blue]Frostbite',
    ['pyromancer'] = '[red]Ignite',
    ['corruptor'] = '[orange]Corruption',
    ['beastmaster'] = '[red]Call of the Wild',
    ['launcher'] = '[orange]Kineticism',
    ['jester'] = "[red]Pandemonium",
    ['assassin'] = '[purple]Toxic Delivery',
    ['host'] = '[orange]Invasion',
    ['carver'] = '[green]World Tree',
    ['bane'] = '[purple]Nightmare',
    ['psykino'] = '[fg]Magnetic Force',
    ['barrager'] = '[green]Barrage',
    ['highlander'] = '[yellow]Moulinet',
    ['fairy'] = '[green]Whimsy',
    ['priest'] = '[green]Holy Shield',
    ['infestor'] = '[orange]Infestation',
    ['flagellant'] = '[red]Zealotry',
    ['arcanist'] = '[blue2]Arcane Orb',
    ['illusionist'] = '[blue2]Mirror Image',
    ['artificer'] = '[blue2]Spell Formula Efficiency',
    ['witch'] = '[purple]Death Pool',
    ['silencer'] = '[blue2]Arcane Curse',
    ['vulcanist'] = '[red]Lava Burst',
    ['warden'] = '[yellow]Magnetic Field',
    ['psychic'] = '[fg]Mental Strike',
    ['miner'] = '[yellow2]Golden Bolts',
    ['merchant'] = '[yellow2]Item Shop',
    ['usurer'] = '[purple]Bankruptcy',
    ['gambler'] = '[yellow2]Multicast',
    ['thief'] = '[red]Ultrakill',
  }

  character_effect_names_gray = {
    ['vagrant'] = '[light_bg]Experience',
    ['swordsman'] = '[light_bg]Cleave',
    ['wizard'] = '[light_bg]Blizzard',
    ['magician'] = '[light_bg]Quick Cast',
    ['pyro'] = '[light_bg]Flamethrower',
    ['cannon'] = '[light_bg]Cannon Ball',
    ['sniper'] = '[light_bg]Snipe',
    ['laser'] = '[light_bg]Laser',
    ['archer'] = '[light_bg]Arrow',
    ['scout'] = '[light_bg]Dagger Resonance',
    ['cleric'] = '[light_bg]Mass Heal ',
    ['shaman'] = '[light_bg]Chain Lightning',
    ['druid'] = '[light_bg]Regrowth',
    ['bard'] = '[light_bg]]Attack Dmg buff',
    ['paladin'] = '[light_bgDiving Protection',
    ['necromancer'] = '[light_bg]Reanimate Dead',
    ['outlaw'] = '[light_bg]Flying Daggers',
    ['blade'] = '[light_bg]Blade Resonance',
    ['elementor'] = '[light_bg]Windfield',
    ['saboteur'] = '[light_bg]Demoman',
    ['bomber'] = '[light_bg]Demoman',
    ['stormweaver'] = '[light_bg]Wide Lightning',
    ['sage'] = '[light_bg]Dimension Compression',
    ['squire'] = '[light_bg]Shiny Gear',
    ['cannoneer'] = '[light_bg]Cannon Barrage',
    ['dual_gunner'] = '[light_bg]Gun Kata',
    ['hunter'] = '[light_bg]Feral Pack',
    ['sentry'] = '[light_bg]Sentry Barrage',
    ['chronomancer'] = '[light_bg]Quicken',
    ['spellblade'] = '[light_bg]Spiralism',
    ['psykeeper'] = '[light_bg]Crucio',
    ['engineer'] = '[light_bg]Upgrade!!!',
    ['plague_doctor'] = '[light_bg]Black Death Steam',
    ['barbarian'] = '[light_bg]Seism',
    ['juggernaut'] = '[light_bg]Brutal Impact',
    ['lich'] = '[light_bg]Chain Frost',
    ['cryomancer'] = '[light_bg]Frostbite',
    ['pyromancer'] = '[light_bg]Ignite',
    ['corruptor'] = '[light_bg]Corruption',
    ['beastmaster'] = '[light_bg]Call of the Wild',
    ['launcher'] = '[light_bg]Kineticism',
    ['jester'] = "[light_bg]Pandemonium",
    ['assassin'] = '[light_bg]Toxic Delivery',
    ['host'] = '[light_bg]Invasion',
    ['carver'] = '[light_bg]World Tree',
    ['bane'] = '[light_bg]Nightmare',
    ['psykino'] = '[light_bg]Magnetic Force',
    ['barrager'] = '[light_bg]Barrage',
    ['highlander'] = '[light_bg]Moulinet',
    ['fairy'] = '[light_bg]Whimsy',
    ['priest'] = '[light_bg]Holy Shield',
    ['infestor'] = '[light_bg]Infestation',
    ['flagellant'] = '[light_bg]Zealotry',
    ['arcanist'] = '[light_bg]Arcane Orb',
    ['illusionist'] = '[light_bg]Mirror Image',
    ['artificer'] = '[light_bg]Spell Formula Efficiency',
    ['witch'] = '[light_bg]Death Pool',
    ['silencer'] = '[light_bg]Arcane Curse',
    ['vulcanist'] = '[light_bg]Lava Burst',
    ['warden'] = '[light_bg]Magnetic Field',
    ['psychic'] = '[light_bg]Mental Strike',
    ['miner'] = '[light_bg]Golden Bolts',
    ['merchant'] = '[light_bg]Item Shop',
    ['usurer'] = '[light_bg]Bankruptcy',
    ['gambler'] = '[light_bg]Multicast',
    ['thief'] = '[light_bg]Ultrakill',
  }

  character_effect_descriptions = {
    ['vagrant'] = function() return '[yellow]+15%[fg] attack speed and damage per active class' end,
    ['swordsman'] = function() return "[fg]the swordsman's damage is [yellow]doubled" end,
    ['wizard'] = function() return '[fg]the projectile chains [yellow]2[fg] times' end,
    ['magician'] = function() return
      '[yellow]+50%[[fg] attack speed every [yellow]12[fg] seconds for [yellow]6[fg] seconds' end,
    ['pyro'] = function() return '' end,
    ['sniper'] = function() return '[fg]the arrow ricochets off walls [yellow]3[fg] times' end,
    ['laser'] = function() return '[fg]the arrow ricochets off walls [yellow]3[fg] times' end,
    ['archer'] = function() return '[fg]the arrow ricochets off walls [yellow]3[fg] times' end,
    ['cannon'] = function() return '[fg]teh cannon [yellow]shoots an [yellow]exploding cannon ball' end,
    ['scout'] = function() return '[yellow]+25%[fg] damage per chain and [yellow]+3[fg] chains' end,
    ['cleric'] = function() return '[fg]creates [yellow]4[fg] healing orbs every [yellow]8[fg] seconds' end,
    ['shaman'] = function() return '[fg]creates [yellow]1[fg] healing orb every [yellow]8[fg] seconds' end,
    ['druid'] = function() return '[fg]casts a heal over time spell on allies' end,
    ['bard'] = function() return '[fg] attack speed buff' end,
    ['necromancer'] = function() return '[fg]summons up to [yellow]3[fg] skeletons' end,
    ['paladin'] = function() return 'protects hurt allies with divine bubble' end,
    ['outlaw'] = function() return "[yellow]+50%[fg] outlaw attack speed and his knives seek enemies" end,
    ['blade'] = function() return '[fg]deal additional [yellow]' ..
      math.round(get_character_stat('blade', 3, 'dmg') / 3, 2) .. '[fg] damage per enemy hit' end,
    ['elementor'] = function() return '[fg]slows enemies by [yellow]60%[fg] for [yellow]6[fg] seconds on hit' end,
    ['saboteur'] = function() return
      '[fg]the explosion has [yellow]50%[fg] chance to crit, increasing in size and dealing [yellow]2x[fg] damage' end,
    ['bomber'] = function() return '[yellow]+100%[fg] bomb area and damage' end,
    ['stormweaver'] = function() return
      "[fg]chain lightning's trigger area of effect and number of units hit is [yellow]doubled" end,
    ['sage'] = function() return '[fg]when the projectile expires deal [yellow]' ..
      3 * get_character_stat('sage', 3, 'dmg') .. '[fg] damage to all enemies under its influence' end,
    ['squire'] = function() return '[yellow]+30%[fg] damage, attack speed, movement speed and defense to all allies' end,
    ['cannoneer'] = function() return
      '[fg]showers the hit area in [yellow]7[fg] additional cannon shots that deal [yellow]' ..
      get_character_stat('cannoneer', 3, 'dmg') / 2 .. '[fg] AoE damage' end,
    ['dual_gunner'] = function() return '[fg]every 5th attack shoot in rapid succession for [yellow]2[fg] seconds' end,
    ['hunter'] = function() return '[fg]summons [yellow]3[fg] pets and the pets ricochet off walls once' end,
    ['sentry'] = function() return
      '[yellow]+50%[fg] sentry turret attack speed and the projectiles ricochet [yellow]twice[fg]' end,
    ['chronomancer'] = function() return '[fg]enemies take damage over time [yellow]50%[fg] faster' end,
    ['spellblade'] = function() return '[fg]faster projectile speed and tighter turns' end,
    ['psykeeper'] = function() return '[fg]deal [yellow]double[fg] the damage taken by the psykeeper to all enemies' end,
    ['engineer'] = function() return
      '[fg]drops [yellow]2[fg] additional turrets and grants all turrets [yellow]+50%[fg] damage and attack speed' end,
    ['plague_doctor'] = function() return '[fg]nearby enemies take an additional [yellow]' ..
      get_character_stat('plague_doctor', 3, 'dmg') .. '[fg] damage per second' end,
    ['barbarian'] = function() return '[fg]stunned enemies also take [yellow]100%[fg] increased damage' end,
    ['juggernaut'] = function() return '[fg]enemies pushed by the juggernaut take [yellow]' ..
      4 * get_character_stat('juggernaut', 3, 'dmg') .. '[fg] damage if they hit a wall' end,
    ['lich'] = function() return
      '[fg]chain frost slows enemies hit by [yellow]80%[fg] for [yellow]2[fg] seconds and chains [yellow]+7[fg] times' end,
    ['cryomancer'] = function() return '[fg]enemies are also slowed by [yellow]60%[fg] while in the area' end,
    ['pyromancer'] = function() return '[fg]enemies killed by the pyromancer explode, dealing [yellow]' ..
      get_character_stat('pyromancer', 3, 'dmg') .. '[fg] AoE damage' end,
    ['corruptor'] = function() return '[fg]spawn [yellow]2[fg] small critters if the corruptor hits an enemy' end,
    ['beastmaster'] = function() return '[fg]spawn [yellow]4[fg] small critters if the beastmaster gets hit' end,
    ['launcher'] = function() return '[fg]enemies launched take [yellow]300%[fg] more damage when they hit walls' end,
    ['jester'] = function() return '[fg]all knives seek enemies and pierce [yellow]2[fg] times' end,
    ['assassin'] = function() return '[fg]poison inflicted from crits deals [yellow]8x[fg] damage' end,
    ['host'] = function() return '[fg][yellow]+100%[fg] critter spawn rate and spawn [yellow]2[fg] critters instead' end,
    ['carver'] = function() return '[fg]carves a tree that creates healing orbs [yellow]twice[fg] as fast' end,
    ['bane'] = function() return "[yellow]100%[fg] increased area for bane's void rifts" end,
    ['psykino'] = function() return '[fg]enemies take [yellow]' ..
      4 * get_character_stat('psykino', 3, 'dmg') .. '[fg] damage and are pushed away when the area expires' end,
    ['barrager'] = function() return
      '[fg]every 3rd attack the barrage shoots [yellow]15[fg] projectiles and they push harder' end,
    ['highlander'] = function() return '[fg]quickly repeats the attack [yellow]3[fg] times' end,
    ['fairy'] = function() return
      '[fg]creates [yellow]2[fg] healing orbs and grants [yellow]2[fg] units [yellow]+100%[fg] attack speed' end,
    ['priest'] = function() return
      '[fg]picks [yellow]3[fg] units at random and grants them a buff that prevents death once' end,
    ['infestor'] = function() return '[fg][yellow]triples[fg] the number of critters released' end,
    ['flagellant'] = function() return
      '[yellow]2X[fg] flagellant max HP and grants [yellow]+12%[fg] damage to all allies per cast instead' end,
    ['arcanist'] = function() return
      '[yellow]+50%[fg] attack speed for the orb and [yellow]2[fg] projectiles are released per cast' end,
    ['illusionist'] = function() return
      '[yellow]doubles[fg] the number of copies created and they release [yellow]12[fg] projectiles on death' end,
    ['artificer'] = function() return
      '[fg]automatons shoot and move 50% faster and release [yellow]12[fg] projectiles on death' end,
    ['witch'] = function() return '[fg]the area releases projectiles, each dealing [yellow]' ..
      get_character_stat('witch', 3, 'dmg') .. '[fg] damage and chaining once' end,
    ['silencer'] = function() return '[fg]the curse also deals [yellow]' ..
      get_character_stat('silencer', 3, 'dmg') .. '[fg] damage per second' end,
    ['vulcanist'] = function() return '[fg]the number and speed of explosions is [yellow]doubled[fg]' end,
    ['warden'] = function() return '[fg]creates the force field around [yellow]2[fg] units' end,
    ['psychic'] = function() return '[fg]the attack can happen from any distance and repeats once' end,
    ['miner'] = function() return '[fg]release [yellow]8[fg] homing projectiles instead and they pierce twice' end,
    ['merchant'] = function() return '[fg]your first item reroll is always free' end,
    ['usurer'] = function() return '[fg]if the same enemy is cursed [yellow]3[fg] times it takes [yellow]' ..
      10 * get_character_stat('usurer', 3, 'dmg') .. '[fg] damage' end,
    ['gambler'] = function() return '[yellow]60/40/20%[fg] chance to cast the attack [yellow]2/3/4[fg] times' end,
    ['thief'] = function() return '[fg]if the knife crits it deals [yellow]' ..
      10 * get_character_stat('thief', 3, 'dmg') ..
      '[fg] damage, chains [yellow]10[fg] times and grants [yellow]1[fg] gold' end,
  }

  character_effect_descriptions_gray = {
    ['vagrant'] = function() return '[light_bg]+15% attack speed and damage per active class' end,
    ['swordsman'] = function() return "[light_bg]the swordsman's damage is doubled" end,
    ['wizard'] = function() return '[light_bg]the projectile chains 3 times' end,
    ['magician'] = function() return '[light_bg]+50% attack speed every 12 seconds for 6 seconds' end,
    ['pyro'] = function() return '' end,
    ['sniper'] = function() return '[light_bg]the arrow ricochets off walls 3 times' end,
    ['cannon'] = function() return '[light_bg]shoots an exploding cannon ball' end,
    ['laser'] = function() return '[light_bg]the arrow ricochets off walls 3 times' end,
    ['archer'] = function() return '[light_bg]the arrow ricochets off walls 3 times' end,
    ['scout'] = function() return '[light_bg]+25% damage per chain and +3 chains' end,
    ['cleric'] = function() return '[light_bg]creates 4 healing orbs' end,
    ['shaman'] = function() return '[light_bg]creates 4 healing orbs' end,
    ['druid'] = function() return '[light_bg]casts a heal over time spell on allies' end,
    ['bard'] = function() return '[light_bg] attack speed buff' end,
    ['necromancer'] = function() return '[light_bg]summons up to 3 skeletons' end,
    ['paladin'] = function() return '[light_bg]protects allies' end,
    ['outlaw'] = function() return "[light_bg]+50% outlaw attack speed and his knives seek enemies" end,
    ['blade'] = function() return '[light_bg]deal additional ' ..
      math.round(get_character_stat('blade', 3, 'dmg') / 2, 2) .. ' damage per enemy hit' end,
    ['elementor'] = function() return '[light_bg]slows enemies by 60% for 6 seconds on hit' end,
    ['saboteur'] = function() return
      '[light_bg]the explosion has 50% chance to crit, increasing in size and dealing 2x damage' end,
    ['bomber'] = function() return '[light_bg]+100% bomb area and damage' end,
    ['stormweaver'] = function() return
      "[light_bg]chain lightning's trigger area of effect and number of units hit is doubled" end,
    ['sage'] = function() return '[light_bg]when the projectile expires deal ' ..
      3 * get_character_stat('sage', 3, 'dmg') .. ' damage to all enemies under its influence' end,
    ['squire'] = function() return '[light_bg]+30% damage, attack speed, movement speed and defense to all allies' end,
    ['cannoneer'] = function() return '[light_bg]showers the hit area in 7 additional cannon shots that deal ' ..
      get_character_stat('cannoneer', 3, 'dmg') / 2 .. ' AoE damage' end,
    ['dual_gunner'] = function() return '[light_bg]every 5th attack shoot in rapid succession for 2 seconds' end,
    ['hunter'] = function() return '[light_bg]summons 3 pets and the pets ricochet off walls once' end,
    ['sentry'] = function() return '[light_bg]+50% sentry turret attack speed and the projectiles ricochet twice' end,
    ['chronomancer'] = function() return '[light_bg]enemies take damage over time 50% faster' end,
    ['spellblade'] = function() return '[light_bg]faster projectile speed and tighter turns' end,
    ['psykeeper'] = function() return '[light_bg]deal double the damage taken by the psykeeper to all enemies' end,
    ['engineer'] = function() return
      '[light_bg]drops 2 additional turrets and grants all turrets +50% damage and attack speed' end,
    ['plague_doctor'] = function() return '[light_bg]nearby enemies take an additional ' ..
      get_character_stat('plague_doctor', 3, 'dmg') .. ' damage per second' end,
    ['barbarian'] = function() return '[light_bg]stunned enemies also take 100% increased damage' end,
    ['juggernaut'] = function() return '[light_bg]enemies pushed by the juggernaut take ' ..
      4 * get_character_stat('juggernaut', 3, 'dmg') .. ' damage if they hit a wall' end,
    ['lich'] = function() return '[light_bg]chain frost slows enemies hit by 80% for 2 seconds and chains +7 times' end,
    ['cryomancer'] = function() return '[light_bg]enemies are also slowed by 60% while in the area' end,
    ['pyromancer'] = function() return '[light_bg]enemies killed by the pyromancer explode, dealing ' ..
      get_character_stat('pyromancer', 3, 'dmg') .. ' AoE damage' end,
    ['corruptor'] = function() return '[light_bg]spawn 2 small critters if the corruptor hits an enemy' end,
    ['beastmaster'] = function() return '[light_bg]spawn 4 small critters if the beastmaster gets hit' end,
    ['launcher'] = function() return '[light_bg]enemies launched take 300% more damage when they hit walls' end,
    ['jester'] = function() return '[light_bg]curses 6 enemies and all knives seek enemies and pierce 2 times' end,
    ['assassin'] = function() return '[light_bg]poison inflicted from crits deals 8x damage' end,
    ['host'] = function() return '[light_bg]+100% critter spawn rate and spawn 2 critters instead' end,
    ['carver'] = function() return '[light_bg]carves a tree that creates healing orbs twice as fast' end,
    ['bane'] = function() return "[light_bg]100% increased area for bane's void rifts" end,
    ['psykino'] = function() return '[light_bg]enemies take ' ..
      4 * get_character_stat('psykino', 3, 'dmg') .. ' damage and are pushed away when the area expires' end,
    ['barrager'] = function() return '[light_bg]every 3rd attack the barrage shoots 15 projectiles and they push harder' end,
    ['highlander'] = function() return '[light_bg]quickly repeats the attack 3 times' end,
    ['fairy'] = function() return '[light_bg]creates 2 healing orbs and grants 2 units +100% attack speed' end,
    ['priest'] = function() return '[light_bg]picks 3 units at random and grants them a buff that prevents death once' end,
    ['infestor'] = function() return '[light_bg]triples the number of critters released' end,
    ['flagellant'] = function() return
      '[light_bg]2X flagellant max HP and grants +12% damage to all allies per cast instead' end,
    ['arcanist'] = function() return '[light_bg]+50% attack speed for the orb and 2 projectiles are released per cast' end,
    ['illusionist'] = function() return
      '[light_bg]doubles the number of copies created and they release 12 projectiles on death' end,
    ['artificer'] = function() return
      '[light_bg]automatons shoot and move 50% faster and release 12 projectiles on death' end,
    ['witch'] = function() return '[light_bg]the area periodically releases projectiles, each dealing ' ..
      get_character_stat('witch', 3, 'dmg') .. ' damage and chaining once' end,
    ['silencer'] = function() return '[light_bg]the curse also deals ' ..
      get_character_stat('silencer', 3, 'dmg') .. ' damage per second' end,
    ['vulcanist'] = function() return '[light_bg]the number and speed of explosions is doubled' end,
    ['warden'] = function() return '[light_bg]creates the force field around 2 units' end,
    ['psychic'] = function() return '[light_bg]the attack can happen from any distance and repeats once' end,
    ['miner'] = function() return '[light_bg]release 8 homing projectiles instead and they pierce twice' end,
    ['merchant'] = function() return '[light_bg]your first item reroll is always free' end,
    ['usurer'] = function() return '[light_bg]if the same enemy is cursed 3 times it takes ' ..
      10 * get_character_stat('usurer', 3, 'dmg') .. ' damage' end,
    ['gambler'] = function() return '[light_bg]60/40/20% chance to cast the attack 2/3/4 times' end,
    ['thief'] = function() return '[light_bg]if the knife crits it deals ' ..
      10 * get_character_stat('thief', 3, 'dmg') .. ' damage, chains 10 times and grants 1 gold' end,
  }

  character_stats = {
    ['vagrant'] = function(lvl) return get_character_stat_string('vagrant', lvl) end,
    ['swordsman'] = function(lvl) return get_character_stat_string('swordsman', lvl) end,
    ['wizard'] = function(lvl) return get_character_stat_string('wizard', lvl) end,
    ['magician'] = function(lvl) return get_character_stat_string('magician', lvl) end,
    ['pyro'] = function(lvl) return get_character_stat_string('pyro', lvl) end,
    ['sniper'] = function(lvl) return get_character_stat_string('sniper', lvl) end,
    ['cannon'] = function(lvl) return get_character_stat_string('cannon', lvl) end,
    ['laser'] = function(lvl) return get_character_stat_string('laser', lvl) end,
    ['archer'] = function(lvl) return get_character_stat_string('archer', lvl) end,
    ['scout'] = function(lvl) return get_character_stat_string('scout', lvl) end,
    ['cleric'] = function(lvl) return get_character_stat_string('cleric', lvl) end,
    ['shaman'] = function(lvl) return get_character_stat_string('shaman', lvl) end,
    ['druid'] = function(lvl) return get_character_stat_string('druid', lvl) end,
    ['bard'] = function(lvl) return get_character_stat_string('bard', lvl) end,
    ['paladin'] = function(lvl) return get_character_stat_string('paladin', lvl) end,
    ['necromancer'] = function(lvl) return get_character_stat_string('necromancer', lvl) end,
    ['outlaw'] = function(lvl) return get_character_stat_string('outlaw', lvl) end,
    ['blade'] = function(lvl) return get_character_stat_string('blade', lvl) end,
    ['elementor'] = function(lvl) return get_character_stat_string('elementor', lvl) end,
    ['saboteur'] = function(lvl) return get_character_stat_string('saboteur', lvl) end,
    ['bomber'] = function(lvl) return get_character_stat_string('bomber', lvl) end,
    ['stormweaver'] = function(lvl) return get_character_stat_string('stormweaver', lvl) end,
    ['sage'] = function(lvl) return get_character_stat_string('sage', lvl) end,
    ['squire'] = function(lvl) return get_character_stat_string('squire', lvl) end,
    ['cannoneer'] = function(lvl) return get_character_stat_string('cannoneer', lvl) end,
    ['dual_gunner'] = function(lvl) return get_character_stat_string('dual_gunner', lvl) end,
    ['hunter'] = function(lvl) return get_character_stat_string('hunter', lvl) end,
    ['sentry'] = function(lvl) return get_character_stat_string('sentry', lvl) end,
    ['chronomancer'] = function(lvl) return get_character_stat_string('chronomancer', lvl) end,
    ['spellblade'] = function(lvl) return get_character_stat_string('spellblade', lvl) end,
    ['psykeeper'] = function(lvl) return get_character_stat_string('psykeeper', lvl) end,
    ['engineer'] = function(lvl) return get_character_stat_string('engineer', lvl) end,
    ['plague_doctor'] = function(lvl) return get_character_stat_string('plague_doctor', lvl) end,
    ['barbarian'] = function(lvl) return get_character_stat_string('barbarian', lvl) end,
    ['juggernaut'] = function(lvl) return get_character_stat_string('juggernaut', lvl) end,
    ['lich'] = function(lvl) return get_character_stat_string('lich', lvl) end,
    ['cryomancer'] = function(lvl) return get_character_stat_string('cryomancer', lvl) end,
    ['pyromancer'] = function(lvl) return get_character_stat_string('pyromancer', lvl) end,
    ['corruptor'] = function(lvl) return get_character_stat_string('corruptor', lvl) end,
    ['beastmaster'] = function(lvl) return get_character_stat_string('beastmaster', lvl) end,
    ['launcher'] = function(lvl) return get_character_stat_string('launcher', lvl) end,
    ['jester'] = function(lvl) return get_character_stat_string('jester', lvl) end,
    ['assassin'] = function(lvl) return get_character_stat_string('assassin', lvl) end,
    ['host'] = function(lvl) return get_character_stat_string('host', lvl) end,
    ['carver'] = function(lvl) return get_character_stat_string('carver', lvl) end,
    ['bane'] = function(lvl) return get_character_stat_string('bane', lvl) end,
    ['psykino'] = function(lvl) return get_character_stat_string('psykino', lvl) end,
    ['barrager'] = function(lvl) return get_character_stat_string('barrager', lvl) end,
    ['highlander'] = function(lvl) return get_character_stat_string('highlander', lvl) end,
    ['fairy'] = function(lvl) return get_character_stat_string('fairy', lvl) end,
    ['priest'] = function(lvl) return get_character_stat_string('priest', lvl) end,
    ['infestor'] = function(lvl) return get_character_stat_string('infestor', lvl) end,
    ['flagellant'] = function(lvl) return get_character_stat_string('flagellant', lvl) end,
    ['arcanist'] = function(lvl) return get_character_stat_string('arcanist', lvl) end,
    ['illusionist'] = function(lvl) return get_character_stat_string('illusionist', lvl) end,
    ['artificer'] = function(lvl) return get_character_stat_string('artificer', lvl) end,
    ['witch'] = function(lvl) return get_character_stat_string('witch', lvl) end,
    ['silencer'] = function(lvl) return get_character_stat_string('silencer', lvl) end,
    ['vulcanist'] = function(lvl) return get_character_stat_string('vulcanist', lvl) end,
    ['warden'] = function(lvl) return get_character_stat_string('warden', lvl) end,
    ['psychic'] = function(lvl) return get_character_stat_string('psychic', lvl) end,
    ['miner'] = function(lvl) return get_character_stat_string('miner', lvl) end,
    ['merchant'] = function(lvl) return get_character_stat_string('merchant', lvl) end,
    ['usurer'] = function(lvl) return get_character_stat_string('usurer', lvl) end,
    ['gambler'] = function(lvl) return get_character_stat_string('gambler', lvl) end,
    ['thief'] = function(lvl) return get_character_stat_string('thief', lvl) end,
  }

  unit_stat_multipliers = {
    ['swordsman'] = { hp = 1.5, dmg = 1.25, def = 1.25, mvspd = 1 },
    ['laser'] = { hp = 1, dmg = 1, def = 1, mvspd = 1 },
    ['archer'] = { hp = 1, dmg = 1, def = 1, mvspd = 1 },
    ['pyro'] = { hp = 1.25, dmg = 1, def = 1.25, mvspd = 1 },
    ['cannon'] = { hp = 1, dmg = 2, def = 1.25, mvspd = 1 },
    ['shaman'] = { hp = 1, dmg = 1, def = 1, mvspd = 1 },
    ['sniper'] = { hp = 0.8, dmg = 4, def = 1, mvspd = 0.9 },
    ['bomber'] = { hp = 1, dmg = 6, def = 1, mvspd = 1.1 },

    ['none'] = { hp = 1, dmg = 1, def = 1, mvspd = 1 },
  }

  enemy_type_to_stats = {
    ['seeker'] = { dmg = 0.25 },
    ['shooter'] = {},

    ['arcspread'] = { dmg = 0.5 },
    ['assassin'] = {},
    ['laser'] = {},
    ['mortar'] = { dmg = 1.5 },
    ['rager'] = { dmg = 0.5, mvspd = 2 },
    ['spawner'] = {},
    ['stomper'] = { dmg = 2.5 },
    ['charger'] = { dmg = 1.5, mvspd = 0.5 },
    ['summoner'] = {},
    ['bomb'] = { hp = -0.25 },

  }

  local ylb1 = function(lvl)
    if lvl == 3 then
      return 'light_bg'
    elseif lvl == 2 then
      return 'light_bg'
    elseif lvl == 1 then
      return 'yellow'
    else
      return 'light_bg'
    end
  end
  local ylb2 = function(lvl)
    if lvl == 3 then
      return 'light_bg'
    elseif lvl == 2 then
      return 'yellow'
    else
      return 'light_bg'
    end
  end
  local ylb3 = function(lvl)
    if lvl == 3 then
      return 'yellow'
    else
      return 'light_bg'
    end
  end
  class_descriptions = {
    ['ranger'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']3[light_bg]/[' ..
      ylb2(lvl) ..
      ']6 [fg]- [' ..
      ylb1(lvl) .. ']8%[light_bg]/[' .. ylb2(lvl) .. ']16% [fg]chance to release a barrage on attack to allied rangers' end,
    ['warrior'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']3[light_bg]/[' ..
      ylb2(lvl) .. ']6 [fg]- [' .. ylb1(lvl) .. ']+25[light_bg]/[' .. ylb2(lvl) .. ']+50 [fg]defense to allied warriors' end,
    ['mage'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']3[light_bg]/[' ..
      ylb2(lvl) .. ']6 [fg]- [' .. ylb1(lvl) .. ']-15[light_bg]/[' .. ylb2(lvl) .. ']-30 [fg]enemy defense' end,
    ['rogue'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']3[light_bg]/[' ..
      ylb2(lvl) ..
      ']6 [fg]- [' ..
      ylb1(lvl) ..
      ']15%[light_bg]/[' .. ylb2(lvl) .. ']30% [fg]chance to crit to allied rogues, dealing [yellow]4x[] damage' end,
    ['healer'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) ..
      ']4 [fg]- [' ..
      ylb1(lvl) ..
      ']+15%[light_bg]/[' ..
      ylb2(lvl) .. ']+30% [fg] chance to create [yellow]+1[fg] healing orb on healing orb creation' end,
    ['enchanter'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) .. ']4 [fg]- [' .. ylb1(lvl) .. ']+15%[light_bg]/[' .. ylb2(lvl) .. ']+25% [fg]damage to all allies' end,
    ['nuker'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']3[light_bg]/[' ..
      ylb2(lvl) ..
      ']6 [fg]- [' .. ylb1(lvl) .. ']+15%[light_bg]/[' .. ylb2(lvl) .. ']+25% [fg]area damage and size to allied nukers' end,
    ['conjurer'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) ..
      ']4 [fg]- [' .. ylb1(lvl) .. ']+25%[light_bg]/[' .. ylb2(lvl) .. ']+50% [fg]construct damage and duration' end,
    ['psyker'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) ..
      ']4 [fg]- [' ..
      ylb1(lvl) .. ']+2[light_bg]/[' .. ylb2(lvl) .. ']+4 [fg]total psyker orbs and [yellow]+1[fg] orb for each psyker' end,
    ['curser'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) ..
      ']4 [fg]- [' .. ylb1(lvl) .. ']+1[light_bg]/[' .. ylb2(lvl) .. ']+3 [fg]max curse targets to allied cursers' end,
    ['cursed'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) ..
      ']4 [fg]- [' .. ylb1(lvl) .. ']+1[light_bg]/[' .. ylb2(lvl) .. ']+3 [fg]max curse targets to allied cursers' end,
    ['forcer'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) ..
      ']4 [fg]- [' .. ylb1(lvl) .. ']+25%[light_bg]/[' .. ylb2(lvl) .. ']+50% [fg]knockback force to all allies' end,
    ['swarmer'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) .. ']4 [fg]- [' .. ylb1(lvl) .. ']+1[light_bg]/[' .. ylb2(lvl) .. ']+3 [fg]hits to critters' end,
    ['voider'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) ..
      ']4 [fg]- [' .. ylb1(lvl) .. ']+20%[light_bg]/[' .. ylb2(lvl) .. ']+40% [fg]damage over time to allied voiders' end,
    ['sorcerer'] = function(lvl)
      return '[' ..
          ylb1(lvl) ..
          ']2[light_bg]/[' ..
          ylb2(lvl) .. ']4[light_bg]/[' .. ylb3(lvl) .. ']6 [fg]- sorcerers repeat their attacks once every [' ..
          ylb1(lvl) .. ']4[light_bg]/[' .. ylb2(lvl) .. ']3[light_bg]/[' .. ylb3(lvl) .. ']2[fg] attacks'
    end,
    ['mercenary'] = function(lvl) return '[' ..
      ylb1(lvl) ..
      ']2[light_bg]/[' ..
      ylb2(lvl) ..
      ']4 [fg]- [' ..
      ylb1(lvl) .. ']+8%[light_bg]/[' .. ylb2(lvl) .. ']+16% [fg]chance for enemies to drop gold on death' end,
    ['explorer'] = function(lvl) return '[yellow]+15%[fg] attack speed and damage per active class to allied explorers' end,
    ['buffer'] = function(lvl) return 'buff stuff yo' end,
  }


  --wizard sucks right now, stacks blizzard and takes too long to cast
  tier_to_characters = {
    [1] = { 'swordsman', 'laser', 'archer' },
    [2] = { 'shaman', 'paladin', 'priest', 'cannon', 'bomber' },
    [3] = { 'sniper', 'necromancer', 'bard', 'druid' },
    [4] = { 'juggernaut' },
  }

  item_images = {
    ['default'] = sword,
    
    ['potion2'] = potion2,
    ['linegoesup'] = linegoesup,
    ['fancyarmor'] = fancyarmor,
    ['turtle'] = turtle,
    ['leaf'] = leaf,
    ['orb'] = orb,
    ['simpleshield'] = simpleshield,
    ['sword'] = sword,
    ['rock'] = rock,
    ['flask'] = flask,
    ['gem'] = gem,
    ['sun'] = sun,
    ['simpleboots'] = simpleboots,
    ['mace'] = mace,
    ['fire'] = fire,
    ['lightning'] = lightning,
    ['clam'] = clam,
  }

  item_costs = {
    ['smallsword'] = 3,
    ['medsword'] = 5,
    ['largesword'] = 10,

    ['smallboots'] = 3,
    ['medboots'] = 5,
    ['largeboots'] = 10,

    ['smallbow'] = 3,
    ['medbow'] = 5,
    ['largebow'] = 10,

    ['smallvest'] = 3,
    ['medvest'] = 5,
    ['largevest'] = 10,

    ['smallshield'] = 3,
    ['medshield'] = 5,
    ['largeshield'] = 10,

    ['smallbomb'] = 3,
    ['medbomb'] = 5,
    ['largebomb'] = 10,

    ['vampirism'] = 6,
    ['ghostboots'] = 6,
    ['frostorb'] = 5,
    ['spikedcollar'] = 6,
    ['basher'] = 5,
    ['berserkerbelt'] = 5,
    ['heartofgold'] = 5,
    ['healingleaf'] = 6,

    ['corpseexplode'] = 10,

  }

  item_stat_lookup = {
    ['dmg'] = 'damage',
    ['mvspd'] = 'move speed',
    ['aspd'] = 'attack speed',
    ['hp'] = 'hp',
    ['def'] = 'defense',
    ['area_size'] = 'area size',
    ['vamp'] = 'vampirism',
    ['ghost'] = 'move through units',
    ['slow'] = 'movement slow on attack',
    ['thorns'] = 'return damage to attacker',
    ['bash'] = 'chance to stun',
    ['enrage'] = 'enrage allies on death',
    ['gold'] = 'gold per round',
    ['heal'] = 'healing per second',
    ['explode'] = 'explode on kill',

    ['proc'] = 'Extra effect on attack',
  }

  item_text = {
    ['smallsword'] = "A tiny sword",
    ['medsword'] = "A medium sword",
    ['largesword'] = "A large sword!",

    ['smallboots'] = "Small boots",
    ['medboots'] = "Medium boots",
    ['largeboots'] = "Large boots!",

    ['smallbow'] = "Small bow",
    ['medbow'] = "Medium lightning bow",
    ['largebow'] = "Large bow!",

    ['smallbomb'] = "Small bomb",
    ['medbomb'] = "Medium bomb",
    ['largebomb'] = "Large bomb",

    ['vampirism'] = 'Vampire cloak',
    ['ghostboots'] = "Ghost boots",
    ['frostorb'] = "Frost orb",
    ['spikedcollar'] = "Spiked collar",
    ['basher'] = "Basher",
    ['berserkerbelt'] = "Berserker belt",
    ['heartofgold'] = "Heart of gold",
    ['healingleaf'] = "Healing leaf",

    ['corpseexplode'] = "Corpse exploder",
  }


  build_proc_text = function(proc)
    local name = proc.name or 'proc name'
    name = name:upper()
    local desc = proc.desc or 'proc desc'

    local out = {}
    table.insert(out, { text = '[fg]' .. name, font = pixul_font, alignment = 'center', height_multiplier = 1.25 })
    table.insert(out, { text = '[fg]' .. desc, font = pixul_font, alignment = 'center', height_multiplier = 1.25 })
    return out
  end

  build_item_text = function(item)
    local name = item.name or 'item name'
    name = name:upper()

    local out = {}
    table.insert(out, { text = '[fg]' .. name, font = pixul_font, alignment = 'center', height_multiplier = 1.25 })
    table.insert(out, {
      text = '[fg]' .. item.desc .. ', costs: ' .. item.cost,
      font = pixul_font,
      alignment = 'center',
      height_multiplier = 1.25
    })
    local stats = item.stats
    if stats then
      for key, val in pairs(stats) do
        local text = ''
        if key == 'gold' then
          text = '[fg] ' .. val .. ' ' .. (item_stat_lookup[key] or '')
        elseif key == 'enrage' or key == 'ghost' then
          text = '[fg] ' .. (item_stat_lookup[key] or '')
        elseif key == 'proc' then
          text = '[fg]' .. 'custom proc... add later'
        else
          text = '[fg] ' .. val * 100 .. '% ' .. (item_stat_lookup[key] or '')
        end
        table.insert(out, { text = text, font = pixul_font, alignment = 'center', height_multiplier = 1.25 })
      end
    end
    return out
  end

  item_to_color = function(item)
    if not item then return grey[0] end

    local cost = item.cost or 0
    local color = grey[0]
    if cost then
      if cost <= 2 then
        color = brown[0]
      elseif cost <= 5 then
        color = grey[0]
      elseif cost <= 10 then
        color = yellow[5]
      elseif cost <= 15 then
        color = orange[3]
      else
        color = red[3]
      end
    end
    return color
  end

  attack_ranges = {
    ['melee'] = 30,
    ['medium'] = 60,
    ['medium-long'] = 100,
    ['ranged'] = 130,
    ['long'] = 150,
    ['ultra-long'] = 250,

    ['whole-map'] = 999,
  }

  attack_speeds = {
    ['short-cast'] = 0.20,
    ['medium-cast'] = 0.37,
    ['long-cast'] = 0.66,
    ['ultra-long-cast'] = 1,

    ['buff'] = 0.66,
    ['ultra-fast'] = 1,
    ['fast'] = 1.35,
    ['medium-fast'] = 1.75,
    ['medium'] = 2.5,
    ['medium-slow'] = 3.5,
    ['slow'] = 5,
    ['ultra-slow'] = 8
  }

  move_speeds = {
    ['ultra-fast'] = 2.5,
    ['fast'] = 1.7,
    ['medium'] = 1.4,
    ['regular'] = 1,
  }

  unit_size = {
    ['small'] = 4,
    ['medium'] = 8,
    ['large'] = 14,
  }

  buff_types = {
    ['dmg'] = 'dmg',
    ['aspd'] = 'aspd',
    ['def'] = 'def',
    ['mvspd'] = 'mvspd',
    ['area_dmg'] = 'area_dmg',
    ['area_size'] = 'area_size',
    ['hp'] = 'hp',
    ['status_resist'] = 'status_resist',
    ['attack_range'] = 'attack_range',
    ['dmg_per_def'] = 'dmg_per_def',

    ['shield'] = 'shield',

    ['eledmg'] = 'eledmg',
    ['elevamp'] = 'elevamp',
    ['vamp'] = 'vamp',

    ['ghost'] = 'ghost',
    ['slow'] = 'slow',
    ['bash'] = 'bash',
    ['heal'] = 'heal',
    ['explode'] = 'explode',
  }

  non_attacking_characters = { 'cleric', 'stormweaver', 'squire', 'chronomancer', 'sage', 'psykeeper', 'bane', 'carver',
    'fairy', 'priest', 'paladin', 'necromancer', 'bard', 'druid', 'flagellant', 'merchant', 'miner' }
  non_cooldown_characters = { 'squire', 'chronomancer', 'psykeeper', 'merchant', 'miner' }

  character_tiers = {
    ['vagrant'] = 1,
    ['swordsman'] = 1,
    ['magician'] = 1,
    ['pyro'] = 1,
    ['laser'] = 1,
    ['archer'] = 1,
    ['bomber'] = 2,
    ['cannon'] = 2,
    ['scout'] = 1,
    ['cleric'] = 1,
    ['shaman'] = 2,
    ['druid'] = 3,
    ['bard'] = 3,
    ['paladin'] = 2,
    ['necromancer'] = 3,
    ['outlaw'] = 2,
    ['blade'] = 4,
    ['elementor'] = 3,
    -- ['saboteur'] = 2,
    ['wizard'] = 2,
    ['stormweaver'] = 3,
    ['sage'] = 2,
    ['squire'] = 2,
    ['cannoneer'] = 4,
    ['dual_gunner'] = 2,
    -- ['hunter'] = 2,
    ['sentry'] = 2,
    ['chronomancer'] = 2,
    ['spellblade'] = 3,
    ['sniper'] = 3,
    ['psykeeper'] = 3,
    ['engineer'] = 3,
    ['plague_doctor'] = 4,
    ['barbarian'] = 2,
    ['juggernaut'] = 3,
    -- ['lich'] = 4,
    ['cryomancer'] = 2,
    ['pyromancer'] = 3,
    ['corruptor'] = 4,
    ['beastmaster'] = 2,
    -- ['launcher'] = 2,
    ['jester'] = 2,
    ['assassin'] = 3,
    ['host'] = 3,
    ['carver'] = 2,
    ['bane'] = 3,
    ['psykino'] = 4,
    ['barrager'] = 3,
    ['highlander'] = 4,
    ['fairy'] = 4,
    ['priest'] = 2,
    ['infestor'] = 3,
    ['flagellant'] = 3,
    ['arcanist'] = 1,
    -- ['illusionist'] = 3,
    ['artificer'] = 3,
    ['witch'] = 2,
    ['silencer'] = 2,
    ['vulcanist'] = 4,
    ['warden'] = 4,
    ['psychic'] = 2,
    ['miner'] = 2,
    ['merchant'] = 1,
    ['usurer'] = 3,
    ['gambler'] = 3,
    ['thief'] = 4,
  }

  tier_to_cost = {
    [1] = 10,
    [2] = 20,
    [3] = 30,
    [4] = 40,
  }

  local ts = function(lvl, a, b, c) return '[' ..
    ylb1(lvl) ..
    ']' ..
    tostring(a) ..
    '[light_bg]/[' .. ylb2(lvl) .. ']' .. tostring(b) .. '[light_bg]/[' .. ylb3(lvl) .. ']' .. tostring(c) .. '[fg]' end
  passive_descriptions_level = {
    ['centipede'] = function(lvl) return ts(lvl, '+10%', '20%', '30%') .. ' movement speed' end,
    ['ouroboros_technique_r'] = function(lvl) return '[fg]rotating around yourself to the right releases ' ..
      ts(lvl, '2', '3', '4') .. ' projectiles per second' end,
    ['ouroboros_technique_l'] = function(lvl) return '[fg]rotating around yourself to the left grants ' ..
      ts(lvl, '+15%', '25%', '35%') .. ' defense to all units' end,
    ['amplify'] = function(lvl) return ts(lvl, '+20%', '35%', '50%') .. ' AoE damage' end,
    ['resonance'] = function(lvl) return '[fg]all AoE attacks deal ' ..
      ts(lvl, '+3%', '5%', '7%') .. ' damage per unit hit' end,
    ['ballista'] = function(lvl) return ts(lvl, '+20%', '35%', '50%') .. ' projectile damage' end,
    ['call_of_the_void'] = function(lvl) return ts(lvl, '+30%', '60%', '90%') .. ' DoT damage' end,
    ['crucio'] = function(lvl) return '[fg]taking damage also shares that across all enemies at ' ..
      ts(lvl, '20%', '30%', '40%') .. ' its value' end,
    ['speed_3'] = function(lvl) return '[fg]position [yellow]3[fg] has [yellow]+50%[fg] attack speed' end,
    ['damage_4'] = function(lvl) return '[fg]position [yellow]4[fg] has [yellow]+30%[fg] damage' end,
    ['shoot_5'] = function(lvl) return '[fg]position [yellow]5[fg] shoots [yellow]3[fg] projectiles per second' end,
    ['death_6'] = function(lvl) return
      '[fg]position [yellow]6[fg] takes [yellow]10%[fg] of its health as damage every [yellow]3[fg] seconds' end,
    ['lasting_7'] = function(lvl) return
      '[fg]position [yellow]7[fg] will stay alive for [yellow]10[fg] seconds after dying' end,
    ['defensive_stance'] = function(lvl) return '[fg]first and last positions have ' ..
      ts(lvl, '+10%', '20%', '30%') .. ' defense' end,
    ['offensive_stance'] = function(lvl) return '[fg]first and last positions have ' ..
      ts(lvl, '+10%', '20%', '30%') .. ' damage' end,
    ['kinetic_bomb'] = function(lvl) return '[fg]when an ally dies it explodes, launching enemies away' end,
    ['porcupine_technique'] = function(lvl) return '[fg]when an ally dies it explodes, releasing piercing projectiles' end,
    ['last_stand'] = function(lvl) return
      '[fg]the last unit alive is fully healed and receives a [yellow]+20%[fg] bonus to all stats' end,
    ['seeping'] = function(lvl) return '[fg]enemies taking DoT damage have ' ..
      ts(lvl, '-15%', '25%', '35%') .. ' defense' end,
    ['deceleration'] = function(lvl) return '[fg]enemies taking DoT damage have ' ..
      ts(lvl, '-15%', '25%', '35%') .. ' movement speed' end,
    ['annihilation'] = function(lvl) return
      '[fg]when a voider dies deal its DoT damage to all enemies for [yellow]3[fg] seconds' end,
    ['malediction'] = function(lvl) return ts(lvl, '+1', '3', '5') .. ' max curse targets to all allied cursers' end,
    ['hextouch'] = function(lvl) return '[fg]enemies take ' ..
      ts(lvl, '10', '15', '20') .. 'damage per second for [yellow]3[fg] seconds when cursed' end,
    ['whispers_of_doom'] = function(lvl) return '[fg]curses apply doom, deal ' ..
      ts(lvl, '100', '150', '200') .. ' every ' .. ts(lvl, '4', '3', '2') .. ' doom instances' end,
    ['tremor'] = function(lvl) return '[fg]when enemies hit walls they create an area based to the knockback force' end,
    ['heavy_impact'] = function(lvl) return '[fg]when enemies hit walls they take damage based on the knockback force' end,
    ['fracture'] = function(lvl) return '[fg]when enemies hit walls they explode into projectiles' end,
    ['meat_shield'] = function(lvl) return '[fg]critters [yellow]block[fg] enemy projectiles' end,
    ['hive'] = function(lvl) return '[fg]critters have ' .. ts(lvl, '+1', '2', '3') .. ' HP' end,
    ['baneling_burst'] = function(lvl) return '[fg]critters die immediately on contact but also deal ' ..
      ts(lvl, '50', '100', '150') .. ' AoE damage' end,
    ['blunt_arrow'] = function(lvl) return '[fg]ranger arrows have ' ..
      ts(lvl, '+10%', '20%', '30%') .. ' chance to knockback' end,
    ['explosive_arrow'] = function(lvl) return '[fg]ranger arrows have ' ..
      ts(lvl, '+10%', '20%', '30%') .. ' chance to deal ' .. ts(lvl, '10%', '20%', '30%') .. ' AoE damage' end,
    ['divine_machine_arrow'] = function(lvl) return '[fg]ranger arrows have a ' ..
      ts(lvl, '10%', '20%', '30%') .. ' chance to seek and pierce ' .. ts(lvl, '1', '2', '3') .. ' times' end,
    ['chronomancy'] = function(lvl) return '[fg]mages cast their spells ' .. ts(lvl, '15%', '25%', '35%') .. ' faster' end,
    ['awakening'] = function(lvl) return ts(lvl, '+50%', '75%', '100%') ..
      ' attack speed and damage to [yellow]1[fg] mage every round for that round' end,
    ['divine_punishment'] = function(lvl) return '[fg]deal damage to all enemies based on how many mages you have' end,
    ['assassination'] = function(lvl) return '[fg]crits from rogues deal ' ..
      ts(lvl, '8x', '10x', '12x') .. ' damage but normal attacks deal [yellow]half[fg] damage' end,
    ['flying_daggers'] = function(lvl) return '[fg]all projectiles thrown by rogues chain ' ..
      ts(lvl, '+2', '3', '4') .. ' times' end,
    ['ultimatum'] = function(lvl) return '[fg]projectiles that chain gain ' ..
      ts(lvl, '+10%', '20%', '30%') .. ' damage with each chain' end,
    ['magnify'] = function(lvl) return ts(lvl, '+20%', '35%', '50%') .. ' area size' end,
    ['echo_barrage'] = function(lvl) return ts(lvl, '10%', '20%', '30%') ..
      ' chance to create ' .. ts(lvl, '1', '2', '3') .. ' secondary AoEs on AoE hit' end,
    ['unleash'] = function(lvl) return '[fg]all nukers gain [yellow]+1%[fg] area size and damage every second' end,
    ['reinforce'] = function(lvl) return ts(lvl, '+10%', '20%', '30%') ..
      ' global damage, defense and aspd if you have one or more enchanters' end,
    ['payback'] = function(lvl) return ts(lvl, '+2%', '5%', '8%') .. ' damage to all allies whenever an enchanter is hit' end,
    ['enchanted'] = function(lvl) return ts(lvl, '+33%', '66%', '99%') ..
      ' attack speed to a random unit if you have two or more enchanters' end,
    ['freezing_field'] = function(lvl) return
      '[fg]creates an area that slows enemies by [yellow]50%[fg] for [yellow]2[fg] seconds on sorcerer spell repeat' end,
    ['burning_field'] = function(lvl) return
      '[fg]creates an area that deals [yellow]30[fg] dps for [yellow]2[fg] seconds on sorcerer spell repeat' end,
    ['gravity_field'] = function(lvl) return
      '[fg]creates an area that pulls enemies in for [yellow]1[fg] seconds on sorcerer spell repeat' end,
    ['magnetism'] = function(lvl) return '[fg]gold coins and healing orbs are attracted to the snake from a longer range' end,
    ['insurance'] = function(lvl) return
      "[fg]heroes have [yellow]4[fg] times the chance of mercenary's bonus to drop [yellow]2[fg] gold on death" end,
    ['dividends'] = function(lvl) return '[fg]mercenaries deal [yellow]+X%[fg] damage, where X is how much gold you have' end,
    ['berserking'] = function(lvl) return '[fg]all warriors have up to ' ..
      ts(lvl, '+50%', '75%', '100%') .. ' attack speed based on missing HP' end,
    ['unwavering_stance'] = function(lvl) return '[fg]all warriors gain ' ..
      ts(lvl, '+4%', '8%', '12%') .. ' defense every [yellow]5[fg] seconds' end,
    ['unrelenting_stance'] = function(lvl) return ts(lvl, '+2%', '5%', '8%') ..
      ' defense to all allies whenever a warrior is hit' end,
    ['blessing'] = function(lvl) return ts(lvl, '+10%', '20%', '30%') .. ' healing effectiveness' end,
    ['haste'] = function(lvl) return
      '[yellow]+50%[fg] movement speed that decays over [yellow]4[fg] seconds on healing orb pick up' end,
    ['divine_barrage'] = function(lvl) return ts(lvl, '20%', '40%', '60%') ..
      ' chance to release a ricocheting barrage on healing orb pick up' end,
    ['orbitism'] = function(lvl) return ts(lvl, '+25%', '50%', '75%') .. ' psyker orb movement speed' end,
    ['psyker_orbs'] = function(lvl) return ts(lvl, '+1', '2', '4') .. ' psyker orbs' end,
    ['psychosense'] = function(lvl) return ts(lvl, '+33%', '66%', '99%') .. ' orb range' end,
    ['psychosink'] = function(lvl) return '[fg]psyker orbs deal ' .. ts(lvl, '+40%', '80%', '120%') .. ' damage' end,
    ['rearm'] = function(lvl) return '[fg]constructs repeat their attacks once' end,
    ['taunt'] = function(lvl) return ts(lvl, '10%', '20%', '30%') ..
      ' chance for constructs to taunt nearby enemies on attack' end,
    ['construct_instability'] = function(lvl) return '[fg]constructs explode when disappearing, dealing ' ..
      ts(lvl, '100', '150', '200%') .. ' damage' end,
    ['intimidation'] = function(lvl) return '[fg]enemies spawn with ' .. ts(lvl, '-10', '20', '30%') .. ' max HP' end,
    ['vulnerability'] = function(lvl) return '[fg]enemies take ' .. ts(lvl, '+10', '20', '30%') .. ' damage' end,
    ['temporal_chains'] = function(lvl) return '[fg]enemies are ' .. ts(lvl, '10', '20', '30%') .. ' slower' end,
    ['ceremonial_dagger'] = function(lvl) return '[fg]killing an enemy fires a homing dagger' end,
    ['homing_barrage'] = function(lvl) return ts(lvl, '8', '16', '24%') ..
      ' chance to release a homing barrage on enemy kill' end,
    ['critical_strike'] = function(lvl) return ts(lvl, '5', '10', '15%') ..
      ' chance for attacks to critically strike, dealing [yellow]2x[fg] damage' end,
    ['noxious_strike'] = function(lvl) return ts(lvl, '8', '16', '24%') ..
      ' chance for attacks to poison, dealing [yellow]20%[fg] dps for [yellow]3[fg] seconds' end,
    ['infesting_strike'] = function(lvl) return ts(lvl, '10', '20', '30%') ..
      ' chance for attacks to spawn [yellow]2[fg] critters on kill' end,
    ['kinetic_strike'] = function(lvl) return ts(lvl, '10', '20', '30%') ..
      ' chance for attacks to push enemies away with high force' end,
    ['burning_strike'] = function(lvl) return
      '[yellow]15%[fg] chance for attacks to burn, dealing [yellow]20%[fg] dps for [yellow]3[fg] seconds' end,
    ['lucky_strike'] = function(lvl) return '[yellow]8%[fg] chance for attacks to cause enemies to drop gold on death' end,
    ['healing_strike'] = function(lvl) return '[yellow]8%[fg] chance for attacks to spawn a healing orb on kill' end,
    ['stunning_strike'] = function(lvl) return ts(lvl, '8', '16', '24%') ..
      ' chance for attacks to stun for [yellow]2[fg] seconds' end,
    ['silencing_strike'] = function(lvl) return ts(lvl, '8', '16', '24%') ..
      ' chance for attacks to silence for [yellow]2[fg] seconds on hit' end,
    ['warping_shots'] = function(lvl) return 'projectiles ignore wall collisions and warp around the screen ' ..
      ts(lvl, '1', '2', '3') .. ' times' end,
    ['culling_strike'] = function(lvl) return '[fg]instantly kill elites below ' ..
      ts(lvl, '10', '20', '30%') .. ' max HP' end,
    ['lightning_strike'] = function(lvl) return ts(lvl, '5', '10', '15%') ..
      ' chance for projectiles to create chain lightning, dealing ' .. ts(lvl, '60', '80', '100%') .. ' damage' end,
    ['psycholeak'] = function(lvl) return
      '[fg]position [yellow]1[fg] generates [yellow]1[fg] psyker orb every [yellow]10[fg] seconds' end,
    ['divine_blessing'] = function(lvl) return '[fg]generate [yellow]1[fg] healing orb every [yellow]8[fg] seconds' end,
    ['hardening'] = function(lvl) return
      '[yellow]+150%[fg] defense to all allies for [yellow]3[fg] seconds after an ally dies' end,
  }

  max_units_to_cost = {
    [3] = 10,
    [4] = 20,
    [5] = 40,
  }

  function level_to_shop_tier(lvl)
    if lvl <= 6 then
      return 1
    elseif lvl <= 12 then
      return 2
    elseif lvl <= 16 then
      return 3
    else
      return 4
    end
  end

  level_to_round_power = {
    [1] = 100,
    [2] = 300,    -- Base round
    [3] = 450,    -- 1.5x base of 300
    [4] = 600,    -- 2x base of 300
    [5] = 800,    -- Next round base
    [6] = 1200,   -- 1.5x base of 800
    [7] = 1600,   -- 2x base of 800
    [8] = 2000,   -- Next round base
    [9] = 3000,   -- 1.5x base of 2000
    [10] = 4000,  -- 2x base of 2000
    [11] = 5000,  -- Next round base
    [12] = 7500,  -- 1.5x base of 5000
    [13] = 10000, -- 2x base of 5000
    [14] = 11000, -- Next round base
    [15] = 16500, -- 1.5x base of 11000
    [16] = 22000, -- 2x base of 11000
    [17] = 20000, -- Next round base
    [18] = 30000, -- 1.5x base of 20000
    [19] = 40000, -- 2x base of 20000
    [20] = 35000, -- Next round base
    [21] = 52500, -- 1.5x base of 35000
    [22] = 70000, -- 2x base of 35000
    [23] = 50000, -- Next round base
    [24] = 75000, -- 1.5x base of 50000
    [25] = 100000 -- 2x base of 50000
  }

  normal_enemies = {
    'shooter',
    'seeker',
  }

  normal_enemy_by_tier = {
    [1] = {
      'seeker',
    },
    [2] = {
      'shooter'
    }
  }

  special_enemy_by_tier = {
    [1] = {
      'laser',
      'stomper',
      'burst',
      'boomerang',
      'plasma',
    },
    [2] = {
      'laser',
      'stomper',
      'burst',
      'boomerang',
      'plasma',
      
      'mortar',
      'spawner',
      'arcspread',
    },
    [3] = {
      'summoner',
      'assassin',
    },
  }

  function find_tier_of_special_enemy(enemy)
    for tier, enemies in pairs(special_enemy_by_tier) do
      for _, e in pairs(enemies) do
        if e == enemy then
          return tier
        end
      end
    end
    return 0
  end

  enemy_to_round_power = {
    ['shooter'] = 100,
    ['seeker'] = 100,
    --special enemies t1
    ['laser'] = 300,
    ['rager'] = 300,
    ['stomper'] = 300,
    ['charger'] = 300,
    ['bomb'] = 300,
    ['burst'] = 300,
    ['boomerang'] = 300,
    ['plasma'] = 300,
    --special enemies t2
    ['mortar'] = 500,
    ['spawner'] = 500,
    ['arcspread'] = 500,
    --special enemies t3
    ['summoner'] = 1000,
    ['assassin'] = 1000,

    --bosses
    ['stompy'] = BOSS_ROUND_POWER,
    ['dragon'] = BOSS_ROUND_POWER,
    ['heigan'] = BOSS_ROUND_POWER,
  }

  enemy_to_color = {
    ['shooter'] = grey[0],
    ['seeker'] = grey[0],
    ['rager'] = red[3],
    ['stomper'] = red[3],
    ['charger'] = red[3],
    ['mortar'] = orange[3],
    ['spawner'] = orange[3],
    ['bomb'] = orange[3],
    ['arcspread'] = blue[3],
    ['summoner'] = purple[3],
    ['assassin'] = purple[3],
  }

  damage_type_to_color = {
    ['physical'] = white[3],
    ['fire'] = red[3],
    ['ice'] = blue[3],
    ['lightning'] = yellow[3],
    ['poison'] = green[3],
    ['dark'] = purple[3],
  }

  level_to_tier_weights = {
    [1] = { 90, 10, 0, 0 },
    [2] = { 80, 15, 5, 0 },
    [3] = { 75, 20, 5, 0 },
    [4] = { 70, 20, 10, 0 },
    [5] = { 70, 20, 10, 0 },
    [6] = { 65, 25, 10, 0 },
    [7] = { 60, 25, 15, 0 },
    [8] = { 55, 25, 15, 5 },
    [9] = { 50, 30, 15, 5 },
    [10] = { 50, 30, 15, 5 },
    [11] = { 45, 30, 20, 5 },
    [12] = { 40, 30, 20, 10 },
    [13] = { 35, 30, 25, 10 },
    [14] = { 30, 30, 25, 15 },
    [15] = { 25, 30, 30, 15 },
    [16] = { 25, 25, 30, 20 },
    [17] = { 20, 25, 35, 20 },
    [18] = { 15, 25, 35, 25 },
    [19] = { 10, 25, 40, 25 },
    [20] = { 5, 25, 40, 30 },
    [21] = { 0, 25, 40, 35 },
    [22] = { 0, 20, 40, 40 },
    [23] = { 0, 20, 35, 45 },
    [24] = { 0, 10, 30, 60 },
    [25] = { 0, 0, 0, 100 },
  }

  level_to_elite_spawn_weights = {
    [1] = { 0 },
    [2] = { 4, 2 },
    [3] = { 10 },
    [4] = { 4, 4 },
    [5] = { 4, 3, 2 },
    [6] = { 12 },
    [7] = { 5, 3, 2 },
    [8] = { 6, 3, 3, 3 },
    [9] = { 14 },
    [10] = { 8, 4 },
    [11] = { 8, 6, 2 },
    [12] = { 16 },
    [13] = { 8, 8 },
    [14] = { 12, 6 },
    [15] = { 18 },
    [16] = { 10, 6, 4 },
    [17] = { 6, 5, 4, 3 },
    [18] = { 18 },
    [19] = { 10, 6 },
    [20] = { 8, 6, 2 },
    [21] = { 22 },
    [22] = { 10, 8, 4 },
    [23] = { 20, 5, 5 },
    [24] = { 30 },
    [25] = { 5, 5, 5, 5, 5, 5 },
  }

  local k = 1
  local l = 0.2
  for i = 26, 5000 do
    local n = i % 25
    if n == 0 then
      n = 25
      k = k + 1
      l = l * 2
    end
    local a, b, c, d, e, f = unpack(level_to_elite_spawn_weights[n])
    a = (a or 0) + (a or 0) * l
    b = (b or 0) + (b or 0) * l
    c = (c or 0) + (c or 0) * l
    d = (d or 0) + (d or 0) * l
    e = (e or 0) + (e or 0) * l
    f = (f or 0) + (f or 0) * l
    level_to_elite_spawn_weights[i] = { a, b, c, d, e, f }
  end

  level_to_boss = {
    [6] = 'speed_booster',
    [12] = 'exploder',
    [18] = 'swarmer',
    [24] = 'forcer',
    [25] = 'randomizer',
  }

  local bosses = { 'speed_booster', 'exploder', 'swarmer', 'forcer', 'randomizer' }
  level_to_boss[31] = 'speed_booster'
  level_to_boss[37] = 'exploder'
  level_to_boss[43] = 'swarmer'
  level_to_boss[49] = 'forcer'
  level_to_boss[50] = 'randomizer'
  local i = 31
  local k = 1
  while i < 5000 do
    level_to_boss[i] = bosses[k]
    k = k + 1
    if k == 5 then i = i + 1 else i = i + 6 end
    if k == 6 then k = 1 end
  end

  level_to_elite_spawn_types = {
    [1] = { 'speed_booster' },
    [2] = { 'speed_booster', 'shooter' },
    [3] = { 'speed_booster' },
    [4] = { 'speed_booster', 'exploder' },
    [5] = { 'speed_booster', 'exploder', 'shooter' },
    [6] = { 'speed_booster' },
    [7] = { 'speed_booster', 'exploder', 'headbutter' },
    [8] = { 'speed_booster', 'exploder', 'headbutter', 'shooter' },
    [9] = { 'shooter' },
    [10] = { 'exploder', 'headbutter' },
    [11] = { 'exploder', 'headbutter', 'tank' },
    [12] = { 'exploder' },
    [13] = { 'speed_booster', 'shooter' },
    [14] = { 'speed_booster', 'spawner' },
    [15] = { 'shooter' },
    [16] = { 'speed_booster', 'exploder', 'spawner' },
    [17] = { 'speed_booster', 'exploder', 'spawner', 'shooter' },
    [18] = { 'spawner' },
    [19] = { 'headbutter', 'tank' },
    [20] = { 'speed_booster', 'tank', 'spawner' },
    [21] = { 'headbutter' },
    [22] = { 'speed_booster', 'headbutter', 'tank' },
    [23] = { 'headbutter', 'tank', 'shooter' },
    [24] = { 'tank' },
    [25] = { 'speed_booster', 'exploder', 'headbutter', 'tank', 'shooter', 'spawner' },
  }

  for i = 26, 5000 do
    local n = i % 25
    if n == 0 then
      n = 25
    end
    level_to_elite_spawn_types[i] = level_to_elite_spawn_types[n]
  end

  level_to_shop_odds = {
    [1] = { 100, 0, 0, 0 },
    [2] = { 70, 30, 0, 0 },
    [3] = { 50, 30, 15, 5 },
    [4] = { 25, 45, 20, 10 },
    [5] = { 10, 25, 45, 20 },
  }

  level_to_item_odds = {
    [1] = { 100, 0, 0, 0 },
    [2] = { 55, 30, 15, 0 },
    [3] = { 35, 40, 20, 5 },
    [4] = { 10, 25, 45, 20 },
    [5] = { 0, 20, 40, 40 },
  }

  get_shop_odds = function(lvl, tier)
    if lvl == 1 then
      if tier == 1 then
        return 70
      elseif tier == 2 then
        return 20
      elseif tier == 3 then
        return 10
      elseif tier == 4 then
        return 0
      end
    elseif lvl == 2 then
      if tier == 1 then
        return 50
      elseif tier == 2 then
        return 30
      elseif tier == 3 then
        return 15
      elseif tier == 4 then
        return 5
      end
    elseif lvl == 3 then
      if tier == 1 then
        return 25
      elseif tier == 2 then
        return 45
      elseif tier == 3 then
        return 20
      elseif tier == 4 then
        return 10
      end
    elseif lvl == 4 then
      if tier == 1 then
        return 10
      elseif tier == 2 then
        return 25
      elseif tier == 3 then
        return 45
      elseif tier == 4 then
        return 20
      end
    elseif lvl == 5 then
      if tier == 1 then
        return 5
      elseif tier == 2 then
        return 15
      elseif tier == 3 then
        return 30
      elseif tier == 4 then
        return 50
      end
    end
  end

  unlevellable_items = {
    'speed_3', 'damage_4', 'shoot_5', 'death_6', 'lasting_7', 'kinetic_bomb', 'porcupine_technique', 'last_stand',
    'annihilation',
    'tremor', 'heavy_impact', 'fracture', 'meat_shield', 'divine_punishment', 'unleash', 'freezing_field',
    'burning_field', 'gravity_field',
    'magnetism', 'insurance', 'dividends', 'haste', 'rearm', 'ceremonial_dagger', 'burning_strike', 'lucky_strike',
    'healing_strike', 'psycholeak', 'divine_blessing', 'hardening',
  }

  --steam.userStats.requestCurrentStats()
  new_game_plus = state.new_game_plus or 0
  if not state.new_game_plus then state.new_game_plus = new_game_plus end
  current_new_game_plus = state.current_new_game_plus or new_game_plus
  if not state.current_new_game_plus then state.current_new_game_plus = current_new_game_plus end
  max_units = MAX_UNITS

  main_song_instance = silence:play { volume = 0.5 }
  main = Main()

  main:add(MainMenu 'mainmenu')
  main:go_to('mainmenu')

  --[[
  main:add(BuyScreen'buy_screen')
  main:go_to('buy_screen', run.level or 1, run.units or {}, passives, run.shop_level or 1, run.shop_xp or 0)
  -- main:go_to('buy_screen', 7, run.units or {}, {'unleash'})
  ]] --

  --[[
  gold = 10
  run_passive_pool = {
    'centipede', 'ouroboros_technique_r', 'ouroboros_technique_l', 'amplify', 'resonance', 'ballista', 'call_of_the_void', 'crucio', 'speed_3', 'damage_4', 'shoot_5', 'death_6', 'lasting_7',
    'defensive_stance', 'offensive_stance', 'kinetic_bomb', 'porcupine_technique', 'last_stand', 'seeping', 'deceleration', 'annihilation', 'malediction', 'hextouch', 'whispers_of_doom',
    'tremor', 'heavy_impact', 'fracture', 'meat_shield', 'hive', 'baneling_burst', 'blunt_arrow', 'explosive_arrow', 'divine_machine_arrow', 'chronomancy', 'awakening', 'divine_punishment',
    'assassination', 'flying_daggers', 'ultimatum', 'magnify', 'echo_barrage', 'unleash', 'reinforce', 'payback', 'enchanted', 'freezing_field', 'burning_field', 'gravity_field', 'magnetism',
    'insurance', 'dividends', 'berserking', 'unwavering_stance', 'unrelenting_stance', 'blessing', 'haste', 'divine_barrage', 'orbitism', 'psyker_orbs', 'psychosink', 'rearm', 'taunt', 'construct_instability',
    'intimidation', 'vulnerability', 'temporal_chains', 'ceremonial_dagger', 'homing_barrage', 'critical_strike', 'noxious_strike', 'infesting_strike', 'burning_strike', 'lucky_strike', 'healing_strike', 'stunning_strike',
    'silencing_strike', 'culling_strike', 'lightning_strike', 'psycholeak', 'divine_blessing', 'hardening', 'kinetic_strike',
  }
  main:add(Arena'arena')
  main:go_to('arena', 21, 0, {
    {character = 'magician', level = 3},
  }, {
    {passive = 'awakening', level = 3},
  })
  ]] --

  --[[
  main:add(Media'media')
  main:go_to('media')
  ]] --

  trigger:every(2, function()
    if debugging_memory then
      for k, v in pairs(system.type_count()) do
        print(k, v)
      end
      print("-- " .. math.round(tonumber(collectgarbage("count")) / 1024, 3) .. "MB --")
      print()
    end
  end)

  --[[
  print(table.tostring(love.graphics.getSupported()))
  print(love.graphics.getRendererInfo())
  local formats = love.graphics.getImageFormats()
  for f, s in pairs(formats) do print(f, tostring(s)) end
  local canvasformats = love.graphics.getCanvasFormats()
  for f, s in pairs(canvasformats) do print(f, tostring(s)) end
  print(table.tostring(love.graphics.getSystemLimits()))
  print(table.tostring(love.graphics.getStats()))
  ]] --
end

love.frame = 0
function update(dt)
  main:update(dt)
  if love.USE_PROFILER then
    Run_Profiler()
  end

  --[[
  if input.b.pressed then
    -- debugging_memory = not debugging_memory
    for k, v in pairs(system.type_count()) do
      print(k, v)
    end
    print("-- " .. math.round(tonumber(collectgarbage("count"))/1024, 3) .. "MB --")
    print()
  end
  ]] --

  --[[
  if input.n.pressed then
    if main.current.sfx_button then
      main.current.sfx_button:action()
      main.current.sfx_button.selected = false
    else
      if sfx.volume == 0.5 then
        sfx.volume = 0
        state.volume_muted = true
      elseif sfx.volume == 0 then
        sfx.volume = 0.5
        state.volume_muted = false
      end
    end
  end

  if input.m.pressed then
    if main.current.music_button then
      main.current.music_button:action()
      main.current.music_button.selected = false
    else
      if music.volume == 0.5 then
        state.music_muted = true
        music.volume = 0
      elseif music.volume == 0 then
        music.volume = 0.5
        state.music_muted = false
      end
    end
  end
  ]] --

  if input.k.pressed then
    if sx > 1 and sy > 1 then
      sx, sy = sx - 0.5, sy - 0.5
      love.window.setMode(480 * sx, 270 * sy)
      state.sx, state.sy = sx, sy
      state.fullscreen = false
    end
  end

  if input.l.pressed then
    sx, sy = sx + 0.5, sy + 0.5
    love.window.setMode(480 * sx, 270 * sy)
    state.sx, state.sy = sx, sy
    state.fullscreen = false
  end

  --[[
  if input.f11.pressed then
    steam.userStats.resetAllStats(true)
    steam.userStats.storeStats()
  end
  ]] --
end

function draw()
  shared_draw(function()
    main:draw()
  end)

  if love.USE_PROFILER then
    Draw_Profiler()
  end
end

function open_options(self)
  input:set_mouse_visible(true)
  trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
    slow_amount = 0
    self.paused = true

    if self:is(Arena) then
      self.paused_t1 = Text2 { group = self.ui, x = gw / 2, y = gh / 2 - 108, sx = 0.6, sy = 0.6, lines = { { text = '[bg10]<-, a or m1       ->, d or m2', font = fat_font, alignment = 'center' } } }
      self.paused_t2 = Text2 { group = self.ui, x = gw / 2, y = gh / 2 - 92, lines = { { text = '[bg10]turn left                                            turn right', font = pixul_font, alignment = 'center' } } }
    end

    if self:is(MainMenu) then
      self.ng_t = Text2 { group = self.ui, x = gw / 2 + 63, y = gh - 50, lines = { { text = '[bg10]current: ' .. current_new_game_plus, font = pixul_font, alignment = 'center' } } }
    end

    self.resume_button = Button { group = self.ui, x = gw / 2, y = gh - 225, force_update = true, button_text = self:is(MainMenu) and 'main menu (esc)' or 'resume game (esc)', fg_color = 'bg10', bg_color = 'bg', action = function(
        b)
      trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
        slow_amount = 1
        self.paused = false
        if self.paused_t1 then
          self.paused_t1.dead = true; self.paused_t1 = nil
        end
        if self.paused_t2 then
          self.paused_t2.dead = true; self.paused_t2 = nil
        end
        if self.ng_t then
          self.ng_t.dead = true; self.ng_t = nil
        end
        if self.resume_button then
          self.resume_button.dead = true; self.resume_button = nil
        end
        if self.restart_button then
          self.restart_button.dead = true; self.restart_button = nil
        end
        if self.dark_transition_button then
          self.dark_transition_button.dead = true; self.dark_transition_button = nil
        end
        if self.run_timer_button then
          self.run_timer_button.dead = true; self.run_timer_button = nil
        end
        if self.sfx_button then
          self.sfx_button.dead = true; self.sfx_button = nil
        end
        if self.music_button then
          self.music_button.dead = true; self.music_button = nil
        end
        if self.video_button_1 then
          self.video_button_1.dead = true; self.video_button_1 = nil
        end
        if self.video_button_2 then
          self.video_button_2.dead = true; self.video_button_2 = nil
        end
        if self.video_button_3 then
          self.video_button_3.dead = true; self.video_button_3 = nil
        end
        if self.video_button_4 then
          self.video_button_4.dead = true; self.video_button_4 = nil
        end
        if self.quit_button then
          self.quit_button.dead = true; self.quit_button = nil
        end
        if self.screen_shake_button then
          self.screen_shake_button.dead = true; self.screen_shake_button = nil
        end
        if self.show_damage_numbers then
          self.show_damage_numbers.dead = true; self.show_damage_numbers = nil
        end
        if self.ng_plus_plus_button then
          self.ng_plus_plus_button.dead = true; self.ng_plus_plus_button = nil
        end
        if self.ng_plus_minus_button then
          self.ng_plus_minus_button.dead = true; self.ng_plus_minus_button = nil
        end
        if self.main_menu_button then
          self.main_menu_button.dead = true; self.main_menu_button = nil
        end
        system.save_state()
        if self:is(MainMenu) or self:is(BuyScreen) then
          input:set_mouse_visible(true)
        elseif self:is(Arena) then
          input:set_mouse_visible(true)
        end
      end, 'pause')
    end }

    --restart new game
    if not self:is(MainMenu) then
      self.restart_button = Button { group = self.ui, x = gw / 2, y = gh - 200, force_update = true, button_text = 'restart run (r)', fg_color = 'bg10', bg_color = 'bg', action = function(
          b)
        self.transitioning = true
        ui_transition2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        ui_switch2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        TransitionEffect { group = main.transitions, x = gw / 2, y = gh / 2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
          slow_amount = 1
          music_slow_amount = 1
          run_time = 0
          passives = {}
          main_song_instance:stop()
          run_passive_pool = {
            'centipede', 'ouroboros_technique_r', 'ouroboros_technique_l', 'amplify', 'resonance', 'ballista',
            'call_of_the_void', 'crucio', 'speed_3', 'damage_4', 'shoot_5', 'death_6', 'lasting_7',
            'defensive_stance', 'offensive_stance', 'kinetic_bomb', 'porcupine_technique', 'last_stand', 'seeping',
            'deceleration', 'annihilation', 'malediction', 'hextouch', 'whispers_of_doom',
            'tremor', 'heavy_impact', 'fracture', 'meat_shield', 'hive', 'baneling_burst', 'blunt_arrow',
            'explosive_arrow', 'divine_machine_arrow', 'chronomancy', 'awakening', 'divine_punishment',
            'assassination', 'flying_daggers', 'ultimatum', 'magnify', 'echo_barrage', 'unleash', 'reinforce', 'payback',
            'enchanted', 'freezing_field', 'burning_field', 'gravity_field', 'magnetism',
            'insurance', 'dividends', 'berserking', 'unwavering_stance', 'unrelenting_stance', 'blessing', 'haste',
            'divine_barrage', 'orbitism', 'psyker_orbs', 'psychosink', 'rearm', 'taunt', 'construct_instability',
            'intimidation', 'vulnerability', 'temporal_chains', 'ceremonial_dagger', 'homing_barrage', 'critical_strike',
            'noxious_strike', 'infesting_strike', 'burning_strike', 'lucky_strike', 'healing_strike', 'stunning_strike',
            'silencing_strike', 'culling_strike', 'lightning_strike', 'psycholeak', 'divine_blessing', 'hardening',
            'kinetic_strike',
          }
          max_units = MAX_UNITS
          main:add(BuyScreen 'buy_screen')
          locked_state = false
          system.save_run()
          

          local new_run = Create_Blank_Save_Data()
          main:go_to('buy_screen', new_run)
        end, text = Text({ { text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']restarting...', font = pixul_font, alignment = 'center' } }, global_text_tags) }
      end }
    end


    self.dark_transition_button = Button { group = self.ui, x = gw / 2 + 13, y = gh - 150, force_update = true, button_text = 'dark transitions: ' .. tostring(state.dark_transitions and 'yes' or 'no'),
      fg_color = 'bg10', bg_color = 'bg', action = function(b)
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      state.dark_transitions = not state.dark_transitions
      b:set_text('dark transitions: ' .. tostring(state.dark_transitions and 'yes' or 'no'))
    end }

    self.run_timer_button = Button { group = self.ui, x = gw / 2 + 121, y = gh - 150, force_update = true, button_text = 'run timer: ' .. tostring(state.run_timer and 'yes' or 'no'), fg_color = 'bg10', bg_color = 'bg',
      action = function(b)
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        state.run_timer = not state.run_timer
        b:set_text('run timer: ' .. tostring(state.run_timer and 'yes' or 'no'))
      end }

    self.sfx_button = Button { group = self.ui, x = gw / 2 - 46, y = gh - 175, force_update = true, button_text = 'sfx volume: ' .. tostring((state.sfx_volume or 0.5) * 10), fg_color = 'bg10', bg_color = 'bg',
      action = function(b)
        ui_switch2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        b.spring:pull(0.2, 200, 10)
        b.selected = true
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        sfx.volume = sfx.volume + 0.1
        if sfx.volume > 1 then sfx.volume = 0 end
        state.sfx_volume = sfx.volume
        b:set_text('sfx volume: ' .. tostring((state.sfx_volume or 0.5) * 10))
      end,
      action_2 = function(b)
        ui_switch2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        b.spring:pull(0.2, 200, 10)
        b.selected = true
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        sfx.volume = sfx.volume - 0.1
        if math.abs(sfx.volume) < 0.001 and sfx.volume > 0 then sfx.volume = 0 end
        if sfx.volume < 0 then sfx.volume = 1 end
        state.sfx_volume = sfx.volume
        b:set_text('sfx volume: ' .. tostring((state.sfx_volume or 0.5) * 10))
      end }

    self.music_button = Button { group = self.ui, x = gw / 2 + 48, y = gh - 175, force_update = true, button_text = 'music volume: ' .. tostring((state.music_volume or 0.5) * 10), fg_color = 'bg10', bg_color = 'bg',
      action = function(b)
        ui_switch2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        b.spring:pull(0.2, 200, 10)
        b.selected = true
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        music.volume = music.volume + 0.1
        if music.volume > 1 then music.volume = 0 end
        state.music_volume = music.volume
        b:set_text('music volume: ' .. tostring((state.music_volume or 0.5) * 10))
      end,
      action_2 = function(b)
        ui_switch2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        b.spring:pull(0.2, 200, 10)
        b.selected = true
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        music.volume = music.volume - 0.1
        if math.abs(music.volume) < 0.001 and music.volume > 0 then music.volume = 0 end
        if music.volume < 0 then music.volume = 1 end
        state.music_volume = music.volume
        b:set_text('music volume: ' .. tostring((state.music_volume or 0.5) * 10))
      end }

    self.video_button_1 = Button { group = self.ui, x = gw / 2 - 136, y = gh - 125, force_update = true, button_text = 'window size-', fg_color = 'bg10', bg_color = 'bg', action = function()
      if sx > 1 and sy > 1 then
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        sx, sy = sx - 0.5, sy - 0.5
        love.window.setMode(480 * sx, 270 * sy)
        state.sx, state.sy = sx, sy
        state.fullscreen = false
      end
    end }

    self.video_button_2 = Button { group = self.ui, x = gw / 2 - 50, y = gh - 125, force_update = true, button_text = 'window size+', fg_color = 'bg10', bg_color = 'bg', action = function()
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      sx, sy = sx + 0.5, sy + 0.5
      love.window.setMode(480 * sx, 270 * sy)
      state.sx, state.sy = sx, sy
      state.fullscreen = false
    end }

    self.video_button_3 = Button { group = self.ui, x = gw / 2 + 29, y = gh - 125, force_update = true, button_text = 'fullscreen', fg_color = 'bg10', bg_color = 'bg', action = function()
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      local _, _, flags = love.window.getMode()
      local window_width, window_height = love.window.getDesktopDimensions(flags.display)
      sx, sy = window_width / 480, window_height / 270
      state.sx, state.sy = sx, sy
      ww, wh = window_width, window_height
      love.window.setMode(window_width, window_height)
    end }

    self.video_button_4 = Button { group = self.ui, x = gw / 2 + 129, y = gh - 125, force_update = true, button_text = 'reset video settings', fg_color = 'bg10', bg_color = 'bg', action = function()
      local _, _, flags = love.window.getMode()
      local window_width, window_height = love.window.getDesktopDimensions(flags.display)
      sx, sy = window_width / 480, window_height / 270
      ww, wh = window_width, window_height
      state.sx, state.sy = sx, sy
      state.fullscreen = false
      ww, wh = window_width, window_height
      love.window.setMode(window_width, window_height)
    end }

    self.screen_shake_button = Button { group = self.ui, x = gw / 2 - 57, y = gh - 100, w = 110, force_update = true, button_text = '[bg10]screen shake: ' .. tostring(state.no_screen_shake and 'no' or 'yes'),
      fg_color = 'bg10', bg_color = 'bg', action = function(b)
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      state.no_screen_shake = not state.no_screen_shake
      b:set_text('screen shake: ' .. tostring(state.no_screen_shake and 'no' or 'yes'))
    end }

    self.show_damage_numbers = Button { group = self.ui, x = gw / 2 + 65, y = gh - 75, w = 125, force_update = true, button_text = '[bg10]show damage numbers: ' .. tostring(state.show_damage_numbers and 'yes' or 'no'),
      fg_color = 'bg10', bg_color = 'bg', action = function(b)
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      state.show_damage_numbers = not state.show_damage_numbers
      b:set_text('show damage numbers: ' .. tostring(state.show_damage_numbers and 'yes' or 'no'))
    end }

    if self:is(MainMenu) then
      self.ng_plus_minus_button = Button { group = self.ui, x = gw / 2 - 58, y = gh - 50, force_update = true, button_text = 'NG+ down', fg_color = 'bg10', bg_color = 'bg', action = function(
          b)
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        b.spring:pull(0.2, 200, 10)
        b.selected = true
        current_new_game_plus = math.clamp(current_new_game_plus - 1, 0, 5)
        state.current_new_game_plus = current_new_game_plus
        self.ng_t.text:set_text({ { text = '[bg10]current: ' .. current_new_game_plus, font = pixul_font, alignment = 'center' } })
        max_units = MAX_UNITS
        system.save_run()
      end }

      self.ng_plus_plus_button = Button { group = self.ui, x = gw / 2 + 5, y = gh - 50, force_update = true, button_text = 'NG+ up', fg_color = 'bg10', bg_color = 'bg', action = function(
          b)
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        b.spring:pull(0.2, 200, 10)
        b.selected = true
        current_new_game_plus = math.clamp(current_new_game_plus + 1, 0, new_game_plus)
        state.current_new_game_plus = current_new_game_plus
        self.ng_t.text:set_text({ { text = '[bg10]current: ' .. current_new_game_plus, font = pixul_font, alignment = 'center' } })
        max_units = MAX_UNITS
        system.save_run()
      end }
    end

    if not self:is(MainMenu) then
      self.main_menu_button = Button { group = self.ui, x = gw / 2, y = gh - 50, force_update = true, button_text = 'main menu', fg_color = 'bg10', bg_color = 'bg', action = function(
          b)
        self.transitioning = true
        ui_transition2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        ui_switch2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        TransitionEffect { group = main.transitions, x = gw / 2, y = gh / 2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
          main:add(MainMenu 'main_menu')
          main:go_to('main_menu')
        end, text = Text({ { text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']..', font = pixul_font, alignment = 'center' } }, global_text_tags) }
      end }
    end

    self.quit_button = Button { group = self.ui, x = gw / 2, y = gh - 25, force_update = true, button_text = 'quit', fg_color = 'bg10', bg_color = 'bg', action = function()
      system.save_state()
      --steam.shutdown()
      love.event.quit()
    end }
  end, 'pause')
end

function close_options(self)
  trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
    slow_amount = 1
    self.paused = false
    if self.paused_t1 then
      self.paused_t1.dead = true; self.paused_t1 = nil
    end
    if self.paused_t2 then
      self.paused_t2.dead = true; self.paused_t2 = nil
    end
    if self.ng_t then
      self.ng_t.dead = true; self.ng_t = nil
    end
    if self.resume_button then
      self.resume_button.dead = true; self.resume_button = nil
    end
    if self.restart_button then
      self.restart_button.dead = true; self.restart_button = nil
    end
    if self.dark_transition_button then
      self.dark_transition_button.dead = true; self.dark_transition_button = nil
    end
    if self.run_timer_button then
      self.run_timer_button.dead = true; self.run_timer_button = nil
    end
    if self.sfx_button then
      self.sfx_button.dead = true; self.sfx_button = nil
    end
    if self.music_button then
      self.music_button.dead = true; self.music_button = nil
    end
    if self.video_button_1 then
      self.video_button_1.dead = true; self.video_button_1 = nil
    end
    if self.video_button_2 then
      self.video_button_2.dead = true; self.video_button_2 = nil
    end
    if self.video_button_3 then
      self.video_button_3.dead = true; self.video_button_3 = nil
    end
    if self.video_button_4 then
      self.video_button_4.dead = true; self.video_button_4 = nil
    end
    if self.screen_shake_button then
      self.screen_shake_button.dead = true; self.screen_shake_button = nil
    end
    if self.show_damage_numbers then
      self.show_damage_numbers.dead = true; self.show_damage_numbers = nil
    end
    if self.quit_button then
      self.quit_button.dead = true; self.quit_button = nil
    end
    if self.ng_plus_plus_button then
      self.ng_plus_plus_button.dead = true; self.ng_plus_plus_button = nil
    end
    if self.ng_plus_minus_button then
      self.ng_plus_minus_button.dead = true; self.ng_plus_minus_button = nil
    end
    if self.main_menu_button then
      self.main_menu_button.dead = true; self.main_menu_button = nil
    end
    system.save_state()
    if self:is(MainMenu) or self:is(BuyScreen) then
      input:set_mouse_visible(true)
    elseif self:is(Arena) then
      input:set_mouse_visible(true)
    end
  end, 'pause')
end

function love.run()
  return engine_run({
    game_name = 'UNDERLOD',
    window_width = 'max',
    window_height = 'max',
  })
end

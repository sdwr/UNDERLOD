require 'save_game'
require 'engine'
require 'shared'
require 'utils'
require 'game_constants'
require 'animations/init'
require 'combat_stats/init'
require 'achievements/achievements'
require 'helper/helper'
require 'ui/ui'
require 'ui/character_tooltip'
require 'ui/set_bonus_tooltip'
require 'door'
require 'level_classes/arena'
require 'level_classes/base_level'
require 'level_classes/level_0'
require 'level_classes/combat_level'
require 'procs/procs'
require 'procs/perks'
require 'items/constants'
require 'items/old_items'
require 'items/items_v2'
require 'mainmenu'
require 'buy_screen_utils'
require 'buy_screen'
require 'world_manager'
require 'objects'
require 'miscellaneous_objects'
require 'media'
require 'spawns/spawn_includes'
require 'enemies/level_manager'
require 'enemies/enemy_includes'
require 'units/units'
require 'util/fpscounter'
require 'util/draw_animations'
require 'util/draw_utils'

love.profiler = require('util/profiler/profile')
require 'util/runprofiler'

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end

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
  firebreath = Sound('firebreath.mp3', s)
  ui_modern_hover = Sound('ui-modern-hover.mp3', s)
  door_open = Sound('door-open.mp3', s)
  arrow_hit = Sound('arrow-hit.wav', s)
  arrow_release1 = Sound('arrow-release1.wav', s)
  arrow_release2 = Sound('arrow-release2.wav', s)
  arrow_release3 = Sound('arrow-release3.wav', s)

  holylight = Sound('HolyLight.ogg', s)
  sword_swing = Sound('sword swing.wav', s)
  freeze_sound = Sound('ice_cracking_trimmed.wav', s)
  arcspread_sound = Sound('arcspread.wav', s)
  arcspread_full_sound = Sound('arcspread_full.wav', s)
  new_spark = Sound('new_spark.wav', s)

  title_music = Sound('Debussy - Reverie.mp3', { tags = { music } })



  -- song1 = Sound('gunnar - 26 hours and I feel Fine.mp3', { tags = { music } })
  -- song2 = Sound('gunnar - Back On Track.mp3', { tags = { music } })
  -- song3 = Sound('gunnar - Chrysalis.mp3', { tags = { music } })
  -- song4 = Sound('gunnar - Fingers.mp3', { tags = { music } })
  -- song5 = Sound('gunnar - Jam 32 Melancholy.mp3', { tags = { music } })
  -- song6 = Sound('gunnar - Make It Rain.mp3', { tags = { music } })
  -- song7 = Sound('gunnar - Mammon.mp3', { tags = { music } })
  -- song8 = Sound('gunnar - Up To The Brink.mp3', { tags = { music } })

  -- derp1 = Sound('derp - Negative Space.mp3')
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
  simpleshield          = Image(d .. 'simpleshield')
  helmet                = Image(d .. 'helmet')
  sword                 = Image(d .. 'sword')
  simpleboots           = Image(d .. 'simpleboots')
  simplearmor           = Image(d .. 'simplearmor')
  orb                   = Image(d .. 'orb')
  potion2               = Image(d .. 'potion2')


  skull                 = Image(d .. 'skull-small')
  fancyarmor            = Image(d .. 'fancyarmor')
  turtle                = Image(d .. 'turtle')
  leaf                  = Image(d .. 'leaf')
  linegoesup            = Image(d .. 'linegoesup')
  rock                  = Image(d .. 'rock')
  flask                 = Image(d .. 'flask')
  gem                   = Image(d .. 'gem')
  sun                   = Image(d .. 'sun')
  mace                  = Image(d .. 'mace')
  fire                  = Image(d .. 'fire')
  lightning             = Image(d .. 'lightning')
  clam                  = Image(d .. 'clam')
  coins                 = Image(d .. 'coins')
  reticle               = Image(d .. 'reticle')
  root                  = Image(d .. 'root')
  bomb2                 = Image(d .. 'bomb2')
  talisman              = Image(d .. 'talisman')
  bloodlust             = Image(d .. 'bloodlust')
  spikedcollar          = Image(d .. 'spikedcollar2')
  bow2                  = Image(d .. 'bow2')
  repeater              = Image(d .. 'repeater')
  monster               = Image(d .. 'monster')
  sackofcash            = Image(d .. 'sackofcash')

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

  exclamation_point_small = Image('exclamation_point_small')
  
  EXCLAMATION_POINT_W = 150
  EXCLAMATION_POINT_H = 160
  EXCLAMATION_POINT_SCALE = 4
  
  locked_image = Image(d ..'locked')
  LOCKED_W = 360
  LOCKED_H = 360
  LOCKED_SCALE = 1.5


-- normal and stopped are tied together for the purpose of attacking
-- rallying and following are tied together for the purpose of moving
  unit_states = {
    ['idle'] = 'idle',
    ['normal'] = 'normal',
    ['moving'] = 'moving',
    ['frozen'] = 'frozen',
    ['stunned'] = 'stunned',
    ['casting'] = 'casting',
    ['channeling'] = 'channeling',
    ['stopped'] = 'stopped',
    ['following'] = 'following',
    ['launching'] = 'launching',
    ['knockback'] = 'knockback',
    ['casting_blocked'] = 'casting_blocked',
  }

  unit_states_can_move = {
    unit_states['idle'],
    unit_states['normal'],
    unit_states['stopped'],
    unit_states['following'],
    unit_states['casting'],
    unit_states['channeling'],
    unit_states['casting_blocked'],
  }

  unit_states_can_rally = {
    unit_states['idle'],
    unit_states['normal'],
    unit_states['stopped'],
    unit_states['following'],
    unit_states['casting'],
    unit_states['channeling'],
    unit_states['casting_blocked'],
  }

  unit_states_enemy_can_move = {
    unit_states['idle'],
    unit_states['normal'],
    unit_states['following'],
    unit_states['casting_blocked'],
  }

  unit_states_enemy_no_velocity = {
    unit_states['stunned'],
    unit_states['frozen'],
    unit_states['channeling'],
  }

  unit_states_can_target = {
    unit_states['idle'],
    unit_states['normal'],
    unit_states['casting_blocked'],
    unit_states['following'],
    
  }

  unit_states_can_cast = {
    unit_states['idle'],
    unit_states['normal'],
    unit_states['following'],
    unit_states['stopped'],
  }

  unit_states_can_continue_cast = {
    unit_states['idle'],
    unit_states['normal'],
    unit_states['following'],
    unit_states['stopped'],
    unit_states['casting'],
    unit_states['channeling'],
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
    ['stormweaver'] = 'Stormweaver',
    ['sage'] = 'Sage',
    ['squire'] = 'Squire',
    ['cannoneer'] = 'Cannoneer',
    ['dual_gunner'] = 'Dual Gunner',
    ['hunter'] = 'Hunter',
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
    ['stormweaver'] = blue[0],
    ['sage'] = purple[0],
    ['squire'] = yellow[0],
    ['cannoneer'] = orange[0],
    ['dual_gunner'] = green[0],
    ['hunter'] = green[0],
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
    ['stormweaver'] = 'blue',
    ['sage'] = 'purple',
    ['squire'] = 'yellow',
    ['cannoneer'] = 'orange',
    ['dual_gunner'] = 'green',
    ['hunter'] = 'green',
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
    local troop_data = { group = group, character = unit.character, level = unit.level, items = unit.items, perks = main.current.perks or {} }
    local troop = Create_Troop(troop_data)
    
    -- Get item stats
    local item_stats = troop:get_item_stats_for_display()
    
    -- Get perk stats
    local perk_stats = troop:get_perk_stats_for_display()
    
    -- Combine item and perk stats
    local combined_stats = {}
    
    -- Start with item stats
    for stat_name, stat_value in pairs(item_stats) do
      combined_stats[stat_name] = stat_value
    end
    
    -- Add perk stats to the combined stats
    for stat_name, stat_value in pairs(perk_stats) do
      if combined_stats[stat_name] then
        combined_stats[stat_name] = combined_stats[stat_name] + stat_value
      else
        combined_stats[stat_name] = stat_value
      end
    end
    
    -- Order stats
    local final_stats = {}
    for _, stat_name in ipairs(item_stat_display_order) do
      if combined_stats[stat_name] then
        final_stats[stat_name] = combined_stats[stat_name]
      end
    end
    
    -- Clean up temporary objects
    troop.dead = true
    group:destroy()
    
    return final_stats
  end


  build_round_stats_text = function(unit)
    local text_lines = {}
    
    -- Format damage and DPS
    local damage_text = math.floor(unit.last_round_damage)
    local dps_text = string.format("%.1f", unit.last_round_dps)
    
    -- Add damage line
    table.insert(text_lines, { 
      text = '[red]DMG: [red]' .. damage_text, 
      font = pixul_font, 
      alignment = 'center' 
    })
    
    -- Add DPS line
    table.insert(text_lines, { 
      text = '[green]DPS: [green]' .. dps_text, 
      font = pixul_font, 
      alignment = 'center' 
    })
    
    -- Add kills if available
    if unit.last_round_kills and unit.last_round_kills > 0 then
      table.insert(text_lines, { 
        text = '[yellow]Kills: [yellow]' .. unit.last_round_kills, 
        font = pixul_font, 
        alignment = 'center' 
      })
    end
    
    local text2 = Text2 { group = main.current.ui, x = 0, y = 0,
      lines = text_lines, font = pixul_font, alignment = 'center',
      force_update = false }
    
    return text2
  end

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
  

  item_images = {
    ['default'] = sword,
    
    ['sword'] = sword,
    ['simplearmor'] = simplearmor,
    ['orb'] = orb,
    ['helmet'] = helmet,
    ['simpleshield'] = simpleshield,
    ['simpleboots'] = simpleboots,

    ['potion2'] = potion2,
    ['linegoesup'] = linegoesup,
    ['fancyarmor'] = fancyarmor,
    ['turtle'] = turtle,
    ['leaf'] = leaf,
    ['rock'] = rock,
    ['flask'] = flask,
    ['gem'] = gem,
    ['sun'] = sun,
    ['mace'] = mace,
    ['fire'] = fire,
    ['lightning'] = lightning,
    ['clam'] = clam,
    ['reticle'] = reticle,
    ['skull'] = skull,
    ['root'] = root,
    ['bomb'] = bomb2,
    ['talisman'] = talisman,
    ['bloodlust'] = bloodlust,
    ['spikedcollar'] = spikedcollar,
    ['bow'] = bow2,
    ['repeater'] = repeater,
    ['monster'] = monster,
    ['sackofcash'] = sackofcash,

  }

  character_images = {
    ['default'] = sword,
    ['swordsman'] = sword,
    ['archer'] = bow2,
    ['laser'] = reticle,
  }

  character_colors = {
    ['default'] = grey[0],
    ['swordsman'] = white[0],
    ['archer'] = green[0],
    ['laser'] = blue[0],
  }

  item_stat_lookup = {
    ['dmg'] = 'damage',
    ['mvspd'] = 'move',
    ['aspd'] = 'aspeed',
    ['hp'] = 'hp',
    ['flat_def'] = 'def',
    ['percent_def'] = 'def',
    ['area_size'] = 'area',
    ['vamp'] = 'lifesteal',
    ['ghost'] = 'ghost',
    ['slow'] = 'slow',
    ['thorns'] = 'reflect',
    ['range'] = 'range',
    ['bash'] = 'stun',
    ['repeat_attack_chance'] = 'repeat',
    ['enrage'] = 'enrage',
    ['gold'] = 'gold',
    ['heal'] = 'heal',
    ['fire_damage'] = 'fire',
    ['lightning_damage'] = 'shock',
    ['cold_damage'] = 'cold',
    ['fire_damage_m'] = 'fire mult',
    ['lightning_damage_m'] = 'shock mult',
    ['cold_damage_m'] = 'cold mult',

    ['crit_chance'] = 'crit',
    ['crit_mult'] = 'crit',
    ['stun_chance'] = 'stun',
    ['knockback_resistance'] = 'knockback resistance',
    ['cooldown_reduction'] = 'cdr',
    ['slow_per_element'] = 'slow per element',

    ['proc'] = 'Extra effect on attack',
  }

  item_stat_display_order = {
    --core offensive stats
    'dmg',
    'aspd',
    'repeat_attack_chance',
    'range',
    
    'crit_chance',
    'crit_mult',
    'stun_chance',
    'cooldown_reduction',

    --core defensive stats
    'hp',
    'flat_def',
    'percent_def',
    'mvspd',
    'knockback_resistance',

    --elemental stats
    'fire_damage',
    'lightning_damage',
    'cold_damage',
    'fire_damage_m',
    'lightning_damage_m',
    'cold_damage_m',

    --other stats
    'area_size',
    'vamp',
    'ghost',
    'slow',
    'slow_per_element',
    'thorns',
  }


  build_achievement_text = function(achieve)
    local name = achieve.name or 'achievement name'
    name = name:upper()

    local out = {}
    table.insert(out, { text = '[fg]' .. name, font = pixul_font, alignment = 'center', height_multiplier = 1.25 })
    table.insert(out, {
      text = '[fg]' .. achieve.desc,
      font = pixul_font,
      alignment = 'center',
      height_multiplier = 1.25
    })
    return out
  end

  build_wave_text = function(i, wave, out)
    --sum all enemies by type
    local enemies = {}
    for _, enemy in pairs(wave) do
      if enemy[1] == 'GROUP' then
        local type = enemy[2]
        if type == 'shooter' or type == 'seeker' then
          type = 'basic'
        else
          type = 'special'
        end

        if not enemies[type] then
          enemies[type] = enemy[3]
        else
          enemies[type] = enemies[type] + enemy[3]
        end
      end
    end
    
    table.insert(out, { text = '[fg]Wave ' .. i .. ':', font = pixul_font, alignment = 'center', height_multiplier = 1.25 })
    local enemy_text = "[fg]"
    for type, count in pairs(enemies) do
      enemy_text = enemy_text .. count .. ' ' .. type .. ', '
    end
    enemy_text = enemy_text:sub(1, #enemy_text - 2)
    table.insert(out, { text = '[fg]' .. enemy_text, font = pixul_font, alignment = 'center', height_multiplier = 1.25 })

    return out

  end

  item_to_color = function(item)
    if not item then return grey[0] end

    if item.rarity then
      return get_rarity_color(item.rarity)
    end

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

  function level_to_shop_tier(lvl)
    if lvl <= 6 then
      return 1
    elseif lvl <= 11 then
      return 2
    elseif lvl <= 16 then
      return 3
    else
      return 4
    end
  end

  enemy_class_names = {
    'regular_enemy',
    'special_enemy',
    'boss',
  }


  normal_enemies = {
    'swarmer',
    'shooter',
    'seeker',
    'chaser',
  }

  special_enemies = {
    'cleaver',
    'laser',
    'stomper',
    'burst',
    'boomerang',
    'charger',
    'plasma',
    'spread',
    'mortar',
    'summoner',
    'arcspread',
    'firewall_caster',
    'turret',
  }

  boss_enemies = {
    'stompy',
    'dragon',
    'heigan',
    'final_boss',
  }

  level_to_boss_enemy = {
    [6] = 'stompy',
    [11] = 'dragon',
    [16] = 'heigan',
    [21] = 'final_boss',
    [25] = 'final_boss',
  }

  normal_enemy_by_tier = {
    [1] = {
      'swarmer',
      'seeker',
      'chaser',
    },
    [1.5] = {
      'swarmer',
      'seeker',
      'chaser',
      'goblin_archer',
    },
    [2] = {
      'swarmer',
      'shooter',
      'chaser',
      'goblin_archer',
    },
    [2.5] = {
      'swarmer',
      'shooter',
      'chaser',
      'goblin_archer',
    }
  }

  special_enemy_by_tier_melee = {
    [1] = {
      'cleaver',
      'selfburst',
    },
    [1.5] = {
      'cleaver',
    },
    [2] = {
      'charger',
    },
    [2.5] = {
      'charger',
    },
    [3] = {
      'charger',
    },
  }

  special_enemy_by_tier = {
    [1] = {
      'goblin_archer',
      'archer',
      -- 'selfburst',
      'burst',
      'snakearrow',
      -- 'turret',
      -- 'cleaver',
      -- 'slowcharger',
    },
    [1.5] = {
      'mortar',
      'singlemortar',
      'line_mortar',
      'aim_spread',
      -- 'charger',
      -- 'big_goblin_archer',
      -- 'boomerang',
      -- 'turret',
    },
    [2] = {
      'firewall_caster',
      'mortar',
      'singlemortar',
      'line_mortar',
      'aim_spread',
      'snakearrow',
      'charger',
      'boomerang',
      'turret',
    },
    [2.5] = {
      'mortar',
      'singlemortar',
      'line_mortar',
      'aim_spread',
      'snakearrow',
      'charger',
      'boomerang',
      'big_goblin_archer',
      'turret',
    },
    [3] = {
      'arcspread',
      'burst',
      'selfburst',
      'singlemortar',
      'line_mortar',
      'aim_spread',
      'snakearrow',
      'plasma',
      'big_goblin_archer',
      'turret',
    },
  }

  enemy_to_round_power = {
    ['swarmer'] = 25,

    ['shooter'] = 50,
    ['seeker'] = 50,
    ['chaser'] = 50,

    --special enemies t1
    ['goblin_archer'] = 150,
    ['archer'] = 150,
    ['burst'] = 150,
    ['turret'] = 150,
    ['cleaver'] = 150,
    ['selfburst'] = 150,
    ['snakearrow'] = 150,

    --special enemies t1.5
    ['mortar'] = 300,
    ['singlemortar'] = 300,
    ['line_mortar'] = 300,
    ['aim_spread'] = 300,
    ['charger'] = 300,

    --special enemies t2
    ['laser'] = 200,
    ['rager'] = 200,
    ['stomper'] = 200,
    ['bomb'] = 200,
    ['boomerang'] = 200,
    ['plasma'] = 200,
    ['big_goblin_archer'] = 200,
    ['slowcharger'] = 200,
    --special enemies t2
    ['firewall_caster'] = 250,
    ['spread'] = 250,
    ['spawner'] = 250,
    ['arcspread'] = 250,
    --special enemies t3
    ['summoner'] = 300,
    ['assassin'] = 300,

    --bosses
    ['stompy'] = BOSS_ROUND_POWER,
    ['dragon'] = BOSS_ROUND_POWER,
    ['heigan'] = BOSS_ROUND_POWER,
  }

  enemy_to_color = {
    ['swarmer'] = grey[0],
    ['shooter'] = grey[0],
    ['seeker'] = grey[0],
    ['chaser'] = grey[0],
    ['cleaver'] = grey[0],

    ['rager'] = red[3],
    ['stomper'] = red[3],
    ['charger'] = red[3],
    ['firewall_caster'] = red[3],
    ['mortar'] = orange[3],
    ['singlemortar'] = green[3],
    ['line_mortar'] = red[3],
    ['aim_spread'] = blue[3],
    ['snakearrow'] = purple[3],
    ['spawner'] = orange[3],
    ['bomb'] = orange[3],
    ['arcspread'] = blue[3],
    ['summoner'] = purple[3],
    ['assassin'] = purple[3],
    ['big_goblin_archer'] = green[3],
    ['archer'] = red[3],
    ['selfburst'] = orange[3],
    ['slowcharger'] = orange[3],
    ['turret'] = red[3],
  }

  DAMAGE_TYPE_TO_COLOR = {
    [DAMAGE_TYPE_PHYSICAL] = white[3],
    [DAMAGE_TYPE_FIRE] = red[3],
    [DAMAGE_TYPE_BURN] = red[3],
    [DAMAGE_TYPE_LIGHTNING] = yellow[3],
    [DAMAGE_TYPE_SHOCK] = yellow[3],
    [DAMAGE_TYPE_POISON] = green[3],
    [DAMAGE_TYPE_COLD] = blue[3],
  }

  level_to_item_odds = {
    [1] = { 100, 0, 0, 0 },
    [2] = { 55, 30, 15, 0 },
    [3] = { 35, 40, 20, 5 },
    [4] = { 10, 25, 45, 20 },
    [5] = { 0, 20, 40, 40 },
  }

  Load_Steam_State()
  new_game_plus = state.new_game_plus or 0
  if not state.new_game_plus then state.new_game_plus = new_game_plus end
  current_new_game_plus = state.current_new_game_plus or new_game_plus
  if not state.current_new_game_plus then state.current_new_game_plus = current_new_game_plus end

  state.show_damage_numbers = state.show_damage_numbers or DAMAGE_NUMBERS_SETTING[4]
  state.show_combat_controls = not not state.show_combat_controls

  max_units = MAX_UNITS

  main_song_instance = title_music:play { volume = state.music_volume or 1 }
  main = Main()

  enable_custom_cursor('simple')

  main:add(MainMenu 'mainmenu')
  main:go_to('mainmenu')

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

  if input.f11.pressed then
    print('resetting all acheives and stats')
    Reset_All_Achievements()
  end

  if input.f10.pressed then
    Unlock_Achievement('heatingup')
  end

  if input['f6'].pressed then
    DEBUG_STEERING_VECTORS = not DEBUG_STEERING_VECTORS
    print('DEBUG_STEERING_VECTORS:', DEBUG_STEERING_VECTORS)
    print('DEBUG_STEERING_ENEMY_TYPE:', DEBUG_STEERING_ENEMY_TYPE)
  end

  if input['f7'].pressed then
    DEBUG_DISTANCE_MULTI = not DEBUG_DISTANCE_MULTI
    print('DEBUG_DISTANCE_MULTI:', DEBUG_DISTANCE_MULTI)
  end
end

function draw()
  shared_draw(function()
    main:draw()
  end)

  if love.USE_PROFILER then
    Draw_Profiler()
  end
end

function reset_slow_amount()
  slow_amount = 1
  music_slow_amount = 1
end

function open_options(self)
  -- input:set_mouse_visible(true)
  trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
    slow_amount = 0
    self.paused = true

    if self:is(Arena) then
      --pass
    end

    if self:is(MainMenu) then
      self.ng_t = Text2 { group = self.options_ui, x = gw / 2 + 63, y = gh - 50, lines = { { text = '[bg10]current: ' .. current_new_game_plus, font = pixul_font, alignment = 'center' } } }
    end

    self.resume_button = Button { group = self.options_ui, x = gw / 2, y = gh - 225, force_update = true, button_text = self:is(MainMenu) and 'main menu (esc)' or 'resume game (esc)', fg_color = 'bg10', bg_color = 'bg', action = function(
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
        if self.show_combat_controls_button then
          self.show_combat_controls_button.dead = true; self.show_combat_controls_button = nil
        end
        if self.show_damage_numbers_button then
          self.show_damage_numbers_button.dead = true; self.show_damage_numbers_button = nil
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
          -- input:set_mouse_visible(true)
        elseif self:is(Arena) then
          -- input:set_mouse_visible(true)
        end
      end, 'pause')
    end }

    --restart new game
    if not self:is(MainMenu) then
      self.restart_button = Button { group = self.options_ui, x = gw / 2, y = gh - 200, force_update = true, button_text = 'restart run', fg_color = 'bg10', bg_color = 'bg', action = function(
          b)
        self.transitioning = true
        ui_transition2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        ui_switch2:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        TransitionEffect { group = main.transitions, x = gw / 2, y = gh / 2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
          
          Start_New_Run_And_Go_To_Buy_Screen()
        end, text = Text({ { text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']restarting...', font = pixul_font, alignment = 'center' } }, global_text_tags) }
      end }
    end

    self.sfx_button = Button { group = self.options_ui, x = gw / 2 - 46, y = gh - 175, force_update = true, button_text = 'sfx volume: ' .. tostring((state.sfx_volume or 0.5) * 10), fg_color = 'bg10', bg_color = 'bg',
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

    self.music_button = Button { group = self.options_ui, x = gw / 2 + 48, y = gh - 175, force_update = true, button_text = 'music volume: ' .. tostring((state.music_volume or 0.5) * 10), fg_color = 'bg10', bg_color = 'bg',
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

    self.video_button_1 = Button { group = self.options_ui, x = gw / 2 - 136, y = gh - 125, force_update = true, button_text = 'window size-', fg_color = 'bg10', bg_color = 'bg', action = function()
      if sx > 1 and sy > 1 then
        ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
        sx, sy = sx - 0.5, sy - 0.5
        love.window.setMode(480 * sx, 270 * sy)
        state.sx, state.sy = sx, sy
        state.fullscreen = false
        create_full_res_canvases()
      end
    end }

    self.video_button_2 = Button { group = self.options_ui, x = gw / 2 - 50, y = gh - 125, force_update = true, button_text = 'window size+', fg_color = 'bg10', bg_color = 'bg', action = function()
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      sx, sy = sx + 0.5, sy + 0.5
      love.window.setMode(480 * sx, 270 * sy)
      state.sx, state.sy = sx, sy
      state.fullscreen = false
      create_full_res_canvases()
    end }

    self.video_button_3 = Button { group = self.options_ui, x = gw / 2 + 29, y = gh - 125, force_update = true, button_text = 'fullscreen', fg_color = 'bg10', bg_color = 'bg', action = function()
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      local _, _, flags = love.window.getMode()
      local window_width, window_height = love.window.getDesktopDimensions(flags.display)
      sx, sy = window_width / 480, window_height / 270
      state.sx, state.sy = sx, sy
      ww, wh = window_width, window_height
      love.window.setMode(window_width, window_height)
      create_full_res_canvases()
    end }

    self.video_button_4 = Button { group = self.options_ui, x = gw / 2 + 129, y = gh - 125, force_update = true, button_text = 'reset video settings', fg_color = 'bg10', bg_color = 'bg', action = function()
      local _, _, flags = love.window.getMode()
      local window_width, window_height = love.window.getDesktopDimensions(flags.display)
      sx, sy = window_width / 480, window_height / 270
      ww, wh = window_width, window_height
      state.sx, state.sy = sx, sy
      state.fullscreen = false
      ww, wh = window_width, window_height
      love.window.setMode(window_width, window_height)
      create_full_res_canvases()
    end }

    self.screen_shake_button = Button { group = self.options_ui, x = gw / 2 - 57, y = gh - 100, w = 110, force_update = true, button_text = '[bg10]screen shake: ' .. tostring(state.no_screen_shake and 'no' or 'yes'),
      fg_color = 'bg10', bg_color = 'bg', action = function(b)
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      state.no_screen_shake = not state.no_screen_shake
      b:set_text('screen shake: ' .. tostring(state.no_screen_shake and 'no' or 'yes'))
    end }

    self.show_damage_numbers_button = Button { group = self.options_ui, x = gw / 2 + 95, y = gh - 100, w = 180, force_update = true, button_text = '[bg10]show damage numbers: ' .. tostring(state.show_damage_numbers or 'off'),
      fg_color = 'bg10', bg_color = 'bg', action = function(b)
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }
      local index = table.find(DAMAGE_NUMBERS_SETTING, state.show_damage_numbers) or 1
      if index == #DAMAGE_NUMBERS_SETTING or index == nil then
        index = 1
      else
        index = index + 1
      end
      state.show_damage_numbers = DAMAGE_NUMBERS_SETTING[index]
      show_damage_numbers = index

      b:set_text('show damage numbers: ' .. tostring(state.show_damage_numbers or 'off'))
    end }

    self.show_combat_controls_button = Button { group = self.options_ui, x = gw / 2, y = gh - 80, force_update = true, button_text = '[bg10]show combat controls: ' .. tostring(state.show_combat_controls and 'yes' or 'no'),
      fg_color = 'bg10', bg_color = 'bg', action = function(b)
      ui_switch1:play { pitch = random:float(0.95, 1.05), volume = 0.5 }

      state.show_combat_controls = not state.show_combat_controls
      show_combat_controls = state.show_combat_controls
      
      b:set_text('show combat controls: ' .. tostring(state.show_combat_controls and 'yes' or 'no'))
    end }

    if self:is(MainMenu) then
      self.ng_plus_minus_button = Button { group = self.options_ui, x = gw / 2 - 58, y = gh - 50, force_update = true, button_text = 'NG+ down', fg_color = 'bg10', bg_color = 'bg', action = function(
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

      self.ng_plus_plus_button = Button { group = self.options_ui, x = gw / 2 + 5, y = gh - 50, force_update = true, button_text = 'NG+ up', fg_color = 'bg10', bg_color = 'bg', action = function(
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
      self.main_menu_button = Button { group = self.options_ui, x = gw / 2, y = gh - 50, force_update = true, button_text = 'main menu', fg_color = 'bg10', bg_color = 'bg', action = function(
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

    self.quit_button = Button { group = self.options_ui, x = gw / 2, y = gh - 25, force_update = true, button_text = 'quit', fg_color = 'bg10', bg_color = 'bg', action = function()
      cleanup_global_cursor()
      system.save_state()
      --steam.shutdown()
      love.event.quit()
    end }
  end, 'pause')
end

function close_options(self, remain_paused)
  trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
    slow_amount = 1
    if not remain_paused then
      self.paused = false
    end
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
    if self.show_damage_numbers_button then
      self.show_damage_numbers_button.dead = true; self.show_damage_numbers_button = nil
    end
    if self.show_combat_controls_button then
      self.show_combat_controls_button.dead = true; self.show_combat_controls_button = nil
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
      -- input:set_mouse_visible(true)
    elseif self:is(Arena) then
      -- input:set_mouse_visible(true)
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

-- Cursor mode management functions
function set_cursor_mode(mode)
  if global_custom_cursor then
    global_custom_cursor.mode = mode
  end
end

function enable_custom_cursor(mode)
  if not global_custom_cursor then
    global_custom_cursor = CustomCursor{}
  end
  global_custom_cursor.mode = mode or 'simple'
  input:set_mouse_visible(false)
end

function set_cursor_simple()
  set_cursor_mode('simple')
end

function set_cursor_animated()
  set_cursor_mode('animated')
end

function cleanup_global_cursor()
  if global_custom_cursor then
    global_custom_cursor:die()
    global_custom_cursor = nil
  end
  input:set_mouse_visible(true)
end

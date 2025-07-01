local spriteFolder = 'newSprites/'


function create_grid(image, w, h)
  return anim8.newGrid(w, h, image.w, image.h)
end

function create_animation(grid, rowNumber, numberPerRow, w, h, speed)
  local numbers = 1 .. '-' .. numberPerRow
  return anim8.newAnimation(grid(numbers, rowNumber), speed)
end

--status effects
FREEZE_MASK_COLOR = nil

STUN_MASK_COLOR = nil

KNOCKBACK_MASK_COLOR = nil

BURN_MASK_COLOR = nil

function set_status_effect_mask_colors()
  FREEZE_MASK_COLOR = blue[0]:clone()
  FREEZE_MASK_COLOR.a = 0.8
  STUN_MASK_COLOR = black[0]:clone()
  STUN_MASK_COLOR.a = 0.8
  BURN_MASK_COLOR = red[0]:clone()
  BURN_MASK_COLOR.a = 0.3
  KNOCKBACK_MASK_COLOR = red[0]:clone()
  KNOCKBACK_MASK_COLOR.a = 0.9
end

--boss sprites
GOLEM_CAST_TIME = 1.5
GOLEM_ATTACK_FRAMES = 9

GOLEM_SPRITE_W = 128
GOLEM_SPRITE_H = 128

GOLEM_SPRITE_SCALE = 3

golem_idle = Image(spriteFolder .. 'golems/Golem1/Idle/Golem1_Idle_full', 'nearest')
golem_walk = Image(spriteFolder .. 'golems/Golem1/Walk/Golem1_Walk_full', 'nearest')
golem_run = Image(spriteFolder .. 'golems/Golem1/Run/Golem1_Run_full', 'nearest')
golem_attack = Image(spriteFolder .. 'golems/Golem1/Attack/Golem1_Attack_full', 'nearest')
golem_hurt = Image(spriteFolder .. 'golems/Golem1/Hurt/Golem1_Hurt_full', 'nearest')
golem_death = Image(spriteFolder .. 'golems/Golem1/Death/Golem1_Death_full', 'nearest')

golem_idle_g = create_grid(golem_idle, 128, 128)
golem_walk_g = create_grid(golem_walk, 128, 128)
golem_run_g = create_grid(golem_run, 128, 128)
golem_attack_g = create_grid(golem_attack, 128, 128)
golem_hurt_g = create_grid(golem_hurt, 128, 128)
golem_death_g = create_grid(golem_death, 128, 128)


golem_idle_a = create_animation(golem_idle_g, 1, 4, 128, 128, 0.4)
golem_walk_a = create_animation(golem_walk_g, 1, 8, 128, 128, 0.2)
golem_run_a = create_animation(golem_run_g, 1, 8, 128, 128, 0.2)
golem_attack_a = create_animation(golem_attack_g, 1, 9, 128, 128, GOLEM_CAST_TIME / GOLEM_ATTACK_FRAMES)
golem_hurt_a = create_animation(golem_hurt_g, 1, 4, 128, 128, 0.4)
golem_death_a = create_animation(golem_death_g, 1, 8, 128, 128, 0.2)

GOLEM3_CAST_TIME = 1.5
GOLEM3_ATTACK_FRAMES = 9

GOLEM3_SPRITE_W = 128
GOLEM3_SPRITE_H = 128

GOLEM3_SPRITE_SCALE = 4

golem3_idle = Image(spriteFolder .. 'golems/Golem3/Idle/Golem3_Idle_full', 'nearest')
golem3_walk = Image(spriteFolder .. 'golems/Golem3/Walk/Golem3_Walk_full', 'nearest')
golem3_run = Image(spriteFolder .. 'golems/Golem3/Run/Golem3_Run_full', 'nearest')
golem3_attack = Image(spriteFolder .. 'golems/Golem3/Attack/Golem3_Attack_full', 'nearest')
golem3_hurt = Image(spriteFolder .. 'golems/Golem3/Hurt/Golem3_Hurt_full', 'nearest')
golem3_death = Image(spriteFolder .. 'golems/Golem3/Death/Golem3_Death_full', 'nearest')

golem3_idle_g = create_grid(golem3_idle, 128, 128)
golem3_walk_g = create_grid(golem3_walk, 128, 128)
golem3_run_g = create_grid(golem3_run, 128, 128)
golem3_attack_g = create_grid(golem3_attack, 128, 128)
golem3_hurt_g = create_grid(golem3_hurt, 128, 128)
golem3_death_g = create_grid(golem3_death, 128, 128)


golem3_idle_a = create_animation(golem3_idle_g, 1, 4, 128, 128, 0.4)
golem3_walk_a = create_animation(golem3_walk_g, 1, 8, 128, 128, 0.2)
golem3_run_a = create_animation(golem3_run_g, 1, 8, 128, 128, 0.2)
golem3_attack_a = create_animation(golem3_attack_g, 1, 9, 128, 128, GOLEM3_CAST_TIME / GOLEM3_ATTACK_FRAMES)
golem3_hurt_a = create_animation(golem3_hurt_g, 1, 4, 128, 128, 0.4)
golem3_death_a = create_animation(golem3_death_g, 1, 8, 128, 128, 0.2)


DRAGON_SPRITE_W = 144
DRAGON_SPRITE_H = 128

DRAGON_SPRITE_W_HD = 191
DRAGON_SPRITE_H_HD = 161

DRAGON_SPRITE_SCALE = 2


dragonHD = Image(spriteFolder .. '/dragon2-HD/flying_dragon-red', 'nearest')

dragonHD_g = create_grid(dragonHD, DRAGON_SPRITE_W_HD, DRAGON_SPRITE_H_HD)

dragonHD_idle_a = create_animation(dragonHD_g, 3, 3, DRAGON_SPRITE_W_HD, DRAGON_SPRITE_H_HD, 0.4)


BEHOLDER_CAST_TIME = 1.5
BEHOLDER_ATTACK_FRAMES = 12

BEHOLDER_SPRITE_W = 64
BEHOLDER_SPRITE_H = 64

BEHOLDER_SPRITE_SCALE = 1.3

beholder_idle = Image(spriteFolder .. '/Beholder3/Idle/Beholder3_Idle_full', 'nearest')
beholder_walk = Image(spriteFolder .. '/Beholder3/Walk/Beholder3_Walk_full', 'nearest')
beholder_run = Image(spriteFolder .. '/Beholder3/Run/Beholder3_Run_full', 'nearest')
beholder_attack = Image(spriteFolder .. '/Beholder3/Attack/Beholder3_Attack_full', 'nearest')
beholder_hurt = Image(spriteFolder .. '/Beholder3/Hurt/Beholder3_Hurt_full', 'nearest')
beholder_death = Image(spriteFolder .. '/Beholder3/Death/Beholder3_Death_full', 'nearest')

beholder_idle_g = create_grid(beholder_idle, 64, 64)
beholder_walk_g = create_grid(beholder_walk, 64, 64)
beholder_run_g = create_grid(beholder_run, 64, 64)
beholder_attack_g = create_grid(beholder_attack, 64, 64)
beholder_hurt_g = create_grid(beholder_hurt, 64, 64)
beholder_death_g = create_grid(beholder_death, 64, 64)

beholder_idle_a = create_animation(beholder_idle_g, 1, 12, 64, 64, 0.2)
beholder_walk_a = create_animation(beholder_walk_g, 1, 8, 64, 64, 0.2)
beholder_run_a = create_animation(beholder_run_g, 1, 8, 64, 64, 0.2)
beholder_attack_a = create_animation(beholder_attack_g, 1, 12, 64, 64, BEHOLDER_CAST_TIME / BEHOLDER_ATTACK_FRAMES)
beholder_hurt_a = create_animation(beholder_hurt_g, 1, 6, 64, 64, 0.4)
beholder_death_a = create_animation(beholder_death_g, 1, 9, 64, 64, 0.2)


golem_spritesheets = {
  ['normal'] = {golem_walk_a, golem_walk},
  ['walk'] = {golem_walk_a, golem_walk},
  ['run'] = {golem_run_a, golem_run},
  ['casting'] = {golem_attack_a, golem_attack},
  ['channeling'] = {golem_attack_a, golem_attack},
  ['hurt'] = {golem_hurt_a, golem_hurt},
  ['death'] = {golem_death_a, golem_death},
}

dragon_spritesheets = {
  ['normal'] = {dragonHD_idle_a, dragonHD},
}

beholder_spritesheets = {
  ['normal'] = {beholder_idle_a, beholder_idle},
  ['walk'] = {beholder_walk_a, beholder_walk},
  ['run'] = {beholder_run_a, beholder_run},
  ['casting'] = {beholder_attack_a, beholder_attack},
  ['channeling'] = {beholder_attack_a, beholder_attack},
  ['hurt'] = {beholder_hurt_a, beholder_hurt},
  ['death'] = {beholder_death_a, beholder_death},
}

--enemy sprites
SKELETON_CAST_TIME = 1
SKELETON_ATTACK_FRAMES = 8

SKELETON_SPRITE_W = 24
SKELETON_SPRITE_H = 24

SKELETON_SPRITE_SCALE = 6


skeleton = Image(spriteFolder .. 'room8_skeleton', 'nearest')

skeleton_birth_g = create_grid(skeleton, 24, 24)
skeleton_idle_g = create_grid(skeleton, 24, 24)
skeleton_attack_g = create_grid(skeleton, 24, 24)


skeleton_birth_a = create_animation(skeleton_birth_g, 2, 8, 24, 24, 0.4)
skeleton_idle_a = create_animation(skeleton_idle_g, 6, 8, 24, 24, 0.4)
skeleton_attack_a = create_animation(skeleton_attack_g, 18, 8, 24, 24, 0.2)

RAT1_CAST_TIME = 1
RAT1_ATTACK_FRAMES = 8

RAT1_SPRITE_W = 128
RAT1_SPRITE_H = 128

RAT_SPRITE_SCALE = 6

RAT1_SPRITE_SCALE = RAT_SPRITE_SCALE

rat1_idle = Image(spriteFolder .. '/giantRat/Rat1/Idle/Rat1_Idle_full', 'nearest')
rat1_walk = Image(spriteFolder .. '/giantRat/Rat1/Walk/Rat1_Walk_full', 'nearest')
rat1_run = Image(spriteFolder .. '/giantRat/Rat1/Run/Rat1_Run_full', 'nearest')
rat1_attack = Image(spriteFolder .. '/giantRat/Rat1/Attack/Rat1_Attack_full', 'nearest')
rat1_hurt = Image(spriteFolder .. '/giantRat/Rat1/Hurt/Rat1_Hurt_full', 'nearest')
rat1_death = Image(spriteFolder .. '/giantRat/Rat1/Death/Rat1_Death_full', 'nearest')

rat1_idle_g = create_grid(rat1_idle, 128, 128)
rat1_walk_g = create_grid(rat1_walk, 128, 128)
rat1_run_g = create_grid(rat1_run, 128, 128)
rat1_attack_g = create_grid(rat1_attack, 128, 128)
rat1_hurt_g = create_grid(rat1_hurt, 128, 128)
rat1_death_g = create_grid(rat1_death, 128, 128)

rat1_idle_a = create_animation(rat1_idle_g, 1, 6, 128, 128, 0.2)
rat1_walk_a = create_animation(rat1_walk_g, 1, 6, 128, 128, 0.2)
rat1_run_a = create_animation(rat1_run_g, 1, 6, 128, 128, 0.2)
rat1_attack_a = create_animation(rat1_attack_g, 1, 8, 128, 128, RAT1_CAST_TIME / RAT1_ATTACK_FRAMES)
rat1_hurt_a = create_animation(rat1_hurt_g, 1, 4, 128, 128, 0.4)
rat1_death_a = create_animation(rat1_death_g, 1, 5, 128, 128, 0.3)

RAT2_CAST_TIME = 1
RAT2_ATTACK_FRAMES = 8

RAT2_SPRITE_W = 128
RAT2_SPRITE_H = 128

RAT2_SPRITE_SCALE = RAT_SPRITE_SCALE

rat2_idle = Image(spriteFolder .. '/giantRat/Rat2/Idle/Rat2_Idle_full', 'nearest')
rat2_walk = Image(spriteFolder .. '/giantRat/Rat2/Walk/Rat2_Walk_full', 'nearest')
rat2_run = Image(spriteFolder .. '/giantRat/Rat2/Run/Rat2_Run_full', 'nearest')
rat2_attack = Image(spriteFolder .. '/giantRat/Rat2/Attack/Rat2_Attack_full', 'nearest')
rat2_hurt = Image(spriteFolder .. '/giantRat/Rat2/Hurt/Rat2_Hurt_full', 'nearest')
rat2_death = Image(spriteFolder .. '/giantRat/Rat2/Death/Rat2_Death_full', 'nearest')

rat2_idle_g = create_grid(rat2_idle, 128, 128)
rat2_walk_g = create_grid(rat2_walk, 128, 128)
rat2_run_g = create_grid(rat2_run, 128, 128)
rat2_attack_g = create_grid(rat2_attack, 128, 128)
rat2_hurt_g = create_grid(rat2_hurt, 128, 128)
rat2_death_g = create_grid(rat2_death, 128, 128)

rat2_idle_a = create_animation(rat2_idle_g, 1, 6, 128, 128, 0.2)
rat2_walk_a = create_animation(rat2_walk_g, 1, 6, 128, 128, 0.2)
rat2_run_a = create_animation(rat2_run_g, 1, 6, 128, 128, 0.2)
rat2_attack_a = create_animation(rat2_attack_g, 1, 8, 128, 128, RAT2_CAST_TIME / RAT2_ATTACK_FRAMES)
rat2_hurt_a = create_animation(rat2_hurt_g, 1, 4, 128, 128, 0.4)
rat2_death_a = create_animation(rat2_death_g, 1, 5, 128, 128, 0.3)

RAT3_CAST_TIME = 1
RAT3_ATTACK_FRAMES = 8

RAT3_SPRITE_W = 128
RAT3_SPRITE_H = 128

RAT3_SPRITE_SCALE = RAT_SPRITE_SCALE

rat3_idle = Image(spriteFolder .. '/giantRat/Rat3/Idle/Rat3_Idle_full', 'nearest')
rat3_walk = Image(spriteFolder .. '/giantRat/Rat3/Walk/Rat3_Walk_full', 'nearest')
rat3_run = Image(spriteFolder .. '/giantRat/Rat3/Run/Rat3_Run_full', 'nearest')
rat3_attack = Image(spriteFolder .. '/giantRat/Rat3/Attack/Rat3_Attack_full', 'nearest')
rat3_hurt = Image(spriteFolder .. '/giantRat/Rat3/Hurt/Rat3_Hurt_full', 'nearest')
rat3_death = Image(spriteFolder .. '/giantRat/Rat3/Death/Rat3_Death_full', 'nearest')

rat3_idle_g = create_grid(rat3_idle, 128, 128)
rat3_walk_g = create_grid(rat3_walk, 128, 128)
rat3_run_g = create_grid(rat3_run, 128, 128)
rat3_attack_g = create_grid(rat3_attack, 128, 128)
rat3_hurt_g = create_grid(rat3_hurt, 128, 128)
rat3_death_g = create_grid(rat3_death, 128, 128)

rat3_idle_a = create_animation(rat3_idle_g, 1, 6, 128, 128, 0.2)
rat3_walk_a = create_animation(rat3_walk_g, 1, 6, 128, 128, 0.2)
rat3_run_a = create_animation(rat3_run_g, 1, 6, 128, 128, 0.2)
rat3_attack_a = create_animation(rat3_attack_g, 1, 8, 128, 128, RAT3_CAST_TIME / RAT3_ATTACK_FRAMES)
rat3_hurt_a = create_animation(rat3_hurt_g, 1, 4, 128, 128, 0.4)
rat3_death_a = create_animation(rat3_death_g, 1, 5, 128, 128, 0.3)

LICH_CAST_TIME = 1
LICH_ATTACK_FRAMES = 8

LICH_SPRITE_W = 64
LICH_SPRITE_H = 64

LICH_SPRITE_SCALE = 3

lich_attack = Image(spriteFolder .. '/Lich2/Attack/Lich2_Attack_full', 'nearest')
lich_idle = Image(spriteFolder .. '/Lich2/Idle/Lich2_Idle_full', 'nearest')
lich_walk = Image(spriteFolder .. '/Lich2/Walk/Lich2_Walk_full', 'nearest')
lich_run = Image(spriteFolder .. '/Lich2/Run/Lich2_Run_full', 'nearest')
lich_hurt = Image(spriteFolder .. '/Lich2/Hurt/Lich2_Hurt_full', 'nearest')
lich_death = Image(spriteFolder .. '/Lich2/Death/Lich2_Death_full', 'nearest')

lich_attack_g = create_grid(lich_attack, 64, 64)
lich_idle_g = create_grid(lich_idle, 64, 64)
lich_walk_g = create_grid(lich_walk, 64, 64)
lich_run_g = create_grid(lich_run, 64, 64)
lich_hurt_g = create_grid(lich_hurt, 64, 64)
lich_death_g = create_grid(lich_death, 64, 64)

lich_attack_a = create_animation(lich_attack_g, 1, 8, 64, 64, LICH_CAST_TIME / LICH_ATTACK_FRAMES)
lich_idle_a = create_animation(lich_idle_g, 1, 4, 64, 64, 0.4)
lich_walk_a = create_animation(lich_walk_g, 1, 6, 64, 64, 0.2)
lich_run_a = create_animation(lich_run_g, 1, 6, 64, 64, 0.2)
lich_hurt_a = create_animation(lich_hurt_g, 1, 4, 64, 64, 0.4)
lich_death_a = create_animation(lich_death_g, 1, 10, 64, 64, 0.2)

SLIME_CAST_TIME = 0.3
SLIME_ATTACK_FRAMES = 5

SLIME_SPRITE_W = 64
SLIME_SPRITE_H = 64

SLIME_SPRITE_SCALE = 3.5

slime_attack = Image(spriteFolder .. '/Slime1/Attack/Slime1_Attack_full', 'nearest')
slime_idle = Image(spriteFolder .. '/Slime1/Idle/Slime1_Idle_full', 'nearest')
slime_walk = Image(spriteFolder .. '/Slime1/Walk/Slime1_Walk_full', 'nearest')
slime_run = Image(spriteFolder .. '/Slime1/Run/Slime1_Run_full', 'nearest')
slime_hurt = Image(spriteFolder .. '/Slime1/Hurt/Slime1_Hurt_full', 'nearest')
slime_death = Image(spriteFolder .. '/Slime1/Death/Slime1_Death_full', 'nearest')

slime_attack_g = create_grid(slime_attack, 64, 64)
slime_idle_g = create_grid(slime_idle, 64, 64)
slime_walk_g = create_grid(slime_walk, 64, 64)
slime_run_g = create_grid(slime_run, 64, 64)
slime_hurt_g = create_grid(slime_hurt, 64, 64)
slime_death_g = create_grid(slime_death, 64, 64)

slime_attack_a = create_animation(slime_attack_g, 1, 5, 64, 64, SLIME_CAST_TIME / SLIME_ATTACK_FRAMES)
slime_idle_a = create_animation(slime_idle_g, 1, 6, 64, 64, 0.2)
slime_walk_a = create_animation(slime_walk_g, 1, 8, 64, 64, 0.2)
slime_run_a = create_animation(slime_run_g, 1, 8, 64, 64, 0.2)
slime_hurt_a = create_animation(slime_hurt_g, 1, 5, 64, 64, 0.4)
slime_death_a = create_animation(slime_death_g, 1, 10, 64, 64, 0.2)

ICESLIME_CAST_TIME = 1.5
ICESLIME_ATTACK_FRAMES = 6

ICESLIME_SPRITE_W = 64
ICESLIME_SPRITE_H = 64

ICESLIME_SPRITE_SCALE = 3.5

iceslime_attack = Image(spriteFolder .. '/slime-mobs-2/Slime1/Attack/Slime1_Attack_full', 'nearest')
iceslime_idle = Image(spriteFolder .. '/slime-mobs-2/Slime1/Idle/Slime1_Idle_full', 'nearest')
iceslime_walk = Image(spriteFolder .. '/slime-mobs-2/Slime1/Walk/Slime1_Walk_full', 'nearest')
iceslime_run = Image(spriteFolder .. '/slime-mobs-2/Slime1/Run/Slime1_Run_full', 'nearest')
iceslime_hurt = Image(spriteFolder .. '/slime-mobs-2/Slime1/Hurt/Slime1_Hurt_full', 'nearest')
iceslime_death = Image(spriteFolder .. '/slime-mobs-2/Slime1/Death/Slime1_Death_full', 'nearest')

iceslime_attack_g = create_grid(iceslime_attack, 64, 64)
iceslime_idle_g = create_grid(iceslime_idle, 64, 64)
iceslime_walk_g = create_grid(iceslime_walk, 64, 64)
iceslime_run_g = create_grid(iceslime_run, 64, 64)
iceslime_hurt_g = create_grid(iceslime_hurt, 64, 64)
iceslime_death_g = create_grid(iceslime_death, 64, 64)

iceslime_attack_a = create_animation(iceslime_attack_g, 1, 6, 64, 64, ICESLIME_CAST_TIME / ICESLIME_ATTACK_FRAMES)
iceslime_idle_a = create_animation(iceslime_idle_g, 1, 6, 64, 64, 0.2)
iceslime_walk_a = create_animation(iceslime_walk_g, 1, 8, 64, 64, 0.2)
iceslime_run_a = create_animation(iceslime_run_g, 1, 8, 64, 64, 0.2)
iceslime_hurt_a = create_animation(iceslime_hurt_g, 1, 5, 64, 64, 0.4)
iceslime_death_a = create_animation(iceslime_death_g, 1, 10, 64, 64, 0.2)


MECH1_SPRITE_W = 80
MECH1_SPRITE_H = 80

MECH1_SPRITE_SCALE = 1.8

mech1_idle = Image(spriteFolder .. '/Mech Assets Pack/Grey/Animation/Mechani4done', 'nearest')

mech1_idle_g = create_grid(mech1_idle, 80, 80)
mech1_idle_a = create_animation(mech1_idle_g, 1, 36, 80, 80, 0.1)

MECH2_SPRITE_W = 80
MECH2_SPRITE_H = 80

MECH2_SPRITE_SCALE = 1.8

mech2_idle = Image(spriteFolder .. '/Mech Assets Pack/Cyan/Animation/Mechani7done', 'nearest')

mech2_idle_g = create_grid(mech2_idle, 80, 80)
mech2_idle_a = create_animation(mech2_idle_g, 1, 36, 80, 80, 0.1)

MECH3_SPRITE_W = 80
MECH3_SPRITE_H = 80

MECH3_SPRITE_SCALE = 1.8

mech3_idle = Image(spriteFolder .. '/Mech Assets Pack/Green/Animation/Mechanidone', 'nearest')

mech3_idle_g = create_grid(mech3_idle, 80, 80)
mech3_idle_a = create_animation(mech3_idle_g, 1, 36, 80, 80, 0.1)


LIZARDMAN_SPRITE_W = 64
LIZARDMAN_SPRITE_H = 64

LIZARDMAN_CAST_TIME = 1
LIZARDMAN_ATTACK_FRAMES = 7

LIZARDMAN_SPRITE_SCALE = 3.5

lizardman_idle = Image(spriteFolder .. '/lizardmen/Lizardman1/Idle/Lizardman1_Idle_full', 'nearest')
lizardman_walk = Image(spriteFolder .. '/lizardmen/Lizardman1/Walk/Lizardman1_Walk_full', 'nearest')
lizardman_run = Image(spriteFolder .. '/lizardmen/Lizardman1/Run/Lizardman1_Run_full', 'nearest')
lizardman_attack = Image(spriteFolder .. '/lizardmen/Lizardman1/Attack/Lizardman1_Attack_full', 'nearest')
lizardman_hurt = Image(spriteFolder .. '/lizardmen/Lizardman1/Hurt/Lizardman1_Hurt_full', 'nearest')
lizardman_death = Image(spriteFolder .. '/lizardmen/Lizardman1/Death/Lizardman1_Death_full', 'nearest')

lizardman_idle_g = create_grid(lizardman_idle, 64, 64)
lizardman_walk_g = create_grid(lizardman_walk, 64, 64)
lizardman_run_g = create_grid(lizardman_run, 64, 64)
lizardman_attack_g = create_grid(lizardman_attack, 64, 64)
lizardman_hurt_g = create_grid(lizardman_hurt, 64, 64)
lizardman_death_g = create_grid(lizardman_death, 64, 64)

lizardman_idle_a = create_animation(lizardman_idle_g, 1, 4, 64, 64, 0.4)
lizardman_walk_a = create_animation(lizardman_walk_g, 1, 6, 64, 64, 0.2)
lizardman_run_a = create_animation(lizardman_run_g, 1, 8, 64, 64, 0.2)
lizardman_attack_a = create_animation(lizardman_attack_g, 1, 7, 64, 64, LIZARDMAN_CAST_TIME / LIZARDMAN_ATTACK_FRAMES)
lizardman_hurt_a = create_animation(lizardman_hurt_g, 1, 5, 64, 64, 0.4)
lizardman_death_a = create_animation(lizardman_death_g, 1, 7, 64, 64, 0.2)

ENT_SPRITE_W = 128
ENT_SPRITE_H = 128

ENT_CAST_TIME = 1
ENT_ATTACK_FRAMES = 7

ENT_SPRITE_SCALE = 4.5

--nearest filter is to fix the texture bleed on the edges of the image
ent_idle = Image(spriteFolder .. '/Ent1/Idle/Ent1_Idle_full', 'nearest')
ent_walk = Image(spriteFolder .. '/Ent1/Walk/Ent1_Walk_full', 'nearest')
ent_run = Image(spriteFolder .. '/Ent1/Run/Ent1_Run_full', 'nearest')
ent_attack = Image(spriteFolder .. '/Ent1/Attack/Ent1_Attack_full', 'nearest')
ent_hurt = Image(spriteFolder .. '/Ent1/Hurt/Ent1_Hurt_full')
ent_hurt.image:setFilter('nearest', 'nearest')
ent_death = Image(spriteFolder .. '/Ent1/Death/Ent1_Death_full')
ent_death.image:setFilter('nearest', 'nearest')


ent_idle_g = create_grid(ent_idle, 128, 128)
ent_walk_g = create_grid(ent_walk, 128, 128)
ent_run_g = create_grid(ent_run, 128, 128)
ent_attack_g = create_grid(ent_attack, 128, 128)
ent_hurt_g = create_grid(ent_hurt, 128, 128)
ent_death_g = create_grid(ent_death, 128, 128)

ent_idle_a = create_animation(ent_idle_g, 1, 4, 128, 128, 0.4)
ent_walk_a = create_animation(ent_walk_g, 1, 6, 128, 128, 0.2)
ent_run_a = create_animation(ent_run_g, 1, 8, 128, 128, 0.2)
ent_attack_a = create_animation(ent_attack_g, 1, 7, 128, 128, ENT_CAST_TIME / ENT_ATTACK_FRAMES)
ent_hurt_a = create_animation(ent_hurt_g, 1, 4, 128, 128, 0.4)
ent_death_a = create_animation(ent_death_g, 1, 6, 128, 128, 0.4)

skeleton_spritesheets = {
  ['normal'] = {skeleton_idle_a, skeleton},
  ['birth'] = {skeleton_birth_a, skeleton},
  ['casting'] = {skeleton_attack_a, skeleton},
}
rat1_spritesheets = {
  ['normal'] = {rat1_idle_a, rat1_idle},
  ['walk'] = {rat1_walk_a, rat1_walk},
  ['run'] = {rat1_run_a, rat1_run},
  ['casting'] = {rat1_attack_a, rat1_attack},
  ['channeling'] = {rat1_attack_a, rat1_attack},
  ['hurt'] = {rat1_hurt_a, rat1_hurt},
  ['death'] = {rat1_death_a, rat1_death},
}

rat2_spritesheets = {
  ['normal'] = {rat2_idle_a, rat2_idle},
  ['walk'] = {rat2_walk_a, rat2_walk},
  ['run'] = {rat2_run_a, rat2_run},
  ['casting'] = {rat2_attack_a, rat2_attack},
  ['channeling'] = {rat2_attack_a, rat2_attack},
  ['hurt'] = {rat2_hurt_a, rat2_hurt},
  ['death'] = {rat2_death_a, rat2_death},
}

rat3_spritesheets = {
  ['normal'] = {rat3_idle_a, rat3_idle},
  ['walk'] = {rat3_walk_a, rat3_walk},
  ['run'] = {rat3_run_a, rat3_run},
  ['casting'] = {rat3_attack_a, rat3_attack},
  ['channeling'] = {rat3_attack_a, rat3_attack},
  ['hurt'] = {rat3_hurt_a, rat3_hurt},
  ['death'] = {rat3_death_a, rat3_death},
}

lich_spritesheets = {

  ['normal'] = {lich_idle_a, lich_idle},
  ['walk'] = {lich_walk_a, lich_walk},
  ['run'] = {lich_run_a, lich_run},
  ['casting'] = {lich_attack_a, lich_attack},
  ['channeling'] = {lich_attack_a, lich_attack},
  ['hurt'] = {lich_hurt_a, lich_hurt},
  ['death'] = {lich_death_a, lich_death},
}

slime_spritesheets = {
  ['normal'] = {slime_idle_a, slime_idle},
  ['walk'] = {slime_walk_a, slime_walk},
  ['run'] = {slime_run_a, slime_run},
  ['casting'] = {slime_attack_a, slime_attack},
  ['channeling'] = {slime_attack_a, slime_attack},
  ['hurt'] = {slime_hurt_a, slime_hurt},
  ['death'] = {slime_death_a, slime_death},
}

iceslime_spritesheets = { 
  ['normal'] = {iceslime_idle_a, iceslime_idle},
  ['walk'] = {iceslime_walk_a, iceslime_walk},
  ['run'] = {iceslime_run_a, iceslime_run},
  ['casting'] = {iceslime_attack_a, iceslime_attack},
  ['channeling'] = {iceslime_attack_a, iceslime_attack},
  ['hurt'] = {iceslime_hurt_a, iceslime_hurt},
  ['death'] = {iceslime_death_a, iceslime_death},
}

mech1_spritesheets = {
  ['normal'] = {mech1_idle_a, mech1_idle},
}

mech2_spritesheets = {
  ['normal'] = {mech_idle_a, mech_idle},
}

mech3_spritesheets = {
  ['normal'] = {mech3_idle_a, mech3_idle},
}

lizardman_spritesheets = {

  ['normal'] = {lizardman_idle_a, lizardman_idle},
  ['walk'] = {lizardman_walk_a, lizardman_walk},
  ['run'] = {lizardman_run_a, lizardman_run},
  ['casting'] = {lizardman_attack_a, lizardman_attack},
  ['channeling'] = {lizardman_attack_a, lizardman_attack},
  ['hurt'] = {lizardman_hurt_a, lizardman_hurt},
  ['death'] = {lizardman_death_a, lizardman_death},
}

ent_spritesheets = {
  ['normal'] = {ent_idle_a, ent_idle},
  ['walk'] = {ent_walk_a, ent_walk},
  ['run'] = {ent_run_a, ent_run},
  ['casting'] = {ent_attack_a, ent_attack},
  ['channeling'] = {ent_attack_a, ent_attack},
  ['hurt'] = {ent_hurt_a, ent_hurt},
  ['death'] = {ent_death_a, ent_death},
}

golem3_spritesheets = {
  ['normal'] = {golem3_idle_a, golem3_idle},
  ['walk'] = {golem3_walk_a, golem3_walk},
  ['run'] = {golem3_run_a, golem3_run},
  ['casting'] = {golem3_attack_a, golem3_attack},
  ['channeling'] = {golem3_attack_a, golem3_attack},
  ['hurt'] = {golem3_hurt_a, golem3_hurt},
  ['death'] = {golem3_death_a, golem3_death},
}

--all spritesheets
enemy_spritesheets = {
  ['golem'] = golem_spritesheets,
  ['skeleton'] = skeleton_spritesheets,
  ['dragon'] = dragon_spritesheets,
  ['beholder'] = beholder_spritesheets,
  ['lich'] = lich_spritesheets,
  ['slime'] = slime_spritesheets,
  ['iceslime'] = iceslime_spritesheets,
  ['mech1'] = mech1_spritesheets,
  ['mech2'] = mech2_spritesheets,
  ['mech3'] = mech3_spritesheets,
  ['lizardman'] = lizardman_spritesheets,
  ['rat1'] = rat1_spritesheets,
  ['rat2'] = rat2_spritesheets,
  ['rat3'] = rat3_spritesheets,
  ['ent'] = ent_spritesheets,
  ['golem3'] = golem3_spritesheets,
}
enemy_sprite_sizes = {
  ['golem'] = {GOLEM_SPRITE_W, GOLEM_SPRITE_H},
  ['skeleton'] = {SKELETON_SPRITE_W, SKELETON_SPRITE_H},
  ['dragon'] = {DRAGON_SPRITE_W, DRAGON_SPRITE_H},
  ['beholder'] = {BEHOLDER_SPRITE_W, BEHOLDER_SPRITE_H},
  ['lich'] = {LICH_SPRITE_W, LICH_SPRITE_H},
  ['slime'] = {SLIME_SPRITE_W, SLIME_SPRITE_H},
  ['iceslime'] = {ICESLIME_SPRITE_W, ICESLIME_SPRITE_H},
  ['rat1'] = {RAT1_SPRITE_W, RAT1_SPRITE_H},
  ['rat2'] = {RAT2_SPRITE_W, RAT2_SPRITE_H},
  ['rat3'] = {RAT3_SPRITE_W, RAT3_SPRITE_H},
  ['lizardman'] = {LIZARDMAN_SPRITE_W, LIZARDMAN_SPRITE_H},
  ['mech1'] = {MECH1_SPRITE_W, MECH1_SPRITE_H},
  ['mech2'] = {MECH2_SPRITE_W, MECH2_SPRITE_H},
  ['mech3'] = {MECH3_SPRITE_W, MECH3_SPRITE_H},
  ['ent'] = {ENT_SPRITE_W, ENT_SPRITE_H},
  ['golem3'] = {GOLEM3_SPRITE_W, GOLEM3_SPRITE_H},
}

enemy_sprite_scales = {
  ['golem'] = GOLEM_SPRITE_SCALE,
  ['skeleton'] = SKELETON_SPRITE_SCALE,
  ['dragon'] = DRAGON_SPRITE_SCALE,
  ['beholder'] = BEHOLDER_SPRITE_SCALE,
  ['lich'] = LICH_SPRITE_SCALE,
  ['slime'] = SLIME_SPRITE_SCALE,
  ['iceslime'] = ICESLIME_SPRITE_SCALE,
  ['rat1'] = RAT1_SPRITE_SCALE,
  ['rat2'] = RAT2_SPRITE_SCALE,
  ['rat3'] = RAT3_SPRITE_SCALE,
  ['lizardman'] = LIZARDMAN_SPRITE_SCALE,
  ['mech1'] = MECH1_SPRITE_SCALE,
  ['mech2'] = MECH2_SPRITE_SCALE,
  ['mech3'] = MECH3_SPRITE_SCALE,
  ['ent'] = ENT_SPRITE_SCALE,
  ['golem3'] = GOLEM3_SPRITE_SCALE,
}

-- ===================================================================
-- Enemy Type to Size Mapping
-- Maps enemy type names to their size categories for spawn circle sizing
-- ===================================================================
enemy_type_to_size = {
  -- Bosses
  ['dragon'] = 'boss',
  ['heigan'] = 'heigan',
  ['stompy'] = 'stompy',
  
  -- Regular enemies
  ['arcspread'] = 'big',
  ['assassin'] = 'big',
  ['laser'] = 'big',
  ['mortar'] = 'big',
  ['rager'] = 'big',
  ['seeker'] = 'regular',
  ['shooter'] = 'regular_big',
  ['spawner'] = 'big',
  ['spread'] = 'big',
  ['stomper'] = 'big',
  ['summoner'] = 'big',
  ['bomb'] = 'big',
  ['charger'] = 'big',
  ['burst'] = 'big',
  ['boomerang'] = 'big',
  ['plasma'] = 'big',
  ['firewall_caster'] = 'big',
  ['cleaver'] = 'big',
  
  -- Minibosses
  ['bigstomper'] = 'huge',
  
  -- Static enemies
  ['dragonegg'] = 'small',
  
  -- Environmental enemies
  ['critter'] = 'critter',
}
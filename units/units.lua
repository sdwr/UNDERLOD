require 'units/player/player_troop'
require 'units/player/laser_troop'
require 'units/player/swordsman_troop'

troop_classes = {
  Troop,
  Laser_Troop,
  Swordsman_Troop
}

friendly_classes = shallowcopy(troop_classes)
table.insert(friendly_classes, Critter)

enemy_classes = {
  Enemy,
  EnemyCritter
}

all_unit_classes = shallowcopy(troop_classes)
table.extend(all_unit_classes, enemy_classes)

function Create_Troop(args)
  if args.character == 'laser' then
    return Laser_Troop(args)
  elseif args.character == 'swordsman' then
    return Swordsman_Troop(args)
  else
    return Troop(args)
  end
end

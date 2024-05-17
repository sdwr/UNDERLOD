require 'units/player/player_troop'
require 'units/player/laser_troop'

function Create_Troop(args)
  if args.character == 'laser' then
    return Laser_Troop(args)
  else
    return Troop(args)
  end
end

require 'enemies/enemy'
require 'enemies/bosses/dragon'
require 'enemies/bosses/heigan'
require 'enemies/bosses/stompy'
require 'enemies/regular/assassin'
require 'enemies/regular/mortar'
require 'enemies/regular/rager'
require 'enemies/regular/seeker'
require 'enemies/regular/shooter'
require 'enemies/regular/stomper'
require 'enemies/regular/summoner'


function Spawn_Enemy(type, name, args)
    local enemy = nil
    if type == 'boss' then
        args.class = "boss"
        if name == 'stompy' then
            enemy = Stompy:init(args)
        elseif name == 'dragon' then
            enemy = Dragon:init(args)
        elseif name == 'heigan' then
            enemy = Heigan:init(args)
        else
          error("boss name " .. name .. " not found")
        end
      else
        args.class = "regular_enemy"
        if type == 'stomper' then
            enemy = Stomper:init(args)
        elseif type == 'mortar' then
            enemy = Mortar:init(args)
        elseif type == 'summoner' then
            enemy = Summoner:init(args)
        elseif type == 'rager' then
            enemy = Rager:init(args)
        elseif type == 'assassin' then
            enemy = Assassin:init(args)
        elseif type == 'shooter' then
            enemy = Shooter:init(args)
        elseif type == 'seeker' then
            enemy = Seeker:init(args)
        else
            error("enemy name " .. type " not found")
        end
      end

      if enemy then
        enemy.state = 'normal'
        enemy.attack_sensor = enemy.attack_sensor or Circle(enemy.x, enemy.y, 20 + enemy.shape.w / 2)
        enemy.aggro_sensor = enemy.aggro_sensor or Circle(enemy.x, enemy.y, 1000)
      end
    return enemy
end
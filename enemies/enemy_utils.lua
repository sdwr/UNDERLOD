enemy_size_to_xy = {
  critter = {x = 7, y = 4},
  small = {x = 8, y = 6},
  regular = {x = 14, y = 6},
  big = {x = 20, y = 10},
  huge = {x = 30, y = 18},

  heigan = {x = 40, y = 60},
  boss = {x = 60, y = 60},
}

Set_Enemy_Shape = function(enemy, size)
  local xy = enemy_size_to_xy[size]
  if not xy then
    print('could not find enemy size: ' .. size)
    xy = enemy_size_to_xy['regular']
  end

  enemy:set_as_rectangle(xy.x, xy.y, 'dynamic', 'enemy')
end

--create a "choose attack system" that will allow for more complex enemy behavior
-- bosses will have a list of attacks that they can choose from
-- each attack will have a trigger condition (ex. enemy is in range)
-- and then a cast time
-- might have a channel time (for fire breath)
-- will each attack have a cooldown? 

--simplest version:
-- put a "choose attack" function in enemy update()
-- have a list of attacks in the specific enemy file that will be chosen from
-- the system picks randomly, and each attack will manage the enemy state like it already does
-- plus set the "last_attack_finished" time when it finishes
-- then the "choose attack" function will have a global cooldown that checks off "last_attack_finished"
-- if no attack options are initialized, then the enemy will just move around like normal (backwards compatibility)

--want bosses to switch between movement styles (chase, roam, etc)
--depending on the attack they are using or just over time
--want instant-cast attacks (attack) to cast while moving maybe


local example_attackdata = {
  viable = function(unit) return unit:in_range()() end,
  casttime = 1,
  oncaststart = function(unit) 
    unit:rotate_towards_object(unit.target, 1)
    alert1:play{volume = 0.5}
  end,
  cast = function(unit) 
    unit:rotate_towards_object(unit.target, 1)
    unit:attack(20, {x = unit.target.x, y = unit.target.y})
  end,
}

--decrement casttime in enemy:update
--draw a cast bar in enemy:draw
--when currentcast == 0, call the cast functio
Enemy_Cast = function(enemy, attackdata)
  enemy.state = unit_states['casting']
  enemy.baseCast = attackdata.casttime
  enemy.last_attack_started = love.timer.getTime()
  enemy.currentcast = attackdata.cast
  attackdata.oncaststart(enemy)
end

Enemy_Pick_Attack = function(enemy)
  if not enemy.attack_options then return end

  local viable_attacks = {}
  for k, v in pairs(enemy.attack_options) do
    if v.viable(enemy) then
      table.insert(viable_attacks, v)
    end
  end

  if #viable_attacks == 0 then return end

  local attack = random:table(viable_attacks)

  print('enemy picked attack: ' .. attack.name)
  Enemy_Cast(enemy, attack)
end
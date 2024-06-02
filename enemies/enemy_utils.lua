enemy_size_to_xy = {
  critter = {x = 6, y = 4},
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
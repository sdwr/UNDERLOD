enemy_size_to_xy = {
  critter = {x = 7, y = 4},
  small = {x = 8, y = 6},
  regular = {x = 12, y = 6},
  regular_big = {x = 16, y = 12},
  big = {x = 20, y = 14},
  huge = {x = 36, y = 24},

  stompy = {x = 46, y = 46},
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

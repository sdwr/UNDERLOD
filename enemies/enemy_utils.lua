enemy_size_to_xy = {
  critter = {x = 7, y = 4},
  small = {x = 8, y = 6},
  regular = {x = 10, y = 10},
  regular_big = {x = 16, y = 12},
  special = {x = 14, y = 14},
  huge = {x = 36, y = 24},

  stompy = {x = 46, y = 46},
  heigan = {x = 40, y = 60},
  boss = {x = 60, y = 60},
}

-- ===================================================================
-- Helper function to get default size for enemy type
-- ===================================================================
function Get_Enemy_Default_Size(enemy_type)
  if enemy_type_to_size and enemy_type_to_size[enemy_type] then
    return enemy_type_to_size[enemy_type]
  end
  return 'regular' -- Default fallback
end

Set_Enemy_Shape = function(enemy, size)
  local xy = enemy_size_to_xy[size]
  if not xy then
    print('could not find enemy size: ' .. size)
    xy = enemy_size_to_xy['regular']
  end

  enemy:set_as_rectangle(xy.x, xy.y, 'dynamic', 'enemy')
end

Helper.Target = {}

function Helper.Target:get_closest_enemy(object, exclude_list)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.enemies
  else
    class_list = main.current.friendlies
  end

  return main.current.main:get_closest_object_by_class(object, class_list, exclude_list)
end

function Helper.Target:get_closest_friendly(object, exclude_list)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.friendlies
  else
    class_list = main.current.enemies
  end

  return main.current.main:get_closest_object_by_class(object, class_list, exclude_list)
end

-----------------------------------------
function Helper.Target:get_close_enemy(object, exclude_list, max_range_from_self)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.enemies
  else
    class_list = main.current.friendlies
  end

  return main.current.main:get_random_close_object(object, class_list, exclude_list, max_range_from_self)
end

function Helper.Target:get_random_enemy(object)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.enemies
  else
    class_list = main.current.friendlies
  end

  return main.current.main:get_random_object_by_class(class_list)
end

function Helper.Target:get_random_friendly(object)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.friendlies
  else
    class_list = main.current.enemies
  end

  return main.current.main:get_random_object_by_class(class_list)
end

function Helper.Target:get_distance_multiplier(unit, target)
  local distance = unit:distance_to_point(target.x, target.y)
  local distance_multiplier = DISTANCE_TO_COOLDOWN_MULTIPLIER(distance)
  return distance_multiplier
end

function Helper.Target:is_in_camera_bounds(x, y)
  return x > 5 and x < gw - 5 and y > 5 and y < gh - 5
end

function Helper.Target:is_fully_in_camera_bounds(x, y)
  return x > SpawnGlobals.CAMERA_BOUNDS_OFFSET 
  and x < gw - SpawnGlobals.CAMERA_BOUNDS_OFFSET 
  and y > SpawnGlobals.CAMERA_BOUNDS_OFFSET 
  and y < gh - SpawnGlobals.CAMERA_BOUNDS_OFFSET
end

function Helper.Target:way_inside_camera_bounds(x, y)
  return x > SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET 
  and x < gw - SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET 
  and y > SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET 
  and y < gh - SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET
end
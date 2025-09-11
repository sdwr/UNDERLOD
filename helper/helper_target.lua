Helper.Target = {}

function Helper.Target:get_closest_enemy(object, exclude_list, required_flags)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.enemies
  else
    class_list = main.current.friendlies
  end

  return main.current.main:get_closest_object_by_class(object, class_list, exclude_list, required_flags)
end

function Helper.Target:get_closest_friendly(object, exclude_list, required_flags)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.friendlies
  else
    class_list = main.current.enemies
  end

  return main.current.main:get_closest_object_by_class(object, class_list, exclude_list, required_flags)
end

-----------------------------------------
function Helper.Target:get_close_enemy(object, exclude_list, required_flags)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.enemies
  else
    class_list = main.current.friendlies
  end

  return main.current.main:get_random_close_object(object, class_list, exclude_list, nil, nil, nil, required_flags)
end

function Helper.Target:get_random_enemy(object, required_flags)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.enemies
  else
    class_list = main.current.friendlies
  end

  return main.current.main:get_random_object_by_class(class_list, required_flags)
end

function Helper.Target:get_random_friendly(object, required_flags)
  local class_list
  if object.faction == 'friendly' then
    class_list = main.current.friendlies
  else
    class_list = main.current.enemies
  end

  return main.current.main:get_random_object_by_class(class_list, required_flags)
end

function Helper.Target:get_distance_multiplier(unit, target)
  if not target or not target.x or not target.y then
    return 1
  end
  local distance = math.distance(unit.x, unit.y, target.x, target.y)
  local distance_multiplier = get_distance_effect_multiplier(distance)
  return distance_multiplier
end

function Helper.Target:is_in_camera_bounds(x, y)
  return x > 0 and x < gw and y > 0 and y < gh
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

function Helper.Target:way_outside_camera_bounds(x, y)
  return x < SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET_WAY_OUTSIDE 
  or x > gw - SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET_WAY_OUTSIDE 
  or y < SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET_WAY_OUTSIDE 
  or y > gh - SpawnGlobals.ENEMY_MOVE_BOUNDS_OFFSET_WAY_OUTSIDE
end

function Helper.Target:approach_orb_stall_speed_multiplier(distance_to_orb)
  if distance_to_orb > 140 then
    return 1
  elseif distance_to_orb > 110 then
    return 0.6
  elseif distance_to_orb > 70 then
    return 0.3
  else
    return 0.15
  end
  
  return 0.15
end
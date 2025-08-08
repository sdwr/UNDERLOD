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
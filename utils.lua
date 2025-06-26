get_random_from_table = function(t)
  local keys = {}
  for key in pairs(t) do
      table.insert(keys, key)
  end
  if #keys == 0 then return nil end
  local index = keys[math.random(#keys)]
  return t[index]
end


add_to_table_no_duplicates = function(t, v)
  for i, value in ipairs(t) do
      if value == v then
          return
      end
  end
  table.insert(t, v)
end

combine_tables = function(t1, t2)
  for i, v in ipairs(t2) do
      table.insert(t1, v)
  end
end

combine_tables_no_duplicates = function(t1, t2)
  for i, v in ipairs(t2) do
      add_to_table_no_duplicates(t1, v)
  end
end

table_length = function(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

table.find = function(t, value)
  for i, v in ipairs(t) do
    if v == value then
      return i
    end
  end
  return nil
end




deepcopy = function(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      setmetatable(copy, deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

shallowcopy = function(orig)
  local copy = {}
  for k, v in pairs(orig) do
      copy[k] = v
  end
  return copy
end

function table.extend(t, t2)
  for i, v in ipairs(t2) do
      table.insert(t, v)
  end
end

function random_offset(offset)
  return math.random(-offset, offset)
end


function rally_offsets(i)
  --up to 10 units away, just fixed values for now
  if i > 10 then 
    print('too many units for rally offset')
    return {x = 0, y = 0}
  end
  local offsets = {
    {x = -10, y = 0},
    {x = 6, y = 1},
    {x = -3, y = 7},
    {x = 0, y = -6},
    {x = 6, y = -8},
    {x = 3, y = -1},
    {x = -7, y = 6},
    {x = 3, y = 5},
    {x = -6, y = -4},
    {x = -1, y = 10}
  }
  return offsets[i]
end

function all_troops_dead(state)
  local troops = state.main:get_objects_by_classes(state.troops)

  if #troops == 0 then return true end
  for _, troop in ipairs(troops) do
    if troop.dead ~= true then return false end
  end
  return true
end

function sum_vectors(v1, v2)
  return {x = v1.x + v2.x, y = v1.y + v2.y}
end

--debug utils
function print_object(obj)
  for k, v in pairs(obj) do
    print(k, v)
  end
end

--UI utils
function find_item_image(item)
  local image = item_images[item.name] or item_images[item.icon] or item_images['default']
  return image
end

function find_enemy_image(enemy)
  local image = enemy_images[enemy.name] or enemy_images[enemy.icon] or enemy_images[enemy]
  return image
end

function find_enemy_spritesheet(enemy)
  local spritesheet = enemy_spritesheets[enemy.name] or enemy_spritesheets[enemy.icon] or enemy_spritesheets[enemy]
  return clone_spritesheet(spritesheet)
end

function get_progress_bar()
  if main and main.current and main.current.progress_bar then
    return main.current.progress_bar
  end
  return nil
end

function get_progress_location()
  local bar = get_progress_bar()
  if bar then
    return bar:get_progress_location()
  end
  return {x = 0, y = 0}
end

function clone_spritesheet(spritesheet)
  if not spritesheet then return nil end
  
  local cloned = {}
  for state, data in pairs(spritesheet) do
    if type(data) == 'table' and #data == 2 then
      -- Clone the animation (first element) and keep the image reference (second element)
      local animation = data[1]
      local image = data[2]
      
      -- Use the animation's clone method
      local new_animation = animation:clone()
      cloned[state] = {new_animation, image}
    else
      cloned[state] = data
    end
  end
  return cloned
end

function world_to_screen(world_x, world_y)
  local scale = math.floor(wh/gh)
  return world_x * scale, world_y * scale
end

function is_point_in_rectangle(x, y, rect_x, rect_y, rect_w, rect_h)
  return x > rect_x and x < rect_x + rect_w and y > rect_y and y < rect_y + rect_h
end

function get_dmg_value(dmg)
  if type(dmg) == 'function' then
    return dmg()
  end
  return dmg or 0
end

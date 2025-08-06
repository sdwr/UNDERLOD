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

function default_to(value, default)
  if value ~= nil then
    return value
  end
  return default
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
  -- Handle V2 items that have icon field
  if item.icon then
    local image = item_images[item.icon] or item_images['default']
    return image
  end
  -- Handle legacy items that have name field
  local image = item_images[item.name] or item_images['default']
  return image
end

function find_character_image(character)
  local image = character_images[character] or character_images['default']
  return image
end

function character_to_color(character)
  return character_colors[character] or character_colors['default']
end

function find_perk_image(perk)
  -- For now, use a default image since perk images aren't defined yet
  -- This can be expanded later when perk images are added
  return item_images[perk.icon] or item_images['default']
end

function get_rarity_color(rarity)
  if rarity == "common" then
    return fg[0]
  elseif rarity == "uncommon" then
    return green[0]
  elseif rarity == "rare" then
    return blue[0]
  elseif rarity == "epic" then
    return purple[0]
  elseif rarity == "legendary" then
    return orange[0]
  else
    return fg[0]
  end
end

function find_enemy_image(enemy)
  local image = enemy_images[enemy.name] or enemy_images[enemy.icon] or enemy_images[enemy]
  return image
end

function find_enemy_spritesheet(enemy)
  local spritesheet = enemy_spritesheets[enemy.name] or enemy_spritesheets[enemy.icon] or enemy_spritesheets[enemy]
  return clone_spritesheet(spritesheet)
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
  -- Use the window scaling factor directly
  local scale = sx
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

-- Unified stat display function
function format_stat_display(stat_name, stat_value)
  local display_name = item_stat_lookup and item_stat_lookup[stat_name] or stat_name
  
  -- Handle gold (always flat value)
  if stat_name == 'gold' then
    return '+', stat_value, ' ', display_name
  end
  
  -- Check if this is a V2 stat (has increment defined)
  if ITEM_STATS and ITEM_STATS[stat_name] and ITEM_STATS[stat_name].increment then
    -- For V2 stats, the value is already the integer amount (e.g., 3 for +3 damage)
    return '+', stat_value, ' ', display_name
  else
    -- For legacy stats, the value is a percentage (e.g., 0.15 for 15%)
    return '+', math.floor(stat_value * 100), '% ', display_name
  end
end

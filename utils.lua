get_random_from_table = function(t)
  local keys = {}
  for key in pairs(t) do
      table.insert(keys, key)
  end
  if #keys == 0 then return nil end
  local index = keys[math.random(#keys)]
  return t[index]
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

function sum_vectors(v1, v2)
  return {x = v1.x + v2.x, y = v1.y + v2.y}
end

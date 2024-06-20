function Validate_Save_Data(data)
  local valid = true
  --nil clears the run, otherwise check for missing fields
  if data == nil then 
    print("Data is nil, expected table")
    return false
  end
  if #data == 0 then return true end
  for _, field in ipairs(EXPECTED_SAVE_FIELDS) do
    if data[field] == nil then
      print("Missing field in run: " .. field)
      valid = false
    end
  end
  return valid
end

function Collect_Save_Data_From_State(state)
  local data = {}
  for i, v in ipairs(EXPECTED_SAVE_FIELDS) do
    if state[v] then
      data[v] = state[v]
    end
  end
  data.locked_state = locked_state
  data.gold = gold
  Validate_Save_Data(data)
  return data
end

function Load_Save_Data_Into_State(state, data)
  if not data then return end
  for i, v in ipairs(EXPECTED_SAVE_FIELDS) do
    if data[v] then
      state[v] = data[v]
    end
  end
  locked_state = data.locked_state
  gold = data.gold
end

function Create_Blank_Save_Data()
  local data = {}
  data.level = 1
  data.level_list = {}
  data.loop = 0
  data.gold = STARTING_GOLD
  data.units = {}
  data.max_units = MAX_UNITS
  data.passives = {}
  data.shop_item_data = {}
  data.locked_state = false
  data.reroll_shop = false
  return data
end
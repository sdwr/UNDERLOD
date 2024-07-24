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
  data.reroll_shop = true
  data.times_rerolled = 0
  return data
end

--should this have just multi-run stats?
-- or save/check the in-combat stats in here as well?
-- like max shield achieve
function Create_Blank_Game_Stats()
  local data = {}
  data.levels_complete = 0
  
  data.max_gold = 0
  data.total_rerolls = 0
  data.total_items_sold = 0
  data.total_items_consumed = 0
  data.max_potion_effects = 0
  
  data.current_run_rerolls = 0
  data.current_run_troop_deaths = 0
  data.current_run_over10cost_items_purchased = 0
  
  data.current_run_num_same_unit = 0

  data.max_fire_stacks = 0
  data.max_aspd = 0
  data.max_dmg_without_hp = 0

  data.max_dota_items_on_unit = 0
  data.max_wow_items_on_unit = 0
  data.max_20cost_items_on_unit = 0

  return data
end
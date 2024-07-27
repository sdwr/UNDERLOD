
function Start_New_Run()
  --create a new run
  local data = Create_Blank_Save_Data()

  --clean up stats from last run
  Clear_User_Stats()

  return data
end




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


--helper functions to update stats
--stats should really be object?
function Create_Blank_Game_Stats()
  local stats = {}
  
  --total stats
  stats.levels_complete = 0 --done

  stats.max_gold = 0 --done (in arena and sell item)
  stats.total_rerolls = 0 --done
  stats.total_items_sold = 0 --done
  stats.total_items_consumed = 0 --done, need to have a consume function though
  stats.max_potion_effects = 0
  
  --current run stats
  stats.current_run_rerolls = 0 --done
  stats.current_run_troop_deaths = 0 --done
  stats.current_run_over10cost_items_purchased = 0 --done

  stats.current_run_num_same_unit = 0 --done

  --combat stats
  stats.max_fire_stacks = 0 --done but need to tweak mechanics
  stats.max_aspd = 0
  stats.max_dmg_without_hp = 0

  --item stats
  stats.max_dota_items_on_unit = 0
  stats.max_wow_items_on_unit = 0
  stats.max_20cost_items_on_unit = 0

  return stats
end

--in between runs
function Clear_User_Stats()
  if not USER_STATS or USER_STATS == {} then
    USER_STATS = Create_Blank_Game_Stats()
  end

  USER_STATS.current_run_rerolls = 0
  USER_STATS.current_run_troop_deaths = 0
  USER_STATS.current_run_over10cost_items_purchased = 0

  USER_STATS.current_run_num_same_unit = 0

  system.save_stats()
end

--full reset, clears all stats
function Reset_User_Stats()
  USER_STATS = Create_Blank_Game_Stats()
  system.save_stats()
end

function Update_User_Stats()
  --check for achievements here, and trigger steam achievements

  system.save_stats()
end

--total stats
function Stats_Level_Complete()

  USER_STATS.stats.levels_complete = USER_STATS.stats.levels_complete + 1
  Update_User_Stats()
end

function Stats_Max_Gold()
  if gold > USER_STATS.stats.max_gold then
    USER_STATS.stats.max_gold = gold
  end
  Update_User_Stats()
end

function Stats_Total_Rerolls()
  USER_STATS.stats.total_rerolls = USER_STATS.stats.total_rerolls + 1
  Update_User_Stats()
end

function Stats_Sell_Item()
  USER_STATS.stats.total_items_sold = USER_STATS.stats.total_items_sold + 1
  Update_User_Stats()
end

function Stats_Consume_Item()
  USER_STATS.stats.total_items_consumed = USER_STATS.stats.total_items_consumed + 1
  Update_User_Stats()
end

function Stats_Max_Potion_Effects(num)
  if num > USER_STATS.stats.max_potion_effects then
    USER_STATS.stats.max_potion_effects = num
  end
  Update_User_Stats()
end

--current run stats
function Stats_Current_Run_Rerolls()
  USER_STATS.stats.current_run_rerolls = USER_STATS.stats.current_run_rerolls + 1
  Update_User_Stats()
end

function Stats_Current_Run_Troop_Deaths()

  USER_STATS.stats.current_run_troop_deaths = USER_STATS.stats.current_run_troop_deaths + 1
  Update_User_Stats()
end

function Stats_Current_Run_Over10Cost_Items_Purchased()

  USER_STATS.stats.current_run_over10cost_items_purchased = USER_STATS.stats.current_run_over10cost_items_purchased + 1
  Update_User_Stats()
end

function Stats_Current_Run_Num_Same_Unit(num)

  if num > USER_STATS.stats.current_run_num_same_unit then
    USER_STATS.stats.current_run_num_same_unit = num
  end
  Update_User_Stats()
end

--combat stats
function Stats_Max_Fire_Stacks(num)

  if num > USER_STATS.stats.max_fire_stacks then
    USER_STATS.stats.max_fire_stacks = num
  end
  Update_User_Stats()
end

function Stats_Max_Aspd(num)

  if num > USER_STATS.stats.max_aspd then
    USER_STATS.stats.max_aspd = num
  end
  Update_User_Stats()
end

function Stats_Max_Dmg_Without_Hp(num)

  if num > USER_STATS.stats.max_dmg_without_hp then
    USER_STATS.stats.max_dmg_without_hp = num
  end
  Update_User_Stats()
end


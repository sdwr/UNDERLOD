
function Is_Boss_Level(level)
  if level == 4 then
    -- return 'snake_boss'
    return nil
  elseif level == 6 then
    return 'stompy'
  elseif level == 11 then
    return 'dragon'
  elseif level == 16 then
    return 'heigan'
  else
    return nil
  end
end

function Build_Level_List(max_level)
  local level_list = {} 
  for i = 1, max_level do
      level_list[i] = {level = i, waves = {}, round_power = 0, color = grey[0], environmental_hazards = {}}
  end

  for i = 1, max_level do
    if Is_Boss_Level(i) then
      level_list[i].boss = Is_Boss_Level(i)
      level_list[i].color = black[0]
      level_list[i].round_power = BOSS_ROUND_POWER

    else
      --local waves = Wave_Types:Get_Waves(i)
      --level_list[i].waves = waves

      if LEVEL_TO_PERKS[i] then
        level_list[i].color = orange[5]
      end
      
      local environmental_hazards = Decide_on_Environmental_Hazards(i)
      level_list[i].environmental_hazards = environmental_hazards

      --calculate the round power for the level
      level_list[i].round_power = ROUND_POWER_BY_LEVEL(i)
      level_list[i].waves_power = {level_list[i].round_power}
    end
  end

  return level_list
end

function Decide_on_Environmental_Hazards(level)
  if level % 4 == 0 then
    return {type = 'laser', level = level / 4}
  else
    return {}
  end
end

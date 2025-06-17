
function Is_Boss_Level(level)
  if level == 6 then
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
      local waves = Wave_Types:Get_Waves(i)
      level_list[i].waves = waves

      --find the first special enemy in the wave
      -- to use as the level color on the buy screen
      local first_special = Wave_Types:Find_First_Special(waves)
      if first_special then
        level_list[i].color = enemy_to_color[first_special]
      end

      local environmental_hazards = Decide_on_Environmental_Hazards(i)
      level_list[i].environmental_hazards = environmental_hazards

      --calculate the round power for the level
      level_list[i].round_power = Wave_Types:Get_Round_Power(waves)
      level_list[i].waves_power = Wave_Types:Get_Waves_Power(waves)
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

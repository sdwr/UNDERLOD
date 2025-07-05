
function BuildLevelMap(group, x, y, parent, level, loop, level_list)
  local level_map = LevelMap{
    group = group,
    x = x,
    y = y,
    parent = parent,
    level = level,
    loop = loop,
    level_list = level_list,
  }
  return level_map
end

function BuildLevelText(level_list, level, x, y)
  local info_text_content = {}
  table.insert(info_text_content, {text = '[fg]Level ' .. level, font = pixul_font, alignment = 'center', height_multiplier = 1.5})
  -- if level_list[level].environmental_hazards and level_list[level].environmental_hazards.type then
  --   table.insert(info_text_content, {text = '[fg]Hazards ' .. level_list[level].environmental_hazards.type .. 'Lv. ' .. level_list[level].environmental_hazards.level, font = pixul_font, alignment = 'center', height_multiplier = 1.5})
  -- end
  if level_list[level].boss then
    table.insert(info_text_content, {text = '[fg]BOSS: ' .. level_list[level].boss, font = pixul_font, alignment = 'center', height_multiplier = 1.5})
  end
  if LEVEL_TO_PERKS[level] then
    table.insert(info_text_content, {text = '[fg]Reward: Perk', font = pixul_font, alignment = 'center', height_multiplier = 1.5})
  end


  local info_text = InfoText{group = main.current.ui}
  info_text:activate(info_text_content
    , nil, nil, nil, nil, 16, 4, nil, 2)
  info_text.x = x
  info_text.y = y
  
  return info_text
end


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
  if level_list[level].environmental_hazards and level_list[level].environmental_hazards.type then
    table.insert(info_text_content, {text = '[fg]Hazards ' .. level_list[level].environmental_hazards.type .. 'Lv. ' .. level_list[level].environmental_hazards.level, font = pixul_font, alignment = 'center', height_multiplier = 1.5})
  end
  table.insert(info_text_content, {text = '[fg]Waves ' .. #level_list[level].waves, font = pixul_font, alignment = 'center', height_multiplier = 1.5})
  for i, wave in ipairs(level_list[level].waves) do
    local wave_text = ''
    for j, enemy in ipairs(wave) do
      wave_text = wave_text .. enemy .. ', '
    end
    table.insert(info_text_content, {text = wave_text, font = pixul_font, alignment = 'center', height_multiplier = 1.5})
  end

  local info_text = InfoText{group = main.current.ui}
  info_text:activate(info_text_content
    , nil, nil, nil, nil, 16, 4, nil, 2)
  info_text.x = x
  info_text.y = y
  
  return info_text
end

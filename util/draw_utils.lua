DrawUtils = {}

function DrawUtils.draw_floor_item_hover_circle(floor_interactable)
  if not floor_interactable.interaction_hover_timer then
    return
  end
  if not floor_interactable.width or not floor_interactable.height then
    return
  end

  local interaction_hover_timer = floor_interactable.interaction_hover_timer
  local radius = ((interaction_hover_timer / 2) * 20) + 10
  local color = white[0]
  color.a = interaction_hover_timer * 0.3
  graphics.rectangle(floor_interactable.x, floor_interactable.y, floor_interactable.width, floor_interactable.height, 6, 6, color)
  graphics.circle(floor_interactable.x, floor_interactable.y, radius, color)
end

function DrawUtils.build_set_bonus_tooltip_text(set_info, number_of_pieces)
  number_of_pieces = number_of_pieces or 0

    -- Create text lines for this specific set
    local text_lines = {}
  
    -- Set name header
    local set_color = set_info.color or 'fg'
    table.insert(text_lines, {
      text = '[' .. set_color .. ']' .. set_info.name:upper(), 
      font = pixul_font, 
      alignment = 'center'
    })
    
    -- Set bonuses
    for i = 1, MAX_SET_BONUS_PIECES do
      local description = set_info.descriptions[i]
      if description then
        local is_reached = number_of_pieces >= i
        local color = is_reached and set_color or 'fg[2]' -- Use set color if reached, gray if not
        
        
        table.insert(text_lines, {
          text = '[' .. color .. ']' .. i .. ': ' .. description, 
          font = pixul_font, 
          alignment = 'left'
        })
      end
    end

    return text_lines
end


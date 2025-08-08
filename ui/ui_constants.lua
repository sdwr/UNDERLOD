


-- ItemPart dimensions
ITEM_PART_WIDTH = 18
ITEM_PART_HEIGHT = 18

function Get_UI_Popup_Position(type)
  --have to put it in the fn so gw and gh are defined
  type = type or main.current.name
  
  local ui_popup_positions_by_state = {
    ['buy_screen'] = {x = gw/2, y = 50},
    ['default'] = {x = gw/2, y = gh/2},
    ['error'] = {x = gw/2, y = gh/2},
  }

  return ui_popup_positions_by_state[type] 
  or ui_popup_positions_by_state['default']
end
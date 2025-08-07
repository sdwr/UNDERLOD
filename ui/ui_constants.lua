


function Get_UI_Popup_Position()
  --have to put it in the fn so gw and gh are defined
  local ui_popup_positions_by_state = {
    ['buy_screen'] = {x = gw/2, y = 50},
    ['default'] = {x = gw/2, y = gh/2},
  }

  if main and main.current then
    return ui_popup_positions_by_state[main.current.name]
    or ui_popup_positions_by_state['default']
  end
  return ui_popup_positions_by_state['default']
end
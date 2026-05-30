


-- ItemPart dimensions
ITEM_PART_WIDTH = 18
ITEM_PART_HEIGHT = 18

-- Card dimensions (ItemCard, PerkCard)
CARD_WIDTH = 60
CARD_HEIGHT = 80

function Get_UI_Popup_Position(type)
  --have to put it in the fn so gw and gh are defined
  type = type or main.current.name

  -- Bottom-of-screen anchor sits over the shop's item-card row (cards are
  -- centered at gh - 45 with h = 80, spanning roughly gh - 85 .. gh - 5).
  -- y = gh - 65 lands in the upper third of that band, so the popup overlaps
  -- the cards without burying their stats and sets.
  local ui_popup_positions_by_state = {
    ['buy_screen'] = {x = gw/2, y = gh - 65},
    ['perk_overlay'] = {x = gw/2, y = gh - 65},
    ['default'] = {x = gw/2, y = gh/2},
    ['error'] = {x = gw/2, y = gh/2},
  }

  return ui_popup_positions_by_state[type]
  or ui_popup_positions_by_state['default']
end
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


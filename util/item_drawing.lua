-- Utility functions for drawing items and their color masks

function draw_item_with_color_masks(item, x, y, scale_x, scale_y, draw_background)
  -- Draw background if requested
  if draw_background then
    local tier_color = item_to_color(item)
    graphics.rectangle(x, y, 18+4, 18+4, 3, 3, tier_color)
    graphics.rectangle(x, y, 18, 18, 3, 3, bg[5])
  end
  
  -- Draw the base item image
  local image = find_item_image(item)
  if image then
    image:draw(x, y, 0, scale_x or 0.4, scale_y or 0.4)
    
    -- draw item colors as mask overlay on top of the image
    if item.colors then
      local num_colors = #item.colors
      local item_height = 18 -- Standard item height
      local color_h = item_height / num_colors
      
      for i, color_name in ipairs(item.colors) do
        --make a copy of the color so we can change the alpha
        local color = _G[color_name]
        color = color[0]:clone()
        color.a = 0.6
        
        love.graphics.setColor(color.r, color.g, color.b, color.a)
        image:draw(x, y, 0, scale_x or 0.4, scale_y or 0.4)
        love.graphics.setColor(1, 1, 1, 1)
      end
    end
  end
end 
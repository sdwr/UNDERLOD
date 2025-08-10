-- The base Image class.
Image = Object:extend()
Image.__class_name = 'Image'
function Image:init(asset_name, filter)
  self.image = love.graphics.newImage("assets/images/" .. asset_name .. ".png")
  if filter then
    self.image:setFilter(filter, filter)
  end
  self.w = self.image:getWidth()
  self.h = self.image:getHeight()
end


function Image:draw(x, y, r, sx, sy, ox, oy, color)
  local _r, g, b, a
  if color then
    _r, g, b, a = love.graphics.getColor()
    graphics.set_color(color)
  end
  love.graphics.draw(self.image, x, y, r or 0, sx or 1, sy or sx or 1, self.w/2 + (ox or 0), self.h/2 + (oy or 0))
  if color then love.graphics.setColor(_r, g, b, a) end
end

-- hardcoded to item dimensions
-- scales to monitor resolution and draws on a separate canvas on top of everything
-- ox, oy aren't scaled properly
function Image:drawFullRes(x,y,r,sx,sy,ox,oy,color)
  
  --hardcoded to only work on items :o
  local scalew = (ITEM_SIZE_W / self.w) * (sx or 1)
  local scaleh = (ITEM_SIZE_H / self.h) * (sy or 1)
  --scale back from game res to full res
  scalew = scalew * (ww/gw)
  scaleh = scaleh * (wh/gh)
  x = x * (ww/gw)
  y = y * (wh/gh)
  --havent fixed origin coord

  --adds draw function to the table of draws (emptied every frame)
  local drawFn = function()
    self:draw(x,y,r,scalew, scaleh,ox,oy,color)
  end
  table.insert(full_res_draws, drawFn)
end




-- The base Quad class. Useful for loading pieces of images as independent Image objects. Every function that takes in an Image also takes in a Quad.
Quad = Object:extend()
Quad.__class_name = 'Quad'
function Quad:init(image, tile_w, tile_h, tile_coordinates)
  self.image = image
  self.quad = love.graphics.newQuad((tile_coordinates[1]-1)*tile_w, (tile_coordinates[2]-1)*tile_h, tile_w, tile_h, self.image.w, self.image.h)
  self.w, self.h = tile_w, tile_h
end


function Quad:draw(x, y, r, sx, sy, ox, oy)
  love.graphics.draw(self.image.image, self.quad, x, y, r or 0, sx or 1, sy or sx or 1, self.w/2 + (ox or 0), self.h/2 + (oy or 0))
end





-- A linear gradient image.
-- The first argument is the direction of the gradient and can be either 'horizontal' or 'vertical'.
GradientImage = Object:extend()
GradientImage.__class_name = 'GradientImage'
function GradientImage:init(direction, ...)
  local colors = {...}
  local mesh_data = {}

  if direction == "horizontal" then
    for i = 1, #colors do
      local color = colors[i]
      local x = (i-1)/(#colors-1)
      table.insert(mesh_data, {x, 1, x, 1, color.r, color.g, color.b, color.a or 1})
      table.insert(mesh_data, {x, 0, x, 0, color.r, color.g, color.b, color.a or 1})
    end
  elseif direction == "vertical" then
    for i = 1, #colors do
      local color = colors[i]
      local y = (i-1)/(#colors-1)
      table.insert(mesh_data, {1, y, 1, y, color.r, color.g, color.b, color.a or 1})
      table.insert(mesh_data, {0, y, 0, y, color.r, color.g, color.b, color.a or 1})
    end
  end

  self.mesh = love.graphics.newMesh(mesh_data, "strip", "static")
end


-- Draws the gradient image with size w, h centered on x, y.
function GradientImage:draw(x, y, w, h, r, sx, sy, ox, oy)
  graphics.push(x, y, r)
  love.graphics.draw(self.mesh, x - (sx or 1)*(w + (ox or 0))/2, y - (sy or 1)*(h + (oy or 0))/2, 0, w*(sx or 1), h*(sy or sx or 1))
  graphics.pop()
end

-- In your setup or a config file, define the colors for your auras.
-- This makes it easy to manage the appearance of different auras.

AURA_COLORS = nil
AURA_BORDERS = nil

function Set_Aura_Colors()
  AURA_COLORS = {
    frostnova = blue_transparent:clone():set_alpha(0.08),
    radiance = red_transparent:clone():set_alpha(0.08),
    default = white_transparent:clone():set_alpha(0.08)
  }
  AURA_BORDERS = {
    frostnova = blue[0],
    radiance = red[0],
    default = white[0]
  }
end

-- This is a global table to hold all objects that currently have an aura
GLOBAL_AURAS = {}

function Draw_Auras()
  if not AURA_COLORS then
    Set_Aura_Colors()
  end

  Check_Auras()
  -- Important: Make sure your main love.draw() function calls love.graphics.clear
  -- with the fifth argument as 'true' to clear the stencil buffer each frame.
  -- Example: love.graphics.clear(0.1, 0.1, 0.1, 1, true)

  for name, objects in pairs(GLOBAL_AURAS) do
      -- Get the color and border properties for the current aura type
      local color = AURA_COLORS[name] or AURA_COLORS.default
      local border = AURA_BORDERS[name] or AURA_BORDERS.default

      -- STEP 1: Draw the combined shape of all auras into the stencil buffer.
      -- This function draws *only* to the stencil buffer, setting the value to 1.
      love.graphics.stencil(function()
          love.graphics.setColor(1, 1, 1, 1) -- Use a solid, opaque color.
          for _, object in ipairs(objects) do
              if object.x and object.y and object.rs then
                  love.graphics.circle('fill', object.x, object.y, object.rs)
              end
          end
      end, "replace", 1)

      -- STEP 2: Draw the BORDER.
      -- We set the test to "notequal" to draw *only* where the stencil is NOT 1.
      -- By drawing slightly larger circles, this fills the area just around the main shape.
      love.graphics.setStencilTest("notequal", 1)
      love.graphics.setColor(border.r, border.g, border.b, border.a)
      for _, object in ipairs(objects) do
          if object.x and object.y and object.rs then
              love.graphics.circle('fill', object.x, object.y, object.rs + 0.35)
          end
      end

      -- STEP 3: Draw the main FILL.
      -- Now we set the test to "equal" to draw only where the stencil IS 1.
      love.graphics.setStencilTest("equal", 1)
      love.graphics.setColor(color.r, color.g, color.b, color.a)
      love.graphics.rectangle('fill', 0, 0, gw, gh) -- Assuming gw and gh are your game's width/height

      -- STEP 4: VERY IMPORTANT - Reset the stencil test so it doesn't affect other drawing.
      love.graphics.setStencilTest()
  end

  -- Reset the main drawing color to white when finished.
  love.graphics.setColor(1, 1, 1, 1)
end

function Add_Aura(name, object)
  if not GLOBAL_AURAS[name] then
      GLOBAL_AURAS[name] = {}
  end
  -- Avoid adding the same object multiple times to the same aura list
  for _, existing_object in ipairs(GLOBAL_AURAS[name]) do
      if existing_object == object then return end
  end
  table.insert(GLOBAL_AURAS[name], object)
end

function Check_Auras()
  for name, objects in pairs(GLOBAL_AURAS) do
      -- Iterate backwards when removing from a table to avoid skipping elements
      for i = #objects, 1, -1 do
          local object = objects[i]
          if object.dead then
              table.remove(objects, i)
          end
      end
  end
end

function Clear_Auras()
  GLOBAL_AURAS = {}
end

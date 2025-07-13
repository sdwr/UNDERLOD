-- The base Shader class.
Shader = Object:extend()
function Shader:init(vertex_name, fragment_name)
  self.shader = love.graphics.newShader("assets/shaders/" .. (vertex_name or "default.vert"), "assets/shaders/" .. fragment_name)
end


-- Sets this shader as the active one.
function Shader:set()
  current_shader = self
  love.graphics.setShader(self.shader)
end

-- Unsets this shader as the active one.
function Shader:unset()
  current_shader = nil
  love.graphics.setShader()
end


-- Takes in a parameter and the data that corresponds to it and sends it to the shader.
-- shader:send('displacement_map', displacement_canvas)
function Shader:send(value, data)
  -- First, check if 'data' is a table that we can call methods on.
  if type(data) == 'table' and data.is then
      if data:is(Canvas) then
          self.shader:send(value, data.canvas)
      elseif data:is(Image) then
          self.shader:send(value, data.image)
      else
          -- It's some other custom object, send it as is.
          self.shader:send(value, data)
      end
  else
      -- It's a primitive type (boolean, number, etc.). Send it directly.
      self.shader:send(value, data)
  end
end

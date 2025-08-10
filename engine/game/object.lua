Object = {}
Object.__index = Object
Object.__class_name = "Object"

local WRAPPER_KEY = {}

Object._profiled_methods = {}
Object._original_methods = {}

function Object:init()
end

function Object:profile(...)
  for _, method_name in pairs({...}) do
    local original_method = self[method_name]

    if original_method and type(original_method) == "function" then
      if original_method[WRAPPER_KEY] then
        --already wrapped in a parent class, skip
        return
      end
      
      -- Store original method for restoration
      if not self._original_methods then self._original_methods = {} end
      self._original_methods[method_name] = original_method
      
      --wrap the method
      local wrapped_method = function(self_ref, ...)
        local timer_name = self_ref.__class_name .. "." .. method_name
        Profiler:start(timer_name)
        local result = {original_method(self_ref, ...)}
        Profiler:finish(timer_name)
        return unpack(result)
      end

      wrapped_method[WRAPPER_KEY] = true
      self[method_name] = wrapped_method
    end
  end
end


function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)

  return cls
end


function Object:implement(...)
  for _, cls in pairs({...}) do
    for k, v in pairs(cls) do
      if self[k] == nil and type(v) == "function" then
        self[k] = v
      end
    end
  end
end

function Object:import(...)
  for key, prop in pairs({...}) do
    self[key] = prop
  end
end


function Object:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end


function Object:__tostring()
  return "Object"
end


function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:init(...)
  return obj
end

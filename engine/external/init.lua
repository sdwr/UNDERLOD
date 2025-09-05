local path = ...
if not path:find("init") then
  binser = require(path .. ".binser")
  mlib = require(path .. ".mlib")
  -- if not web then clipper = require(path .. ".clipper") end
  ripple = require(path .. ".ripple")
  anim8 = require(path .. ".anim8")

  feather = require(path .. ".feather")
  
  -- steam = require 'luasteam'
end

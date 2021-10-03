-- TODO: actually implement this later, for now ripple works fine with just name swaps on top of it for naming consistency.
--Sound = function(asset_name, options) return ripple.newSound(love.audio.newSource('assets/sounds/' .. asset_name, 'static'), options) end
Sound = function(asset_name, options) return {play = function() return end} end
SoundTag = ripple.newTag
Effect = love.audio.setEffect

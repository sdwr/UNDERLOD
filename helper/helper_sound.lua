Helper.Sound = {}


Helper.Sound.radiance_fade_after = 1
Helper.Sound.radiance_last_played = 0

function Helper.Sound:update()
  if Helper.Time.time - self.radiance_last_played >  Helper.Sound.radiance_fade_after then
      self:stop_radiance()
  end
end

function Helper.Sound:init_radiance()
  Helper.Sound.radiance = campfire
  Helper.Sound.radiance:setLooping(true)
  Helper.Sound.radiance:setVolume(0.3)
end

function Helper.Sound:play_radiance()
  if not Helper.Sound.radiance then Helper.Sound:init_radiance() end
  if not Helper.Sound.radiance:isPlaying() then
    self.radiance:play()
    self.radiance_last_played = Helper.Time.time
  else 
    self.radiance:fadeIn(0.5)
  end
end

function Helper.Sound:stop_radiance()
  if self.radiance_is_playing then
    self.radiance:fadeOut(1)
  end
end
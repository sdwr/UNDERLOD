Helper.Sound = {}


Helper.Sound.radiance_fade_after = 1
Helper.Sound.radiance_last_played = 0

Helper.Sound.distance_multiplier_sound = nil

function Helper.Sound:update()
  if Helper.Time.time - self.radiance_last_played >  Helper.Sound.radiance_fade_after then
      self:stop_radiance()
  end

  self:play_distance_multiplier_sound()
end

function Helper.Sound:play_distance_multiplier_sound()
  local distance_multiplier = Helper.Unit.closest_enemy_distance_multiplier
  if not distance_multiplier or distance_multiplier > 0.7 then
    if self.distance_multiplier_sound then
      self.distance_multiplier_sound:stop()
      self.distance_multiplier_sound = nil
    end
  else
    local base_volume = 0.08
    local base_pitch = 0.8
    local distance_multiplier_volume_scale = 1 - distance_multiplier
    local distance_multiplier_pitch_scale = (1 - distance_multiplier) * 0.1

    local scaled_volume = base_volume + base_volume * distance_multiplier_volume_scale
    local scaled_pitch = base_pitch + base_pitch * distance_multiplier_pitch_scale

    if not self.distance_multiplier_sound then
      self.distance_multiplier_sound = choir1:play{volume = scaled_volume, pitch = scaled_pitch}
    else
      self.distance_multiplier_sound.volume = scaled_volume
      self.distance_multiplier_sound.pitch = scaled_pitch
    end
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
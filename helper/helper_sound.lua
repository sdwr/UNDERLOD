Helper.Sound = {}


Helper.Sound.radiance_fade_after = 1
Helper.Sound.radiance_last_played = 0

Helper.Sound.distance_multiplier_sound = nil

function Helper.Sound:update()
  if Helper.Time.time - self.radiance_last_played >  Helper.Sound.radiance_fade_after then
      self:stop_radiance()
  end

  -- TODO: sounds like crap and plays while paused
  -- self:play_distance_multiplier_sound()

  if Helper.Unit.closest_enemy_distance_tier 
  and Helper.Unit.closest_enemy_distance_tier < (Helper.Unit.last_closest_enemy_distance_tier or 4) then
      -- Helper.Sound:play_distance_multiplier_sound(Helper.Unit.closest_enemy_distance_tier)
  end
end

function Helper.Sound:play_distance_multiplier_sound(distance_tier)
  if not distance_tier or distance_tier > 3 then return end

  local tier_to_pitch = {
    [1] = 1.4,
    [2] = 1.1,
    [3] = 0.7,
  }
  local tier_to_volume = {
    [1] = 0.8,
    [2] = 0.6,
    [3] = 0.5,
  }

  local pitch = tier_to_pitch[distance_tier]
  local volume = tier_to_volume[distance_tier]

  local sound = ui_switch1:play{volume = volume, pitch = pitch}
end

function Helper.Sound:play_constant_distance_multiplier_sound()
  local distance_multiplier = Helper.Unit.closest_enemy_distance_multiplier or 1
  local threshold = DISTANCE_MULTIPLIER_THRESHOLD_SOUND
  if not distance_multiplier or distance_multiplier > threshold then
    if self.distance_multiplier_sound then
      self.distance_multiplier_sound:stop()
      self.distance_multiplier_sound = nil
    end
  else
    local base_volume = 0.03
    local base_pitch = 0.7
    --scales from 0 as the lowest to 1 as the highest
    local scaled_multiplier = 1 - math.remap(distance_multiplier, 0, threshold, 0, 1)

    local scaled_volume = base_volume  + scaled_multiplier * base_volume
    local scaled_pitch = base_pitch + scaled_multiplier * 0.5

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
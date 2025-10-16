ProgressBar = Object:extend()
ProgressBar.__class_name = 'ProgressBar'
ProgressBar:implement(GameObject)
function ProgressBar:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = false
  self.progress = args.progress or 0
  self.max_progress = args.max_progress or 1
  self.number_of_waves = #args.waves_power
  self.waves_power = args.waves_power or {self.max_progress}
  self.bgcolor = args.bgcolor or bg[-1]:clone()

  self.fade_in_duration = args.fade_in_duration or 4
  if self.fade_in then
    self.bgcolor.a = 0
  end

  self.sensor = Rectangle(self.x, self.y, self.w + 12, self.h + 12)
  self.target_transparency = 1
  self.current_transparency = 1
  self.transparency_fade_speed = 1
  
  self.segments = {}
  local spacing = 4 -- Spacing between segments in pixels
  local width_minus_spacing = self.shape.w - (self.number_of_waves - 1) * spacing
  local segment_width = width_minus_spacing / self.number_of_waves
  local segment_x = self.x - (self.shape.w / 2) + (segment_width / 2)

  for i = 1, self.number_of_waves do
    self.segments[i] = ProgressBarSegment{
      group = self.group,
      parent = self, segment_index = i, max_segment_index = self.number_of_waves, color = self.color, bgcolor = self.bgcolor, wave_power = self.waves_power[i],
      x = segment_x + (segment_width * (i - 1)) + (spacing * (i - 1)),
      y = self.y,
      w = self.shape.w / self.number_of_waves,
      h = self.shape.h,
      fade_in = self.fade_in,
    }
  end

  self.active_wave = 1
end

function ProgressBar:update(dt)
  self:update_game_object(dt)

  if main.current and main.current.main and main.current.enemies then
    local enemies_in_sensor = main.current.main:get_objects_in_shape(self.sensor, main.current.enemies, nil)
    local friendlies_in_sensor = main.current.main:get_objects_in_shape(self.sensor, main.current.friendlies, nil)
    if #enemies_in_sensor > 0 or #friendlies_in_sensor > 0 then
      self.target_transparency = 0.3
    else
      self.target_transparency = 1
    end
  end

  if self.current_transparency ~= self.target_transparency then
    if self.current_transparency < self.target_transparency then
      self.current_transparency = math.min(self.current_transparency + self.transparency_fade_speed * dt, self.target_transparency)
    else
      self.current_transparency = math.max(self.current_transparency - self.transparency_fade_speed * dt, self.target_transparency)
    end
  end
end

function ProgressBar:begin_fade_in()
  self.t:tween(self.fade_in_duration, self.bgcolor, {a = 1}, math.linear)
  for i = 1, #self.segments do
    self.segments[i]:begin_fade_in(self.fade_in_duration)
  end
end

function ProgressBar:draw()
  local background_padding = 6
  local draw_color = self.bgcolor:clone()
  draw_color.a = draw_color.a * self.current_transparency

  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(
      self.x, self.y, self.shape.w + background_padding, self.shape.h + background_padding,
      6, 6, draw_color
    )
  graphics.pop()
end

function ProgressBar:highest_wave_complete()
  for i = 1, self.number_of_waves do
    if self.wave_cumulative_power and #self.wave_cumulative_power >= i then
      if self.progress >= self.wave_cumulative_power[i] then
        return i
      end
    end
  end
  return 0
end

function ProgressBar:increase_with_particles(roundPower, x, y)
  -- Don't create particles if all waves are complete or invalid wave index
  if self.active_wave > self.number_of_waves or self.active_wave < 1 then
    return
  end

  local segment = self.segments[self.active_wave]
  if segment then
    segment:create_progress_particle(roundPower, x, y)
  end
end

function ProgressBar:complete_wave(wave_index)
  if wave_index < 1 or wave_index > self.number_of_waves then
    return
  end

  local segment = self.segments[wave_index]
  if segment then
    segment:complete_wave()
  end

  if self.active_wave <= wave_index then
    -- Don't increment past the total number of waves
    self.active_wave = math.min(self.active_wave + 1, self.number_of_waves + 1)
  end
end

function ProgressBar:die()
  self.dead = true
end

ProgressBarSegment = Object:extend()
ProgressBarSegment.__class_name = 'ProgressBarSegment'
ProgressBarSegment:implement(GameObject)
function ProgressBarSegment:init(args)
  self:init_game_object(args)
  self.parent = args.parent
  self.segment_index = args.segment_index
  self.max_segment_index = args.max_segment_index

  self.segment_color = args.segment_color or yellow[-4]:clone()
  self.segment_bgcolor = args.segment_bgcolor or fg[-10]:clone()
  self.particles_color = args.particles_color or self.segment_color:clone()

  if self.fade_in then
    self.segment_color.a = 0
    self.segment_bgcolor.a = 0
  end

  self.wave_power = args.wave_power or 100
  self.progress = args.progress or 0
  self.max_progress = args.max_progress or self.wave_power

  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = false
end

function ProgressBarSegment:begin_fade_in(duration)
  self.t:tween(duration, self.segment_bgcolor, {a = 1}, math.linear)
  self.t:tween(duration, self.segment_color, {a = 1}, math.linear)
end

function ProgressBarSegment:update(dt)
  self:update_game_object(dt)
end

function ProgressBarSegment:draw()
  local progressPct = math.min(self.progress / self.max_progress, 1)
  local width = self.shape.w * progressPct
  local new_center_x = self.x - self.shape.w/2 + width/2

  local transparency = self.parent and self.parent.current_transparency or 1
  local bg_color = self.segment_bgcolor:clone()
  local fg_color = self.segment_color:clone()
  bg_color.a = bg_color.a * transparency
  fg_color.a = fg_color.a * transparency

  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(
      self.x, self.y, self.shape.w, self.shape.h,
      4, 4, bg_color
    )
    if progressPct > 0 then
      graphics.rectangle(
        new_center_x, self.y, width, self.shape.h,
        4, 4, fg_color
      )
    end
  graphics.pop()
end

function ProgressBarSegment:increase_progress(amount)
  self.progress = self.progress + amount

  if self.progress >= self.max_progress then
    self:complete_wave()
  end

  alert1:play{pitch = random:float(0.95, 1.05), volume = 0.3}

  self:create_particles()
end

function ProgressBarSegment:get_progress_location()
  -- Return the actual position of this segment
  return {x = self.x, y = self.y}
end

function ProgressBarSegment:create_progress_particle(roundPower, x, y)
  -- Ensure we have a valid arena and group before creating particle
  if not main.current or not main.current.current_arena then
    return
  end

  local arena = main.current.current_arena
  if not arena.main then
    return
  end

  self.t:after(0.0, function()
    ProgressParticle{
      group = arena.main,
      x = x,
      y = y,
      roundPower = roundPower,
      parent = self,
    }
  end)
end

function ProgressBarSegment:complete_wave()
  if self.progress < self.max_progress then
    self.progress = self.max_progress
    self:create_particles()
  end
end

function ProgressBarSegment:create_particles()
  local progress_location = self:get_progress_location()
  local color = self.particles_color:clone()
  color.a = math.max(color.a, 0.3)
  for i = 1, 3 do
    HitParticle{group = main.current.effects, x = progress_location.x, y = progress_location.y, color = color}
  end
end

function ProgressBarSegment:die()
  self.dead = true
  for i = 1, self.max_segment_index do
    if self.parent.segments[i] then
      self.parent.segments[i]:die()
    end
  end
end

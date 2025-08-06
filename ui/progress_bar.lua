ProgressBar = Object:extend()
ProgressBar:implement(GameObject)
function ProgressBar:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = false
  self.progress = args.progress or 0
  self.max_progress = args.max_progress or 1
  self.number_of_waves = args.number_of_waves or 1
  self.waves_power = args.waves_power or {self.max_progress}
  self.color = args.color or fg[0]
  self.bgcolor = args.bgcolor or bg[1]
  
  self.segments = {}
  for i = 1, self.number_of_waves do
    self.segments[i] = ProgressBarSegment{
      group = self.group,
      parent = self, segment_index = i, max_segment_index = self.number_of_waves, color = self.color, bgcolor = self.bgcolor, wave_power = self.waves_power[i],
      x = self.x + (self.shape.w / self.number_of_waves) * (i - 1),
      y = self.y,
      w = self.shape.w / self.number_of_waves,
      h = self.shape.h,
    }
  end

  self.active_wave = 1
end

function ProgressBar:update(dt)
  self:update_game_object(dt)
end

function ProgressBar:draw()
  --just draw a background rectangle
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.bgcolor)
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
  self.segments[self.active_wave]:create_progress_particle(roundPower, x, y)
end

function ProgressBar:complete_wave(wave_index)
  self.segments[wave_index]:complete_wave()
  if self.active_wave <= wave_index then
    self.active_wave = self.active_wave + 1
  end
end

function ProgressBar:die()
  self.dead = true
end

ProgressBarSegment = Object:extend()
ProgressBarSegment:implement(GameObject)
function ProgressBarSegment:init(args)
  self:init_game_object(args)
  self.parent = args.parent
  self.segment_index = args.segment_index
  self.max_segment_index = args.max_segment_index
  self.color = args.color or fg[0]
  self.bgcolor = args.bgcolor or bg[1]
  self.wave_power = args.wave_power or 100
  self.progress = args.progress or 0
  self.max_progress = args.max_progress or self.wave_power

  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = false
end

function ProgressBarSegment:update(dt)
  self:update_game_object(dt)
end

function ProgressBarSegment:draw()
  local progressPct = math.min(self.progress / self.max_progress, 1)
  local width = self.shape.w*progressPct
  local new_center_x = self.x - self.shape.w/2 + width/2
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.bgcolor)
    graphics.rectangle(new_center_x, self.y, width, self.shape.h, 4, 4, self.color)
  graphics.pop()
end

function ProgressBarSegment:increase_progress(amount)
  self.progress = self.progress + amount

  if self.progress >= self.max_progress then
    self:complete_wave()
  end

  alert1:play{pitch = random:float(0.95, 1.05), volume = 1.1}

  self:create_particles()
end

function ProgressBarSegment:get_progress_location()
  local progress_location = {x = self.x, y = self.y}
  progress_location.x = progress_location.x - self.shape.w/2 + self.shape.w*self.progress/self.max_progress
  return progress_location
end

function ProgressBarSegment:create_progress_particle(roundPower, x, y)
  ProgressParticle{
    group = main.current.main,
    x = x,
    y = y,
    roundPower = roundPower,
    parent = self, 
  }

end

function ProgressBarSegment:complete_wave()
  if self.progress < self.max_progress then
    self.progress = self.max_progress
    self:create_particles()
  end
end

function ProgressBarSegment:create_particles()
  local progress_location = self:get_progress_location()
  for i = 1, 10 do
    HitParticle{group = main.current.effects, x = progress_location.x, y = progress_location.y, color = self.color}
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

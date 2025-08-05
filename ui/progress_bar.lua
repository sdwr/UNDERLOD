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
  self.wave_cumulative_power = self:set_wave_cumulative_power()
  self.color = args.color or fg[0]
  self.bgcolor = args.bgcolor or bg[1]
end

function ProgressBar:update(dt)
  self:update_game_object(dt)
end

function ProgressBar:draw()
  local progressPct = math.min(self.progress / self.max_progress, 1)
  local width = self.shape.w*progressPct
  local new_center_x = self.x - self.shape.w/2 + width/2
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, bg[1])
    graphics.rectangle(new_center_x, self.y, width, self.shape.h, 4, 4, self.color)
  graphics.pop()

  local x = self.x - self.shape.w/2
  for i = 1, self.number_of_waves do
    x = x + (self.waves_power[i] / self.max_progress) * self.shape.w
    graphics.circle(x, self.y, 4, fg[0])
  end
end

function ProgressBar:is_complete()
  return self.progress >= self.max_progress
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

function ProgressBar:get_progress_location()
  local progress_location = {x = self.x, y = self.y}
  progress_location.x = progress_location.x - self.shape.w/2 + self.shape.w*self.progress/self.max_progress
  return progress_location
end

function ProgressBar:set_progress(progress)
  self.progress = progress
end

function ProgressBar:set_max_progress(max_progress)
  self.max_progress = max_progress
  self:set_wave_cumulative_power()
end

function ProgressBar:set_number_of_waves(number_of_waves)
  self.number_of_waves = number_of_waves
  self:set_wave_cumulative_power()
end

function ProgressBar:set_waves_power(waves_power)
  self.waves_power = waves_power
  self:set_wave_cumulative_power()
end

function ProgressBar:set_wave_cumulative_power()
  self.wave_cumulative_power = {}
  for i = 1, self.number_of_waves do
    if i > 1 and self.waves_power[i] then
      self.wave_cumulative_power[i] = self.wave_cumulative_power[i-1] + self.waves_power[i]
    elseif self.waves_power[i] then
      self.wave_cumulative_power[i] = self.waves_power[i]
    else
      self.wave_cumulative_power[i] = 0
    end
  end
end

function ProgressBar:increase_with_particles(roundPower, x, y)
  self:create_progress_particle(roundPower, x, y)
end

function ProgressBar:increase_progress(amount)
  self.progress = self.progress + amount

  alert1:play{pitch = random:float(0.95, 1.05), volume = 1.1}
  
  self:create_particles()
end

function ProgressBar:create_particles()
  local progress_location = self:get_progress_location()
  for i = 1, 10 do
    HitParticle{group = main.current.effects, x = progress_location.x, y = progress_location.y, color = self.color}
  end
end

function ProgressBar:create_progress_particle(roundPower, x, y)
  ProgressParticle{
    group = main.current.main,
    x = x,
    y = y,
    roundPower = roundPower,
    parent = self, 
  }

end

function ProgressBar:die()
  self.dead = true
end
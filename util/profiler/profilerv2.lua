-- profiler.lua
Profiler = {}

function Profiler:start_frame()
  self.marks = {}
  -- os.clock() is great for measuring CPU time
  self.currentFrameStartTime = os.clock()

  -- Calculate time since last frame
  if self.lastFrameEndTime then
    self.frameTime = (self.currentFrameStartTime - self.lastFrameEndTime) * 1000 -- Convert to milliseconds

    -- Report if frame time is over 17ms (slow frame)
    if self.frameTime > 17 then
      print(string.format('--- Slow Frame Detected: %.2fms ---', self.frameTime))
    end
  end

  self:mark('start')
end

function Profiler:mark(name)
  local currentTime = os.clock()
  local elapsed = (currentTime - self.currentFrameStartTime) * 1000 -- Convert to milliseconds
  self.marks[name] = {
    time = elapsed,
    since_last = (currentTime - (self.lastMarkTime or self.currentFrameStartTime)) * 1000
  }
  self.lastMarkTime = currentTime
end

function Profiler:end_frame_and_print()
  self:mark('end')

  -- Store the end time for next frame calculation
  self.lastFrameEndTime = os.clock()

  local totalTime = (os.clock() - self.currentFrameStartTime) * 1000

  -- Only print if the frame is slow (e.g., > 17ms for 60fps)
  if totalTime < 17 then return end

  print('--- Slow Frame ---')
  print(string.format('Total Frame Time: %.2fms', totalTime))

  for name, data in pairs(self.marks) do
    if name ~= 'start' and name ~= 'end' then
      -- "since_last" is the most useful metric. It tells you how long
      -- the block of code between the previous mark and this one took.
      print(string.format('  - %s took: %.2fms', name, data.since_last))
    end
  end
end

return Profiler
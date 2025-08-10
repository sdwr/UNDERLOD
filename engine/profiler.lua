-- Performance Profiler for UNDERLOD
-- Tracks real wall-clock frame times vs fixed timestep to identify performance bottlenecks

Profiler = {}

-- Configuration
PROFILER_CONFIG = {
  auto_enable = false,
  slow_frame_threshold = 33.33, -- ms (30 FPS)
  max_history_frames = 1000,
  report_interval = 60, -- seconds
  detailed_systems = {'physics', 'ai', 'rendering', 'audio', 'update', 'draw'}
}

-- Core state
Profiler.enabled = PROFILER_CONFIG.auto_enable
Profiler.current_frame = {}
Profiler.frame_history = {}
Profiler.section_stack = {}

-- Statistics
Profiler.total_frames = 0
Profiler.slow_frames = 0
Profiler.system_totals = {}
Profiler.last_report_time = 0

-- Initialize profiler
function Profiler:init()
  self.enabled = PROFILER_CONFIG.auto_enable
  self.current_frame = {}
  self.frame_history = {}
  self.section_stack = {}
  self.total_frames = 0
  self.slow_frames = 0
  self.system_totals = {}
  self.last_report_time = love.timer.getTime()
  
  -- Initialize system totals
  for _, system in ipairs(PROFILER_CONFIG.detailed_systems) do
    self.system_totals[system] = {total_time = 0, calls = 0, max_time = 0}
  end
  
  print("Profiler initialized.")
  print("Controls: F3=Toggle profiling, F4=Show report, F5=Reset data")
  print("Enable profiling first with F3, then run the game to collect data.")
end

-- Enable/disable profiling
function Profiler:enable()
  self.enabled = true
  print("Profiler enabled")
end

function Profiler:disable()
  self.enabled = false
  print("Profiler disabled")
end

function Profiler:toggle()
  if self.enabled then
    self:disable()
  else
    self:enable()
  end
end

-- Start a new real frame
function Profiler:start_real_frame()
  if not self.enabled then return end
  
  self.current_frame = {
    real_start_time = love.timer.getTime(),
    real_duration = 0,
    update_iterations = 0,
    systems = {},
    custom_sections = {},
    memory_usage_start = collectgarbage("count"),
    memory_usage_end = 0,
    gc_time = 0,
    is_slow_frame = false
  }
  
  -- Initialize system timings for this frame
  for _, system in ipairs(PROFILER_CONFIG.detailed_systems) do
    self.current_frame.systems[system] = {total_time = 0, calls = 0}
  end
end

-- Mark start of an update iteration
function Profiler:start_update_iteration()
  if not self.enabled then return end
  if not self.current_frame or not self.current_frame.update_iterations then return end
  self.current_frame.update_iterations = self.current_frame.update_iterations + 1
end

-- Start timing a system or section
function Profiler:start(section_name)
  if not self.enabled then return end
  if not self.current_frame then
    -- Initialize frame if it doesn't exist (fallback for timing calls outside main loop)
    self:start_real_frame()
  end
  
  local start_time = love.timer.getTime()
  table.insert(self.section_stack, {name = section_name, start_time = start_time})
end

-- Finish timing a system or section
function Profiler:finish(section_name)
  if not self.enabled then return end
  if not self.current_frame then
    -- Initialize frame if it doesn't exist (fallback for timing calls outside main loop)  
    self:start_real_frame()
  end
  if #self.section_stack == 0 then return end
  
  local section = table.remove(self.section_stack)
  if section.name ~= section_name then
    print("Profiler warning: mismatched section '" .. section_name .. "', expected '" .. section.name .. "'")
    return
  end
  
  local elapsed = love.timer.getTime() - section.start_time
  
  -- Store in current frame
  if self.current_frame.systems and self.current_frame.systems[section_name] then
    self.current_frame.systems[section_name].total_time = self.current_frame.systems[section_name].total_time + elapsed
    self.current_frame.systems[section_name].calls = self.current_frame.systems[section_name].calls + 1
  else
    if not self.current_frame.custom_sections then
      self.current_frame.custom_sections = {}
    end
    if not self.current_frame.custom_sections[section_name] then
      self.current_frame.custom_sections[section_name] = {total_time = 0, calls = 0}
    end
    self.current_frame.custom_sections[section_name].total_time = self.current_frame.custom_sections[section_name].total_time + elapsed
    self.current_frame.custom_sections[section_name].calls = self.current_frame.custom_sections[section_name].calls + 1
  end
  
  -- Update global totals
  if not self.system_totals[section_name] then
    self.system_totals[section_name] = {total_time = 0, calls = 0, max_time = 0}
  end
  self.system_totals[section_name].total_time = self.system_totals[section_name].total_time + elapsed
  self.system_totals[section_name].calls = self.system_totals[section_name].calls + 1
  self.system_totals[section_name].max_time = math.max(self.system_totals[section_name].max_time, elapsed)
end

-- Convenience function to profile a function
function Profiler:section(section_name, func)
  self:start(section_name)
  local result = func()
  self:finish(section_name)
  return result
end

-- End the current real frame
function Profiler:end_real_frame()
  if not self.enabled then return end
  if not self.current_frame.real_start_time then return end
  
  -- Measure garbage collection
  local gc_start_time = love.timer.getTime()
  local memory_before_gc = collectgarbage("count")
  collectgarbage("step", 1) -- Do minimal GC step to measure overhead
  self.current_frame.gc_time = love.timer.getTime() - gc_start_time
  self.current_frame.memory_usage_end = collectgarbage("count")
  
  self.current_frame.real_duration = love.timer.getTime() - self.current_frame.real_start_time
  self.current_frame.is_slow_frame = self.current_frame.real_duration * 1000 > PROFILER_CONFIG.slow_frame_threshold
  
  -- Update statistics
  self.total_frames = self.total_frames + 1
  if self.current_frame.is_slow_frame then
    self.slow_frames = self.slow_frames + 1
  end
  
  -- Store frame in history
  table.insert(self.frame_history, self.current_frame)
  if #self.frame_history > PROFILER_CONFIG.max_history_frames then
    table.remove(self.frame_history, 1)
  end
  
  -- Check if we should generate a report
  local current_time = love.timer.getTime()
  if current_time - self.last_report_time > PROFILER_CONFIG.report_interval then
    self:auto_report()
    self.last_report_time = current_time
  end
end

-- Generate automatic performance report
function Profiler:auto_report()
  if self.total_frames < 60 then return end -- Need some data first
  
  local slow_percentage = (self.slow_frames / self.total_frames) * 100
  if slow_percentage > 10 then -- More than 10% slow frames
    print(string.format("PERFORMANCE WARNING: %.1f%% slow frames (%d/%d)", 
      slow_percentage, self.slow_frames, self.total_frames))
    self:report_summary()
  end
end

-- Generate a summary report
function Profiler:report_summary()
  if not self.enabled or self.total_frames == 0 then
    print("No profiling data available")
    return
  end
  
  print("\n=== PROFILER SUMMARY ===")
  print(string.format("Total frames: %d", self.total_frames))
  print(string.format("Slow frames: %d (%.1f%%)", self.slow_frames, (self.slow_frames / self.total_frames) * 100))
  
  -- Recent frame analysis
  local recent_frames = {}
  local recent_count = math.min(60, #self.frame_history)
  for i = #self.frame_history - recent_count + 1, #self.frame_history do
    table.insert(recent_frames, self.frame_history[i])
  end
  
  if #recent_frames > 0 then
    local total_time = 0
    local total_updates = 0
    local total_gc_time = 0
    local total_memory_delta = 0
    local max_memory_usage = 0
    
    for _, frame in ipairs(recent_frames) do
      total_time = total_time + frame.real_duration
      total_updates = total_updates + frame.update_iterations
      if frame.gc_time then total_gc_time = total_gc_time + frame.gc_time end
      if frame.memory_usage_start and frame.memory_usage_end then
        total_memory_delta = total_memory_delta + (frame.memory_usage_end - frame.memory_usage_start)
        max_memory_usage = math.max(max_memory_usage, frame.memory_usage_end)
      end
    end
    
    local avg_frame_time = (total_time / #recent_frames) * 1000
    local avg_updates = total_updates / #recent_frames
    local avg_gc_time = (total_gc_time / #recent_frames) * 1000
    
    print(string.format("Recent %d frames: %.1fms avg, %.1f updates/frame avg", 
      #recent_frames, avg_frame_time, avg_updates))
    print(string.format("Memory: %.1f MB current, %.2f KB/frame delta, GC: %.3fms avg", 
      max_memory_usage / 1024, total_memory_delta / #recent_frames, avg_gc_time))
  end
  
  -- System breakdown
  print("\nSystem breakdown (total time):")
  local sorted_systems = {}
  for name, data in pairs(self.system_totals) do
    if data.calls > 0 then
      table.insert(sorted_systems, {name = name, data = data})
    end
  end
  table.sort(sorted_systems, function(a, b) return a.data.total_time > b.data.total_time end)
  
  for i, system in ipairs(sorted_systems) do
    if i <= 10 then -- Top 10 systems
      local avg_time = (system.data.total_time / system.data.calls) * 1000
      print(string.format("  %s: %.1fms total, %.2fms avg, %.2fms max (%d calls)", 
        system.name, system.data.total_time * 1000, avg_time, system.data.max_time * 1000, system.data.calls))
    end
  end
  
  print("========================\n")
end

-- Reset all profiling data
function Profiler:reset()
  self.current_frame = {}
  self.frame_history = {}
  self.section_stack = {}
  self.total_frames = 0
  self.slow_frames = 0
  self.system_totals = {}
  self.last_report_time = love.timer.getTime()
  
  for _, system in ipairs(PROFILER_CONFIG.detailed_systems) do
    self.system_totals[system] = {total_time = 0, calls = 0, max_time = 0}
  end
  
  print("Profiler data reset")
end

-- Force garbage collection and measure the time
function Profiler:force_gc()
  local start_time = love.timer.getTime()
  local memory_before = collectgarbage("count")
  collectgarbage("collect")
  local gc_time = love.timer.getTime() - start_time
  local memory_after = collectgarbage("count")
  
  print(string.format("Forced GC: %.2fms, freed %.1f KB (%.1f MB -> %.1f MB)", 
    gc_time * 1000, memory_before - memory_after, memory_before / 1024, memory_after / 1024))
end

return Profiler
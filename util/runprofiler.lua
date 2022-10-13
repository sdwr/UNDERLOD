love.USE_PROFILER = false

function Run_Profiler()
  love.frame = love.frame + 1

  if love.frame%10 == 0 then
    love.profiler.start()
  else
    love.profiler.stop()
  end
  if love.frame%300 == 0 then
    love.report = love.profiler.report(10)
    love.profiler.reset()
  end
end

function Draw_Profiler()
    love.graphics.print(love.report or "Please wait...")
end
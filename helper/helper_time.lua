past_time = 0
delta_time = 0
intervals = {}

function set_interval(delay, intervalfunction)
    local id = -1

    for _, interval in ipairs(intervals) do
        if interval.stopped then
            id = _
            break
        end
    end

    if id == -1 then
        id = #intervals + 1
    end
    
    local interval = {
        intervalfunction = intervalfunction,
        startat = love.timer.getTime(),
        delay = delay,
        looped = 1,
        stopped = false
    }

    intervals[id] = interval

    return id
end



function stop_interval(id)
    intervals[id].stopped = true
end



function run_intervals()
    for _, interval in ipairs(intervals) do
        if love.timer.getTime() - interval.startat > interval.delay * interval.looped and not interval.stopped then
            interval.intervalfunction()
            interval.looped = interval.looped + 1
        end
    end
end
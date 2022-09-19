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



waits = {}

function wait(delay, waitfunction)
    local id = -1

    for _, wait in ipairs(waits) do
        if wait.finished then
            id = _
            break
        end
    end

    if id == -1 then
        id = #waits + 1
    end
    
    local wait = {
        waitfunction = waitfunction,
        startat = love.timer.getTime(),
        delay = delay,
        finished = false
    }

    waits[id] = wait
end

function run_waits()
    for _, wait in ipairs(waits) do
        if love.timer.getTime() - wait.startat > wait.delay and not wait.finished then
            wait.waitfunction()
            wait.finished = true
        end
    end
end
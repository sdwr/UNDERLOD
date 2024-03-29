Helper.Time = {}

Helper.Time.delta_time = 0

Helper.Time.time = love.timer.getTime()



Helper.Time.intervals = {}

function Helper.Time:set_interval(delay, intervalfunction, number_of_loops)
    local id = -1

    for _, interval in ipairs(Helper.Time.intervals) do
        if interval.stopped then
            id = _
            break
        end
    end

    if id == -1 then
        id = #Helper.Time.intervals + 1
    end
    
    local interval = {
        intervalfunction = intervalfunction,
        startat = Helper.Time.time,
        delay = delay,
        looped = 1,
        stopped = false,
        number_of_loops = number_of_loops or -1
    }

    Helper.Time.intervals[id] = interval

    return id
end

function Helper.Time:stop_interval(id)
    if id <= #Helper.Time.intervals and id > 0 then
        Helper.Time.intervals[id].stopped = true
    end
end

function Helper.Time:stop_all_intervals()
    for i, interval in ipairs(Helper.Time.intervals) do
        Helper.Time.intervals[i].stopped = true
    end
end

function Helper.Time:run_intervals()
    for _, interval in ipairs(Helper.Time.intervals) do
        if Helper.Time.time - interval.startat > interval.delay * interval.looped and not interval.stopped then
            interval.intervalfunction()
            interval.looped = interval.looped + 1
            if interval.number_of_loops ~= -1 and interval.looped > interval.number_of_loops then
                interval.stopped = true
            end
        end
    end
end



Helper.Time.waits = {}

function Helper.Time:wait(delay, waitfunction)
    local id = -1

    for _, wait in ipairs(Helper.Time.waits) do
        if wait.finished then
            id = _
            break
        end
    end

    if id == -1 then
        id = #Helper.Time.waits + 1
    end
    
    local wait = {
        waitfunction = waitfunction,
        startat = Helper.Time.time,
        delay = delay,
        finished = false
    }

    Helper.Time.waits[id] = wait
    return id
end

function Helper.Time:run_waits()
    for _, wait in ipairs(Helper.Time.waits) do
        if Helper.Time.time - wait.startat > wait.delay and not wait.finished then
            wait.waitfunction()
            wait.finished = true
        end
    end
end

function Helper.Time:cancel_wait(id)
    if id <= #Helper.Time.waits and id > 0 then
        Helper.Time.waits[id].finished = true
    end
end

function Helper.Time:stop_all_waits()
    for i, wait in ipairs(Helper.Time.waits) do
        Helper.Time.waits[i].finished = true
    end
end
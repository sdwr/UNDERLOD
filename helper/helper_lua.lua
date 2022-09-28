function is_in_list(list, element)
    for i, value in ipairs(list) do
        if element == value then
            return true
        end
    end

    return false
end

function find_in_list(list, element)
    for i, value in ipairs(list) do
        if element == value then
            return i
        end
    end

    return -1
end

function find_in_list(list, element, findfunction)
    for i, value in ipairs(list) do
        if element == findfunction(value) then
            return i, value
        end
    end

    return -1, -1
end

function get_random(lower, upper)
    return math.random() * (upper - lower) - lower
end
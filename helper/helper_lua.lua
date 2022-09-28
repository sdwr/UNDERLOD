function is_in_list(list, element_input)
    for i, element in ipairs(list) do
        if element_input == element then
            return true
        end
    end

    return false
end

function find_in_list(list, element_input)
    for i, element in ipairs(list) do
        if element_input == element then
            return i
        end
    end

    return -1
end
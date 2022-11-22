local M = {}

M.string_split = function(target, separator)
    if separator == nil then
        separator = "%s"
    end
    local results = {}
    for match in string.gmatch(target, "([^" .. separator .. "]+)") do
        table.insert(results, match)
    end
    return results
end

M.string_at = function(target, position)
    return string.sub(target, position, position)
end

M.remove_tail = function(target, tail)
    local target_tail = string.sub(target, #target - #tail + 1, #target)
    if target_tail == tail then
        return string.sub(target, 1, #target - #tail)
    end
    return target
end


return M

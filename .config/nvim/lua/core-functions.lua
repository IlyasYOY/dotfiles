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

return M

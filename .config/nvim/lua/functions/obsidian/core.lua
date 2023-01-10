local M = {}

---Searches for the link under the specified charater
---@param str string string to search in
---@param num number number of the cheracter to search the link around
---@return string? name of the link
function M.find_link(str, num)
    if #str <= 4 then
        return nil
    end

    local start
    local ending
    for i = 2, #str do
        local last_items = string.sub(str, i - 1, i)
        if last_items == "[[" then
            start = i + 1
        end
        if last_items == "]]" then
            ending = i - 2
        end
        if start ~= nil and ending ~= nil then
            if start <= num and ending >= num then
                return string.sub(str, start, ending)
            end
        end
    end
end

return M

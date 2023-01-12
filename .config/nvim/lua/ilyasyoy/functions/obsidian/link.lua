---Simple link representation
---@class ilyasyoy.obsidian.Link
---@field public name string
---@field public alias string?
---@field public header string?
local Link = {}
Link.__index = Link

--- link constructor
---@param name string
---@param alias string?
---@param header string?
---@return ilyasyoy.obsidian.Link
function Link:new(name, alias, header)
    return setmetatable({
        name = name,
        alias = alias,
        header = header,
    }, self)
end

--- creates link from string like name, name|alias, name#title
---@param str string
---@return ilyasyoy.obsidian.Link?
function Link.from_string(str)
    -- TODO: add link validation
    if #str == 0 then
        return nil
    end

    local function split_on(to_split, index)
        local before = string.sub(to_split, 1, index - 1)
        local after = string.sub(to_split, index + 1, -1)
        return before, after
    end

    local sharp_index = string.find(str, "#")
    if sharp_index then
        local name, header = split_on(str, sharp_index)
        return Link:new(name, nil, header)
    end

    local pipe_index = string.find(str, "|")
    if pipe_index then
        local name, alias = split_on(str, pipe_index)
        return Link:new(name, alias, nil)
    end

    return Link:new(str)
end

---Searches for the link under the specified charater
---@param str string string to search in
---@param index number number of the cheracter to search the link around
---@return ilyasyoy.obsidian.Link? name of the link
function Link.find_link_at(str, index)
    if #str < 4 then
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
            if start <= index and ending >= index then
                local link_string = string.sub(str, start, ending)
                return Link.from_string(link_string)
            end
        end
    end
end

return Link

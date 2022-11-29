local M = {}

-- Dumps a table to a string. Useful for debug.
--- @param o table a table to dump
--- @return string
local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

M.dump = dump

-- Merges lines to a text blob
--- @param lines string[] array of lines to merge
--- @param separator string? a string to be used as separator
--- @return string
local function merge_lines(lines, separator)
    if separator == nil then
        separator = "\n"
    end

    local result = ""
    for i, line in ipairs(lines) do
        result = result .. line .. separator
    end

    return result
end

M.merge_lines = merge_lines

-- Splits string using separator.
--- @param target string to split
--- @param separator string?
--- @return string[]
local function string_split(target, separator)
    if separator == nil then
        separator = "%s"
    end

    local results = {}
    for match in string.gmatch(target, "([^" .. separator .. "]+)") do
        table.insert(results, match)
    end

    return results
end

M.string_split = string_split

-- Gets string element at element using position.
--- @param target string
--- @param position number
--- @return string
local function string_at(target, position)
    return string.sub(target, position, position)
end

M.string_at = string_at

-- Strips tail if present.
--- @param target string
--- @param tail string
--- @return string
local function strip_tail(target, tail)
    local target_tail = string.sub(target, #target - #tail + 1, #target)
    if target_tail == tail then
        return string.sub(target, 1, #target - #tail)
    end
    return target
end

M.strip_tail = strip_tail

-- Returns text lines selected in V mode.
--- @return string[]
local function get_selected_lines()
    local start_position = vim.fn.getpos("'<")
    local end_position = vim.fn.getpos("'>")
    local buffer_number = vim.api.nvim_get_current_buf()

    if end_position[3] == 2147483647 and start_position[3] == 1 then
        return vim.api.nvim_buf_get_lines(buffer_number, start_position[2] - 1, end_position[2], false)
    else
        return vim.api.nvim_buf_get_text(buffer_number, start_position[2] - 1, start_position[3] - 1,
            end_position[2] - 1
            , end_position[3] - 1, {})
    end
end

M.get_selected_lines = get_selected_lines

-- Returns text selected in V mode.
--- @return string
local function get_selected_text()
    local lines = get_selected_lines()
    return merge_lines(lines)
end

M.get_selected_text = get_selected_text

-- Reloads module.
--- @param name string
local function reload_module(name)
    if package.loaded[name] == nil then
        package.loaded[name] = nil
        print("module '" .. name .. "' is being reloaded")
    end
    return require(name)
end

M.reload_module = reload_module

return M

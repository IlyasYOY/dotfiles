local Path = require "plenary.path"

local M = {}

local function resolve_dotfiles_plenary_path()
    local path_from_env = vim.fn.environ().ILYASYOY_DOTFILES_DIR
    return Path:new(path_from_env)
end

function M.find_first_present_file(fileList)
    for _, filePath in ipairs(fileList) do
        if vim.fn.filereadable(filePath) == 1 then
            return filePath
        end
    end
    return nil
end

function M.get_dotfiles_dir()
    return resolve_dotfiles_plenary_path():expand()
end

function M.resolve_relative_to_dotfiles_dir(path)
    local plenary_path = resolve_dotfiles_plenary_path()
    return (plenary_path / path):expand()
end

---Merges strings to a text blob
---@param strings string[] array of strings to merge
---@param separator string? a string to be used as separator, default is '\n'
---@return string
local function string_merge(strings, separator)
    if separator == nil then
        separator = "\n"
    end

    local result = ""
    for number, line in ipairs(strings) do
        result = result .. line
        -- add separator in case this is not last iteration
        if number ~= #strings then
            result = result .. separator
        end
    end

    return result
end

M.string_merge = string_merge

---Splits string using separator.
---@param target string to split
---@param separator string
---@return string[]
function M.string_split(target, separator)
    return vim.split(target, separator, { plain = true, trimempty = true })
end

-- Check if str starts with prefix.
---@param str string string to have prefix.
---@param prefix string? prefix itself.
---@param plain boolean? default is false
---@return boolean
local function string_has_prefix(str, prefix, plain)
    if plain == nil then
        plain = false
    end
    if prefix == nil then
        return false
    end

    local index = string.find(str, prefix, 1, plain)

    return index == 1
end

M.string_has_prefix = string_has_prefix

-- Check if str ends with prefix.
---@param str string
---@param suffix string?
---@param plain boolean? default is false
---@return boolean
local function string_has_suffix(str, suffix, plain)
    if suffix == nil then
        return false
    end

    return string_has_prefix(string.reverse(str), string.reverse(suffix), plain)
end

M.string_has_suffix = string_has_suffix

-- Strips tail if present.
-- Works on plain strings.
---@param target string
---@param tail string
---@return string
function M.string_strip_suffix(target, tail)
    if not string_has_suffix(target, tail, true) then
        return target
    end

    return string.sub(target, 1, #target - #tail)
end

-- Strips prefix if present.
-- Works on plain strings.
---@param target string
---@param prefix string
---@return string
function M.string_strip_prefix(target, prefix)
    if not string_has_prefix(target, prefix, true) then
        return target
    end

    return string.sub(target, #prefix + 1, #target)
end

return M

local core = require "functions.core"
local Path = require "plenary.path"

---Simple file wrapper
---@class ilyasyoy.obsidian.File
---@field public path string
---@field public name string
---@field private _path Path
local File = {}
File.__index = File

--- lists files from path matching glob pattern
---@param path string
---@param glob string
---@return ilyasyoy.obsidian.File[]
function File.list(path, glob)
    -- TODO: Speed this up a bit. Maybe I should use `plenary.scandir`.
    local files_as_text = vim.fn.globpath(path, glob)
    local files_pathes = core.string_split(files_as_text, "\n")
    local results = core.array_map(files_pathes, function(file_path)
        return File:new(file_path)
    end)
    return results
end

--- creates file wrapper
---@param path string
---@return ilyasyoy.obsidian.File
function File:new(path)
    local path_split = core.string_split(path, "/")
    local name_with_extension = path_split[#path_split]
    local name_with_extension_split =
        core.string_split(name_with_extension, ".")
    name_with_extension_split[#name_with_extension_split] = nil

    return setmetatable({
        path = path,
        name = core.string_merge(name_with_extension_split, "."),
        _path = Path:new(path),
    }, self)
end

---Reads file content as string
---@return string?
function File:read()
    return self._path:read()
end

return File

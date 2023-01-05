local core = require "functions.core"

-- Simple file wrapper
--- @class File
--- @field public path string
--- @field public name string
local File = {}

-- lists files from path matching glob pattern
--- @param path string
--- @param glob string
--- @return File[]
function File.list(path, glob)
    -- TODO: Speed this up a bit. Maybe I should use `plenary.scandir`.
    local files_as_text = vim.fn.globpath(path, glob)
    local files_pathes = core.string_split(files_as_text, "\n")
    local results = core.array_map(files_pathes, function(file_path)
        return File:new(file_path)
    end)
    return results
end

-- creates file wrapper
--- @param path string
--- @return File
function File:new(path)
    self.__index = self
    local file = setmetatable({}, self)

    local path_split = core.string_split(path, "/")
    local name_with_extension = path_split[#path_split]
    local name_with_extension_split =
        core.string_split(name_with_extension, ".")
    name_with_extension_split[#name_with_extension_split] = nil

    file.path = path
    file.name = core.string_merge(name_with_extension_split, ".")

    return file
end

return File

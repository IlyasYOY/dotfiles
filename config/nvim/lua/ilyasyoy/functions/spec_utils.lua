local Path = require "plenary.path"
local core = require "ilyasyoy.functions.core"

local M = {}

---@class ilyasyoy.spec_utils.Path
---@field public path Path path to the directory

--- Creates empty directory per test
---@return ilyasyoy.spec_utils.Path
function M.temp_dir_fixture()
    local result = {}

    before_each(function()
        local tmp_file_name = "/tmp/lua-" .. core.uuid()
        result.path = Path:new(tmp_file_name)
        if not result.path:mkdir() then
            error "cannot create temp file"
        end
    end)

    after_each(function()
        os.execute("rm -rf " .. result.path:expand())
    end)

    return result
end

---@generic T
---@param list T[]
---@param size number
function M.assert_list_size(list, size)
    assert.are.equal(size, #list, "wrong number of etries")
end

---@param template ilyasyoy.obsidian.File
---@param name string?
---@param path string?
function M.assert_file(template, name, path)
    assert.are.equal(name, template.name, "wrong file name")
    assert.are.equal(path, template.path, "wrong file path")
end

assert.list_size = M.assert_list_size
assert.file = M.assert_file

return M

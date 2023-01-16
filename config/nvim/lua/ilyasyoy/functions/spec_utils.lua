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

return M

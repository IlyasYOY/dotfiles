local Path = require "plenary.path"
local core = require "functions.core"

local M = {}

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

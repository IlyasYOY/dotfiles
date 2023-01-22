local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt

local s = ls.snippet
local f = ls.function_node

local function create_package()
    return f(function()
        local core = require "ilyasyoy.functions.core"

        local file_dir = core.current_working_file_dir()
        local splitted = core.string_split(file_dir, "/java/")
        local package_dir = splitted[#splitted]
        if not package_dir then
            return ""
        end

        return string.gsub(package_dir, "/", ".")
    end)
end

return {
    s(
        "package",
        fmt("package {};", {
            create_package(),
        })
    ),
}
local ls = require "luasnip"

local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node

local function create_package()
    return f(function()
        local core = require "coredor"

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

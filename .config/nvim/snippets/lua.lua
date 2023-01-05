local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node

local function rep_replacing(node_index, pattern, substitution)
    return f(function(arguments)
        local first_argument = arguments[1][1]
        return string.gsub(first_argument, pattern, substitution)
    end, { node_index })
end

local function rep_last_split(node_index, pattern)
    return f(function(arguments)
        local first_argument = arguments[1][1]
        local splitted = vim.split(first_argument, pattern, {})
        return splitted[#splitted] or first_argument
    end, { node_index })
end

local module_split_regex = "[%./]"

return {
    s(
        "lreq",
        fmt('local {} = require "{}"', {
            c(2, {
                rep_last_split(1, module_split_regex),
                rep_replacing(1, module_split_regex, "_"),
            }),
            i(1, "module"),
        })
    ),
    s(
        "cls",
        fmt(
            [[
    local {} = {}
    function {}:new()
        self.__index = self
        local this = setmetatable({{}}, self)
        {}
        return this
    end
    ]],
            {
                i(1, "Class"),
                i(2, "{}"),
                rep(1),
                i(0),
            }
        )
    ),
}

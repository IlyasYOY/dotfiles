local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node

local function sanitize_for_lua(text)
    return string.gsub(text, "[^%a%d_]", "_")
end

local function rep_replacing(node_index, pattern, substitution)
    return f(function(arguments)
        local first_argument = arguments[1][1]
        return sanitize_for_lua(
            string.gsub(first_argument, pattern, substitution)
        )
    end, { node_index })
end

local function rep_last_split(node_index, pattern)
    return f(function(arguments)
        local first_argument = arguments[1][1]
        local splitted = vim.split(first_argument, pattern, {})
        return sanitize_for_lua(splitted[#splitted] or first_argument)
    end, { node_index })
end

return {
    s(
        "lreq",
        fmt('local {} = require "{}"', {
            c(2, {
                rep_last_split(1, "[%./]"),
                rep_replacing(1, "[%./]", "_"),
            }),
            i(1, "module"),
        })
    ),
    s(
        "cls",
        fmt(
            [[
    local {} = {}
    {}.__index = {}
    function {}:new()
        local this = setmetatable({{}}, self)
        {}
        return this
    end
    ]],
            {
                i(1, "Class"),
                i(2, "{}"),
                rep(1),
                rep(1),
                rep(1),
                i(0),
            }
        )
    ),
    s(
        "func",
        fmt(
            [[
    function {}({})
        {}
    end
    ]],
            {
                i(1),
                i(2),
                i(3, "return"),
            }
        )
    ),
}

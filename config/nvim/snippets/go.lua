local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local ilyasyoy_snippets = require "ilyasyoy.snippets"

return {
    s("today", ilyasyoy_snippets.current_date()),
    s(
        "errp",
        fmt([[
        if err != nil {{
            return {}, err
        }}
        ]], {
            i(0, "nil"),
        })
    ),
}

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
        "trun",
        fmt(
            [[
        t.Run("{}", func(t *testing.T) {{
            {}
        }})
        ]],
            {
                i(1, "test case"),
                i(0, ""),
            }
        )
    ),
    s(
        "errp",
        fmt(
            [[
        if err != nil {{
            panic({})
        }}
        ]],
            {
                i(0, "err"),
            }
        )
    ),
    s(
        "errr",
        fmt(
            [[
        if err != nil {{
            return nil, {}
        }}
        ]],
            {
                i(0, "err"),
            }
        )
    ),
}

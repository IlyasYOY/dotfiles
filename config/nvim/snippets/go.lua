local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local ilyasyoy_snippets = require "ilyasyoy.snippets"

local function rep_capitalize(node_index)
    return f(function(arguments)
        local first_argument = arguments[1][1]
        local splitted = string.sub(first_argument, 1, 1):upper()
            .. string.sub(first_argument, 2, #first_argument)
        return splitted
    end, { node_index })
end

return {
    s("today", ilyasyoy_snippets.current_date()),
    s(
        "withfopts",
        fmt(
            [[
            func With{}(o *{}) error {{
                return nil
            }}
            ]],
            {
                i(1, "Param"),
                i(2, "opts"),
            }
        )
    ),
    s(
        "fopts",
        fmt(
            [[
            type {} struct{{
            }}

            type {}Configurer func(*{}) error

            func new{}(cs ...{}Configurer) (*{}, error) {{
                o := new({})
                for _, c := range cs {{
                    err := c(o)
                    if err != nil {{
                        return nil, err
                    }}
                }}
                return o, nil
            }}
            ]],
            {
                i(1, "opts"),
                rep(1),
                rep(1),
                rep_capitalize(1),
                rep(1),
                rep(1),
                rep(1),
            }
        )
    ),
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
}

local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep
local t = ls.text_node
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

local function in_func()
    local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
    if not ok then
        return false
    end
    local current_node = ts_utils.get_node_at_cursor()
    if not current_node then
        return false
    end
    local expr = current_node

    while expr do
        if
            expr:type() == "function_declaration"
            or expr:type() == "method_declaration"
        then
            return true
        end
        expr = expr:parent()
    end
    return false
end

local function is_in_test_file()
    local filename = vim.fn.expand "%:p"
    return vim.endswith(filename, "_test.go")
end

local function is_in_test_function()
    return is_in_test_file() and in_func()
end

local in_test_fn = {
    show_condition = is_in_test_function,
    condition = is_in_test_function,
}

return {
    s("ctxb", t "ctx := context.Background()"),
    s(
        "ctxb",
        t [[
            ctx, cancel := context.WithCancel(context.Background())
            cancel()
        ]]
    ),
    s(
        { trig = "gocmp", dscr = "Create an if block comparing with cmp.Diff" },
        fmt(
            [[
        if diff := cmp.Diff({}, {}); diff != "" {{
        	t.Errorf("(-want +got):\\n%s", diff)
        }}
      ]],
            {
                i(1, "want"),
                i(2, "got"),
            }
        ),
        in_test_fn
    ),
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
        ),
        in_test_fn
    ),
    s(
        "reqne",
        fmt(
            [[
        require.NoError(t, {})
        ]],
            {
                i(0, "error"),
            }
        ),
        in_test_fn
    ),
    s(
        "reqei",
        fmt(
            [[
        require.ErrorIs(t, {}, {})
        ]],
            {
                i(1, "expected"),
                i(0, "actual"),
            }
        ),
        in_test_fn
    ),
    s(
        "req",
        fmt(
            [[
        require.Equal(t, {}, {})
        ]],
            {
                i(1, "expected"),
                i(0, "actual"),
            }
        ),
        in_test_fn
    ),
    s(
        "reqv",
        fmt(
            [[
        require.EqualValues(t, {}, {})
        ]],
            {
                i(1, "expected"),
                i(0, "actual"),
            }
        ),
        in_test_fn
    ),
    s(
        "aeq",
        fmt(
            [[
        assert.Equal(t, {}, {})
        ]],
            {
                i(1, "expected"),
                i(0, "actual"),
            }
        ),
        in_test_fn
    ),
    s(
        "aeqv",
        fmt(
            [[
        assert.EqualValues(t, {}, {})
        ]],
            {
                i(1, "expected"),
                i(0, "actual"),
            }
        ),
        in_test_fn
    ),
}

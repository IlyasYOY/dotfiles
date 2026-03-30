local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local postfix = require("luasnip.extras.postfix").postfix
local rep = require("luasnip.extras").rep
local t = ls.text_node
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node

local function in_func()
    local current_node = vim.treesitter.get_node()
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

local in_fn = {
    show_condition = in_func,
    condition = in_func,
}

return {
    s("ctxb", t "ctx := context.Background()"),
    s(
        "ctxbc",
        t [[
            ctx, cancel := context.WithCancel(context.Background())
            defer cancel()
        ]]
    ),
    -- https://github.com/ray-x/go.nvim/blob/41a18f0c05534c375bafec7ed05cdb409c4abcc6/lua/snips/go.lua#L375-L387
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
    s(
        "trun",
        fmt(
            [[
        t.Run({}, func(t *testing.T) {{
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
                i(0, "gotErr"),
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
                i(1, "want"),
                i(0, "got"),
            }
        ),
        in_test_fn
    ),
    s(
        { trig = "test", dscr = "Go test function" },
        fmt(
            [[
func Test{}(t *testing.T) {{
    {}
}}
]],
            { i(1, "Name"), i(0, "") }
        ),
        { show_condition = is_in_test_file, condition = is_in_test_file }
    ),
    s(
        "if",
        fmt(
            [[
if {} {{
    {}
}}
]],
            { i(1, "condition"), i(0) }
        ),
        in_fn
    ),
    s(
        "ife",
        fmt(
            [[
if {} {{
    {}
}} else {{
    {}
}}
]],
            { i(1, "condition"), i(2), i(0) }
        ),
        in_fn
    ),
    s(
        "for",
        fmt(
            [[
for {} {{
    {}
}}
]],
            { i(1), i(0) }
        ),
        in_fn
    ),
    s(
        { trig = "fori", dscr = "Index-based for loop" },
        fmt(
            [[
for {} := 0; {} < {}; {}++ {{
    {}
}}
]],
            { i(1, "i"), rep(1), i(2, "n"), rep(1), i(0) }
        ),
        in_fn
    ),
    s(
        { trig = "fork", dscr = "Range over keys" },
        fmt(
            [[
for {} := range {} {{
    {}
}}
]],
            { i(1, "k"), i(2, "iter"), i(0) }
        ),
        in_fn
    ),
    s(
        { trig = "forv", dscr = "Range over values" },
        fmt(
            [[
for _, {} := range {} {{
    {}
}}
]],
            { i(1, "v"), i(2, "iter"), i(0) }
        ),
        in_fn
    ),
    s(
        { trig = "forkv", dscr = "Range over key-value pairs" },
        fmt(
            [[
for {}, {} := range {} {{
    {}
}}
]],
            { i(1, "k"), i(2, "v"), i(3, "iter"), i(0) }
        ),
        in_fn
    ),
    s("rt", fmt("return {}", { i(0) }), in_fn),
}

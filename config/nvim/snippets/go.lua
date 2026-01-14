local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local t = ls.text_node
local s = ls.snippet
local i = ls.insert_node

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
}

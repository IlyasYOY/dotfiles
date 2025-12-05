local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local t = ls.text_node
local s = ls.snippet
local i = ls.insert_node

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
        "ctxbc",
        t [[
            ctx, cancel := context.WithCancel(context.Background())
            cancel()
        ]]
    ),
    s(
        { trig = "gocmpass", dscr = "Create an if block comparing with cmp.Diff and assert" },
        fmt(
            [[
                assert.Empty(t, cmp.Diff({}, {}), "(-want +got)")
            ]],
            {
                i(1, "want"),
                i(2, "got"),
            }
        ),
        in_test_fn
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
        "req",
        fmt(
            [[
        require.Equal(t, {}, {})
        ]],
            {
                i(1, "want"),
                i(0, "got"),
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
                i(1, "want"),
                i(0, "got"),
            }
        ),
        in_test_fn
    ),
    s(
        "rlen",
        fmt(
            [[
        require.Len(t, {}, {})
        ]],
            {
                i(1, "got"),
                i(0, "len"),
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
                i(1, "want"),
                i(0, "got"),
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
                i(1, "want"),
                i(0, "got"),
            }
        ),
        in_test_fn
    ),
    s(
        "alen",
        fmt(
            [[
        assert.Len(t, {}, {})
        ]],
            {
                i(1, "got"),
                i(0, "len"),
            }
        ),
        in_test_fn
    ),
}

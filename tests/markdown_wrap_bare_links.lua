local repo_root = vim.fn.getcwd()

vim.g.maplocalleader = ","
vim.opt.runtimepath:prepend(repo_root .. "/config/nvim")
vim.cmd "filetype plugin on"

local function assert_lines(expected, message)
    local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(vim.deep_equal(actual, expected), message)
end

local function open_markdown_buffer(lines)
    vim.cmd "enew!"
    vim.bo.buftype = ""
    vim.bo.bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd "file test.md"
    vim.cmd "setfiletype markdown"
end

local function toggle_list_item(row)
    vim.api.nvim_win_set_cursor(0, { row, 0 })
    vim.cmd "normal ,t"
end

open_markdown_buffer {
    "See https://example.com, ./notes/today.md, ../docs/plan.md, and /tmp/demo.md.",
    "",
    "`./inline-code.md` should stay untouched.",
    "[./already-linked.md](./already-linked.md) should stay untouched.",
}

vim.cmd "MarkdownWrapBareLinks"

assert_lines(
    {
        "See <https://example.com>, [./notes/today.md](./notes/today.md), "
            .. "[../docs/plan.md](../docs/plan.md), and "
            .. "[/tmp/demo.md](/tmp/demo.md).",
        "",
        "`./inline-code.md` should stay untouched.",
        "[./already-linked.md](./already-linked.md) should stay untouched.",
    },
    "MarkdownWrapBareLinks should wrap URLs and file paths while skipping protected ranges"
)

local first_pass = vim.api.nvim_buf_get_lines(0, 0, -1, false)

vim.cmd "MarkdownWrapBareLinks"

assert_lines(
    first_pass,
    "MarkdownWrapBareLinks should be idempotent on a second pass"
)

open_markdown_buffer {
    "---",
    "url: https://example.com",
    "file: ./notes/today.md",
    "closing: ../docs/plan.md",
    "...",
    "",
    "See https://example.com and ./notes/today.md.",
}

vim.cmd "MarkdownWrapBareLinks"

assert_lines({
    "---",
    "url: https://example.com",
    "file: ./notes/today.md",
    "closing: ../docs/plan.md",
    "...",
    "",
    "See <https://example.com> and [./notes/today.md](./notes/today.md).",
}, "MarkdownWrapBareLinks should skip YAML frontmatter")

open_markdown_buffer { "Buy milk" }

toggle_list_item(1)
assert_lines({ "- Buy milk" }, "Toggle should turn plain text into a list item")

toggle_list_item(1)
assert_lines(
    { "- [ ] Buy milk" },
    "Toggle should turn a list item into an unchecked task"
)

toggle_list_item(1)
assert_lines(
    { "- [x] Buy milk" },
    "Toggle should turn an unchecked task into a checked task"
)

toggle_list_item(1)
assert_lines(
    { "Buy milk" },
    "Toggle should turn a checked task back into plain text"
)

open_markdown_buffer { "  Buy milk" }

toggle_list_item(1)
toggle_list_item(1)
toggle_list_item(1)
toggle_list_item(1)
assert_lines(
    { "  Buy milk" },
    "Toggle should preserve indentation when removing a list marker"
)

vim.cmd.qall { bang = true }

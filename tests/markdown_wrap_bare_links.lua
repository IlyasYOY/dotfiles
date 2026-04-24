local repo_root = vim.fn.getcwd()

vim.opt.runtimepath:prepend(repo_root .. "/config/nvim")
vim.cmd "filetype plugin on"

local function assert_lines(expected, message)
    local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(vim.deep_equal(actual, expected), message)
end

local function open_markdown_buffer(lines)
    vim.cmd.enew()
    vim.bo.buftype = ""
    vim.bo.bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd "file test.md"
    vim.cmd "setfiletype markdown"
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

vim.cmd.qall { bang = true }

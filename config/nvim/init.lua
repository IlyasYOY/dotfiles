-- TODO: Remove this after: https://github.com/neovim/neovim/issues/31675
vim.hl = vim.highlight
vim.opt.guicursor = "n:block-Cursor"

-- Here I load files with custom settings for machine.
-- This lua file is hidden from VCS, so I can do tricky stuff there.
pcall(require, "ilyasyoy.hidden")

require "ilyasyoy.plugins"

require "ilyasyoy.global"
require "ilyasyoy"

vim.api.nvim_create_user_command("AIChatCodeEdit", function(opts)
    vim.cmd("'<,'>!aichat --code --role \\%nvim-code-edit\\% " .. opts.args)
end, { range = true, nargs = 1 })

vim.api.nvim_create_user_command(
    "AIChatFixGrammar",
    "'<'>!aichat --code --role \\%fix-grammar\\%",
    {
        range = true,
    }
)

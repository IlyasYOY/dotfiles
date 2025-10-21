-- TODO: Remove this after: https://github.com/neovim/neovim/issues/31675
vim.hl = vim.highlight
vim.opt.guicursor = "n:block-Cursor"

-- Here I load files with custom settings for machine.
-- This lua file is hidden from VCS, so I can do tricky stuff there.
pcall(require, "ilyasyoy.hidden")

require "ilyasyoy.plugins"

require "ilyasyoy.global"
require "ilyasyoy"
require "ilyasyoy.aichat"


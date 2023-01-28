require "ilyasyoy"

require "ilyasyoy.plugins"

require "ilyasyoy.setups.colors"
require "ilyasyoy.global"

require "ilyasyoy.obsidian"
require "ilyasyoy.mapping"

-- Run all setups!!! (they are stored at lua/ilyasyoy/setups)
-- NOTE: should replace with lazy loading?

require "ilyasyoy.setups.nvim-luapad"

require "ilyasyoy.setups.nvim-tree"
require "ilyasyoy.setups.lualine"

require "ilyasyoy.setups.neogit"
require "ilyasyoy.setups.gitsigns"
require "ilyasyoy.setups.git-link"

require "ilyasyoy.setups.telescope"
require "ilyasyoy.setups.treesitter"
require "ilyasyoy.setups.todo-comments"

require "ilyasyoy.setups.luasnip"
require "ilyasyoy.setups.nvim-cmp"

require "ilyasyoy.setups.dap"
require "ilyasyoy.setups.lsp"
require "ilyasyoy.setups.lsp-java"
require "ilyasyoy.setups.lsp-lua"
require "ilyasyoy.setups.null-ls"
require "ilyasyoy.setups.symbols-outline"

require "ilyasyoy.setups.mason"


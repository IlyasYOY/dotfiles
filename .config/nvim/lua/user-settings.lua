local mapping = require('map-functions')

local map_terminal = mapping.map_terminal

-- Terminal commands
map_terminal("<Esc>", "<C-\\><C-n>")

vim.g.netrw_banner = 0 -- Now we won't have bloated top of the window 
vim.g.netrw_liststyle = 3 -- Now it will be a tree view  
vim.g.netrw_bufsettings = 'nu nobl'

vim.cmd("source ~/.vimrc")

vim.cmd("colorscheme gruvbox")



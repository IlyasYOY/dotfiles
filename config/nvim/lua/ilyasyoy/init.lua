vim.cmd "source ~/.vimrc"

vim.g.netrw_banner = 0 -- Now we won't have bloated top of the window
vim.g.netrw_liststyle = 3 -- Now it will be a tree view
vim.g.netrw_bufsettings = "nu nobl"

vim.cmd "highlight WinSeparator guibg=None"

vim.o.spelllang = "ru_ru,en_us"
vim.o.spellfile = vim.fn.expand "~/.config/nvim/spell/custom.utf-8.add"
vim.o.winborder = "rounded"

vim.diagnostic.config { virtual_text = true }

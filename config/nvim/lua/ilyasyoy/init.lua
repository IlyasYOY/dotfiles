vim.cmd "source ~/.vimrc"

vim.g.netrw_banner = 0 -- Now we won't have bloated top of the window
vim.g.netrw_liststyle = 3 -- Now it will be a tree view
vim.g.netrw_bufsettings = "nu nobl"

vim.opt.laststatus = 3
vim.cmd "highlight WinSeparator guibg=None"

if vim.fn.has "mac" == 1 then
    vim.keymap.set(
        "n",
        "gx",
        '<cmd>call jobstart(["open", expand("<cfile>")], {"detach": v:true})<cr>',
        { silent = true }
    )
elseif vim.fn.has "unix" == 1 then
    vim.keymap.set(
        "n",
        "gx",
        '<cmd>call jobstart(["xdg-open", expand("<cfile>")], {"detach": v:true})<cr>',
        { silent = true }
    )
else
    vim.keymap.set(
        "n",
        "gx",
        '<cmd>lua print("Error: gx is not supported on this OS!")<cr>',
        { silent = true }
    )
end

vim.opt.spelllang = "ru_ru,en_us"
vim.opt.spellfile = vim.fn.expand "~/.config/nvim/spell/custom.utf-8.add"

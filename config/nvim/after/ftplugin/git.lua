vim.opt_local.foldmethod = "syntax"
vim.opt_local.foldenable = true
vim.opt_local.foldlevel = 0
vim.opt_local.foldlevelstart = 0

vim.keymap.set(
    "n",
    "<localleader>rs",
    [[<cmd>execute ':Git reset --soft ' . expand('<cWORD>') <CR>]],
    {
        buffer = true,
    }
)

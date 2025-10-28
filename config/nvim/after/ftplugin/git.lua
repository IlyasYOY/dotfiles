-- for now it's better to use this way
-- a lot of stuff was marked to fold correctly in syntax file
vim.opt_local.foldmethod = "syntax"

vim.keymap.set(
    "n",
    "<localleader>rs",
    [[<cmd>execute ':Git reset --soft ' . expand('<cWORD>') <CR>]],
    {
        buffer = true,
    }
)

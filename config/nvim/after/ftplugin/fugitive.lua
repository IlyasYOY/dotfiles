vim.keymap.set("n", "dt", ":Gtabedit <Plug><cfile><Bar>Gvdiffsplit<CR>", {
    buffer = true,
})

vim.keymap.set(
    "n",
    "<localleader>rs",
    [[<cmd>execute ':Git reset --soft ' . expand('<cWORD>') <CR>]],
    {
        buffer = true,
    }
)

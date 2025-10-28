vim.api.nvim_buf_set_keymap(
    0,
    "n",
    "<leader>lclR",
    "<Cmd>lua vim.lsp.codelens.refresh { bufnr = 0 }<CR>",
    { silent = true }
)

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    "<leader>lclr",
    "<Cmd>lua vim.lsp.codelens.run()<CR>",
    { silent = true }
)

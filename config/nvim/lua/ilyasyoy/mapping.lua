vim.keymap.set("n", "<leader><leader>sc", function()
    vim.opt_local.spell = not (vim.opt_local.spell:get())
    vim.notify("spell: " .. tostring(vim.o.spell))
end, { desc = "Toggle spell check" })

vim.keymap.set(
    "t",
    "<Esc>",
    "<C-\\><C-n>",
    { desc = "Use Escape to go from terminal to Normal mode" }
)

-- Dev things

vim.keymap.set(
    "n",
    "<leader><leader>S",
    "<cmd>mksession!<CR>",
    { desc = "create session file" }
)

vim.keymap.set(
    "n",
    "<leader>Dt",
    "<cmd>diffthis<CR>",
    { desc = "diff this file" }
)

vim.keymap.set(
    "n",
    "<leader>Do",
    "<cmd>diffoff<CR>",
    { desc = "diff off file" }
)

vim.keymap.set(
    "n",
    "<leader><leader>mt",
    "<cmd>make! test<CR>",
    { desc = "run make test" }
)

vim.keymap.set("n", "<leader>D", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostic virtual_lines" })

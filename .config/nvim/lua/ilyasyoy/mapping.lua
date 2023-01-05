vim.keymap.set({ "s" }, "<leader>y", function()
    local core = require "functions.core"
    local text = core.get_selected_text()
    vim.fn.setreg("+", text)
end)

vim.keymap.set("n", "<leader>sc", function()
    vim.opt_local.spell = not (vim.opt_local.spell:get())
    vim.notify("spell: " .. tostring(vim.o.spell))
end, { desc = "Toggle [s]pell [c]heck" })

vim.keymap.set(
    "t",
    "<Esc>",
    "<C-\\><C-n>",
    { desc = "Use Escape to go from terminal to Normal mode" }
)

-- Dev things

vim.keymap.set("n", "<leader><leader>s", "<cmd>source %<CR>")

vim.keymap.set("n", "<leader><leader>t", "<Plug>PlenaryTestFile", {
    desc = "Runs Plenary [t]ests for file",
})

vim.keymap.set("n", "<leader><leader>T", "<cmd>PlenaryBustedDirectory .<CR>", {
    desc = "Runs Plenary [T]ests in cwd",
})

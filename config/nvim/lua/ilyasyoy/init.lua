vim.cmd "source ~/.vimrc"

vim.g.netrw_banner = 0 -- Now we won't have bloated top of the window
vim.g.netrw_liststyle = 3 -- Now it will be a tree view
vim.g.netrw_bufsettings = "nu nobl"

vim.cmd "highlight WinSeparator guibg=None"

vim.o.spelllang = "ru_ru,en_us"
vim.o.spellfile = vim.fn.expand "~/.config/nvim/spell/custom.utf-8.add"
vim.o.winborder = "rounded"

vim.diagnostic.config { virtual_text = true }

-- Dev things

vim.keymap.set("n", "<leader><leader>d", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostic virtual_lines" })

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
    "<leader><leader>S",
    "<cmd>mksession!<CR>",
    { desc = "create session file" }
)

-- Create a variable to track the state
vim.g.auto_refresh_enabled = false

-- Function to toggle the behavior
local function toggle_auto_refresh()
    if vim.g.auto_refresh_enabled then
        vim.api.nvim_clear_autocmds { group = "AutoRefresh" }
        vim.g.auto_refresh_enabled = false
        print "Auto refresh disabled"
    else
        vim.o.autoread = true
        vim.api.nvim_create_augroup("AutoRefresh", { clear = true })
        vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
            group = "AutoRefresh",
            command = "if mode() != 'c' | checktime | endif",
            pattern = "*",
        })
        vim.g.auto_refresh_enabled = true
        print "Auto refresh enabled"
    end
end

vim.keymap.set("n", "<leader><leader>ar", toggle_auto_refresh, {
    noremap = true,
    silent = false,
    desc = "Toggle auto refresh of files",
})

vim.keymap.set("n", "<leader><leader>sc", function()
    vim.opt_local.spell = not (vim.opt_local.spell:get())
    vim.notify("spell: " .. tostring(vim.o.spell))
end, { desc = "Toggle spell check" })

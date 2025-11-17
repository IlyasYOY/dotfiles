vim.cmd "source ~/.vimrc"

vim.g.netrw_banner = 0    -- Now we won't have bloated top of the window
vim.g.netrw_liststyle = 3 -- Now it will be a tree view
vim.g.netrw_bufsettings = "nu nobl"

vim.cmd "highlight WinSeparator guibg=None"

vim.o.spelllang = "ru_ru,en_us"
vim.o.spellfile = vim.fn.expand "~/.config/nvim/spell/custom.utf-8.add"
vim.o.winborder = "rounded"

vim.diagnostic.config { virtual_text = true }

-- Dev things

vim.keymap.set("n", "<leader>D", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostic" })

vim.keymap.set("n", "<localleader>sc", function()
    vim.opt_local.spell = not (vim.opt_local.spell:get())
    vim.notify("spell: " .. tostring(vim.o.spell))
end, { desc = "Toggle spell check" })

vim.keymap.set("n", "<leader>cp", function()
    local path = vim.fn.expand "%:."
    path = "./" .. path
    vim.fn.setreg("+", path)
    vim.notify("Copied: " .. path)
end, { desc = "Copy relative file path to clipboard" })

vim.keymap.set("v", "<leader>cp", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
        "nx", -- 'n' for normal mode, 'x' to update '<' and '>' marks correctly
        false
    )
    local start_line = vim.fn.line "'<"
    local end_line = vim.fn.line "'>"
    local path = vim.fn.expand "%:."
    local link = path
    if start_line ~= end_line then
        link = link .. ":" .. start_line .. "-" .. end_line
    else
        link = link .. ":" .. start_line
    end
    path = "./" .. path
    vim.fn.setreg("+", link)
    vim.notify("Copied: " .. link)
end, { desc = "Copy relative file path with line numbers to clipboard" })

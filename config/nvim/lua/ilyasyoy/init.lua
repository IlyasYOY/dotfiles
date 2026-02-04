vim.cmd "source ~/.vimrc"

vim.opt.completeopt = { "fuzzy", "popup", "menu" }

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
    vim.notify("copied: " .. path)
end, { desc = "Copy relative file path to clipboard" })

vim.keymap.set("n", "<leader>cP", function()
    local abs_path = vim.fn.expand "%:p"
    vim.fn.setreg("+", abs_path)
    vim.notify("copied absolute path: " .. abs_path)
end, { desc = "Copy absolute file path to clipboard" })

vim.keymap.set("v", "<leader>cp", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
        "nx", -- 'n' for normal mode, 'x' to update '<' and '>' marks correctly
        false
    )
    local start_line = vim.fn.line "'<"
    local end_line = vim.fn.line "'>"
    local path = vim.fn.expand "%:."
    if start_line ~= end_line then
        path = path .. ":" .. start_line .. "-" .. end_line
    else
        path = path .. ":" .. start_line
    end
    path = "./" .. path
    vim.fn.setreg("+", path)
    vim.notify("copied: " .. path)
end, { desc = "Copy relative file path with line numbers to clipboard" })

vim.keymap.set("v", "<leader>cP", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
        "nx",
        false
    )
    local path = vim.fn.expand "%:p"
    local start_line = vim.fn.line "'<"
    local end_line = vim.fn.line "'>"
    if start_line ~= end_line then
        path = path .. ":" .. start_line .. "-" .. end_line
    else
        path = path .. ":" .. start_line
    end
    vim.fn.setreg("+", path)
    vim.notify("Copied: " .. path)
end, { desc = "Copy absolute file path with line numbers to clipboard" })

-- Monotask integration
local function run_monotask(path)
    path = path or "."
    local cmd = "monotask " .. vim.fn.shellescape(path)
    vim.cmd.Dispatch { "-compiler=make", cmd }
end

vim.api.nvim_create_user_command("Monotask", function(opts)
    run_monotask(opts.args ~= "" and opts.args or nil)
end, {
    nargs = "?",
    desc = "Run monotask on path (default: current dir) and populate quickfix",
})

vim.keymap.set("n", "<leader>mt", function()
    run_monotask()
end, { desc = "Run monotask on current directory" })

vim.keymap.set("n", "<leader>mT", function()
    run_monotask(vim.fn.expand "%")
end, { desc = "Run monotask on current file" })

vim.api.nvim_create_user_command("AIChatCodeEdit", function(opts)
    vim.cmd("'<,'>!aichat --code --role \\%nvim-code-edit\\% " .. opts.args)
end, {
    range = true,
    nargs = 1,
    desc = "Run AIChat code edit on the selected range with the provided arguments",
})

vim.keymap.set("v", "<leader>ce", function()
    local prompt = vim.fn.input "Write a prompt: "
    return ":AIChatCodeEdit " .. prompt .. "<CR>"
end, {
    expr = true,
    desc = "Edit code via AIChat",
})

vim.api.nvim_create_user_command(
    "AIChatFixGrammar",
    "'<'>!aichat --code --role \\%fix-grammar\\%",
    {
        range = true,
        desc = "Fix grammar using AIChat",
    }
)

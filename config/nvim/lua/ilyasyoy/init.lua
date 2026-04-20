-- Make sure to setup `mapleader` and `maplocalleader` before
-- registering plugins so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = ","

require "ilyasyoy.pack"

vim.o.autoread = true

vim.cmd "packadd nvim.difftool"
vim.cmd "packadd nvim.undotree"

vim.cmd "source ~/.vimrc"

vim.opt.completeopt = { "popup", "menu", "preview" }

vim.cmd "highlight WinSeparator guibg=None"

vim.o.spelllang = "ru_ru,en_us"
vim.o.spellfile = vim.fn.expand "~/.config/nvim/spell/custom.utf-8.add"
vim.o.winborder = "rounded"

vim.diagnostic.config { virtual_text = true }

-- Dev things

vim.keymap.set("n", "<leader>d", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostic" })

vim.keymap.set("n", "<localleader>sc", function()
    vim.opt_local.spell = not (vim.opt_local.spell:get())
    vim.notify("spell: " .. tostring(vim.opt_local.spell))
end, { desc = "Toggle spell check" })

local function get_current_path(absolute)
    local path
    local bufname = vim.api.nvim_buf_get_name(0)

    if vim.bo.filetype == "oil" then
        local ok, oil = pcall(require, "oil")
        if ok then
            path = oil.get_current_dir()
        end
    elseif
        vim.startswith(bufname, "fugitive:")
        and vim.fn.exists "*FugitivePath" == 1
    then
        path = vim.fn.FugitivePath(bufname)
    else
        path = vim.fn.expand "%:p"
    end

    if not path or path == "" then
        return nil
    end

    path = vim.fs.normalize(path)
    if absolute then
        return path
    end

    local cwd = vim.fs.normalize(vim.fn.getcwd())
    if path == cwd then
        return "./."
    end

    local cwd_prefix = cwd .. "/"
    if vim.startswith(path, cwd_prefix) then
        local relative_path = path:sub(#cwd_prefix + 1)
        return "./" .. relative_path
    end

    return path
end

local function copy_current_path(opts)
    opts = opts or {}

    if opts.with_line_numbers then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
            "nx", -- 'n' for normal mode, 'x' to update '<' and '>' marks correctly
            false
        )
    end

    local path = get_current_path(opts.absolute)
    if not path then
        vim.notify("nothing to copy", vim.log.levels.WARN)
        return
    end

    if opts.with_line_numbers then
        local start_line = vim.fn.line "'<"
        local end_line = vim.fn.line "'>"
        if start_line ~= end_line then
            path = path .. ":" .. start_line .. "-" .. end_line
        else
            path = path .. ":" .. start_line
        end
    end

    vim.fn.setreg("+", path)
    vim.notify("copied: " .. path)
end

vim.keymap.set("n", "<leader>cp", function()
    copy_current_path()
end, { desc = "Copy relative file path to clipboard" })

vim.keymap.set("n", "<leader>cP", function()
    copy_current_path { absolute = true }
end, { desc = "Copy absolute file path to clipboard" })

vim.keymap.set("v", "<leader>cp", function()
    copy_current_path { with_line_numbers = true }
end, { desc = "Copy relative file path with line numbers to clipboard" })

vim.keymap.set("v", "<leader>cP", function()
    copy_current_path { absolute = true, with_line_numbers = true }
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

-- Make sure to setup `mapleader` and `maplocalleader` before
-- registering plugins so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.g.firenvim_config = {
    globalSettings = {
        alt = "all",
    },
    localSettings = {
        [".*"] = {
            takeover = "never",
        },
    },
}

if vim.g.started_by_firenvim then
    vim.o.guifont = "GoMono Nerd Font:h18"
end

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

local function format_path_for_copy(path, absolute)
    if not path or path == "" then
        return nil
    end

    path = vim.fs.normalize(vim.fn.expand(path))
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

local function is_fugitive_status_buffer()
    return vim.bo.filetype == "fugitive"
        and vim.fn.exists "*fugitive#PorcelainCfile" == 1
end

local function get_fugitive_status_path_at_line(line)
    if not is_fugitive_status_buffer() then
        return nil
    end

    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local ok, path = pcall(function()
        vim.api.nvim_win_set_cursor(win, { line, 0 })
        return vim.fn["fugitive#PorcelainCfile"]()
    end)

    vim.api.nvim_win_set_cursor(win, cursor)

    if not ok or not path or path == "" then
        return nil
    end

    if
        vim.startswith(path, "fugitive:")
        and vim.fn.exists "*FugitivePath" == 1
    then
        local resolved_ok, resolved_path = pcall(vim.fn.FugitivePath, path)
        if resolved_ok and resolved_path ~= "" then
            path = resolved_path
        end
    end

    return path
end

local function parse_fugitive_hunk_header(line)
    local old_start, new_start = line:match "^@@ %-(%d+),?%d* %+(%d+),?%d* @@"

    return tonumber(old_start), tonumber(new_start)
end

local function get_fugitive_diff_line_number(target_line)
    local target_text = vim.api.nvim_buf_get_lines(
        0,
        target_line - 1,
        target_line,
        false
    )[1] or ""
    local first_char = target_text:sub(1, 1)

    if
        not target_text:match "^@@ "
        and first_char ~= " "
        and first_char ~= "+"
        and first_char ~= "-"
    then
        return nil
    end

    local hunk_line
    local old_line
    local new_line

    for line = target_line, 1, -1 do
        old_line, new_line = parse_fugitive_hunk_header(
            vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
        )

        if old_line and new_line then
            hunk_line = line
            break
        end
    end

    if not hunk_line then
        return nil
    end

    if target_line == hunk_line then
        return new_line
    end

    for line = hunk_line + 1, target_line do
        local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
            or ""
        local char = text:sub(1, 1)

        if char == "-" then
            if line == target_line then
                return old_line
            end
            old_line = old_line + 1
        elseif char == "+" then
            if line == target_line then
                return new_line
            end
            new_line = new_line + 1
        elseif char == " " then
            if line == target_line then
                return new_line
            end
            old_line = old_line + 1
            new_line = new_line + 1
        elseif line == target_line then
            return nil
        end
    end

    return nil
end

local function get_fugitive_status_selection_path(
    start_line,
    end_line,
    absolute
)
    local absolute_path
    local diff_lines = {}

    for line = start_line, end_line do
        local line_path =
            format_path_for_copy(get_fugitive_status_path_at_line(line), true)

        if line_path then
            if absolute_path and absolute_path ~= line_path then
                return nil, "selection spans multiple files"
            end

            absolute_path = line_path
        end

        local diff_line = get_fugitive_diff_line_number(line)
        if diff_line then
            table.insert(diff_lines, diff_line)
        end
    end

    local path = format_path_for_copy(absolute_path, absolute)
    if not path then
        return nil
    end

    if #diff_lines > 0 then
        local first_line = diff_lines[1]
        local last_line = diff_lines[#diff_lines]

        if first_line == last_line then
            path = path .. ":" .. first_line
        else
            path = path .. ":" .. first_line .. "-" .. last_line
        end
    end

    return path
end

local function get_current_path(absolute)
    local path
    local bufname = vim.api.nvim_buf_get_name(0)

    if vim.bo.filetype == "oil" then
        local ok, oil = pcall(require, "oil")
        if ok then
            path = oil.get_current_dir()
        end
    elseif is_fugitive_status_buffer() then
        path = get_fugitive_status_path_at_line(vim.fn.line ".")
    elseif
        vim.startswith(bufname, "fugitive:")
        and vim.fn.exists "*FugitivePath" == 1
    then
        path = vim.fn.FugitivePath(bufname)
    else
        path = vim.fn.expand "%:p"
    end

    return format_path_for_copy(path, absolute)
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

    local path
    local err

    if opts.with_line_numbers and is_fugitive_status_buffer() then
        local start_line = math.min(vim.fn.line "'<", vim.fn.line "'>")
        local end_line = math.max(vim.fn.line "'<", vim.fn.line "'>")
        path, err = get_fugitive_status_selection_path(
            start_line,
            end_line,
            opts.absolute
        )
    else
        path = get_current_path(opts.absolute)
    end

    if not path then
        vim.notify(err or "nothing to copy", vim.log.levels.WARN)
        return
    end

    if opts.with_line_numbers and not is_fugitive_status_buffer() then
        local start_line = math.min(vim.fn.line "'<", vim.fn.line "'>")
        local end_line = math.max(vim.fn.line "'<", vim.fn.line "'>")
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

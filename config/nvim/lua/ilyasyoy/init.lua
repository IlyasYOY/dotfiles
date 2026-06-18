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
vim.o.exrc = true

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

local function review_spell_errors(start_line, end_line)
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    local original_spell = vim.wo[win].spell
    local skipped_words = {}
    local state = {
        line = start_line,
        col = 0,
        reviewed = 0,
        saved = 0,
        skipped = 0,
        finished = false,
    }

    local function restore_spell()
        if vim.api.nvim_win_is_valid(win) then
            vim.wo[win].spell = original_spell
        end
    end

    local function is_active()
        return vim.api.nvim_win_is_valid(win)
            and vim.api.nvim_buf_is_valid(buf)
            and vim.api.nvim_win_get_buf(win) == buf
    end

    local function finish(message, level)
        if state.finished then
            return
        end

        state.finished = true
        restore_spell()
        vim.notify(
            string.format(
                "SpellFix: %s (reviewed %d, saved %d, skipped %d)",
                message,
                state.reviewed,
                state.saved,
                state.skipped
            ),
            level or vim.log.levels.INFO
        )
    end

    local function set_next_position(line, col, word)
        state.line = line
        state.col = col + math.max(#word, 1)
    end

    local function step()
        if state.finished then
            return
        end

        if not is_active() then
            finish("window changed", vim.log.levels.WARN)
            return
        end

        local line_count = vim.api.nvim_buf_line_count(buf)
        local range_end = math.min(end_line, line_count)

        while state.line <= range_end do
            local line = vim.api.nvim_buf_get_lines(
                buf,
                state.line - 1,
                state.line,
                false
            )[1] or ""

            if state.col > #line then
                state.line = state.line + 1
                state.col = 0
                goto continue
            end

            local col = math.min(state.col, #line)
            local bad = vim.api.nvim_win_call(win, function()
                vim.api.nvim_win_set_cursor(win, { state.line, col })
                return vim.fn.spellbadword()
            end)
            local word = bad[1]

            if word == "" then
                state.line = state.line + 1
                state.col = 0
            else
                local pos = vim.api.nvim_win_get_cursor(win)
                local word_line = pos[1]
                local word_col = pos[2]

                if word_line ~= state.line or word_col < state.col then
                    state.line = state.line + 1
                    state.col = 0
                    goto continue
                end

                if skipped_words[word] then
                    state.skipped = state.skipped + 1
                    set_next_position(word_line, word_col, word)
                else
                    local actions = {
                        { id = "fix", label = "Fix from suggestions" },
                        { id = "save", label = "Save spelling" },
                        { id = "skip", label = "Skip word" },
                        { id = "stop", label = "Stop" },
                    }

                    vim.ui.select(actions, {
                        prompt = string.format(
                            "SpellFix: %s (%s) at %d:%d",
                            word,
                            bad[2],
                            word_line,
                            word_col + 1
                        ),
                        format_item = function(item)
                            return item.label
                        end,
                    }, function(choice)
                        vim.schedule(function()
                            if not choice or choice.id == "stop" then
                                finish "stopped"
                                return
                            end

                            if not is_active() then
                                finish("window changed", vim.log.levels.WARN)
                                return
                            end

                            vim.api.nvim_win_set_cursor(
                                win,
                                { word_line, word_col }
                            )

                            local function continue_after_current(advance_word)
                                set_next_position(
                                    word_line,
                                    word_col,
                                    advance_word or word
                                )
                                vim.schedule(step)
                            end

                            if choice.id == "fix" then
                                local suggestions = vim.api.nvim_win_call(
                                    win,
                                    function()
                                        return vim.fn.spellsuggest(
                                            word,
                                            10,
                                            bad[2] == "caps"
                                        )
                                    end
                                )

                                if #suggestions == 0 then
                                    state.skipped = state.skipped + 1
                                    vim.notify(
                                        "SpellFix: no suggestions for " .. word,
                                        vim.log.levels.WARN
                                    )
                                    continue_after_current()
                                    return
                                end

                                local prompt = "SpellFix replacement for "
                                    .. word
                                vim.ui.select(
                                    suggestions,
                                    { prompt = prompt },
                                    function(suggestion)
                                        vim.schedule(function()
                                            if not suggestion then
                                                state.skipped = state.skipped
                                                    + 1
                                                continue_after_current()
                                                return
                                            end

                                            if not is_active() then
                                                finish(
                                                    "window changed",
                                                    vim.log.levels.WARN
                                                )
                                                return
                                            end

                                            vim.api.nvim_buf_set_text(
                                                buf,
                                                word_line - 1,
                                                word_col,
                                                word_line - 1,
                                                word_col + #word,
                                                { suggestion }
                                            )
                                            state.reviewed = state.reviewed + 1
                                            vim.api.nvim_win_set_cursor(
                                                win,
                                                { word_line, word_col }
                                            )
                                            continue_after_current(suggestion)
                                        end)
                                    end
                                )
                                return
                            end

                            local ok, err
                            if choice.id == "save" then
                                ok, err = pcall(
                                    vim.api.nvim_win_call,
                                    win,
                                    function()
                                        vim.api.nvim_win_set_cursor(
                                            win,
                                            { word_line, word_col }
                                        )
                                        vim.cmd.normal {
                                            "zg",
                                            bang = true,
                                        }
                                    end
                                )
                                if ok then
                                    state.saved = state.saved + 1
                                end
                            elseif choice.id == "skip" then
                                skipped_words[word] = true
                                state.skipped = state.skipped + 1
                                ok = true
                            end

                            if not ok then
                                finish(err, vim.log.levels.ERROR)
                                return
                            end

                            continue_after_current()
                        end)
                    end)
                    return
                end
            end

            ::continue::
        end

        if state.reviewed == 0 and state.saved == 0 and state.skipped == 0 then
            finish "no spelling errors"
        else
            finish "done"
        end
    end

    vim.wo[win].spell = true
    step()
end

vim.api.nvim_create_user_command("SpellFix", function(opts)
    review_spell_errors(opts.line1, opts.line2)
end, {
    range = "%",
    desc = "Review spelling errors with suggestion picker",
})

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

local function get_current_path(absolute)
    local path

    if vim.bo.filetype == "oil" then
        local ok, oil = pcall(require, "oil")
        if ok then
            path = oil.get_current_dir()
        end
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
    path = get_current_path(opts.absolute)

    if not path then
        vim.notify("nothing to copy", vim.log.levels.WARN)
        return
    end

    if opts.with_line_numbers then
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

-- OpenCode review integration
local function run_opencode_review(args)
    args = args or ""
    local cmd = "opencode run --command review"
    if args ~= "" then
        cmd = cmd .. " " .. args
    end

    if vim.fn.exists ":Dispatch" == 2 then
        vim.cmd.Dispatch { "-compiler=opencodereview", cmd }
        return
    end

    vim.cmd.compiler "opencodereview"
    if args == "" then
        vim.cmd.make()
    else
        vim.cmd.make { args }
    end
end

vim.api.nvim_create_user_command("OpenCodeReview", function(opts)
    run_opencode_review(opts.args)
end, {
    nargs = "*",
    desc = "Run OpenCode review and populate quickfix",
})

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

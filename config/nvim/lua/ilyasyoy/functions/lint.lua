local M = {}

--- Dispatch a lint command and remember it for later re-runs.
---
--- Stores both the command and the compiler in `vim.g[var_name]` so
--- that `setup_last_command` can replay with the correct compiler.
---
--- @param opts { var_name: string, compiler: string?, cmd: string }
function M.dispatch(opts)
    vim.g[opts.var_name] = { cmd = opts.cmd, compiler = opts.compiler }
    if opts.compiler then
        vim.cmd.Dispatch {
            "-compiler=" .. opts.compiler,
            opts.cmd,
        }
    else
        vim.cmd.Dispatch { opts.cmd }
    end
end

--- Create a `*LintLast` command and keymap for the current buffer.
---
--- @param opts { command: string, var_name: string, lang: string }
function M.setup_last_command(opts)
    vim.api.nvim_buf_create_user_command(0, opts.command, function()
        local last = vim.g[opts.var_name]
        if last then
            if last.compiler then
                vim.cmd.Dispatch {
                    "-compiler=" .. last.compiler,
                    last.cmd,
                }
            else
                vim.cmd.Dispatch { last.cmd }
            end
        else
            vim.notify(
                "No previous " .. opts.lang .. " lint command to run",
                vim.log.levels.WARN
            )
        end
    end, {
        desc = "run the last lint command again",
    })

    vim.keymap.set(
        "n",
        "<localleader>ll",
        "<cmd>" .. opts.command .. "<cr>",
        { desc = "run the last lint command again", buffer = true }
    )
end

--- Create a single lint command with optional keymap and dispatch.
---
--- @class LintCommandOpts
--- @field command string
--- @field var_name string
--- @field compiler? string
--- @field desc string
--- @field keymap? string
--- @field cmd? string
--- @field cmd_fn? fun(opts: table): string?
--- @field bang? boolean
--- @field nargs? string|number
---
--- @param opts LintCommandOpts
function M.setup_command(opts)
    vim.api.nvim_buf_create_user_command(0, opts.command, function(cmd_opts)
        local cmd
        if opts.cmd_fn then
            cmd = opts.cmd_fn(cmd_opts)
        else
            cmd = opts.cmd
        end
        if cmd then
            M.dispatch {
                var_name = opts.var_name,
                compiler = opts.compiler,
                cmd = cmd,
            }
        end
    end, {
        desc = opts.desc,
        bang = opts.bang,
        nargs = opts.nargs,
    })

    if opts.keymap then
        vim.keymap.set("n", opts.keymap, "<cmd>" .. opts.command .. "<cr>", {
            desc = opts.desc,
            buffer = true,
        })
    end
end

--- @class LintScopeOpts
--- @field cmd? string              static command string
--- @field cmd_fn? fun(opts: table): string?  dynamic builder
--- @field desc? string             command description
--- @field bang? boolean            allow ! modifier
--- @field bang_desc? string        description for the bang keymap
--- @field nargs? string|number     number of arguments
--- @field keymap? string           single-letter keymap suffix

--- @class LintSetupOpts
--- @field prefix string
--- @field var_name string
--- @field compiler? string
--- @field lang string
--- @field keymap_prefix? string
--- @field all? LintScopeOpts
--- @field file? LintScopeOpts
--- @field package? LintScopeOpts

--- Set up lint commands and keymaps for the current buffer.
---
--- Creates `{prefix}All`, `{prefix}Package`, `{prefix}File`, and
--- `{prefix}Last` commands (when the corresponding scope is provided),
--- along with buffer-local keymaps.
---
--- @param opts LintSetupOpts
function M.setup(opts)
    local kp = opts.keymap_prefix or "<localleader>l"

    local function create_scope(suffix, default_key, scope)
        if not scope then
            return
        end

        local command = opts.prefix .. suffix
        local desc = scope.desc or ("lint " .. suffix:lower())

        vim.api.nvim_buf_create_user_command(0, command, function(cmd_opts)
            local cmd
            if scope.cmd_fn then
                cmd = scope.cmd_fn(cmd_opts)
            else
                cmd = scope.cmd
            end
            if cmd then
                M.dispatch {
                    var_name = opts.var_name,
                    compiler = opts.compiler,
                    cmd = cmd,
                }
            end
        end, {
            desc = desc,
            bang = scope.bang,
            nargs = scope.nargs,
        })

        local key = scope.keymap or default_key
        vim.keymap.set("n", kp .. key, "<cmd>" .. command .. "<cr>", {
            desc = desc,
            buffer = true,
        })

        if scope.bang then
            vim.keymap.set(
                "n",
                kp .. key:upper(),
                "<cmd>" .. command .. "!<cr>",
                {
                    desc = scope.bang_desc or desc,
                    buffer = true,
                }
            )
        end
    end

    create_scope("All", "a", opts.all)
    create_scope("Package", "p", opts.package)
    create_scope("File", "f", opts.file)

    M.setup_last_command {
        command = opts.prefix .. "Last",
        var_name = opts.var_name,
        lang = opts.lang,
    }
end

return M

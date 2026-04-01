local M = {}

--- Dispatch a test command and remember it for later re-runs.
---
--- @param opts { var_name: string, compiler: string?, cmd: string }
function M.dispatch(opts)
    vim.g[opts.var_name] = opts.cmd
    if opts.compiler then
        vim.cmd.Dispatch {
            "-compiler=" .. opts.compiler,
            opts.cmd,
        }
    else
        vim.cmd.Dispatch { opts.cmd }
    end
end

--- Create a `*TestLast` command and keymap for the current buffer.
---
--- @param opts { command: string, var_name: string, compiler: string?, lang: string, keymap: string? }
function M.setup_last_command(opts)
    vim.api.nvim_buf_create_user_command(0, opts.command, function()
        local last = vim.g[opts.var_name]
        if last then
            if opts.compiler then
                vim.cmd.Dispatch {
                    "-compiler=" .. opts.compiler,
                    last,
                }
            else
                vim.cmd.Dispatch { last }
            end
        else
            vim.notify(
                "No previous " .. opts.lang .. " test command to run",
                vim.log.levels.WARN
            )
        end
    end, {
        desc = "run the last test command again",
    })

    vim.keymap.set(
        "n",
        opts.keymap or "<localleader>tl",
        "<cmd>" .. opts.command .. "<cr>",
        { desc = "run the last test command again", buffer = true }
    )
end

--- @class TestScopeOpts
--- @field cmd? string              static command string
--- @field cmd_fn? fun(opts: table): string?  dynamic builder
--- @field desc? string             command description
--- @field bang? boolean            allow ! modifier
--- @field bang_desc? string        description for the bang keymap
--- @field count? number            allow count prefix
--- @field nargs? string|number     number of arguments
--- @field keymap? string           single-letter keymap suffix

--- @class TestCurrentOpts : TestScopeOpts
--- @field test_file_pattern? string         pattern to detect test files
--- @field node_type? string                 treesitter node type
--- @field get_name_fn? fun(): string?       custom test name extractor
--- @field test_name_pattern? string         pattern the name must match
--- cmd_fn receives (test_name, cmd_opts) instead of (cmd_opts)

--- Set up test commands and keymaps for the current buffer.
---
--- Creates `{prefix}TestAll`, `{prefix}TestPackage`,
--- `{prefix}TestFile`, `{prefix}TestFunction`, and
--- `{prefix}TestLast` commands (when the corresponding scope is
--- provided), along with buffer-local keymaps.
---
--- @class TestSetupOpts
--- @field prefix string
--- @field var_name string
--- @field compiler? string
--- @field lang string
--- @field keymap_prefix? string
--- @field all? TestScopeOpts
--- @field file? TestScopeOpts
--- @field package? TestScopeOpts
--- @field current? TestCurrentOpts
---
--- @param opts TestSetupOpts
function M.setup(opts)
    local kp = opts.keymap_prefix or "<localleader>t"

    local function create_scope(suffix, default_key, scope)
        if not scope then
            return
        end

        local command = opts.prefix .. "Test" .. suffix
        local desc = scope.desc or ("run test " .. suffix:lower())

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
            count = scope.count,
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

    if opts.current then
        local cur = opts.current
        local command = opts.prefix .. "TestFunction"
        local desc = cur.desc or "run test for a function"

        vim.api.nvim_buf_create_user_command(0, command, function(cmd_opts)
            if cur.test_file_pattern then
                local cwf = vim.fn.expand "%:."
                if not string.find(cwf, cur.test_file_pattern) then
                    vim.notify "Not a test file"
                    return
                end
            end

            local name
            if cur.get_name_fn then
                name = cur.get_name_fn()
            elseif cur.node_type then
                local ts = require "ilyasyoy.functions.treesitter"
                name = ts.get_enclosing_name(cur.node_type)
            end

            if not name then
                vim.notify "Test function was not found"
                return
            end

            if
                cur.test_name_pattern
                and not name:match(cur.test_name_pattern)
            then
                return
            end

            local cmd
            if cur.cmd_fn then
                cmd = cur.cmd_fn(name, cmd_opts)
            else
                cmd = cur.cmd
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
            bang = cur.bang,
            count = cur.count,
            nargs = cur.nargs,
        })

        local key = cur.keymap or "t"
        vim.keymap.set("n", kp .. key, "<cmd>" .. command .. "<cr>", {
            desc = desc,
            buffer = true,
        })

        if cur.bang then
            vim.keymap.set(
                "n",
                kp .. key:upper(),
                "<cmd>" .. command .. "!<cr>",
                {
                    desc = cur.bang_desc or desc,
                    buffer = true,
                }
            )
        end
    end

    M.setup_last_command {
        command = opts.prefix .. "TestLast",
        var_name = opts.var_name,
        compiler = opts.compiler,
        lang = opts.lang,
        keymap = kp .. "l",
    }
end

return M

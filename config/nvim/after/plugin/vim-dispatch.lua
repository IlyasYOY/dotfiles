local core = require "ilyasyoy.functions.core"

--- Dispatch a lint command and remember it for later re-runs.
---
--- Stores both the command and the compiler in `vim.g[var_name]` so
--- that `setup_lint_last_command` can replay with the correct compiler.
---
--- @param opts { var_name: string, compiler: string?, cmd: string }
local function dispatch_lint(opts)
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
local function setup_lint_last_command(opts)
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
local function setup_lint_command(opts)
    vim.api.nvim_buf_create_user_command(0, opts.command, function(cmd_opts)
        local cmd
        if opts.cmd_fn then
            cmd = opts.cmd_fn(cmd_opts)
        else
            cmd = opts.cmd
        end
        if cmd then
            dispatch_lint {
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
--- @field cmd? string
--- @field cmd_fn? fun(opts: table): string?
--- @field desc? string
--- @field bang? boolean
--- @field bang_desc? string
--- @field nargs? string|number
--- @field keymap? string

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
--- @param opts LintSetupOpts
local function setup_lint(opts)
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
                dispatch_lint {
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

    setup_lint_last_command {
        command = opts.prefix .. "Last",
        var_name = opts.var_name,
        lang = opts.lang,
    }
end

--- Dispatch a test command and remember it for later re-runs.
---
--- @param opts { var_name: string, compiler: string?, cmd: string }
local function dispatch_test(opts)
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

--- @param test_command string|{ cmd: string, compiler: string? }|nil
--- @param default_compiler string?
--- @return string?, string?
local function resolve_test_command(test_command, default_compiler)
    if type(test_command) == "table" then
        return test_command.cmd, test_command.compiler
    end

    return test_command, default_compiler
end

--- Create a `*TestLast` command and keymap for the current buffer.
---
--- @param opts { command: string, var_name: string, compiler: string?, lang: string, keymap: string? }
local function setup_test_last_command(opts)
    vim.api.nvim_buf_create_user_command(0, opts.command, function()
        local last = vim.g[opts.var_name]
        if last then
            local cmd, compiler = resolve_test_command(last, opts.compiler)
            if compiler then
                vim.cmd.Dispatch {
                    "-compiler=" .. compiler,
                    cmd,
                }
            else
                vim.cmd.Dispatch { cmd }
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
--- @field cmd? string
--- @field cmd_fn? fun(opts: table): string|{ cmd: string, compiler: string? }?
--- @field desc? string
--- @field bang? boolean
--- @field bang_desc? string
--- @field count? number
--- @field nargs? string|number
--- @field keymap? string

--- @class TestCurrentOpts : TestScopeOpts
--- @field test_file_pattern? string
--- @field node_type? string
--- @field get_name_fn? fun(): string?
--- @field cmd_fn? fun(name: string, opts: table): string|{ cmd: string, compiler: string? }?
--- @field test_name_pattern? string

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
local function setup_test(opts)
    local kp = opts.keymap_prefix or "<localleader>t"

    local function create_scope(suffix, default_key, scope)
        if not scope then
            return
        end

        local command = opts.prefix .. "Test" .. suffix
        local desc = scope.desc or ("run test " .. suffix:lower())

        vim.api.nvim_buf_create_user_command(0, command, function(cmd_opts)
            local test_command
            if scope.cmd_fn then
                test_command = scope.cmd_fn(cmd_opts)
            else
                test_command = scope.cmd
            end
            local cmd, compiler =
                resolve_test_command(test_command, opts.compiler)
            if cmd then
                dispatch_test {
                    var_name = opts.var_name,
                    compiler = compiler,
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
                cur.test_name_pattern and not name:match(cur.test_name_pattern)
            then
                return
            end

            local test_command
            if cur.cmd_fn then
                test_command = cur.cmd_fn(name, cmd_opts)
            else
                test_command = cur.cmd
            end
            local cmd, compiler =
                resolve_test_command(test_command, opts.compiler)
            if cmd then
                dispatch_test {
                    var_name = opts.var_name,
                    compiler = compiler,
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

    setup_test_last_command {
        command = opts.prefix .. "TestLast",
        var_name = opts.var_name,
        compiler = opts.compiler,
        lang = opts.lang,
        keymap = kp .. "l",
    }
end

local function build_go_lint_cmd(path)
    local command = "run --fix=false --out-format=tab"
    local binary = "golangci-lint"
    local fallback_binary = "bin/golangci-lint"

    if
        vim.fn.filereadable(fallback_binary) == 1
        and vim.fn.executable(fallback_binary)
    then
        binary = fallback_binary
    end

    -- This version detection mirrors the none-ls golangci-lint builtin.
    local version = vim.system({ binary, "version" }, { text = true })
        :wait().stdout
    if
        version
        and (version:match "version v2.0." or version:match "version 2.0.")
    then
        command = "run --fix=false --show-stats=false --output.tab.path=stdout"
    elseif
        version
        and (version:match "version v2" or version:match "version 2")
    then
        command =
            "run --fix=false --show-stats=false --output.tab.path=stdout --path-mode=abs"
    end

    local config_path = core.find_first_present_file {
        "./.golangci.pipeline.yaml",
        "./.golangci.pipeline.yml",
        "./.golangci.yml",
        "./.golangci.yaml",
        core.resolve_relative_to_dotfiles_dir "./config/.golangci.yml",
    }

    return string.format(
        "%s %s --config %s %s",
        binary,
        command,
        config_path,
        path
    )
end

local function setup_go_linters()
    setup_lint {
        prefix = "GoLangCiLint",
        var_name = "last_go_lint_command",
        compiler = "make",
        lang = "Go",
        keymap_prefix = "<localleader>l",
        all = {
            cmd_fn = function()
                return build_go_lint_cmd "./..."
            end,
            desc = "lint all packages",
        },
        package = {
            cmd_fn = function()
                return build_go_lint_cmd(vim.fn.expand "%:p:h")
            end,
            desc = "lint current package",
        },
        file = {
            cmd_fn = function()
                return build_go_lint_cmd(vim.fn.expand "%")
            end,
            desc = "lint current file",
        },
    }
end

--- Extract Go build tags declared in the current buffer.
---
--- @return table string[] build tags found in the buffer
local function get_build_tags()
    local build_tags = {}
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    for _, line in ipairs(lines) do
        if core.string_has_prefix(line, "//go:build", true) then
            line = core.string_strip_prefix(line, "//go:build")
            local tags = core.string_split(line, " ")

            for _, tag in ipairs(tags) do
                if tag ~= "" then
                    table.insert(build_tags, tag)
                end
            end
        end
    end

    return build_tags
end

local function build_go_bench_cmd(path, names, opts)
    local base = "go test -fullpath -bench=" .. names
    local tags = get_build_tags()
    if #tags > 0 then
        base = base .. ' -tags "' .. table.concat(tags, " ") .. '"'
    end

    local cmd = { base }
    if opts.bang then
        table.insert(cmd, "-run=^$")
    end
    if opts.count ~= 0 then
        table.insert(cmd, "-count=" .. opts.count)
    end

    table.insert(cmd, path)
    return table.concat(cmd, " ")
end

local function setup_go_bench()
    setup_test {
        prefix = "GoBench",
        var_name = "last_go_bench_command",
        compiler = "make",
        lang = "Go benchmark",
        keymap_prefix = "<localleader>m",
        all = {
            cmd_fn = function(opts)
                return build_go_bench_cmd("./...", ".", opts)
            end,
            desc = "run all benchmarks",
            bang = true,
            bang_desc = "run all benchmarks (skip tests)",
            count = 0,
        },
        package = {
            cmd_fn = function(opts)
                return build_go_bench_cmd(vim.fn.expand "%:p:h", ".", opts)
            end,
            desc = "run package benchmarks",
            bang = true,
            bang_desc = "run package benchmarks (skip tests)",
            count = 0,
        },
        file = {
            cmd_fn = function(opts)
                return build_go_bench_cmd(vim.fn.expand "%:.", ".", opts)
            end,
            desc = "run file benchmarks",
            bang = true,
            bang_desc = "run file benchmarks (skip tests)",
            count = 0,
        },
        current = {
            node_type = "function_declaration",
            test_name_pattern = "^Benchmark",
            cmd_fn = function(bench_name, opts)
                local cwd = vim.fn.expand "%:p:h"
                return build_go_bench_cmd(cwd, "^" .. bench_name .. "$", opts)
            end,
            keymap = "b",
            desc = "run benchmark under cursor",
            bang = true,
            bang_desc = "run benchmark under cursor (skip tests)",
            count = 0,
        },
    }
end

local function build_go_test_cmd(path, opts)
    local base_go_test = "go test -fullpath"
    local tags = get_build_tags()
    if #tags > 0 then
        base_go_test = base_go_test
            .. ' -v -tags "'
            .. table.concat(tags, " ")
            .. '"'
    end

    local cmd_parts = { base_go_test }
    if opts.bang then
        table.insert(cmd_parts, "-short")
    end
    -- TODO: support count-aware keymaps separately from commands.
    if opts.count ~= 0 then
        table.insert(cmd_parts, "-count=" .. opts.count)
        table.insert(cmd_parts, "-shuffle=on")
    end

    table.insert(cmd_parts, path)
    return table.concat(cmd_parts, " ")
end

local function setup_go_test()
    setup_test {
        prefix = "Go",
        var_name = "last_go_test_command",
        compiler = "make",
        lang = "Go",
        all = {
            cmd_fn = function(opts)
                return build_go_test_cmd("./...", opts)
            end,
            desc = "run test for all packages",
            bang = true,
            bang_desc = "run test for all packages short",
            count = 0,
        },
        package = {
            cmd_fn = function(opts)
                return build_go_test_cmd(vim.fn.expand "%:p:h", opts)
            end,
            desc = "run test for a package",
            bang = true,
            bang_desc = "run test for a package short",
            count = 0,
        },
        file = {
            cmd_fn = function(opts)
                return build_go_test_cmd(vim.fn.expand "%:.", opts)
            end,
            desc = "run test for a file",
            bang = true,
            bang_desc = "run test for a file short",
            count = 0,
        },
        current = {
            test_file_pattern = "_test%.go$",
            node_type = "function_declaration",
            test_name_pattern = "^Test.+",
            cmd_fn = function(test_name, opts)
                local cwd = vim.fn.expand "%:p:h"
                return build_go_test_cmd(cwd .. " -run " .. test_name, opts)
            end,
            desc = "run test for a function",
            bang = true,
            bang_desc = "run test for a function",
            count = 0,
        },
    }
end

local function setup_go_build()
    vim.api.nvim_buf_create_user_command(0, "GoBuildAll", function()
        local tags = get_build_tags()
        local cmd = "go build"
        if #tags > 0 then
            cmd = cmd .. ' -tags "' .. table.concat(tags, " ") .. '"'
        end
        cmd = cmd .. " ./..."
        vim.cmd.Dispatch { "-compiler=make", cmd }
    end, { desc = "build all packages" })
    vim.keymap.set("n", "<localleader>ba", "<cmd>GoBuildAll<cr>", {
        desc = "build all packages",
        buffer = true,
    })

    vim.api.nvim_buf_create_user_command(0, "GoBuildPackage", function()
        local tags = get_build_tags()
        local cmd = "go build"
        if #tags > 0 then
            cmd = cmd .. ' -tags "' .. table.concat(tags, " ") .. '"'
        end
        cmd = cmd .. " ."
        vim.cmd.Dispatch { "-compiler=make", cmd }
    end, { desc = "build current package" })
    vim.keymap.set("n", "<localleader>bp", "<cmd>GoBuildPackage<cr>", {
        desc = "build current package",
        buffer = true,
    })

    vim.api.nvim_buf_create_user_command(0, "GoBuildFile", function()
        local tags = get_build_tags()
        local cmd = "go build"
        if #tags > 0 then
            cmd = cmd .. ' -tags "' .. table.concat(tags, " ") .. '"'
        end
        local file = vim.fn.expand "%:p"
        cmd = cmd .. " " .. file
        vim.cmd.Dispatch { "-compiler=make", cmd }
    end, { desc = "build current file" })
    vim.keymap.set("n", "<localleader>bf", "<cmd>GoBuildFile<cr>", {
        desc = "build current file",
        buffer = true,
    })
end

local function setup_go()
    setup_go_linters()
    setup_go_bench()
    setup_go_test()
    setup_go_build()
end

local function setup_java_linters()
    setup_lint_command {
        command = "JavaPMD",
        var_name = "last_java_lint_command",
        compiler = "make",
        desc = "runs pmd for current buffer",
        cmd_fn = function()
            return "pmd check --no-cache --dir % -R "
                .. core.resolve_relative_to_dotfiles_dir "config/pmd.xml"
        end,
    }

    setup_lint_command {
        command = "JavaCheckstyle",
        var_name = "last_java_lint_command",
        desc = "runs checkstyle for current buffer",
        cmd_fn = function()
            return "checkstyle % -c "
                .. core.resolve_relative_to_dotfiles_dir "config/checkstyle.xml"
        end,
    }

    setup_lint_last_command {
        command = "JavaLintLast",
        var_name = "last_java_lint_command",
        lang = "Java",
    }
end

local function setup_java_test()
    setup_test {
        prefix = "Java",
        var_name = "last_java_test_command",
        lang = "Java",
        all = {
            cmd = "./gradlew test --console=plain",
            desc = "run test for all packages",
        },
        file = {
            cmd_fn = function()
                return "./gradlew test --tests " .. vim.fn.expand "%:t:r"
            end,
            desc = "run test for a file",
        },
        current = {
            test_file_pattern = "Tests?%.java$",
            node_type = "method_declaration",
            cmd_fn = function(name)
                return "./gradlew test --tests "
                    .. vim.fn.expand "%:t:r"
                    .. "."
                    .. name
            end,
            desc = "run test for a function",
        },
    }
end

local function setup_java()
    setup_java_linters()
    setup_java_test()
end

local function setup_python_test()
    setup_test {
        prefix = "Python",
        var_name = "last_python_test_command",
        compiler = "pytest",
        lang = "Python",
        all = {
            cmd = "pytest",
            desc = "run test for all packages",
        },
        package = {
            cmd_fn = function()
                return "pytest " .. vim.fn.expand "%:p:h"
            end,
            desc = "run test for a package",
        },
        file = {
            cmd_fn = function()
                return "pytest " .. vim.fn.expand "%:."
            end,
            desc = "run test for a file",
        },
        current = {
            test_file_pattern = "test_.*%.py$",
            node_type = "function_definition",
            cmd_fn = function(name)
                return "pytest " .. vim.fn.expand "%:." .. "::" .. name
            end,
            desc = "run test for a function",
        },
    }
end

---@param node TSNode
---@return string?
local function get_js_test_name(node)
    if node:type() ~= "call_expression" then
        return
    end

    local func_node = node:field("function")[1]
    if not func_node then
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local func_name = vim.treesitter.get_node_text(func_node, bufnr)
    if func_name ~= "test" and func_name ~= "it" then
        return
    end

    local args = node:field "arguments"
    if not args or #args == 0 then
        return
    end

    local arguments_node = args[1]
    if arguments_node:named_child_count() == 0 then
        return
    end

    local name_node = arguments_node:named_child(0)
    if not name_node or name_node:type() ~= "string" then
        return
    end

    local raw_test_name = vim.treesitter.get_node_text(name_node, bufnr)
    local test_name = raw_test_name:gsub("^[\"']", ""):gsub("[\"']$", "")
    return test_name
end

local function find_js_test_name()
    local node = vim.treesitter.get_node()
    while node do
        local name = get_js_test_name(node)
        if name then
            return name
        end
        node = node:parent()
    end
end

local js_dependency_fields = {
    "dependencies",
    "devDependencies",
    "peerDependencies",
    "optionalDependencies",
}

---@return table?
local function read_nearest_package_json()
    local paths = vim.fs.find("package.json", {
        upward = true,
        path = vim.fn.expand "%:p:h",
        limit = 1,
    })
    local package_json_path = paths[1]
    if not package_json_path then
        return
    end

    local ok_read, lines = pcall(vim.fn.readfile, package_json_path)
    if not ok_read then
        return
    end

    local ok_decode, parsed = pcall(vim.json.decode, table.concat(lines, "\n"))
    if ok_decode and type(parsed) == "table" then
        return parsed
    end
end

---@param package_json table
---@param runner string
---@return boolean
local function package_json_mentions_runner(package_json, runner)
    for _, field in ipairs(js_dependency_fields) do
        local dependencies = package_json[field]
        if type(dependencies) == "table" and dependencies[runner] then
            return true
        end
    end

    local scripts = package_json.scripts
    if type(scripts) == "table" then
        for _, script in pairs(scripts) do
            if type(script) == "string" and script:find(runner, 1, true) then
                return true
            end
        end
    end

    return false
end

---@return "jest"|"vitest"
local function find_js_test_runner()
    local package_json = read_nearest_package_json()
    if not package_json then
        return "jest"
    end

    if package_json_mentions_runner(package_json, "vitest") then
        return "vitest"
    end
    if package_json_mentions_runner(package_json, "jest") then
        return "jest"
    end
    return "jest"
end

---@param scope "all"|"package"|"file"|"current"
---@param value string?
---@return { cmd: string, compiler: string? }
local function build_js_test_command(scope, value)
    local runner = find_js_test_runner()
    local base_command = "npx jest"
    local compiler = "jest"
    if runner == "vitest" then
        base_command = "npx vitest run"
        compiler = nil
    end

    if scope == "all" then
        return { cmd = base_command .. " .", compiler = compiler }
    end
    if scope == "current" then
        return {
            cmd = base_command .. " -t " .. vim.fn.shellescape(value),
            compiler = compiler,
        }
    end

    return {
        cmd = base_command .. " " .. vim.fn.shellescape(value),
        compiler = compiler,
    }
end

local function setup_javascript_test()
    setup_test {
        prefix = "JS",
        var_name = "last_js_test_command",
        lang = "JavaScript/TypeScript",
        all = {
            cmd_fn = function()
                return build_js_test_command "all"
            end,
            desc = "run test for all packages",
        },
        package = {
            cmd_fn = function()
                return build_js_test_command("package", vim.fn.expand "%:.:h")
            end,
            desc = "run test for a package",
        },
        file = {
            cmd_fn = function()
                return build_js_test_command("file", vim.fn.expand "%:.")
            end,
            desc = "run test for a file",
        },
        current = {
            test_file_pattern = "%.test%.[jt]sx?$",
            get_name_fn = find_js_test_name,
            cmd_fn = function(name)
                return build_js_test_command("current", name)
            end,
            desc = "run test for a function",
        },
    }
end

local function setup_proto_linters()
    vim.api.nvim_buf_create_user_command(
        0,
        "ProtoLint",
        "Dispatch -compiler=make protolint lint -reporter=unix %:.",
        {
            desc = "runs proto linter on current file",
        }
    )

    vim.api.nvim_buf_create_user_command(
        0,
        "ProtoLintBuf",
        "Dispatch -compiler=make buf lint %:.",
        {
            desc = "runs proto linter on current file",
        }
    )
end

local function run_make_target(target)
    if vim.fn.exists ":Make" > 0 then
        vim.cmd("Make -C %:p:h " .. target)
    else
        vim.cmd("make -C %:p:h " .. target)
    end
end

local function setup_make_targets()
    vim.api.nvim_buf_create_user_command(0, "MakeTargets", function()
        local parser = vim.treesitter.get_parser(0, "make")
        if not parser then
            vim.notify(
                "Treesitter make parser not available.",
                vim.log.levels.ERROR
            )
            return
        end

        local tree = parser:parse()[1]
        local root = tree:root()
        local query =
            vim.treesitter.query.parse("make", "(rule (targets) @targets)")
        local targets = {}
        for _, node in query:iter_captures(root, 0) do
            local text = vim.treesitter.get_node_text(node, 0)
            for target in text:gmatch "%S+" do
                targets[target] = true
            end
        end

        local target_list = {}
        for target, _ in pairs(targets) do
            table.insert(target_list, target)
        end

        if #target_list == 0 then
            vim.notify("No targets found in Makefile.", vim.log.levels.WARN)
            return
        end

        vim.ui.select(
            target_list,
            { prompt = "Select a make target:" },
            function(choice)
                if choice then
                    run_make_target(choice)
                end
            end
        )
    end, { desc = "run target from the current file" })

    vim.api.nvim_buf_create_user_command(0, "MakeTarget", function()
        local parser = vim.treesitter.get_parser(0, "make")
        if not parser then
            vim.notify(
                "Treesitter make parser not available.",
                vim.log.levels.ERROR
            )
            return
        end

        local cursor = vim.api.nvim_win_get_cursor(0)
        local node = vim.treesitter.get_node {
            bufnr = 0,
            pos = { cursor[1] - 1, cursor[2] },
        }
        while node and node:type() ~= "rule" do
            node = node:parent()
        end
        if not node then
            vim.notify(
                "Cursor is not within a make target rule.",
                vim.log.levels.WARN
            )
            return
        end

        local target_node = node:child(0)
        if target_node and target_node:type() == "targets" then
            local text = vim.treesitter.get_node_text(target_node, 0)
            local target = text:match "%S+"
            if target then
                run_make_target(target)
            else
                vim.notify(
                    "No valid target found in current rule.",
                    vim.log.levels.WARN
                )
            end
        else
            vim.notify(
                "Unable to parse target in current rule.",
                vim.log.levels.ERROR
            )
        end
    end, { desc = "run the current make target" })

    vim.keymap.set("n", "<localleader>T", ":MakeTargets<CR>", { buffer = true })
    vim.keymap.set("n", "<localleader>t", ":MakeTarget<CR>", { buffer = true })
end

local dispatch_group = vim.api.nvim_create_augroup("ilyasyoy-dispatch", {})

vim.api.nvim_create_autocmd("FileType", {
    group = dispatch_group,
    pattern = "go",
    callback = setup_go,
})

vim.api.nvim_create_autocmd("FileType", {
    group = dispatch_group,
    pattern = "java",
    callback = setup_java,
})

vim.api.nvim_create_autocmd("FileType", {
    group = dispatch_group,
    pattern = "python",
    callback = setup_python_test,
})

vim.api.nvim_create_autocmd("FileType", {
    group = dispatch_group,
    pattern = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },
    callback = setup_javascript_test,
})

vim.api.nvim_create_autocmd("FileType", {
    group = dispatch_group,
    pattern = "proto",
    callback = setup_proto_linters,
})

vim.api.nvim_create_autocmd("FileType", {
    group = dispatch_group,
    pattern = "make",
    callback = setup_make_targets,
})

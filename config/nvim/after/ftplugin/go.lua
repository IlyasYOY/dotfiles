local core = require "ilyasyoy.functions.core"
local lint_helpers = require "ilyasyoy.functions.lint"
local test_helpers = require "ilyasyoy.functions.test"
local toggle_helper = require "ilyasyoy.functions.toggle_test"

vim.opt_local.expandtab = false
vim.opt_local.spell = false
vim.bo.formatoptions = vim.bo.formatoptions .. "ro/"
vim.bo.formatprg = "gofumpt"

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    "<leader>lclR",
    "<Cmd>lua vim.lsp.codelens.refresh { bufnr = 0 }<CR>",
    { silent = true }
)
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    "<leader>lclr",
    "<Cmd>lua vim.lsp.codelens.run()<CR>",
    { silent = true }
)

vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceDotComments",
    [[%s/\/\/ \w* \.*$//gc]],
    { desc = "remove all comments repeating name of the struct" }
)
vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceMockeryRawMockWithNew",
    [[%s/&mocks\.\(\w*\){}/mocks.New\1(t)/gc]],
    { desc = "replace all mockery &mocks.Some with mocks.NewSome(t)" }
)
vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceMockeryOnWithExpect",
    [[%s/On(\_.\{-}"\(\w*\)",/EXPECT().\1(/gc]],
    { desc = "replace all mockery api with a new one" }
)
vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceRequireWithSuiteRequire",
    [[%s/require\.\(\w*\)(\(\w*\).T(), /\2.Require().\1(/gc]],
    { desc = "replace require with suite require" }
)
vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceAssertWithSuiteAssert",
    [[%s/assert\.\(\w*\)(\(\w*\).T(), /\2.\1(/gc]],
    { desc = "replace assert with suite assert" }
)

vim.api.nvim_buf_create_user_command(0, "GoFzfLuaInGoMod", function()
    local fzf = require "fzf-lua"
    fzf.live_grep {
        cwd = "~/go/pkg/mod",
    }
end, {
    desc = "find files in go mod",
})

vim.keymap.set("n", "<localleader>Dm", function()
    require("dap-go").debug_test()
end, {
    desc = "debug nearest test",
    buffer = true,
})

local function setup_linters()
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
            command =
                "run --fix=false --show-stats=false --output.tab.path=stdout"
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

    lint_helpers.setup {
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

--- Extract the Go build tags declared in the current buffer.
---
--- The function scans the whole buffer for lines that start with the
--- `//go:build` directive, removes that prefix, splits the remaining
--- expression on whitespace and returns each individual tag as an
--- element of a table.
---
--- @return table string[] of strings, each being a single build tag found in
--- the buffer. If no `//go:build` lines are present, an empty table is
--- returned.
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

local function setup_bench()
    test_helpers.setup {
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
    -- TODO: for now it works only for commands, I have to add the separate logic to support this in keymaps.
    if opts.count ~= 0 then
        table.insert(cmd_parts, "-count=" .. opts.count)
        table.insert(cmd_parts, "-shuffle=on")
    end

    table.insert(cmd_parts, path)
    return table.concat(cmd_parts, " ")
end

local function setup_test()
    test_helpers.setup {
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

local function setup_build()
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

local function setup_lsp_actions()
    vim.keymap.set("n", "<localleader>jl", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.rewrite.joinLines"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set("n", "<localleader>sl", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.rewrite.splitLines"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set("n", "<localleader>oi", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "source.organizeImports"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set({ "v", "s" }, "<localleader>em", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.extract.method"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set({ "v", "s" }, "<localleader>ef", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.extract.function"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set({ "v", "s" }, "<localleader>eC", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.extract.constant-all"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set({ "v", "s" }, "<localleader>ec", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.extract.constant"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set({ "v", "s" }, "<localleader>eV", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.extract.variable-all"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set({ "v", "s" }, "<localleader>ev", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.extract.variable"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set("n", "<localleader>fs", function()
        vim.lsp.buf.code_action {
            filter = function(x)
                return x.kind == "refactor.rewrite.fillStruct"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set("n", "<localleader>fS", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "refactor.rewrite.fillStruct"
            end,
        }
    end, {
        buffer = true,
    })

    vim.keymap.set("n", "<localleader>at", function()
        vim.lsp.buf.code_action {
            apply = true,
            filter = function(x)
                return x.kind == "source.addTest"
            end,
        }
    end, {
        buffer = true,
    })
end

setup_linters()
setup_bench()
setup_test()
setup_build()
setup_lsp_actions()

toggle_helper.setup {
    command = "GoToggleTest",
    rules = {
        {
            detect = "_test%.go$",
            gsub_pattern = "(%w+)_test%.go$",
            gsub_replacement = "%1.go",
        },
        {
            detect = "%.go$",
            gsub_pattern = "(%w+)%.go$",
            gsub_replacement = "%1_test.go",
        },
    },
}

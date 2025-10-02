vim.opt_local.expandtab = false
vim.opt_local.spell = false
vim.bo.formatoptions = vim.bo.formatoptions .. "ro/"

local last_test_command = nil

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
    {
        desc = "remove all comments repeating name of the struct",
    }
)

vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceMockeryRawMockWithNew",
    [[%s/&mocks\.\(\w*\){}/mocks.New\1(t)/gc]],
    {
        desc = "replace all mockery &mocks.Some with mocks.NewSome(t)",
    }
)

vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceMockeryOnWithExpect",
    [[%s/On(\_.\{-}"\(\w*\)",/EXPECT().\1(/gc]],
    {
        desc = "replace all mockery api with a new one",
    }
)

vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceRequireWithSuiteRequire",
    [[%s/require\.\(\w*\)(\(\w*\).T(), /\2.Require().\1(/gc]],
    {
        desc = "replace require with suite require",
    }
)

vim.api.nvim_buf_create_user_command(
    0,
    "GoReplaceAssertWithSuiteAssert",
    [[%s/assert\.\(\w*\)(\(\w*\).T(), /\2.\1(/gc]],
    {
        desc = "replace assert with suite assert",
    }
)

vim.api.nvim_buf_create_user_command(0, "GoFzfLuaInGoMod", function()
    local fzf = require "fzf-lua"
    fzf.live_grep {
        cwd = "~/go/pkg/mod",
    }
end, {
    desc = "find files in go mod",
})

--- Run a `go test` command for the given *path*.
--- The function builds the command line, adds the common flags
--- (`-short`, `-count=`) and finally dispatches it via `:Dispatch`.
--- @param path string   The path/argument that will be appended to the test
--- command. Typical values: "./...", cwd, or a file name.
--- @param opts table    Table supplied by the user‑command. It contains:
--- - `bang`  (boolean) – whether the command was invoked with `!`.
--- - `count` (integer) – the count supplied before the command
--- (e.g. `3GoTestFile`). A value of `0` means “no count”.
local function run_go_test(path, opts)
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

        local core = require "ilyasyoy.functions.core"
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

    local base_go_test = "go test -fullpath -failfast"
    if vim.fn.executable "gotestsum" then
        base_go_test = "gotestsum --format testname -- -fullpath -failfast"
    end

    local tags = get_build_tags()
    if #tags > 0 then
        -- I also add -v cause I want to see the output of hard tests as they go.
        base_go_test = base_go_test
            .. ' -v -tags "'
            .. table.concat(tags, " ")
            .. '"'
    end

    local cmd_parts = { base_go_test }
    if opts.bang then
        table.insert(cmd_parts, "-short")
    end
    -- TODO: for now it works only for commands, I have to add the separate
    -- logic to support this in keymaps.
    if opts.count ~= 0 then
        table.insert(cmd_parts, "-count=" .. opts.count)
        table.insert(cmd_parts, "-shuffle=on")
    end

    table.insert(cmd_parts, path)

    last_test_command = table.concat(cmd_parts, " ")
    vim.cmd.Dispatch { "-compiler=make", last_test_command }
end

vim.api.nvim_buf_create_user_command(0, "GoTestAll", function(opts)
    run_go_test("./...", opts)
end, {
    desc = "run test for all packages",
    bang = true,
    count = 0,
})

vim.keymap.set(
    "n",
    "<localleader>ta",
    "<cmd>GoTestAll<cr>",
    { desc = "run test for all packages", buffer = true }
)

vim.keymap.set(
    "n",
    "<localleader>tA",
    "<cmd>GoTestAll!<cr>",
    { desc = "run test for all packages short", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "GoTestPackage", function(opts)
    run_go_test(vim.fn.expand "%:p:h", opts)
end, {
    desc = "run test for a package",
    bang = true,
    count = 0,
})

vim.keymap.set(
    "n",
    "<localleader>tp",
    "<cmd>GoTestPackage<cr>",
    { desc = "run test for a package", buffer = true }
)

vim.keymap.set(
    "n",
    "<localleader>tP",
    "<cmd>GoTestPackage!<cr>",
    { desc = "run test for a package short", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "GoTestFile", function(opts)
    run_go_test(vim.fn.expand "%:.", opts)
end, {
    desc = "run test for a file",
    bang = true,
    count = 0,
})

vim.keymap.set(
    "n",
    "<localleader>tt",
    "<cmd>GoTestFile<cr>",
    { desc = "run test for a file", buffer = true }
)

vim.keymap.set(
    "n",
    "<localleader>tT",
    "<cmd>GoTestFile!<cr>",
    { desc = "run test for a file", buffer = true }
)

---@param node TSNode
---@return string?
local function get_test_name(node)
    if node:type() == "function_declaration" then
        local name_nodes = node:field "name"
        if #name_nodes == 0 then
            return
        end

        local name_node = name_nodes[1]
        if not name_node then
            return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        return vim.treesitter.get_node_text(name_node, bufnr)
    end
end

vim.api.nvim_buf_create_user_command(0, "GoTestFunction", function(opts)
    local cwf = vim.fn.expand "%:."
    local cwd = vim.fn.expand "%:p:h"

    if not string.find(cwf, "_test%.go$") then
        vim.notify "not a test file"
        return
    end

    local test_name = nil
    local node = vim.treesitter.get_node()
    while node do
        test_name = get_test_name(node)
        if test_name then
            break
        end
        node = node:parent()
    end

    if not test_name then
        vim.notify "test function was not found"
    elseif string.match(test_name, "^Test.+") then
        run_go_test(cwd .. " -run " .. test_name, opts)
    end
end, {
    desc = "run test for a function",
    bang = true,
    count = 0,
})

vim.keymap.set(
    "n",
    "<localleader>tf",
    "<cmd>GoTestFunction<cr>",
    { desc = "run test for a function", buffer = true }
)

vim.keymap.set(
    "n",
    "<localleader>tF",
    "<cmd>GoTestFunction!<cr>",
    { desc = "run test for a function short", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "GoTestLast", function(opts)
    if last_test_command then
        vim.cmd.Dispatch { "-compiler=make", last_test_command }
    else
        vim.notify("No previous test command to run", vim.log.levels.WARN)
    end
end, {
    desc = "run the last test command again",
    bang = true,
    count = 0,
})

vim.keymap.set(
    "n",
    "<localleader>tl",
    "<cmd>GoTestLast<cr>",
    { desc = "run the last test command again", buffer = true }
)

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

vim.api.nvim_buf_create_user_command(0, "GoToggleTest", function()
    local cwf = vim.fn.expand "%:."
    if string.find(cwf, "_test%.go$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)_test%.go$", "%1.go"))
    elseif string.find(cwf, "%.go$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)%.go$", "%1_test.go"))
    end
end, {
    desc = "toggle between test and source code",
})

vim.keymap.set("n", "<localleader>ot", "<cmd>GoToggleTest<cr>", {
    desc = "toggle between test and source code",
    buffer = true,
})

vim.keymap.set("n", "<localleader>dm", function()
    require("dap-go").debug_test()
end, {
    buffer = true,
})

vim.api.nvim_buf_create_user_command(0, "AIChatGoWrapErrors", function(opts)
    vim.cmd "'<,'>!aichat --code --role \\%nvim-go-wrap-errors\\% "
end, {
    range = true,
    desc = "Wrap Go errors in the selected region using AI Chat",
})

vim.keymap.set("v", "<localleader>we", function()
    return ":AIChatGoWrapErrors<CR>"
end, {
    expr = true,
    buffer = true,
    desc = "Wrap errors via AIChatGo",
})

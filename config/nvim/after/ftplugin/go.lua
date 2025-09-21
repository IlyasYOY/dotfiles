vim.opt_local.expandtab = false
vim.opt_local.spell = false
vim.bo.formatoptions = vim.bo.formatoptions .. "ro/"

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

-- get_build_tags fetches all build tags of the go file. Later they will be used to run tests from this file.
-- all commands for the buffer inherit tags of the buffer.
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
        .. table.concat(get_build_tags(), " ")
        .. '"'
end

vim.api.nvim_buf_create_user_command(0, "GoTestAll", function(opts)
    if opts.bang then
        vim.cmd.Dispatch { "-compiler=make", base_go_test .. " -short ./..." }
    else
        vim.cmd.Dispatch { "-compiler=make", base_go_test .. " ./..." }
    end
end, {
    desc = "run test for all packages",
    bang = true,
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
    if opts.bang then
        vim.cmd.Dispatch {
            "-compiler=make",
            base_go_test .. " -short " .. vim.fn.expand "%:p:h",
        }
    else
        vim.cmd.Dispatch {
            "-compiler=make",
            base_go_test .. " " .. vim.fn.expand "%:p:h",
        }
    end
end, {
    desc = "run test for a package",
    bang = true,
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
    local cwf = vim.fn.expand "%:."
    if opts.bang then
        vim.cmd.Dispatch {
            "-compiler=make",
            base_go_test .. " -short " .. cwf,
        }
    else
        vim.cmd.Dispatch { "-compiler=make", base_go_test .. " " .. cwf }
    end
end, {
    desc = "run test for a file",
    bang = true,
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

vim.api.nvim_buf_create_user_command(0, "GoTestFunction", function(opts)
    local cwf = vim.fn.expand "%:."

    local bufnr = vim.api.nvim_get_current_buf()
    if string.find(cwf, "_test%.go$") then
        local function_name = nil
        local node_under_cursor = vim.treesitter.get_node()
        local curr_node = node_under_cursor
        while curr_node do
            if curr_node:type() == "function_declaration" then
                local name_node = curr_node:field("name")[1]
                if name_node then
                    function_name =
                        vim.treesitter.get_node_text(name_node, bufnr)
                    break
                end
            end
            curr_node = curr_node:parent()
        end
        if not function_name then
            vim.notify "test function was not found"
        elseif string.match(function_name, "^Test.+") then
            if opts.bang then
                vim.cmd.Dispatch {
                    "-compiler=make",
                    base_go_test
                        .. " -short "
                        .. cwf
                        .. " -run "
                        .. function_name,
                }
            else
                vim.cmd.Dispatch {
                    "-compiler=make",
                    base_go_test .. " " .. cwf .. " -run " .. function_name,
                }
            end
        else
            vim.notify "function is not a test"
        end
    end
end, {
    desc = "run test for a function",
    bang = true,
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
    return "AIChatGoWrapErrors"
end, {
    expr = true,
    buffer = true,
    desc = "Wrap errors via AIChatGo",
})

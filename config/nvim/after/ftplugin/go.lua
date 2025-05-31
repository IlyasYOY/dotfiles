vim.opt_local.expandtab = false
vim.opt_local.spell = false

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

vim.api.nvim_buf_create_user_command(0, "GoTestAll", function(opts)
    if opts.bang then
        vim.cmd.Dispatch { "go test -short -fullpath ./..." }
    else
        vim.cmd.Dispatch { "go test -fullpath ./..." }
    end
end, {
    desc = "run test for all packages",
    bang = true,
})

vim.keymap.set(
    "n",
    "<leader>ta",
    "<cmd>GoTestAll<cr>",
    { desc = "run test for all packages", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "GoTestPackage", function(opts)
    if opts.bang then
        vim.cmd.Dispatch {
            "go test -short -fullpath " .. vim.fn.expand "%:p:h",
        }
    else
        vim.cmd.Dispatch {
            "go test -fullpath " .. vim.fn.expand "%:p:h",
        }
    end
end, {
    desc = "run test for a package",
    bang = true,
})

vim.keymap.set(
    "n",
    "<leader>tp",
    "<cmd>GoTestPackage<cr>",
    { desc = "run test for a package", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "GoTestFile", function(opts)
    local cwf = vim.fn.expand "%:."
    if opts.bang then
        vim.cmd.Dispatch { "go test -short -fullpath " .. cwf }
    else
        vim.cmd.Dispatch { "go test -fullpath " .. cwf }
    end
end, {
    desc = "run test for a file",
    bang = true,
})

vim.keymap.set(
    "n",
    "<leader>tt",
    "<cmd>GoTestFile<cr>",
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
                    "go test -short -fullpath "
                        .. cwf
                        .. " -run "
                        .. function_name,
                }
            else
                vim.cmd.Dispatch {
                    "go test -fullpath " .. cwf .. " -run " .. function_name,
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
    "<leader>tf",
    "<cmd>GoTestFunction<cr>",
    { desc = "run test for a function", buffer = true }
)

local toggle_helper = require "ilyasyoy.functions.toggle_test"

vim.opt_local.expandtab = false
vim.opt_local.spell = false
vim.bo.formatoptions = vim.bo.formatoptions .. "ro/"
vim.bo.formatprg = "gofumpt"

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

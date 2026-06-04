local java_helpers = require "ilyasyoy.functions.java"
local jdtls = require "jdtls"

local function setup_jdtls()
    local bufnr = vim.api.nvim_get_current_buf()
    if not java_helpers.start_or_attach(jdtls) then
        return
    end

    vim.keymap.set("n", "<localleader>oi", function()
        jdtls.organize_imports()
    end, {
        desc = "organize imports",
        buffer = bufnr,
    })
    vim.keymap.set("n", "<localleader>oa", function()
        jdtls.organize_imports()
        vim.lsp.buf.format()
    end, {
        desc = "organize all",
        buffer = bufnr,
    })

    vim.keymap.set("v", "<localleader>ev", function()
        jdtls.extract_variable(true)
    end, {
        desc = "java extract selected to variable",
        noremap = true,
        buffer = bufnr,
    })
    vim.keymap.set("n", "<localleader>ev", function()
        jdtls.extract_variable()
    end, {
        desc = "java extract variable",
        noremap = true,
        buffer = bufnr,
    })

    vim.keymap.set("v", "<localleader>eV", function()
        jdtls.extract_variable_all(true)
    end, {
        desc = "java extract all selected to variable",
        noremap = true,
        buffer = bufnr,
    })
    vim.keymap.set("n", "<localleader>eV", function()
        jdtls.extract_variable_all()
    end, {
        desc = "java extract all to variable",
        noremap = true,
        buffer = bufnr,
    })

    vim.keymap.set("n", "<localleader>ec", function()
        jdtls.extract_constant()
    end, {
        desc = "java extract constant",
        noremap = true,
        buffer = bufnr,
    })
    vim.keymap.set("v", "<localleader>ec", function()
        jdtls.extract_constant(true)
    end, {
        desc = "java extract selected to constant",
        noremap = true,
        buffer = bufnr,
    })

    vim.keymap.set("n", "<localleader>em", function()
        jdtls.extract_method()
    end, {
        desc = "java extract method",
        noremap = true,
        buffer = bufnr,
    })
    vim.keymap.set("v", "<localleader>em", function()
        jdtls.extract_method(true)
    end, {
        desc = "java extract selected to method",
        noremap = true,
        buffer = bufnr,
    })
    vim.keymap.set("n", "<localleader>oT", function()
        local plugin = require "jdtls.tests"
        plugin.goto_subjects()
    end, {
        desc = "java open test",
        noremap = true,
        buffer = bufnr,
    })
    vim.keymap.set("n", "<localleader>ct", function()
        local plugin = require "jdtls.tests"
        plugin.generate()
    end, {
        desc = "java create test",
        noremap = true,
        buffer = bufnr,
    })

    vim.keymap.set("n", "<localleader>Dm", function()
        jdtls.test_nearest_method()
    end, {
        desc = "java debug nearest test method",
        buffer = bufnr,
    })
    vim.keymap.set("n", "<localleader>Dc", function()
        jdtls.test_class()
    end, {
        desc = "java debug nearest test class",
        buffer = bufnr,
    })
    vim.keymap.set(
        "n",
        "<localleader>lr",
        "<cmd>JdtWipeDataAndRestart<CR>",
        { desc = "restart jdtls", buffer = bufnr }
    )
end

setup_jdtls()

require("ilyasyoy.functions.toggle_test").setup {
    command = "JavaToggleTest",
    rules = {
        {
            detect = "/main/java/",
            transform = function(cwf)
                cwf = string.gsub(cwf, "/main/java/", "/test/java/")
                cwf = string.gsub(cwf, "(%w+)%.java$", "%1Test.java")
                return cwf
            end,
        },
        {
            detect = "/test/java/",
            transform = function(cwf)
                cwf = string.gsub(cwf, "/test/java/", "/main/java/")
                cwf = string.gsub(cwf, "(%w+)Test%.java$", "%1.java")
                return cwf
            end,
        },
    },
}

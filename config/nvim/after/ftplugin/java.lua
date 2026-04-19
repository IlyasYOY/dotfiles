local core = require "ilyasyoy.functions.core"
local java_helpers = require "ilyasyoy.functions.java"
local lint_helpers = require "ilyasyoy.functions.lint"
local test_helpers = require "ilyasyoy.functions.test"
local jdtls = require "jdtls"

local function setup_linters()
    lint_helpers.setup_command {
        command = "JavaPMD",
        var_name = "last_java_lint_command",
        compiler = "make",
        desc = "runs pmd for current buffer",
        cmd_fn = function()
            return "pmd check --no-cache --dir % -R "
                .. core.resolve_relative_to_dotfiles_dir "config/pmd.xml"
        end,
    }

    lint_helpers.setup_command {
        command = "JavaCheckstyle",
        var_name = "last_java_lint_command",
        desc = "runs checkstyle for current buffer",
        cmd_fn = function()
            return "checkstyle % -c "
                .. core.resolve_relative_to_dotfiles_dir "config/checkstyle.xml"
        end,
    }

    lint_helpers.setup_last_command {
        command = "JavaLintLast",
        var_name = "last_java_lint_command",
        lang = "Java",
    }
end

local function setup_test()
    test_helpers.setup {
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

local function setup_lsp()
    if not java_helpers.start_or_attach(jdtls) then
        return
    end

    vim.keymap.set("n", "<localleader>oi", function()
        jdtls.organize_imports()
    end, {
        desc = "organize imports",
        buffer = true,
    })
    vim.keymap.set("n", "<localleader>oa", function()
        jdtls.organize_imports()
        vim.lsp.buf.format()
    end, {
        desc = "organize all",
        buffer = true,
    })

    vim.keymap.set("v", "<localleader>ev", function()
        jdtls.extract_variable(true)
    end, {
        desc = "java extract selected to variable",
        noremap = true,
        buffer = true,
    })
    vim.keymap.set("n", "<localleader>ev", function()
        jdtls.extract_variable()
    end, {
        desc = "java extract variable",
        noremap = true,
        buffer = true,
    })

    vim.keymap.set("v", "<localleader>eV", function()
        jdtls.extract_variable_all(true)
    end, {
        desc = "java extract all selected to variable",
        noremap = true,
        buffer = true,
    })
    vim.keymap.set("n", "<localleader>eV", function()
        jdtls.extract_variable_all()
    end, {
        desc = "java extract all to variable",
        noremap = true,
        buffer = true,
    })

    vim.keymap.set("n", "<localleader>ec", function()
        jdtls.extract_constant()
    end, {
        desc = "java extract constant",
        noremap = true,
        buffer = true,
    })
    vim.keymap.set("v", "<localleader>ec", function()
        jdtls.extract_constant(true)
    end, {
        desc = "java extract selected to constant",
        noremap = true,
        buffer = true,
    })

    vim.keymap.set("n", "<localleader>em", function()
        jdtls.extract_method()
    end, {
        desc = "java extract method",
        noremap = true,
        buffer = true,
    })
    vim.keymap.set("v", "<localleader>em", function()
        jdtls.extract_method(true)
    end, {
        desc = "java extract selected to method",
        noremap = true,
        buffer = true,
    })
    vim.keymap.set("n", "<localleader>oT", function()
        local plugin = require "jdtls.tests"
        plugin.goto_subjects()
    end, {
        desc = "java open test",
        noremap = true,
        buffer = true,
    })
    vim.keymap.set("n", "<localleader>ct", function()
        local plugin = require "jdtls.tests"
        plugin.generate()
    end, {
        desc = "java create test",
        noremap = true,
        buffer = true,
    })

    vim.keymap.set("n", "<localleader>Dm", function()
        jdtls.test_nearest_method()
    end, {
        desc = "java debug nearest test method",
        buffer = true,
    })
    vim.keymap.set("n", "<localleader>Dc", function()
        jdtls.test_class()
    end, {
        desc = "java debug nearest test class",
        buffer = true,
    })
    vim.keymap.set(
        "n",
        "<localleader>lr",
        "<cmd>JdtWipeDataAndRestart<CR>",
        { desc = "restart jdtls", buffer = true }
    )
end

setup_linters()
setup_test()
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
setup_lsp()

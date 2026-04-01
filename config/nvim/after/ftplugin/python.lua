local test_helpers = require "ilyasyoy.functions.test"
local toggle_helpers = require "ilyasyoy.functions.toggle_test"

vim.bo.formatoptions = vim.bo.formatoptions .. "ro/"

test_helpers.setup {
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

toggle_helpers.setup {
    command = "PythonToggleTest",
    rules = {
        {
            detect = "test_[%w_]+%.py$",
            gsub_pattern = "test_([%w_]+)%.py$",
            gsub_replacement = "%1.py",
        },
        {
            detect = "[%w_]+%.py$",
            gsub_pattern = "([%w_]+)%.py$",
            gsub_replacement = "test_%1.py",
        },
    },
}

vim.keymap.set("n", "<localleader>Dm", function()
    local dap_python = require "dap-python"
    dap_python.test_method()
end)

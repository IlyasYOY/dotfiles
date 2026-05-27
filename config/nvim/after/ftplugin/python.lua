local toggle_helpers = require "ilyasyoy.functions.toggle_test"

vim.bo.formatoptions = vim.bo.formatoptions .. "ro/"

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

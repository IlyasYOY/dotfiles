local toggle_helpers = require "ilyasyoy.functions.toggle_test"

toggle_helpers.setup {
    command = "JSToggleTest",
    rules = {
        {
            detect = ".*%.test%.js$",
            gsub_pattern = "(%w+)%.test%.js$",
            gsub_replacement = "%1.js",
        },
        {
            detect = "%.js$",
            gsub_pattern = "(%w+)%.js$",
            gsub_replacement = "%1.test.js",
        },
    },
}

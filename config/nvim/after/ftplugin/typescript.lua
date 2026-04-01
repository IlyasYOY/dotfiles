local toggle_helpers = require "ilyasyoy.functions.toggle_test"

toggle_helpers.setup {
    command = "TSToggleTest",
    rules = {
        {
            detect = ".*%.test%.ts$",
            gsub_pattern = "(%w+)%.test%.ts$",
            gsub_replacement = "%1.ts",
        },
        {
            detect = "%.ts$",
            gsub_pattern = "(%w+)%.ts$",
            gsub_replacement = "%1.test.ts",
        },
    },
}

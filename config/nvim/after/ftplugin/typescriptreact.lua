local toggle_helpers = require "ilyasyoy.functions.toggle_test"

toggle_helpers.setup {
    command = "TSXToggleTest",
    rules = {
        {
            detect = ".*%.test%.tsx$",
            gsub_pattern = "(%w+)%.test%.tsx$",
            gsub_replacement = "%1.tsx",
        },
        {
            detect = "%.tsx$",
            gsub_pattern = "(%w+)%.tsx$",
            gsub_replacement = "%1.test.tsx",
        },
    },
}

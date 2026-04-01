local toggle_helpers = require "ilyasyoy.functions.toggle_test"

vim.bo.formatprg = "stylua -"

toggle_helpers.setup {
    command = "LuaToggleTest",
    rules = {
        {
            detect = "_spec%.lua$",
            gsub_pattern = "(%w+)_spec%.lua$",
            gsub_replacement = "%1.lua",
        },
        {
            detect = "%.lua$",
            gsub_pattern = "(%w+)%.lua$",
            gsub_replacement = "%1_spec.lua",
        },
    },
}

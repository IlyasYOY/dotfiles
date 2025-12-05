return {
    {
        "williamboman/mason.nvim",
        event = "VeryLazy",
        config = function()
            local mason = require "mason"

            mason.setup {
                PATH = "append",
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            }
        end,
    },
}

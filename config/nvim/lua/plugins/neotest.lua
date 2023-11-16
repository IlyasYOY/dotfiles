return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-plenary",
            "nvim-neotest/neotest-python",
        },
        lazy = true,
        ft = { "lua", "python" },
        config = function()
            require("neotest").setup {
                adapters = {
                    require "neotest-plenary",
                    require "neotest-python",
                },
            }

            vim.keymap.set("n", "<leader>tt", function()
                require("neotest").run.run()
            end)
            vim.keymap.set("n", "<leader>tf", function()
                require("neotest").run.run(vim.fn.expand "%")
            end)
            vim.keymap.set("n", "<leader>ta", function()
                require("neotest").run.run "."
            end)
            vim.keymap.set("n", "<leader>ts", function()
                require("neotest").run.stop()
            end)
            vim.keymap.set("n", "<leader>tr", function()
                require("neotest").summary.toggle()
            end)
            vim.keymap.set("n", "<leader>to", function()
                require("neotest").output.open()
            end)
            vim.keymap.set("n", "<leader>tO", function()
                require("neotest").output_panel.toggle()
            end)
            vim.keymap.set("n", "[c", function()
                require("neotest").jump.prev()
            end)
            vim.keymap.set("n", "]c", function()
                require("neotest").jump.next()
            end)
        end,
    },
}

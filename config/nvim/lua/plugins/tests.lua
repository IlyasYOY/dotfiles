return {
    {
        "vim-test/vim-test",
        lazy = true,
        ft = { "java" },
        config = function()
            vim.keymap.set(
                "n",
                "<leader>tt",
                "<cmd>TestFile<cr>",
                { silent = true }
            )

            vim.keymap.set(
                "n",
                "<leader>ta",
                "<cmd>TestSuite<cr>",
                { silent = true }
            )
        end,
    },
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-plenary",
            "nvim-neotest/neotest-python",
            "nvim-neotest/neotest-go",
        },
        lazy = true,
        ft = { "lua", "python", "go" },
        config = function()
            local neotest_ns = vim.api.nvim_create_namespace "neotest"
            vim.diagnostic.config({
                virtual_text = {
                    format = function(diagnostic)
                        local message = diagnostic.message
                            :gsub("\n", " ")
                            :gsub("\t", " ")
                            :gsub("%s+", " ")
                            :gsub("^%s+", "")
                        return message
                    end,
                },
            }, neotest_ns)

            require("neotest").setup {
                adapters = {
                    require "neotest-plenary",
                    require "neotest-python",
                    require "neotest-go" {
                        recursive_run = true,
                    },
                },
            }

            vim.keymap.set("n", "<leader>tt", function()
                require("neotest").run.run()
            end)
            vim.keymap.set("n", "<leader>tf", function()
                require("neotest").run.run(vim.fn.expand "%")
            end)
            vim.keymap.set("n", "<leader>ta", function()
                require("neotest").run.run(vim.fn.getcwd())
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
        end,
    },
}

return {
    {
        "andythigpen/nvim-coverage",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        lazy = true,
        ft = { "go" },
        config = function()
            require("coverage").setup {
                lang = {
                    go = {
                        coverage_file = "cover.out",
                    },
                },
            }

            vim.keymap.set("n", "<leader>tC", function()
                vim.cmd.Coverage()
            end)
            vim.keymap.set("n", "<leader>tcs", function()
                vim.cmd.CoverageSummary()
            end)
            vim.keymap.set("n", "<leader>tcc", function()
                vim.cmd.CoverageToggle()
            end)
        end,
    },
}

return {
    {
        "github/copilot.vim",
        event = "VeryLazy",
        config = function()
            vim.g.copilot_filetypes = {
                ["*"] = false,

                lua = true,
                gitcommit = true,
                python = true,
                go = true,
                java = true,
                make = true,
                sh = true,
            }

            vim.keymap.set("n", "<leader>aa", "<cmd>Copilot panel<CR>", { desc = "Open Copilot Panel" })
            vim.keymap.set("n", "<leader>ae", "<cmd>Copilot enable<CR>", { desc = "Enable Copilot" })
            vim.keymap.set("n", "<leader>ad", "<cmd>Copilot disable<CR>", { desc = "Disable Copilot" })
        end
    }
}

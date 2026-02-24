return {
    {
        "github/copilot.vim",
        event = "VeryLazy",
        config = function()
            vim.keymap.set('i', '<M-j>', 'copilot#Accept("\\<CR>")', {
                expr = true,
                replace_keycodes = false
            })
            vim.g.copilot_no_tab_map = true

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
            vim.keymap.set("n", "<leader>ar", "<cmd>Copilot restart<CR>", { desc = "Reload Copilot" })
        end
    }
}

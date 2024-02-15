return {
    {
        "ray-x/go.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
            "ray-x/guihua.lua",
        },
        config = function()
            require("go").setup {
                dap_debug_keymap = false,
                test_runner = "gotestsum",
                icons = false,
                dap_debug_gui = false,
                lsp_inlay_hints = {
                    enable = false
                }
            }

            vim.keymap.set("n", "<leader><leader>gtf", "<cmd>GoTestFile<cr>")
            vim.keymap.set("n", "<leader><leader>gtt", "<cmd>GoTestFunc<cr>")
            vim.keymap.set("n", "<leader><leader>gta", "<cmd>GoTest ./...<cr>")

            vim.keymap.set("n", "<leader><leader>gts", "<cmd>GoTestSum<cr>")
            vim.keymap.set("n", "<leader><leader>ga", "<cmd>GoCodeLenAct<cr>")
        end,
        event = { "CmdlineEnter" },
        ft = { "go", "gomod" },
        build = ':lua require("go.install").update_all_sync()',
    },
}

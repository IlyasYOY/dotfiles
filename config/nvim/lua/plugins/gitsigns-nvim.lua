return {
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup {}

            vim.keymap.set(
                "n",
                "<leader>gb",
                "<cmd>Gitsigns blame_line<CR>",
                { desc = "blame current line", noremap = true }
            )
            vim.keymap.set(
                "n",
                "<leader>gv",
                ":Gitsigns preview_hunk<cr>",
                { desc = "preview hunk" }
            )
            vim.keymap.set(
                "n",
                "<leader>ga",
                ":Gitsigns stage_hunk<cr>",
                { desc = "stage hunk" }
            )
            vim.keymap.set(
                "n",
                "<leader>gA",
                ":Gitsigns stage_buffer<cr>",
                { desc = "stage buffer" }
            )
            vim.keymap.set(
                "n",
                "<leader>gr",
                ":Gitsigns reset_hunk<cr>",
                { desc = "reset hunk" }
            )
            vim.keymap.set(
                "n",
                "<leader>gR",
                ":Gitsigns prev_buffer<cr>",
                { desc = "reset buffer" }
            )
            vim.keymap.set(
                "n",
                "[g",
                ":Gitsigns prev_hunk<cr>",
                { desc = "go to prev hunk" }
            )
            vim.keymap.set(
                "n",
                "]g",
                ":Gitsigns next_hunk<cr>",
                { desc = "go to next hunk" }
            )
        end,
    },
}

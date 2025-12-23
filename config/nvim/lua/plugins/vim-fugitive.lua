return {
    {
        "tpope/vim-fugitive",
        event = "VeryLazy",
        dependencies = {
            "shumphrey/fugitive-gitlab.vim",
            "tommcdo/vim-fubitive",
            "tpope/vim-rhubarb",
            "tpope/vim-dispatch",
        },
        config = function()
            vim.keymap.set(
                "n",
                "<leader>gg",
                ":Gedit :<CR>",
                { desc = "Open fugitive UI window", silent = true }
            )

            vim.keymap.set(
                "n",
                "<leader>gps",
                ":Git push<CR>",
                { desc = "Pushes changes to remote" }
            )
            vim.keymap.set(
                "n",
                "<leader>gpl",
                ":Git pull<CR>",
                { desc = "Pulls changes from remote" }
            )

            vim.keymap.set(
                "n",
                "<leader>gy",
                ":.GBrowse!<cr>",
                { desc = "Copy link to current line" }
            )
            vim.keymap.set(
                "n",
                "<leader>gY",
                ":GBrowse!<CR>",
                { desc = "Copy link to file" }
            )
            vim.keymap.set(
                "x",
                "<leader>gy",
                ":'<'>GBrowse!<cr>",
                { desc = "Copy link to current lines" }
            )

            vim.keymap.set(
                { "n", "v", "s" },
                "<leader>gb",
                ":Git blame<cr>",
                { desc = "Open blame" }
            )

            vim.keymap.set(
                { "n", "v", "s" },
                "<leader>gl",
                ":Gclog<cr>",
                { desc = "Open history for repo or selection" }
            )

            vim.keymap.set(
                { "n" },
                "<leader>gL",
                ":Gclog %<cr>",
                { desc = "Open history for the selected buffer" }
            )
        end,
    },
}

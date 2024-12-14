return {
    {
        "tpope/vim-fugitive",
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
                "<leader>gl",
                ":Git log<cr>",
                { desc = "Open log" }
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
                "n",
                "<leader>gB",
                ":Git blame<cr>",
                { desc = "Open blame" }
            )
        end,
    },
}

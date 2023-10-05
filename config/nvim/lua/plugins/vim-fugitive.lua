return {
    {
        "tpope/vim-fugitive",
        dependencies = {
            "shumphrey/fugitive-gitlab.vim",
            "tommcdo/vim-fubitive",
            "tpope/vim-rhubarb",
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
                "<leader>gP",
                ":Git push<CR>",
                { desc = "Pushes changes to remote" }
            )
            vim.keymap.set(
                "n",
                "<leader>gp",
                ":Git pull<CR>",
                { desc = "Pushes changes to remote" }
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
                ":.GBrowse<CR>",
                { desc = "Open link to current line" }
            )

            vim.keymap.set(
                "x",
                "<leader>gy",
                ":'<'>GBrowse!<cr>",
                { desc = "Copy link to current line" }
            )
            vim.keymap.set(
                "x",
                "<leader>gY",
                ":'<'>GBrowse<CR>",
                { desc = "Open link to current line" }
            )
        end,
    },
}

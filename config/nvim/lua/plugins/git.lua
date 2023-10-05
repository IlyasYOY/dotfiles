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
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup {
                signs = {
                    add = {
                        hl = "GitSignsAdd",
                        text = "+",
                        numhl = "GitSignsAddNr",
                        linehl = "GitSignsAddLn",
                    },
                    change = {
                        hl = "GitSignsChange",
                        text = "~",
                        numhl = "GitSignsChangeNr",
                        linehl = "GitSignsChangeLn",
                    },
                    delete = {
                        hl = "GitSignsDelete",
                        text = "x",
                        numhl = "GitSignsDeleteNr",
                        linehl = "GitSignsDeleteLn",
                    },
                    topdelete = {
                        hl = "GitSignsDelete",
                        text = "x",
                        numhl = "GitSignsDeleteNr",
                        linehl = "GitSignsDeleteLn",
                    },
                    changedelete = {
                        hl = "GitSignsChange",
                        text = "~",
                        numhl = "GitSignsChangeNr",
                        linehl = "GitSignsChangeLn",
                    },
                },
            }

            vim.keymap.set(
                "n",
                "<leader>gb",
                "<cmd>Gitsigns blame_line<CR>",
                { desc = "blame current line", noremap = true }
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

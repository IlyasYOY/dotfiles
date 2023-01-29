return {
    {
        "IlyasYOY/git-link.nvim",
        dev = true,
        dependencies = {
            "IlyasYOY/coredor.nvim",
        },
        config = function()
            local git_link = require "git-link"

            vim.api.nvim_create_user_command("GitRemoteCopyRepoLink", function()
                git_link.copy_repo_link()
            end, {
                desc = "Copies a link to currently working repository into the clipboard",
            })

            vim.api.nvim_create_user_command(
                "GitRemoteCopyRepoLinkToFile",
                function()
                    git_link.copy_repo_link_to_file()
                end,
                {
                    desc = "Copies a link to currently working file into the clipboard",
                }
            )

            vim.api.nvim_create_user_command(
                "GitRemoteCopyRepoLinkToLine",
                function()
                    git_link.copy_repo_link_to_line()
                end,
                {
                    desc = "Copies a link to currently working line into the clipboard",
                }
            )
        end,
    },
    {
        "TimUntersberger/neogit",
        config = function()
            vim.keymap.set(
                "n",
                "<leader>g",
                ":Neogit<CR>",
                { desc = "Open neo[g]it UI window", silent = true }
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
                        text = "-",
                        numhl = "GitSignsDeleteNr",
                        linehl = "GitSignsDeleteLn",
                    },
                    topdelete = {
                        hl = "GitSignsDelete",
                        text = "‾",
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
        end,
    },
}

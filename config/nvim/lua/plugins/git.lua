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
        "tpope/vim-fugitive",
        config = function()
            vim.keymap.set(
                "n",
                "<leader>GG",
                ":Git<CR>",
                { desc = "Open fugitive UI window", silent = true }
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
    {
        "ThePrimeagen/git-worktree.nvim",
        config = function()
            require("git-worktree").setup {}
            require("telescope").load_extension "git_worktree"

            vim.keymap.set(
                "n",
                "<leader>Gw",
                require("telescope").extensions.git_worktree.git_worktrees,
                { desc = "find local git workspaces" }
            )

            vim.keymap.set(
                "n",
                "<leader>GW",
                require("telescope").extensions.git_worktree.create_git_worktree,
                { desc = "find branch and create git workspaces" }
            )

            local worktree = require "git-worktree"
            worktree.on_tree_change(function(op, metadata)
                if op == worktree.Operations.Switch then
                    local clients = vim.lsp.get_active_clients()
                    for _, client in ipairs(clients) do
                        if client.initialized then
                            vim.notify("Restarting LSP cilent " .. client.name)
                            vim.cmd [[:LspRestart]]
                        end
                    end
                end
            end)
        end,
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
    },
}

return {
    {
        "folke/todo-comments.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "ibhagwan/fzf-lua",
        },
        config = function()
            require("todo-comments").setup {
                keywords = {
                    TODO = {
                        alt = { "TODO", "todo", "ToDo" },
                    },
                    FIXME = {
                        alt = { "FIX", "FIXME", "fix", "fixme", "FixMe" },
                    },
                },
                search = {
                    args = {
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--hidden",
                    },
                },
            }

            vim.keymap.set("n", "]t", function()
                require("todo-comments").jump_next()
            end, { desc = "Next todo comment" })

            vim.keymap.set("n", "[t", function()
                require("todo-comments").jump_prev()
            end, { desc = "Previous todo comment" })

            vim.keymap.set(
                "n",
                "<leader>ft",
                ":TodoFzfLua<CR>",
                { desc = "find todos in project" }
            )
        end,
    },
}

return {
    {
        "nvim-telescope/telescope-ui-select.nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("telescope").load_extension "ui-select"
        end,
    },
    {
        "aaronhallaert/advanced-git-search.nvim",
        config = function()
            require("telescope").load_extension "advanced_git_search"
            vim.keymap.set("n", "<leader>fG", "<cmd>AdvancedGitSearch<cr>")
        end,
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "tpope/vim-fugitive",
            "sindrets/diffview.nvim",
        },
    },
    {
        "nvim-telescope/telescope.nvim",
        version = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        config = function()
            local telescope = require "telescope"
            local builtin = require "telescope.builtin"
            local themes = require "telescope.themes"
            telescope.setup {
                extensions = {
                    advanced_git_search = {},
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    ["ui-select"] = {
                        require("telescope.themes").get_ivy {},
                    },
                },
                defaults = {
                    path_display = { "smart" },
                    file_ignore_patterns = { "node_modules", ".git/" },
                    -- TODO: Think of the way to make
                    --  it work only for buffers dialog
                    mappings = {
                        n = {
                            ["<c-b>"] = require("telescope.actions").delete_buffer,
                        },
                        i = {
                            ["<c-b>"] = require("telescope.actions").delete_buffer,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        opts = {
                            "--smart-case",
                        },
                    },
                    live_grep = {
                        additional_args = function(opts)
                            return {
                                "--hidden",
                                "--smart-case",
                            }
                        end,
                    },
                },
            }
            require("telescope").load_extension "fzf"

            vim.keymap.set("n", "<leader>ff", function()
                builtin.find_files()
            end, { desc = "find files" })

            vim.keymap.set("n", "<leader>fF", function()
                builtin.git_files()
            end, { desc = "find git files" })

            vim.keymap.set("n", "<leader>fg", function()
                builtin.live_grep()
            end, { desc = "find grep through files" })

            vim.keymap.set("n", "<leader>fa", function()
                builtin.builtin(themes.get_ivy())
            end, { desc = "find in commands" })

            vim.keymap.set("n", "<leader>fq", function()
                builtin.quickfix(themes.get_ivy())
            end, { desc = "find in quickfix" })

            vim.keymap.set("n", "<leader>fl", function()
                builtin.loclist(themes.get_ivy())
            end, { desc = "find in loc list" })

            vim.keymap.set("n", "<leader>fS", function()
                builtin.lsp_document_symbols(themes.get_ivy())
            end, { desc = "find document symbols" })

            vim.keymap.set("n", "<leader>fs", function()
                builtin.lsp_dynamic_workspace_symbols(themes.get_ivy())
            end, { desc = "find worspace symbols" })

            vim.keymap.set("n", "<leader>fd", function()
                builtin.diagnostics(themes.get_ivy())
            end, { desc = "find worspace diagnostics" })

            vim.keymap.set("n", "<leader>fm", function()
                builtin.man_pages()
            end, { desc = "find man pager" })

            vim.keymap.set("n", "<leader>fh", function()
                builtin.help_tags(themes.get_ivy())
            end, { desc = "find help tags" })

            vim.keymap.set("n", "<leader>fb", function()
                builtin.buffers(themes.get_ivy())
            end, { desc = "find buffers" })

            vim.keymap.set("n", "<leader>fB", function()
                builtin.current_buffer_fuzzy_find()
            end, { desc = "find current buffer" })

            vim.keymap.set("n", "<leader>fGb", function()
                builtin.git_branches(themes.get_ivy())
            end, { desc = "find git branches" })

            vim.keymap.set("n", "<leader>fGc", function()
                builtin.git_commits(themes.get_ivy())
            end, { desc = "find git commits" })

            vim.keymap.set("n", "<leader>fGf", function()
                builtin.git_files(themes.get_ivy())
            end, { desc = "find git files" })

            vim.keymap.set("n", "<leader>fc", function()
                builtin.commands(themes.get_ivy())
            end, { desc = "find commands" })
        end,
    },
}

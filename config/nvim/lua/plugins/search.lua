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
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("telescope").load_extension "fzf"
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        version = "0.1.x",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = require "telescope"
            local builtin = require "telescope.builtin"
            local themes = require "telescope.themes"
            telescope.setup {
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    ["ui-select"] = {
                        require("telescope.themes").get_cursor {},
                    },
                },
                defaults = {
                    file_ignore_patterns = { "node_modules", ".git/" },
                    -- TODO: Think of the way to make
                    --  it work only for buffers dialog
                    mappings = {
                        n = {
                            ["<c-d>"] = require("telescope.actions").delete_buffer,
                        },
                        i = {
                            ["<c-d>"] = require("telescope.actions").delete_buffer,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                    live_grep = {
                        additional_args = function(opts)
                            return {
                                "--hidden",
                            }
                        end,
                    },
                },
            }

            vim.keymap.set("n", "<leader>ff", function()
                builtin.find_files()
            end, { desc = "find files" })

            vim.keymap.set("n", "<leader>fF", function()
                builtin.git_files()
            end, { desc = "find git files" })

            vim.keymap.set("n", "<leader>fg", function()
                builtin.live_grep()
            end, { desc = "find grep through files" })

            vim.keymap.set("n", "<leader>fT", function()
                builtin.builtin(themes.get_ivy())
            end, { desc = "find built in commands" })

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

            vim.keymap.set("n", "<leader>fc", function()
                builtin.commands(themes.get_ivy())
            end, { desc = "find commands" })

            vim.keymap.set(
                "n",
                "<leader>ft",
                ":TodoTelescope<CR>",
                { desc = "find todos in project" }
            )
        end,
    },
}

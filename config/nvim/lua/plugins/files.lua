return {
    {
        "nvim-tree/nvim-tree.lua",
        tag = "nightly",
        config = function()
            vim.opt.termguicolors = true

            local nvimtree = require "nvim-tree"

            nvimtree.setup {
                hijack_netrw = true,
                disable_netrw = false,
                view = {
                    number = true,
                    relativenumber = true,
                    adaptive_size = true,
                },
                renderer = {
                    group_empty = true,
                    indent_markers = {
                        enable = true,
                    },
                    icons = {
                        show = {
                            file = true,
                            folder = true,
                            folder_arrow = true,
                            git = true,
                        },
                    },
                },
                diagnostics = {
                    enable = true,
                    show_on_open_dirs = true,
                    debounce_delay = 50,
                    severity = {
                        min = vim.diagnostic.severity.WARN,
                        max = vim.diagnostic.severity.ERROR,
                    },
                    icons = {
                        hint = "h",
                        info = "i",
                        warning = "w",
                        error = "e",
                    },
                },
            }

            vim.keymap.set("n", "<leader>e", function()
                nvimtree.toggle()
            end, { desc = "Open nvim tree to [e]xplore files" })
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
                defaults = { file_ignore_patterns = { "node_modules", ".git" } },
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                    live_grep = {
                        additional_args = function(opts)
                            return { "--hidden", "-g", "!.git" }
                        end,
                    },
                },
            }

            vim.keymap.set("n", "<leader>ff", function()
                builtin.find_files()
            end)

            vim.keymap.set("n", "<leader>fF", function()
                builtin.git_files()
            end, { desc = "find git files" })

            vim.keymap.set("n", "<leader>fg", function()
                builtin.live_grep()
            end, { desc = "find grepping files" })

            vim.keymap.set("n", "<leader>fT", function()
                builtin.builtin(themes.get_ivy())
            end, { desc = "find built in commands" })

            vim.keymap.set("n", "<leader>fs", function()
                builtin.lsp_document_symbols(themes.get_ivy())
            end, { desc = "find document symbols" })

            vim.keymap.set("n", "<leader>fS", function()
                builtin.lsp_dynamic_workspace_symbols(themes.get_ivy())
            end, { desc = "find worspace symbols" })

            vim.keymap.set("n", "<leader>fm", function()
                builtin.man_pages()
            end, { desc = "find man pager" })

            vim.keymap.set("n", "<leader>fh", function()
                builtin.help_tags(themes.get_ivy())
            end, { desc = "find help tags" })

            vim.keymap.set("n", "<leader>fb", function()
                builtin.buffers(themes.get_ivy())
            end, { desc = "find buffers" })

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

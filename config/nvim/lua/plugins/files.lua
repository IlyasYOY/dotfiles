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
            end, { desc = "Open nvim tree to explore files" })

            vim.keymap.set(
                "n",
                "<leader>E",
                "<cmd>NvimTreeFindFile<CR>",
                { desc = "Open nvim tree to explore current file directory" }
            )

            local function open_nvim_tree(data)
                local directory = vim.fn.isdirectory(data.file) == 1

                if not directory then
                    return
                end

                require("nvim-tree.api").tree.open {
                    path = data.file,
                }
            end

            vim.api.nvim_create_autocmd(
                { "VimEnter" },
                { callback = open_nvim_tree }
            )
        end,
    },
}

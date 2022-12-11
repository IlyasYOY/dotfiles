vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

local nvimtree = require("nvim-tree")

nvimtree.setup({
    view = {
        number = true,
        relativenumber = true,
        adaptive_size = true,
    },
    renderer = {
        group_empty = true,
        indent_markers = {
            enable = true
        },
        icons = {
            show = {
                file = false,
                folder = false,
                folder_arrow = false,
                git = true,
            },
            glyphs = {
                git = {
                    unstaged = "✗",
                    staged = "✓",
                    unmerged = "?",
                    renamed = "➜",
                    untracked = "★",
                    deleted = "-",
                    ignored = "◌",
                }
            }
        },
    },
    diagnostics = {
        enable = true,
        show_on_open_dirs = true,
        debounce_delay = 50,
        severity = {
            min = vim.diagnostic.severity.HINT,
            max = vim.diagnostic.severity.ERROR
        },
        icons = {
            hint = "h",
            info = "i",
            warning = "w",
            error = "e",
        },
    },
})

vim.keymap.set("n", "<leader>e", function()
    nvimtree.toggle()
end)

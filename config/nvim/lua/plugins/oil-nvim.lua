return {
    {
        "stevearc/oil.nvim",
        config = function()
            require("oil").setup {
                columns = {
                    -- "icon",
                    -- "permissions",
                    -- "size",
                    -- "mtime",
                },
                keymaps = {
                    ["g?"] = "actions.show_help",
                    ["<CR>"] = "actions.select",
                    ["<C-v>"] = "actions.select_vsplit",
                    ["<C-s>"] = "actions.select_split",
                    ["<C-t>"] = "actions.select_tab",
                    ["<C-p>"] = "actions.preview",
                    ["<C-c>"] = "actions.close",
                    ["<C-r>"] = "actions.refresh",
                    ["-"] = "actions.parent",
                    ["_"] = "actions.open_cwd",
                    ["`"] = "actions.cd",
                    ["~"] = "actions.tcd",
                    ["g."] = "actions.toggle_hidden",
                },
                use_default_keymaps = false,
            }
            vim.keymap.set("n", "-", "<cmd>Oil<CR>")
            vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>")
            vim.keymap.set("n", "<leader>E", "<cmd>Oil --float<CR>")
        end,
    },
}

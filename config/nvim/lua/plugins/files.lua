return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("neo-tree").setup {
                source_selector = {
                    winbar = true,
                    sources = {
                        { source = "filesystem" },
                        { source = "buffers" },
                        { source = "git_status" },
                        { source = "document_symbols" },
                    },
                },
                sources = {
                    "filesystem",
                    "buffers",
                    "git_status",
                    "document_symbols",
                },
                sort_case_insensitive = true, -- used when sorting files and directories in the tree
                sort_function = nil, -- uses a custom function for sorting files and directories in the tree
                use_popups_for_input = true, -- If false, inputs will use vim.ui.input instead of custom floats.
                window = {
                    auto_expand_width = true, -- expand the window when file exceeds the window width. does not work with position = "float"
                },
                use_default_mappings = true,
                filesystem = {
                    follow_current_file = {
                        enabled = true, -- This will find and focus the file in the active buffer every time
                    },
                    hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
                },
            }

            vim.keymap.set("n", "<leader>ee", "<cmd>Neotree float<CR>")
            vim.keymap.set("n", "<leader>ef", "<cmd>Neotree float source=filesystem<CR>")
            vim.keymap.set("n", "<leader>eb", "<cmd>Neotree float source=buffers<CR>")
            vim.keymap.set("n", "<leader>es", "<cmd>Neotree float source=document_symbols<CR>")
            vim.keymap.set("n", "<leader>eg", "<cmd>Neotree float source=git_status<CR>")
            vim.keymap.set("n", "<leader>E", "<cmd>Neotree toggle<CR>")

            local group =
                vim.api.nvim_create_augroup("neotree-netrw", { clear = true })
            vim.api.nvim_create_autocmd("UiEnter", {
                desc = "Open Neotree automatically",
                group = group,
                callback = function()
                    local stats = vim.loop.fs_stat(vim.api.nvim_buf_get_name(0))
                    if stats and stats.type == "directory" then
                        require("neo-tree.setup.netrw").hijack()
                    end
                end,
            })
        end,
    },
}

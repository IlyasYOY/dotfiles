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
    {
        "NStefan002/speedtyper.nvim", 
        lazy = true,
        cmd = { "Speedtyper" }
    },
    "nvim-tree/nvim-web-devicons",
    "tjdevries/colorbuddy.nvim",
    {
        "ellisonleao/gruvbox.nvim",
        config = function()
            vim.api.nvim_set_option("background", "dark")
            vim.cmd "colorscheme gruvbox"
        end,
    },
    {
        "f-person/auto-dark-mode.nvim",
        cond = false,
        dependencies = {
            "ellisonleao/gruvbox.nvim",
        },
        config = {
            update_interval = 1000,
            set_dark_mode = function()
                vim.api.nvim_set_option("background", "dark")
                vim.cmd "colorscheme gruvbox"
            end,
            set_light_mode = function()
                vim.api.nvim_set_option("background", "light")
                vim.cmd "colorscheme gruvbox"
            end,
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "IlyasYOY/coredor.nvim",
        },
        config = function()
            local core = require "coredor"
            local lualine = require "lualine"

            local is_jdtls_buffer = function()
                local buf_path = vim.fn.expand "%"
                return core.string_has_prefix(buf_path, "jdt", true)
            end

            lualine.setup {
                options = {
                    theme = "gruvbox",
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch" },
                    lualine_c = {
                        {
                            "filename",
                            path = 3,
                            cond = function()
                                return not is_jdtls_buffer()
                            end,
                        },
                        {
                            "filename",
                            cond = function()
                                return is_jdtls_buffer()
                            end,
                        },
                    },
                    lualine_x = { "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            }
        end,
    },
}

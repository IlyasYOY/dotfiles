return {
    "nvim-tree/nvim-web-devicons",
    "tjdevries/colorbuddy.nvim",
    {
        "BooleanCube/keylab.nvim",
        lazy = true,
        keys = {
            "<leader><leader>K"
        },
        config = function()
            local keylab = require "keylab"
            keylab.setup {}

            vim.keymap.set(
                "n",
                "<leader><leader>K",
                require("keylab").start,
                { desc = "Start a keylab session" }
            )
        end,
    },
    "christoomey/vim-tmux-navigator",
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        config = function()
            vim.cmd.colorscheme "gruvbox"
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "IlyasYOY/coredor.nvim",
        },
        config = function()
            local lualine = require "lualine"
            local core = require "coredor"

            ---TODO: Consider adding cache here?
            local function active_lsp_names()
                local result = {}
                local clients = vim.lsp.get_active_clients()
                for _, client in ipairs(clients) do
                    if client.initialized then
                        table.insert(result, client.name)
                    end
                end
                return core.string_merge(result, ", ")
            end

            local function get_cwd()
                return vim.fn.pathshorten(vim.fn.getcwd())
            end

            lualine.setup {
                options = {
                    theme = "gruvbox",
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diagnostics" },
                    lualine_c = { "filename", get_cwd },
                    lualine_x = { "fileformat", "filetype", active_lsp_names },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            }
        end,
    },
    {
        "akinsho/bufferline.nvim",
        version = "v3.*",
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function()
            vim.opt.termguicolors = true
            require("bufferline").setup {
                options = {
                    offsets = {
                        {
                            filetype = "NvimTree",
                            text = "File Explorer",
                        },
                    },
                },
            }
        end,
    },
}

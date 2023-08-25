return {
    {
        "stevearc/oil.nvim",
        config = function()
            require("oil").setup {
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
        "BooleanCube/keylab.nvim",
        lazy = true,
        keys = {
            "<leader><leader>K",
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
    "nvim-tree/nvim-web-devicons",
    "tjdevries/colorbuddy.nvim",
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
                    lualine_b = { "branch" },
                    lualine_c = { "filename", get_cwd },
                    lualine_x = { "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            }
        end,
    },
}

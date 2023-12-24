return {
    { "IlyasYOY/coredor.nvim", dev = true },
    "nvim-tree/nvim-web-devicons",
    "nvim-lua/plenary.nvim",
    "christoomey/vim-tmux-navigator",
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
                    ["gs"] = "actions.change_sort",
                    ["gx"] = "actions.open_external",
                    ["g."] = "actions.toggle_hidden",
                    ["g\\"] = "actions.toggle_trash",
                },
                use_default_keymaps = false,
            }
            vim.keymap.set("n", "-", "<cmd>Oil<CR>")
            vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>")
            vim.keymap.set("n", "<leader>E", "<cmd>Oil --float<CR>")
        end,
    },
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup {
                move_cursor = false,
            }
        end,
    },
    {
        "glacambre/firenvim",
        -- Lazy load firenvim
        -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
        -- run this without cond: nvim --headless "+call firenvim#install(0) | q"
        cond = not not vim.g.started_by_firenvim,
        build = function()
            require("lazy").load { plugins = "firenvim", wait = true }
            vim.fn["firenvim#install"](0)
        end,
        init = function()
            vim.cmd [[
                let g:firenvim_config = {
                    \ 'globalSettings': {
                        \ 'alt': 'all',
                    \  },
                    \ 'localSettings': {
                        \ '.*': {
                            \ 'takeover': 'never',
                        \ },
                    \ }
                \ }
                if exists('g:started_by_firenvim')
                    set guifont=Hack:h12
                else
                    set laststatus=2
                endif
            ]]
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "IlyasYOY/coredor.nvim",
            "ellisonleao/gruvbox.nvim",
        },
        config = function()
            local core = require "coredor"
            local lualine = require "lualine"

            local function is_jdtls_buffer()
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

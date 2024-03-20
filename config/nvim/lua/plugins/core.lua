local function get_git_ignored_files_in(dir)
    local found = vim.fs.find(".git", {
        upward = true,
        path = dir,
    })
    if #found == 0 then
        return {}
    end

    local cmd = string.format(
        'git -C %s ls-files --ignored --exclude-standard --others --directory | grep -v "/.*\\/"',
        dir
    )

    local handle = io.popen(cmd)
    if handle == nil then
        return
    end

    local ignored_files = {}
    for line in handle:lines "*l" do
        line = line:gsub("/$", "")
        table.insert(ignored_files, line)
    end
    handle:close()

    return ignored_files
end

return {
    { "IlyasYOY/coredor.nvim", dev = true },
    "nvim-tree/nvim-web-devicons",
    "nvim-lua/plenary.nvim",
    {
        "mbbill/undotree",
        lazy = true,
        keys = {
            "<leader>ut",
        },
        cmd = {
            "UndotreeToggle",
        },
        config = function()
            vim.keymap.set("n", "<leader>ut", ":UndotreeToggle<CR>")
        end,
    },
    "christoomey/vim-tmux-navigator",
    {
        "stevearc/oil.nvim",
        config = function()
            local oil = require "oil"
            oil.setup {
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
                view_options = {
                    show_hidden = true,
                    is_hidden_file = function(name, bufnr)
                        local ignored_files =
                            get_git_ignored_files_in(oil.get_current_dir())
                        return vim.tbl_contains(ignored_files, name)
                            or vim.startswith(name, ".")
                    end,
                },
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
        lazy = not vim.g.started_by_firenvim,
        module = false,
        build = function()
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
                    set guifont=Hack:h15
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

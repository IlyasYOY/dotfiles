local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath "data"
        .. "/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system {
            "git",
            "clone",
            "--depth",
            "1",
            "https://github.com/wbthomason/packer.nvim",
            install_path,
        }
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require("packer").startup(function(use)
    use "wbthomason/packer.nvim"
    use "nvim-lua/plenary.nvim"

    use {
        "nvim-treesitter/nvim-treesitter",
        run = function()
            local ts_update = require("nvim-treesitter.install").update {
                with_sync = true,
            }
            ts_update()
        end,
    }
    use "nvim-treesitter/playground"

    use {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.x",
        requires = { { "nvim-lua/plenary.nvim" } },
    }

    use { "nvim-tree/nvim-tree.lua", tag = "nightly" }

    use {
        "mhinz/vim-startify",

        "nvim-lualine/lualine.nvim",

        "TimUntersberger/neogit",
        "lewis6991/gitsigns.nvim",
    }

    use {
        "neovim/nvim-lspconfig",
        "jose-elias-alvarez/null-ls.nvim",
        "folke/neodev.nvim",
        "L3MON4D3/LuaSnip",
    }

    use {
        "rcarriga/nvim-dap-ui",
        "mfussenegger/nvim-dap",
        "mfussenegger/nvim-dap-python",
    }

    use {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "jayp0521/mason-null-ls.nvim",
        "jayp0521/mason-nvim-dap.nvim",
    }

    use {
        "hrsh7th/nvim-cmp",
        "onsails/lspkind.nvim",

        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/cmp-nvim-lsp",

        "saadparwaiz1/cmp_luasnip",
    }

    use "rafcamlet/nvim-luapad"

    use {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    }
    use {
        "folke/todo-comments.nvim",
        requires = "nvim-lua/plenary.nvim",
    }

    use {
        "ellisonleao/gruvbox.nvim",
        "nvim-tree/nvim-web-devicons",
        "tjdevries/colorbuddy.nvim",
    }

    if packer_bootstrap then
        require("packer").sync()
    end
end)

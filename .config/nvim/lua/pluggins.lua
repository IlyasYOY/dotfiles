local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system { "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path }
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require "packer".startup(function(use)
    use "wbthomason/packer.nvim"

    use "nvim-lua/plenary.nvim"
    use { "nvim-treesitter/nvim-treesitter",
        run = function()
            local ts_update = require "nvim-treesitter.install".update({
                with_sync = true
            })
            ts_update()
        end,
    }
    use "nvim-treesitter/playground"
    use { "nvim-telescope/telescope.nvim", tag = "0.1.x", requires = { { "nvim-lua/plenary.nvim" } } }
    use { "nvim-tree/nvim-tree.lua",
        tag = "nightly"
    }

    use {
        "mhinz/vim-startify",
        "tpope/vim-fugitive",
        "tpope/vim-surround",
        "tpope/vim-repeat",
        "vim-airline/vim-airline",
        "airblade/vim-gitgutter",
    }

    use {
        "neovim/nvim-lspconfig",
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "folke/neodev.nvim",
        "L3MON4D3/LuaSnip",
    }

    use {
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "saadparwaiz1/cmp_luasnip",
    }

    use {
        "renerocksai/calendar-vim",
        "renerocksai/telekasten.nvim",
    }

    use "gruvbox-community/gruvbox"

    if packer_bootstrap then
        require "packer".sync()
    end
end)

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
    use {
        "nvim-treesitter/nvim-treesitter",
        run = function()
            local ts_update = require "nvim-treesitter.install".update({ with_sync = true })
            ts_update()
        end,
    }
    use "nvim-treesitter/playground"

    -- Fuzzy search
    use {
        "nvim-telescope/telescope.nvim", tag = "0.1.x",
        requires = { { "nvim-lua/plenary.nvim" } }
    }

    use "renerocksai/calendar-vim"
    use "renerocksai/telekasten.nvim"
    -- use "IlyasYOY/telekasten.nvim"

    use "gruvbox-community/gruvbox"

    use "tpope/vim-fugitive"
    use "tpope/vim-surround"
    use "tpope/vim-repeat"

    use "vim-airline/vim-airline"
    use "airblade/vim-gitgutter"

    use "honza/vim-snippets"
    use {
        "neoclide/coc.nvim", branch = "release"
    }
    use "puremourning/vimspector"

    use "mhinz/vim-startify"

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if packer_bootstrap then
        require "packer".sync()
    end
end)

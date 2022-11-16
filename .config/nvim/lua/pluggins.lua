local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    -- Themes
    use 'gruvbox-community/gruvbox'

    -- Some utilities for lua IO
    use 'nvim-lua/plenary.nvim'

    -- Git
    use 'tpope/vim-fugitive'
    -- Surround
    use 'tpope/vim-surround'

    -- Status line
    use 'vim-airline/vim-airline'
    use 'airblade/vim-gitgutter'

    use 'honza/vim-snippets'

    use 'renerocksai/calendar-vim'
    use 'renerocksai/telekasten.nvim'

    use {
        'neoclide/coc.nvim', branch = 'release'
    }

    -- Fuzzy search
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if packer_bootstrap then
        require('packer').sync()
    end
end)

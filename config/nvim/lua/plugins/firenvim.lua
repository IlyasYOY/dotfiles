return {
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
}

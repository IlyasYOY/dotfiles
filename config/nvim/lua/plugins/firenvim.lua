return {
    {
        "glacambre/firenvim",
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
                    set guifont=Hack:h16

                else
                    set laststatus=2
                endif
            ]]
        end,

        -- Lazy load firenvim
        -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
        cond = not not vim.g.started_by_firenvim,
    },
}

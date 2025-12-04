return {
    {
        "kristijanhusak/vim-dadbod-completion",
        lazy = true,
        config = function()
            vim.cmd [[
                autocmd FileType sql setlocal omnifunc=vim_dadbod_completion#omni
            ]]
        end,
    },
}

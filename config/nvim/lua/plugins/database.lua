return {
    {
        "kristijanhusak/vim-dadbod-ui",
        lazy = true,
        cmd = { "DB", "DBUI" },
        ft = { "sql", "mysql", "plsql" },
        config = function()
            vim.g.db_ui_save_location = vim.fn.getcwd() .. "/sql/"
        end,
        dependencies = {
            "tpope/vim-dadbod",
            "kristijanhusak/vim-dadbod-completion",
        },
    },
    { "tpope/vim-dadbod", lazy = true },
    {
        "kristijanhusak/vim-dadbod-completion",
        lazy = true,
        config = function()
            vim.cmd [[
                autocmd FileType sql setlocal omnifunc=vim_dadbod_completion#omni
                autocmd FileType sql,mysql,plsql lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} })
            ]]
        end,
    },
}

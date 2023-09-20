return {
    {
        "tpope/vim-dadbod",
        lazy = true,
        cmd = { "DB", "DBUI" },
        ft = { "sql", "mysql", "plsql" },
        dependencies = {
            {
                "kristijanhusak/vim-dadbod-completion",
                config = function()
                    vim.cmd [[
                    autocmd FileType sql setlocal omnifunc=vim_dadbod_completion#omni
                    autocmd FileType sql,mysql,plsql lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} })
                    ]]
                end,
            },
            {
                "kristijanhusak/vim-dadbod-ui",
                config = function()
                    vim.g.db_ui_save_location = vim.fn.getcwd() .. "/sql/"
                end,
            },
        },
    },
}

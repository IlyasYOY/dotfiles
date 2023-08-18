return {
    { "tpope/vim-dadbod", lazy = true, cmd = { "DB", "DBUI" } },
    {
        "kristijanhusak/vim-dadbod-ui",
        lazy = true,
        cmd = { "DBUI" },
        config = function()
            vim.g.db_ui_save_location = vim.fn.getcwd() .. "/sql/"
        end,
    },
}

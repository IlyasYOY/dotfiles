return {
    {
        "kristijanhusak/vim-dadbod-ui",
        lazy = true,
        cmd = { "DB", "DBUI" },
        ft = { "sql", "mysql", "plsql" },
        config = function()
            vim.g.db_ui_save_location = vim.fn.getcwd() .. "/sql/"
            vim.g.db_ui_table_helpers = {
                postgresql = {
                    ["Table Size"] = [[
select table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))), pg_total_relation_size(quote_ident(table_name)) from information_schema.tables where table_schema = 'public' and table_name = '{table}';
]],
                    ["Count"] = [[
select count(*) from {table};
]],
                },
            }
        end,
        dependencies = {
            "tpope/vim-dadbod",
            "kristijanhusak/vim-dadbod-completion",
        },
    },
}

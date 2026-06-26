local name = vim.fn.expand("%:t"):lower()

local dialect = "ansi"
if name:find "clickhouse" or name:find "ch" then
    dialect = "clickhouse"
elseif name:find "postgres" or name:find "pg" then
    dialect = "postgres"
end

vim.bo.formatprg = string.format("sqlfluff format --dialect %s -", dialect)

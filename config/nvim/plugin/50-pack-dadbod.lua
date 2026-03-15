local pack = require "ilyasyoy.pack"

vim.pack.add(pack.specs.dadbod, pack.no_load())

for _, command in ipairs {
    "DB",
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
    "DBUILastQueryInfo",
    "DBUIRenameBuffer",
    "DBUIExecuteQuery",
    "DBUIToggleDetails",
} do
    pack.lazy_user_command("dadbod", command, { nargs = "*", bang = true, range = true })
end

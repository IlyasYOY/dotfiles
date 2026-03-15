local pack = require "ilyasyoy.pack"

vim.pack.add(pack.specs.fzf_lua, pack.no_load())
pack.lazy_user_command("fzf_lua", "FzfLua", { nargs = "*" })

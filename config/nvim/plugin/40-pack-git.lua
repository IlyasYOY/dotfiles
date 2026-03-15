local pack = require "ilyasyoy.pack"

vim.pack.add(pack.specs.git_tools, pack.no_load())

for _, command in ipairs {
    { name = "Dispatch", opts = { nargs = "*" } },
    { name = "Git", opts = { nargs = "*", bang = true, range = true } },
    { name = "Gedit", opts = { nargs = "*", bang = true } },
    { name = "GBrowse", opts = { nargs = "*", bang = true, range = true } },
    { name = "Gclog", opts = { nargs = "*", bang = true, range = true } },
    { name = "Gtabedit", opts = { nargs = "*", bang = true } },
    { name = "Gvdiffsplit", opts = { nargs = "*", bang = true } },
} do
    pack.lazy_user_command("git_tools", command.name, command.opts)
end

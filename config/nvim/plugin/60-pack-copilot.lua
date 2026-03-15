local pack = require "ilyasyoy.pack"

vim.pack.add(pack.specs.copilot, pack.no_load())
pack.lazy_user_command("copilot", "Copilot", { nargs = "*", bang = true })

vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    callback = function()
        pack.load "copilot"
    end,
})

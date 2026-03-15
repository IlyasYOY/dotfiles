local pack = require "ilyasyoy.pack"

vim.pack.add(pack.specs.oil, pack.no_load())
pack.lazy_user_command("oil", "Oil", { nargs = "*" })

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        if vim.fn.argc() ~= 1 then
            return
        end

        local path = vim.fn.argv(0)
        if vim.fn.isdirectory(path) == 0 then
            return
        end

        path = vim.fn.fnamemodify(path, ":p")
        vim.schedule(function()
            pack.load "oil"
            vim.cmd("Oil " .. vim.fn.fnameescape(path))
        end)
    end,
})

vim.cmd "source ~/.vimrc"

vim.g.netrw_banner = 0 -- Now we won't have bloated top of the window
vim.g.netrw_liststyle = 3 -- Now it will be a tree view
vim.g.netrw_bufsettings = "nu nobl"

vim.opt.laststatus = 3
vim.cmd "highlight WinSeparator guibg=None"

vim.opt.spelllang = "ru_ru,en_us"
vim.opt.spellfile = vim.fn.expand "~/.config/nvim/spell/custom.utf-8.add"

local function replace_browse()
    local command

    if vim.fn.has "mac" == 1 then
        command = 'call jobstart(["open", "<args>"], {"detach": v:true})'
    elseif vim.fn.has "unix" == 1 then
        command = 'call jobstart(["xdg-open", "<args>"], {"detach": v:true})'
    else
        command = 'lua print("Error: gx is not supported on this OS!")'
    end

    vim.api.nvim_create_user_command("Browse", command, { nargs = 1 })

    vim.keymap.set("n", "gx", function()
        local link = vim.fn.expand "<cfile>"
        vim.cmd.Browse(link)
    end)
end

replace_browse()

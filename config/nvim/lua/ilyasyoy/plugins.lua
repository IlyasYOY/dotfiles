local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "

require("lazy").setup("plugins", {
    change_detection = {
        enabled = false,
        notify = false, -- get a notification when changes are found
    },
    dev = {
        path = "~/Projects/other",
        patterns = { "IlyasYOY" },
        fallback = true,
    },
})

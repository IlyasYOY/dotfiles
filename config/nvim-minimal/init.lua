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

require("lazy").setup({
    "nvim-treesitter/nvim-treesitter",
    build = function()
        local ts_update = require("nvim-treesitter.install").update {
            with_sync = true,
        }
        ts_update()
    end,
    config = function()
        local ts_config = require "nvim-treesitter.configs"

        ts_config.setup {
            ensure_installed = "all",
        }
    end,
}, {
    change_detection = {
        enabled = false,
        notify = false,
    },
})

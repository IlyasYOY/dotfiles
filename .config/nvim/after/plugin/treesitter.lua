local ts_config = require "nvim-treesitter.configs"

ts_config.setup {
    ensure_installed = {
        "lua",
        "rust",
        "java",
        "kotlin",
        "python",
        "markdown",
        "javascript",
    },
    sync_install = false,
    auto_install = false,
    highlight = {
        enable = true,
        disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats =
                pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                return true
            end
        end,
        additional_vim_regex_highlighting = false,
    },
}

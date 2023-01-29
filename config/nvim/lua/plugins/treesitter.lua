return {
    "nvim-treesitter/playground",
    {
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
                ensure_installed = {
                    "lua",
                    "rust",
                    "java",
                    "kotlin",
                    "python",
                    "markdown",
                    "markdown_inline",
                    "javascript",
                },
                sync_install = false,
                auto_install = false,
                highlight = {
                    enable = true,
                    disable = function(lang, buf)
                        local max_filesize = 100 * 1024 -- 100 KB
                        local ok, stats = pcall(
                            vim.loop.fs_stat,
                            vim.api.nvim_buf_get_name(buf)
                        )
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end,
                    additional_vim_regex_highlighting = false,
                },
            }
        end,
    },
}
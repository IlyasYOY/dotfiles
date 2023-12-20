return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "IlyasYOY/coredor.nvim",
            "ellisonleao/gruvbox.nvim",
        },
        config = function()
            local core = require "coredor"
            local lualine = require "lualine"

            local function is_jdtls_buffer()
                local buf_path = vim.fn.expand "%"
                return core.string_has_prefix(buf_path, "jdt", true)
            end

            lualine.setup {
                options = {
                    theme = "gruvbox",
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch" },
                    lualine_c = {
                        {
                            "filename",
                            path = 3,
                            cond = function()
                                return not is_jdtls_buffer()
                            end,
                        },
                        {
                            "filename",
                            cond = function()
                                return is_jdtls_buffer()
                            end,
                        },
                    },
                    lualine_x = { "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            }
        end,
    },
}

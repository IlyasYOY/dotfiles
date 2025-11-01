return {
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            local lualine = require "lualine"

            local function is_jdtls_buffer()
                local buf_path = vim.fn.expand "%"
                return 1 == string.find(buf_path, "jdt", 1, true)
            end

            lualine.setup {
                options = {
                    icons_enabled = false,
                },
                sections = {
                    lualine_a = {
                        "lsp_status",
                    },
                    lualine_b = { 'FugitiveHead' },
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
                    lualine_x = { "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            }
        end,
    },
}

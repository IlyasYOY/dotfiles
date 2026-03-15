local lualine = require "lualine"

local function is_jdtls_buffer()
    local buf_path = vim.fn.expand "%"
    return 1 == string.find(buf_path, "jdt", 1, true)
end

local function fugitive_head()
    if vim.fn.exists "*FugitiveHead" == 0 then
        return ""
    end

    return vim.fn.FugitiveHead()
end

lualine.setup {
    options = {
        icons_enabled = false,
    },
    sections = {
        lualine_a = {
            "lsp_status",
        },
        lualine_b = {
            {
                fugitive_head,
                cond = function()
                    return fugitive_head() ~= ""
                end,
            },
        },
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

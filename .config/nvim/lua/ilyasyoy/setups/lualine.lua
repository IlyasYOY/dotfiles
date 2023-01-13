local lualine = require "lualine"
local core = require "ilyasyoy.functions.core"

local function active_lsp_names()
    local result = {}
    local clients = vim.lsp.get_active_clients()
    for _, client in ipairs(clients) do
        if client.initialized then
            table.insert(result, client.name)
        end
    end
    return core.string_merge(result, ", ")
end

local function get_cwd()
    return vim.fn.pathshorten(vim.fn.getcwd())
end

-- local noirbuddy_lualine = require "noirbuddy.plugins.lualine"

lualine.setup {
    options = {
        -- theme = noirbuddy_lualine.theme,
        theme = "gruvbox",
    },
    -- inactive_sections = noirbuddy_lualine.inactive_sections,
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diagnostics" },
        lualine_c = { "filename", get_cwd },
        lualine_x = { "fileformat", "filetype", active_lsp_names },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
}

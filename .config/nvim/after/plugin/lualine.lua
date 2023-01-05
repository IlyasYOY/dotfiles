local lualine = require "lualine"
local core = require "functions.core"

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

lualine.setup {
    options = {
        theme = "gruvbox",
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diagnostics" },
        lualine_c = { "filename", get_cwd },
        lualine_x = { "fileformat", "filetype", active_lsp_names },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
}

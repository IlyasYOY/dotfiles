-- TODO: Remove this file and use vim.keymap
-- Functional wrapper for mapping custom keybindings
local function map(mode, alias, command, custom_options)
    local default_options = { noremap = true }
    if custom_options then
        default_options =
            vim.tbl_extend("force", default_options, custom_options)
        if default_options == nil then
            vim.notify(
                "Cannot map mode:"
                    .. mode
                    .. " alias:"
                    .. alias
                    .. " for:"
                    .. command
                    .. " options:"
                    .. custom_options
            )
            return
        end
    end
    vim.keymap.set(mode, alias, command, default_options)
end

local M = {}

M.map = map

M.map_interactive = function(lhs, rhs, opts)
    map("i", lhs, rhs, opts)
end

M.map_visual_and_select = function(lhs, rhs, opts)
    map("v", lhs, rhs, opts)
end

M.map_select = function(lhs, rhs, opts)
    map("s", lhs, rhs, opts)
end

M.map_comand = function(lhs, rhs, opts)
    map("c", lhs, rhs, opts)
end

M.map_terminal = function(lhs, rhs, opts)
    map("t", lhs, rhs, opts)
end

M.map_visual = function(lhs, rhs, opts)
    map("x", lhs, rhs, opts)
end

M.map_operator = function(lhs, rhs, opts)
    map("o", lhs, rhs, opts)
end


return M

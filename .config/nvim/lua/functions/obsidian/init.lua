local Vault = require "functions.obsidian.vault"

local M = {}

-- This functions creates module filesds that hold API tables.
--- @param opts table this is options table
function M.setup(opts)
    M.vault = Vault:new(opts)
end

return M

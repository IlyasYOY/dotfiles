local Vault = require "ilyasyoy.functions.obsidian.vault"

local M = {}

---This functions creates module filesds that hold API tables.
---@param opts ilyasyoy.obsidian.VaultOpts
function M.setup(opts)
    M.vault = Vault:new(opts)
end

return M

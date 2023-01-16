local core = require "ilyasyoy.functions.core"
local lsp = require "ilyasyoy.functions.lsp"
local lspconfig = require "lspconfig"

local library = {}
local path = core.string_split(package.path, ";")

-- this is the ONLY correct way to setup your path
table.insert(path, "lua/?.lua")
table.insert(path, "lua/?/init.lua")

local function add(lib)
    for _, p in pairs(vim.fn.expand(lib, false, true)) do
        p = vim.loop.fs_realpath(p)
        if p then
            library[p] = true
        end
    end
end

-- add runtime
add "$VIMRUNTIME"
-- add plugins
-- if you're not using packer, then you might need to change the paths below
add "~/.local/share/nvim/site/pack/packer/opt/*"
add "~/.local/share/nvim/site/pack/packer/start/*"

lspconfig.sumneko_lua.setup {
    on_attach = lsp.on_attach,
    capabilities = lsp.get_capabilities(),
    settings = {
        Lua = {
            runtime = { version = "LuaJIT", path = path },
            diagnostics = {
                globals = {
                    "vim",
                    -- Tests
                    "assert",
                    "describe",
                    "it",
                    "setup",
                    "before_each",
                    "after_each",
                    "teardown",
                    "pending",
                    "clear",

                    "G_P",
                    "G_R",
                },
            },
            format = {
                enable = false,
            },
            workspace = {
                library = library,
                checkThirdParty = false,
            },
            telemetry = {
                enable = false,
            },
        },
    },
}

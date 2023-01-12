local described = require("ilyasyoy.functions.core").described
local lsp = require "ilyasyoy.functions.lsp"
local lspconfig = require "lspconfig"

-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set(
    "n",
    "<leader>d",
    vim.diagnostic.open_float,
    described(opts, "[d]iagnostics")
)
vim.keymap.set(
    "n",
    "[d",
    vim.diagnostic.goto_prev,
    described(opts, "Previous [d]iagostics")
)
vim.keymap.set(
    "n",
    "]d",
    vim.diagnostic.goto_next,
    described(opts, "Next [d]iagnostics")
)
vim.keymap.set(
    "n",
    "<leader>dl",
    vim.diagnostic.setloclist,
    described(opts, "Put [d]iagnostics to [q]uickfix list")
)

local generic_servers = { "gopls", "gradle_ls", "pyright", "rust_analyzer", "tsserver" }
for _, client in ipairs(generic_servers) do
    lspconfig[client].setup {
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
    }
end

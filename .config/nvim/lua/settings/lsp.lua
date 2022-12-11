-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<space>d", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)

    vim.keymap.set("n", "<leader>S", vim.lsp.buf.workspace_symbol, bufopts)

    vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, bufopts)
    vim.keymap.set({ "n", "i" }, "<C-s>", vim.lsp.buf.signature_help, bufopts)

    vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)

    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, bufopts)
    vim.keymap.set({ "n", "v" }, "<space>oc", function() vim.lsp.buf.format { async = true } end, bufopts)

    vim.keymap.set({ "n" }, "<space>a", vim.lsp.buf.code_action, bufopts)
    vim.keymap.set({ "v" }, "<space>a", vim.lsp.buf.code_action, bufopts)
end

local get_capabilities = function()
    return require("cmp_nvim_lsp").default_capabilities()
end

local lspconfig = require("lspconfig")

local capabilities = get_capabilities()
local generic_servers = { "gopls", "gradle_ls", "jdtls", "pyright", "rust_analyzer" }
for _, lsp in ipairs(generic_servers) do
    lspconfig[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
    }
end

local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

-- this trick remove doubling of my dir in completion
local runtime_file = vim.api.nvim_get_runtime_file("", true)
table.remove(runtime_file, 1)

lspconfig.sumneko_lua.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = { version = "LuaJIT", path = runtime_path, },
            diagnostics = { globals = { "vim" }, },
            workspace = {
                library = runtime_file,
                checkThirdParty = false,
            },
            telemetry = {
                enable = false,
            },
        },
    },
}


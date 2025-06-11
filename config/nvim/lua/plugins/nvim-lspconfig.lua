local lsp = require "ilyasyoy.functions.lsp"

local described = lsp.described

local opts = { noremap = true, silent = true }

local function setup_generic()
    local lspconfig = require "lspconfig"

    local generic_servers = {
        "clojure_lsp",
        "rust_analyzer",
        "bashls",
    }
    for _, client in ipairs(generic_servers) do
        lspconfig[client].setup {
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end
end

local function setup_go()
    local lspconfig = require "lspconfig"

    local hints = vim.empty_dict()
    hints.assignVariableTypes = true
    hints.compositeLiteralFields = true
    hints.compositeLiteralTypes = true
    hints.constantValues = true
    hints.functionTypeParameters = true
    hints.parameterNames = true
    hints.rangeVariableTypes = true

    lspconfig.gopls.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.documentFormattingProvider = false
            lsp.on_attach(client, bufnr)
        end,
        settings = {
            gopls = {
                codelenses = {
                    test = true,
                    gc_details = true,
                    generate = true,
                    run_govulncheck = true,
                    tidy = true,
                    upgrade_dependency = true,
                    vendor = true,
                },
                gofumpt = true,
                completeUnimported = true,
                usePlaceholders = false,
                diagnosticsDelay = "250ms",
                staticcheck = true,
                hints = hints,
                analyses = {
                    framepointer = true,
                    modernize = true,
                    nilness = true,
                    hostport = true,
                    gofix = true,
                    sigchanyzer = true,
                    stdversion = true,
                    unreachable = true,
                    unusedfunc = true,
                    unusedparams = true,
                    unusedvariable = true,
                    unusedwrite = true,
                    useany = true,
                },
            },
        },
        capabilities = lsp.get_capabilities(),
    }
end

local function setup_tsserver()
    local lspconfig = require "lspconfig"

    lspconfig.ts_ls.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.documentFormattingProvider = false
            lsp.on_attach(client, bufnr)
        end,
        capabilities = lsp.get_capabilities(),
    }
end

local function setup_clangd()
    local lspconfig = require "lspconfig"

    lspconfig.clangd.setup {
        on_attach = lsp.on_attach,
        filetypes = { "c", "cpp" },
        capabilities = lsp.get_capabilities(),
    }
end

local function setup_lua()
    local lspconfig = require "lspconfig"

    lspconfig.lua_ls.setup {
        root_dir = lspconfig.util.root_pattern(
            "init.lua",
            ".luarc.json",
            ".luarc.jsonc",
            ".luacheckrc",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            "selene.yml",
            ".git"
        ),
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
    }
end

local function setup_python()
    local lspconfig = require "lspconfig"

    lspconfig.basedpyright.setup {
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
    }
end

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "folke/lazydev.nvim",
        },
        config = function()
            -- HACK: This sucker dosn't work if I add it as a simple plugin due
            -- to lazy.nvim's 'lazy' nature.
            require("lazydev").setup()

            setup_generic()
            setup_tsserver()
            setup_lua()
            setup_python()
            setup_clangd()
            setup_go()

            local bufopts = { noremap = true, silent = true }

            vim.keymap.set(
                "n",
                "<leader>d",
                vim.diagnostic.open_float,
                described(opts, "diagnostics")
            )

            vim.keymap.set({ "n", "v" }, "<leader>oc", function()
                vim.lsp.buf.format { async = false, timeout_ms = 10000 }
            end, described(bufopts, "organize code"))

            vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<cr>")

            vim.lsp.handlers["textDocument/hover"] =
                vim.lsp.with(vim.lsp.handlers.hover, {
                    border = "single",
                })
        end,
    },
}

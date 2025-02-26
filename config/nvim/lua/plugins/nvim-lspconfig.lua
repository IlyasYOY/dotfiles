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
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
        settings = {
            Lua = {
                diagnostics = {
                    globals = {
                        "vim",
                        "assert",
                        "describe",
                        "it",
                        "before_each",
                        "after_each",
                        "pending",
                        "clear",

                        "G_P",
                        "G_R",
                    },
                },
                format = {
                    enable = false,
                },
            },
        },
    }
end

local function setup_python()
    local lspconfig = require "lspconfig"

    lspconfig.pylsp.setup {
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
        settings = {
            settings = {
                pylsp = {
                    plugins = {
                        black = { enabled = false },
                        autopep8 = { enabled = false },
                        yapf = { enabled = false },
                        pylint = { enabled = false },
                        pyflakes = { enabled = false },
                        pycodestyle = { enabled = false },

                        pylsp_mypy = { enabled = true },
                        jedi_completion = { fuzzy = true },
                        pyls_isort = { enabled = true },
                        sort = { enabled = true },
                    },
                },
            },
        },
    }
end

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "folke/neodev.nvim",
        },
        config = function()
            require("neodev").setup {
                override = function(root_dir, options)
                    for _, plugin in ipairs(require("lazy").plugins()) do
                        if plugin.dev and root_dir == plugin.dir then
                            options.plugins = true
                        end
                    end
                end,
            }
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

            vim.keymap.set(
                { "n", "v" },
                "<space>a",
                vim.lsp.buf.code_action,
                described(bufopts, "Perform code action")
            )

            vim.lsp.handlers["textDocument/hover"] =
                vim.lsp.with(vim.lsp.handlers.hover, {
                    border = "single",
                })
        end,
    },
}

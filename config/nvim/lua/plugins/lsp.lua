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

local function setup_tsserver()
    local lspconfig = require "lspconfig"

    lspconfig.tsserver.setup {
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

local function setup_go()
    local lspconfig = require "lspconfig"
    local util = require "lspconfig.util"

    lspconfig.gopls.setup {
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_dir = util.root_pattern("go.work", "go.mod", ".git"),
        settings = {
            gopls = {
                gofumpt = true,
                codelenses = {
                    gc_details = true,
                    test = true,
                    generate = true,
                },
                completeUnimported = true,
                usePlaceholders = false,
                staticcheck = true,
                analyses = {
                    unusedparams = true,
                    unreachable = true,
                    unusedwrite = true,
                    unusedvariable = true,
                    useany = true,
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
        "j-hui/fidget.nvim",
        tag = "legacy",
        lazy = true,
        event = "LspAttach",
        opts = {},
    },
    {
        "folke/neodev.nvim",
        lazy = true,
    },
    {
        "mfussenegger/nvim-jdtls",
        lazy = true,
        ft = {
            "java",
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "IlyasYOY/coredor.nvim",
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
            setup_go()
            setup_clangd()

            local bufopts = { noremap = true, silent = true }

            vim.keymap.set(
                "n",
                "<leader>d",
                vim.diagnostic.open_float,
                described(opts, "diagnostics")
            )
            vim.keymap.set(
                "n",
                "[d",
                vim.diagnostic.goto_prev,
                described(opts, "Previous diagostics")
            )
            vim.keymap.set(
                "n",
                "]d",
                vim.diagnostic.goto_next,
                described(opts, "Next diagnostics")
            )

            vim.keymap.set({ "n", "v" }, "<space>oc", function()
                vim.lsp.buf.format { async = false, timeout_ms = 5000 }
            end, described(bufopts, "organize code"))

            vim.keymap.set(
                { "n", "v" },
                "<space>a",
                vim.lsp.buf.code_action,
                described(bufopts, "Perform code action")
            )

            vim.keymap.set(
                "n",
                "<leader>k",
                vim.lsp.buf.hover,
                described(bufopts, "show hover")
            )
        end,
    },
}

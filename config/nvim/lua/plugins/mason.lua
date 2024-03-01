return {
    {
        "jayp0521/mason-nvim-dap.nvim",
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function()
            require("mason-nvim-dap").setup {
                ensure_installed = {
                    "python",
                    "delve",
                    "javadbg",
                    "javatest",
                },
                automatic_installation = false,
            }
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function()
            require("mason-lspconfig").setup {
                ensure_installed = {
                    "gopls",
                    "clangd",
                    "jdtls",
                    "lua_ls",
                    "clojure_lsp",
                    "rust_analyzer",
                    "tsserver",
                    "bashls",
                },
                automatic_installation = false,
            }
        end,
    },
    {
        "jayp0521/mason-null-ls.nvim",
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function()
            require("mason-null-ls").setup {
                ensure_installed = {
                    "ruff",
                    "checkstyle",
                    "eslint_d",
                    "gofumpt",
                    "goimports",
                    "golangci-lint",
                    "golines",
                    "gomodifytags",
                    "impl",
                    "gotests",
                    "gotestsum",
                    "json-to-struct",
                    "isort",
                    "jsonlint",
                    "luacheck",
                    "markdownlint",
                    "prettier",
                    "pylint",
                    "sqlfluff",
                    "stylelint",
                    "stylua",
                    "yamllint",
                },
                automatic_installation = false,
            }
        end,
    },
    {
        "williamboman/mason.nvim",
        config = function()
            local mason = require "mason"

            mason.setup {
                PATH = "append",
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            }
        end,
    },
}

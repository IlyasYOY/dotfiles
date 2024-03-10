return {
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function()
            require("mason-tool-installer").setup {
                ensure_installed = {
                    "autopep8",
                    "bash-language-server",
                    "checkstyle",
                    "clangd",
                    "clojure-lsp",
                    "debugpy",
                    "delve",
                    "eslint_d",
                    "gofumpt",
                    "goimports",
                    "golangci-lint",
                    "golines",
                    "gomodifytags",
                    "gopls",
                    "gotests",
                    "gotestsum",
                    "impl",
                    "isort",
                    "java-debug-adapter",
                    "java-test",
                    "jdtls",
                    "json-to-struct",
                    "jsonlint",
                    "lua-language-server",
                    "luacheck",
                    "markdownlint",
                    "prettier",
                    "pylint",
                    "ruff",
                    "rust-analyzer",
                    "sqlfluff",
                    "stylelint",
                    "stylua",
                    "typescript-language-server",
                    "yamllint",
                },
                start_delay = 0,
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

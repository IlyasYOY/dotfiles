return {
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
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup {
                ensure_installed = {
                    "gopls",
                    "jdtls",
                    "lua_ls",
                    "clojure_lsp",
                    "pyright",
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
        config = function()
            require("mason-null-ls").setup {
                ensure_installed = {
                    "stylua",
                    "luacheck",
                    "jsonlint",
                    "yamllint",
                    "pylint",
                    "autopep8",
                    "isort",
                    "prettier",
                    "stylelint",
                    "eslint_d",
                    "checkstyle",
                },
                automatic_installation = false,
            }
        end,
    },
    {
        "jayp0521/mason-nvim-dap.nvim",
        config = function()
            require("mason-nvim-dap").setup {
                ensure_installed = {
                    "python",
                    "javadbg",
                    "javatest",
                },
                automatic_installation = false,
            }
        end,
    },
}

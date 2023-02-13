return {
    {
        "williamboman/mason.nvim",
        config = function()
            local mason = require "mason"

            mason.setup {
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
                    "gradle_ls",
                    "jdtls",
                    "lua_ls",
                    "pyright",
                    "rust_analyzer",
                    "tsserver",
                },
                automatic_installation = true,
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
                    "markdownlint",
                },
                automatic_installation = true,
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
                automatic_installation = true,
            }
        end,
    },
}

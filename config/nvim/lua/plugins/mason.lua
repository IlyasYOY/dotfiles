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
                    "pylsp",
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
                    "autopep8",
                    "checkstyle",
                    "eslint_d",
                    "gofumpt",
                    "goimports",
                    "golangci-lint",
                    "golines",
                    "gomodifytags",
                    "impl",
                    "isort",
                    "jsonlint",
                    "luacheck",
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

            local pylsp =
                require("mason-registry").get_package "python-lsp-server"
            pylsp:on("install:success", function()
                local function mason_package_path(package)
                    local path = vim.fn.resolve(
                        vim.fn.stdpath "data" .. "/mason/packages/" .. package
                    )
                    return path
                end

                local path = mason_package_path "python-lsp-server"
                local command = path .. "/venv/bin/pip"
                local args = {
                    "install",
                    "rope",
                    "pylsp-rope",
                    "pylsp-mypy",
                    "pyls-isort",
                    -- "python-lsp-black",
                    -- "pyflakes",
                    -- "python-lsp-ruff",
                    -- "pyls-flake8",
                    "sqlalchemy-stubs",
                }

                require("plenary.job")
                    :new({
                        command = command,
                        args = args,
                        cwd = path,
                    })
                    :start()
            end)
        end,
    },
}

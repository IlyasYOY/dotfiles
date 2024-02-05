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
                completeUnimported = true,
                usePlaceholders = true,
                analyses = {
                    unusedparams = true,
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
        "nvimtools/none-ls.nvim",
        config = function()
            local null_ls = require "null-ls"
            local core = require "ilyasyoy.functions.core"

            local function with_root_file(builtin, file)
                return builtin.with {
                    condition = function(utils)
                        return utils.root_has_file(file)
                    end,
                }
            end

            null_ls.setup {
                debounce = 150,
                save_after_format = false,
                sources = {
                    with_root_file(
                        null_ls.builtins.formatting.stylua,
                        "stylua.toml"
                    ),
                    with_root_file(
                        null_ls.builtins.diagnostics.luacheck,
                        ".luacheckrc"
                    ),

                    null_ls.builtins.diagnostics.jsonlint,
                    null_ls.builtins.diagnostics.yamllint,

                    null_ls.builtins.formatting.gofmt,
                    null_ls.builtins.formatting.goimports,
                    null_ls.builtins.diagnostics.golangci_lint,
                    null_ls.builtins.code_actions.impl,
                    null_ls.builtins.code_actions.gomodifytags,

                    null_ls.builtins.diagnostics.pylint,
                    null_ls.builtins.formatting.isort,
                    null_ls.builtins.formatting.autopep8,

                    with_root_file(
                        null_ls.builtins.formatting.prettier,
                        ".prettierrc.js"
                    ),
                    with_root_file(
                        null_ls.builtins.formatting.stylelint,
                        ".stylelintrc.js"
                    ),
                    with_root_file(
                        null_ls.builtins.code_actions.eslint_d,
                        ".eslintrc.js"
                    ),

                    null_ls.builtins.diagnostics.checkstyle.with {
                        args = { "-f", "sarif", "$FILENAME" },
                        extra_args = {
                            "-c",
                            core.resolve_realative_to_dotfiles_dir "config/checkstyle.xml",
                        },
                    },
                    null_ls.builtins.diagnostics.pmd.with {
                        args = {
                            "--format",
                            "json",
                            "--no-cache",
                            "--dir",
                            "$FILENAME",
                        },
                        extra_args = {
                            "-R",
                            core.resolve_realative_to_dotfiles_dir "config/pmd.xml",
                        },
                    },
                },
            }
        end,
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
                vim.lsp.buf.format { async = false }
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

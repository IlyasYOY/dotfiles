local lsp = require "ilyasyoy.functions.lsp"

local described = lsp.described

-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
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
vim.keymap.set(
    "n",
    "<leader>ld",
    vim.diagnostic.setloclist,
    described(opts, "Put diagnostics to quickfix list")
)

local function setup_generic()
    local lspconfig = require "lspconfig"

    local generic_servers = {
        "gopls",
        "gradle_ls",
        "pyright",
        "rust_analyzer",
        "tsserver",
        "bashls",
    }
    for _, client in ipairs(generic_servers) do
        lspconfig[client].setup {
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end
end

local function setup_lua()
    local lsp = require "ilyasyoy.functions.lsp"
    local lspconfig = require "lspconfig"

    lspconfig.lua_ls.setup {
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
        settings = {
            Lua = {
                diagnostics = {
                    globals = {
                        "vim",
                        -- Tests
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

return {
    { "onsails/lspkind.nvim" },
    { "folke/neodev.nvim" },
    {
        "mfussenegger/nvim-jdtls",
        lazy = true,
        ft = { "java" },
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
            setup_lua()

            -- NOTE: This mapping may be used by null-ls in any given file.
            local bufopts = { noremap = true, silent = true }

            vim.keymap.set({ "n", "v" }, "<space>oc", function()
                vim.lsp.buf.format { async = true }
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
    {
        "simrat39/symbols-outline.nvim",
        lazy = true,
        keys = {
            "<leader>O",
        },
        config = function()
            local outline = require "symbols-outline"

            outline.setup()

            vim.keymap.set("n", "<leader>O", function()
                outline.toggle_outline()
            end, { desc = "Opens Outline", silent = true })
        end,
    },
    {
        "jose-elias-alvarez/null-ls.nvim",
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
                debug = true,
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

                    null_ls.builtins.code_actions.gitsigns,

                    null_ls.builtins.diagnostics.checkstyle.with {
                        extra_args = {
                            "-c",
                            core.resolve_realative_to_dotfiles_dir "config/checkstyle.xml",
                        },
                    },
                    null_ls.builtins.diagnostics.pmd.with {
                        args = {
                            "check",
                            "--format",
                            "json",
                            "--no-cache",
                            "--no-progress",
                            "--dir",
                            "$ROOT",
                        },
                        extra_args = {
                            "-R",
                            core.resolve_realative_to_dotfiles_dir "config/pmd.xml",
                        },
                        timeout = 10000,
                    },
                },
            }
        end,
    },
}

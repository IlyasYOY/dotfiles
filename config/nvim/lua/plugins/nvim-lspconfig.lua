local lsp = require "ilyasyoy.functions.lsp"

local described = lsp.described

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
    vim.diagnostic.setqflist,
    described(opts, "Put diagnostics to quickfix list")
)

local function setup_generic()
    local lspconfig = require "lspconfig"

    local generic_servers = {
        "gopls",
        "pyright",
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

return {
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

            local bufopts = { noremap = true, silent = true }

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

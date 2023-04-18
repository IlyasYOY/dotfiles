local function setup_generic()
    local lsp = require "ilyasyoy.functions.lsp"
    local lspconfig = require "lspconfig"

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
        "<leader>dl",
        vim.diagnostic.setloclist,
        described(opts, "Put diagnostics to quickfix list")
    )

    local generic_servers =
        { "gopls", "gradle_ls", "pyright", "rust_analyzer", "tsserver", "bashls" }
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
    { "mfussenegger/nvim-jdtls" },
    { "onsails/lspkind.nvim" },
    { "folke/neodev.nvim" },
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
        end,
    },
    {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
            local null_ls = require "null-ls"

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
                },
            }
        end,
    },
    {
        "simrat39/symbols-outline.nvim",
        config = function()
            local outline = require "symbols-outline"

            outline.setup()

            vim.keymap.set("n", "<leader>O", function()
                outline.toggle_outline()
            end, { desc = "Opens Outline", silent = true })
        end,
    },
}

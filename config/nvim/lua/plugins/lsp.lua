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
        described(opts, "[d]iagnostics")
    )
    vim.keymap.set(
        "n",
        "[d",
        vim.diagnostic.goto_prev,
        described(opts, "Previous [d]iagostics")
    )
    vim.keymap.set(
        "n",
        "]d",
        vim.diagnostic.goto_next,
        described(opts, "Next [d]iagnostics")
    )
    vim.keymap.set(
        "n",
        "<leader>dl",
        vim.diagnostic.setloclist,
        described(opts, "Put [d]iagnostics to [q]uickfix list")
    )

    local generic_servers =
        { "gopls", "gradle_ls", "pyright", "rust_analyzer", "tsserver" }
    for _, client in ipairs(generic_servers) do
        lspconfig[client].setup {
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end
end

local function setup_lua()
    local coredor = require "coredor"
    local lsp = require "ilyasyoy.functions.lsp"
    local lspconfig = require "lspconfig"

    local library = {}
    local path = coredor.string_split(package.path, ";")

    -- this is the ONLY correct way to setup your path
    table.insert(path, "lua/?.lua")
    table.insert(path, "lua/?/init.lua")

    local function add(lib)
        local cwd = vim.fn.getcwd()
        for _, p in pairs(vim.fn.expand(lib, false, true)) do
            p = vim.loop.fs_realpath(p)
            if p then
                library[p] = true
            end
        end
    end

    -- add runtime
    add "$VIMRUNTIME"
    -- add plugins
    add "~/.local/share/nvim/lazy/*"
    add "~/Projects/other/git-link.nvim"
    add "~/Projects/other/coredor.nvim"

    lspconfig.sumneko_lua.setup {
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
        settings = {
            Lua = {
                runtime = { version = "LuaJIT", path = path },
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
                workspace = {
                    library = library,
                    checkThirdParty = false,
                },
                telemetry = {
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
        },
        config = function()
            setup_generic()
            setup_lua()
        end,
    },
    {
        "mfussenegger/nvim-jdtls",
    },
    { "onsails/lspkind.nvim" },
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
            end, { desc = "Opens [O]utline", silent = true })
        end,
    },
}

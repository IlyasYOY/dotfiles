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
        "RRethy/vim-illuminate",
        config = function()
            require("illuminate").configure {
                modes_allowlist = {"n"}
            }
            vim.cmd [[
                augroup illuminate_augroup
                    autocmd!
                    autocmd VimEnter * hi illuminatedWordRead cterm=none gui=none guibg=#526252
                    autocmd VimEnter * hi illuminatedWordText cterm=none gui=none guibg=#525252
                    autocmd VimEnter * hi illuminatedWordWrite cterm=none gui=none guibg=#625252
                augroup END
            ]]
        end,
    },
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
            setup_tsserver()
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
            -- local pmd_cpd_source = require "ilyasyoy.null-ls.pmd-cpd"
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
                            "$FILENAME",
                        },
                        extra_args = {
                            "-R",
                            core.resolve_realative_to_dotfiles_dir "config/pmd.xml",
                        },
                    },
                    -- TODO: check this from time to time.
                    -- for now it's almost unusable.
                    -- pmd_cpd_source.with {
                    --     extra_args = {
                    --         "--minimum-tokens=60",
                    --     },
                    -- },
                },
            }
        end,
    },
}

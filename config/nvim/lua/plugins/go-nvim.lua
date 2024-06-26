return {
    {
        "ray-x/go.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
            "ray-x/guihua.lua",
        },
        config = function()
            require("go").setup {
                dap_debug_keymap = false,
                icons = false,
                luasnip = true,
                dap_debug_gui = false,
                lsp_keymaps = false,
                lsp_document_formatting = false,
                lsp_on_attach = function(client, bufnr)
                    -- NOTE: somehow this happens to be nil when I open a new file.
                    if client then
                        client.server_capabilities.semanticTokensProvider = nil
                        require("ilyasyoy.functions.lsp").on_attach(
                            client,
                            bufnr
                        )
                    end
                end,
                lsp_codelens = true,
                lsp_cfg = {
                    settings = {
                        gopls = {
                            gofumpt = true,
                            codelenses = {},
                            completeUnimported = true,
                            usePlaceholders = false,
                            staticcheck = true,
                            analyses = {
                                unusedparams = true,
                                framepointer = true,
                                sigchanyzer = true,
                                unreachable = true,
                                stdversion = true,
                                unusedwrite = true,
                                unusedvariable = true,
                                useany = true,
                                nilness = true,
                            },
                        },
                    },
                },
                textobjects = false,
                lsp_inlay_hints = {
                    enable = false,
                },
            }

            -- vim.keymap.set("n", "<leader><leader>gtf", "<cmd>GoTestFile<cr>")
            vim.keymap.set("n", "<leader><leader>gtf", function()
                local makeprg = vim.opt_local.makeprg
                vim.cmd.GoTestFile()
                vim.opt_local.makeprg = makeprg
            end)
            -- vim.keymap.set("n", "<leader><leader>gtp", "<cmd>GoTestPackage<cr>")
            vim.keymap.set("n", "<leader><leader>gtp", function()
                local makeprg = vim.opt_local.makeprg
                vim.cmd.GoTestPackage()
                vim.opt_local.makeprg = makeprg
            end)
            -- vim.keymap.set("n", "<leader><leader>gtt", "<cmd>GoTestFunc<cr>")
            vim.keymap.set("n", "<leader><leader>gtt", function()
                local makeprg = vim.opt_local.makeprg
                vim.cmd.GoTestFunc()
                vim.opt_local.makeprg = makeprg
            end)
            -- vim.keymap.set("n", "<leader><leader>gta", "<cmd>GoTest ./...<cr>")
            vim.keymap.set("n", "<leader><leader>gta", function()
                local makeprg = vim.opt_local.makeprg
                vim.cmd.GoTest "./..."
                vim.opt_local.makeprg = makeprg
            end)

            vim.keymap.set("n", "<leader><leader>gts", "<cmd>GoTestSum<cr>")
            vim.keymap.set("n", "<leader><leader>ga", "<cmd>GoCodeLenAct<cr>")
        end,
        event = { "CmdlineEnter" },
        ft = { "go", "gomod" },
    },
}

return {
    {
        "petertriho/cmp-git",
        config = function()
            require("cmp_git").setup {}
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "onsails/lspkind.nvim",

            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lsp-signature-help",

            "IlyasYOY/obs.nvim",

            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",

            "davidsierradz/cmp-conventionalcommits",
            "petertriho/cmp-git",
        },
        config = function()
            local luasnip = require "luasnip"
            local cmp = require "cmp"
            local lspkind = require "lspkind"
            local cmp_source = require "obs.cmp-source"

            cmp.register_source("obs", cmp_source.new())

            cmp.setup {
                completion = {
                    autocomplete = {},
                },
                formatting = {
                    format = lspkind.cmp_format {
                        mode = "text",
                        maxwidth = 50,
                        ellipsis_char = "...",
                        menu = {
                            nvim_lsp = "[lsp]",
                            nvim_lsp_signature_help = "[signature]",
                            luasnip = "[snippet]",
                            buffer = "[buffer]",
                            conventionalcommits = "[commit]",
                            git = "[git]",
                            path = "[path]",
                            obs = "[notes]",
                        },
                    },
                },
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert {
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    },

                    ["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item()),
                    ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item()),

                    ["<C-j>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<C-k>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "nvim_lsp_signature_help" },
                    { name = "luasnip" },
                    { name = "path" },
                },
            }
        end,
    },
}

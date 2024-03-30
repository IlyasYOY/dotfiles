return {
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "onsails/lspkind.nvim",
            "L3MON4D3/LuaSnip",
            "IlyasYOY/obs.nvim",

            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lsp-signature-help",
            "saadparwaiz1/cmp_luasnip",
            "davidsierradz/cmp-conventionalcommits",
        },
        config = function()
            local luasnip = require "luasnip"

            local cmp = require "cmp"
            local types = require "cmp.types"
            local cmp_feedkeys = require "cmp.utils.feedkeys"
            local cmp_keymap = require "cmp.utils.keymap"

            local lspkind = require "lspkind"
            local cmp_source = require "obs.cmp-source"

            cmp.register_source("obs", cmp_source.new())

            cmp.setup {
                completion = {
                    autocomplete = {},
                },
                confirmation = {
                    default_behavior = types.cmp.ConfirmBehavior.Replace,
                },
                formatting = {
                    format = lspkind.cmp_format {
                        mode = "text",
                        maxwidth = 50,
                        ellipsis_char = "...",
                        menu = {
                            nvim_lsp = "[lsp]",
                            ["vim-dadbod-completion"] = "[db]",
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
                    ["<C-f>"] = cmp.mapping.complete(),
                    -- https://github.com/hrsh7th/nvim-cmp/issues/1326#issuecomment-1497250292
                    ["<CR>"] = function(fallback)
                        if vim.fn.pumvisible() == 1 then
                            if
                                vim.fn.complete_info({ "selected" }).selected
                                == -1
                            then
                                cmp_feedkeys.call(cmp_keymap.t "<CR>", "in")
                            else
                                cmp_feedkeys.call(
                                    cmp_keymap.t "<C-X><C-Z>",
                                    "in"
                                )
                            end
                        else
                            cmp.mapping.confirm { select = false }(fallback)
                        end
                    end,

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

                    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-d>"] = cmp.mapping.scroll_docs(4),
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

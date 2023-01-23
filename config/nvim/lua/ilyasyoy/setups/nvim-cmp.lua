local luasnip = require "luasnip"
local cmp = require "cmp"
local lspkind = require "lspkind"
local cmp_source = require "ilyasyoy.functions.obsidian.cmp-source"

cmp.register_source("obsidian", cmp_source.new())

cmp.setup {
    completion = {
        autocomplete = false,
    },
    formatting = {
        format = lspkind.cmp_format {
            mode = "text",
            maxwidth = 50,
            ellipsis_char = "...",
            menu = {
                nvim_lsp = "[LSP]",
                luasnip = "[Snippet]",
                obsidian = "[Notes]",
            },
        },
    },
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert {
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        },
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
    },
    sources = {
        { name = "nvim_lsp" },
        { name = "luasnip" },
    },
}

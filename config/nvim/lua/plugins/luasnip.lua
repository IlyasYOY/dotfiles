return {
    {
        "L3MON4D3/LuaSnip",
        dependencies = {
            "honza/vim-snippets",
        },
        config = function()
            local ls = require "luasnip"

            vim.keymap.set("i", "<C-f>", function()
                if ls.expandable() then
                    vim.schedule(function()
                        ls.expand()
                    end)
                else
                    return "<C-f>"
                end
            end, {
                expr = true
            })

            vim.keymap.set("i", "<C-j>", function()
                if ls.expandable() then
                    vim.schedule(function()
                        ls.expand()
                    end)
                elseif ls.locally_jumpable(1) then
                    ls.expand_or_jump()
                else
                    return "<C-j>"
                end
            end, {
                expr = true
            })

            vim.keymap.set("i", "<C-k>", function()
                if ls.jumpable(-1) then
                    ls.jump(-1)
                else
                    return "<C-k>"
                end
            end, {
                expr = true
            })

            vim.keymap.set("i", "<C-l>", function()
                if ls.choice_active() then
                    ls.change_choice(1)
                else
                    return "<C-l>"
                end
            end, {
                expr = true
            })

            vim.keymap.set("i", "<C-h>", function()
                if ls.choice_active() then
                    ls.change_choice(-1)
                else
                    return "<C-h>"
                end
            end, {
                expr = true
            })

            require("luasnip.loaders.from_snipmate").lazy_load()
            require("luasnip.loaders.from_lua").lazy_load {
                paths = { "~/.config/nvim/snippets/" },
            }
            ls.parser.parse_snippet(
                { trig = "lsp" },
                "$1 is ${2|hard,easy,challenging|}"
            )
        end,
    },
}

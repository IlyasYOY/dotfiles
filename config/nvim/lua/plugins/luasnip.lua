return {
    {
        "L3MON4D3/LuaSnip",
        dependencies = {
            "honza/vim-snippets",
        },
        config = function()
            local ls = require "luasnip"

            vim.keymap.set("i", "<C-l>", function()
                if ls.choice_active() then
                    ls.change_choice(1)
                end
            end)

            vim.keymap.set("i", "<C-h>", function()
                if ls.choice_active() then
                    ls.change_choice(-1)
                end
            end)

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

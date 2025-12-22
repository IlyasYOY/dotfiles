return {
    {
        "L3MON4D3/LuaSnip",
        event = "VeryLazy",
        ft = {
            "go",
            "java",
            "lua",
            "markdown",
        },
        dependencies = {
            "honza/vim-snippets",
        },
        config = function()
            local ls = require "luasnip"

            vim.keymap.set("i", "<Tab>", function()
                if ls.expandable() then
                    vim.schedule(function()
                        ls.expand()
                    end)
                else
                    return "<Tab>"
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


            local random = math.random
            local function uuid()
                local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
                return string.gsub(template, '[xy]', function(c)
                    local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
                    return string.format('%x', v)
                end)
            end

            ls.add_snippets(
                "all",
                {
                    ls.s({ trig = "uid", wordTrig = true }, { ls.f(uuid), ls.i(0) })
                }
            )
        end,
    },
}

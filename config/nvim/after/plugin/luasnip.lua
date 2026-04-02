local ls = require "luasnip"

ls.config.set_config {
    update_events = "TextChanged,TextChangedI",
}

local function schedule_luasnip(action)
    vim.schedule(action)
    return ""
end

vim.keymap.set({ "i" }, "<C-j>", function()
    if ls.expandable() then
        return schedule_luasnip(function()
            ls.expand()
        end)
    elseif ls.locally_jumpable(1) then
        return schedule_luasnip(function()
            ls.jump(1)
        end)
    end

    return "<C-j>"
end, { expr = true, silent = true })

vim.keymap.set({ "i", "s" }, "<C-k>", function()
    if ls.jumpable(-1) then
        return schedule_luasnip(function()
            ls.jump(-1)
        end)
    end

    return "<C-k>"
end, { expr = true, silent = true })

vim.keymap.set({ "i", "s" }, "<C-l>", function()
    if ls.choice_active() then
        return schedule_luasnip(function()
            ls.change_choice(1)
        end)
    end

    return "<C-l>"
end, { expr = true, silent = true })

vim.keymap.set({ "i", "s" }, "<C-h>", function()
    if ls.choice_active() then
        return schedule_luasnip(function()
            ls.change_choice(-1)
        end)
    end

    return "<C-h>"
end, { expr = true, silent = true })

vim.defer_fn(function()
    require("luasnip.loaders.from_snipmate").lazy_load()
    require("luasnip.loaders.from_lua").lazy_load {
        paths = { "~/.config/nvim/snippets/" },
    }

    local random = math.random
    local function uuid()
        local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        return string.gsub(template, "[xy]", function(c)
            local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
            return string.format("%x", v)
        end)
    end

    local ilyasyoy_snippets = require "ilyasyoy.snippets"
    local fmt = require("luasnip.extras.fmt").fmt
    ls.add_snippets("all", {
        ls.s("today", ilyasyoy_snippets.current_date()),
        ls.s("tomorrow", fmt("{}", ilyasyoy_snippets.tomorrow_date())),
        ls.s("yesterday", fmt("{}", ilyasyoy_snippets.yesterday_date())),
        ls.s({ trig = "uid", wordTrig = true }, { ls.f(uuid), ls.i(0) }),
    })
end, 0)

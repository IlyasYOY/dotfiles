local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

local function current_date()
    return f(function()
        return os.date "%Y-%m-%d"
    end)
end

return {
    s("cb", fmt("- {} {}", { c(1, { t "[ ]", t "[x]" }), i(0, "Todo") })),
    s("today", fmt("{}", current_date())),
    s("todaylink", fmt("[[{}]]", current_date())),
}

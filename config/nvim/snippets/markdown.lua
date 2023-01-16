local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

return {
    s("cb", fmt("- {} {}", { c(1, { t "[ ]", t "[x]" }), i(0, "Todo") })),
}

local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node

local date_format = "%Y-%m-%d"
local seconds_in_day = 60 * 60 * 24

local function current_date()
    return f(function()
        return os.date(date_format)
    end)
end

local function yesterday_date()
    return f(function()
        return os.date(date_format, os.time() - seconds_in_day)
    end)
end

local function tomorrow_date()
    return f(function()
        return os.date(date_format, os.time() + seconds_in_day)
    end)
end

return {
    s("checkbox", fmt("- {} {}", { c(1, { t "[ ]", t "[x]" }), i(0, "Todo") })),
    s("today", fmt("{}", current_date())),
    s("todaylink", fmt("[[{}]]", current_date())),
    s("tomorrow", fmt("{}", tomorrow_date())),
    s("tomorrowlink", fmt("[[{}]]", tomorrow_date())),
    s("yesterday", fmt("{}", yesterday_date())),
    s("yesterdaylink", fmt("[[{}]]", yesterday_date())),
    s(
        "callout",
        fmt("> [!{}] {}\n> {}", {
            c(1, {
                t "note",
                t "abstract",
                t "summary",
                t "tldr",
                t "info",
                t "todo",
                t "tip",
                t "hint",
                t "important",
                t "success",
                t "check",
                t "done",
                t "question",
                t "help",
                t "faq",
                t "warning",
                t "caution",
                t "attention",
                t "failure",
                t "fail",
                t "missing",
                t "danger",
                t "error",
                t "bug",
                t "example",
                t "quote",
                t "cite",
            }),
            i(2, "Title"),
            i(0, "Text"),
        })
    ),
}

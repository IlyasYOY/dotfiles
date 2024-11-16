local setup_colors = function()
    -- fork of: https://github.com/redbug312/cactusbuddy/blob/master/lua/cactusbuddy.lua
    local colorbuddy = require "colorbuddy"

    local Color = colorbuddy.Color
    local Group = colorbuddy.Group
    local c = colorbuddy.colors
    local g = colorbuddy.groups
    local s = colorbuddy.styles

    -- setup colors
    local palette = {
        white = { gui = "#bcbcbc", cterm = 250 },
        grey = { gui = "#949494", cterm = 246 },
        dark = { gui = "#767676", cterm = 243 },
        darker = { gui = "#585858", cterm = 240 },
        darkest = { gui = "#444444", cterm = 238 },
        base = { gui = "#262626", cterm = 235 },
        black = { gui = "#1c1c1c", cterm = 234 },
        backgnd = { gui = "#121212", cterm = 233 },

        cactus = { gui = "#5f875f", cterm = 065 }, -- darkgreen
        grass = { gui = "#87af87", cterm = 108 }, -- limegreen
        fruit = { gui = "#d787af", cterm = 175 }, -- coralpink
        brick = { gui = "#875f5f", cterm = 095 }, -- brickpink
        purple = { gui = "#8787af", cterm = 103 },
        cyan = { gui = "#87afd7", cterm = 110 },
        red = { gui = "#d75f5f", cterm = 167 },
        orange = { gui = "#d7875f", cterm = 173 },
        brown = { gui = "#af875f", cterm = 137 },
        blue = { gui = "#5f87af", cterm = 067 },
    }

    for key, value in pairs(palette) do
        Color.new(key, value.gui)
    end

    -- EDITOR BASICS
    -- https://neovim.io/doc/user/syntax.html#group-name

    --  Custom groups
    Group.new("Noise", c.dark, c.none, s.none)

    -- Basic groups
    Group.new("Comment", c.darker, c.none, s.none)
    Group.new("Normal", c.white, c.none, s.none)
    Group.new("NonText", c.darkest, c.none, s.none)

    Group.new("Error", c.red, c.none, s.none)
    Group.new("Number", c.grass, c.none, s.none)
    Group.new("Special", c.purple, c.none, s.none)
    Group.new("String", c.cactus, c.none, s.none)
    Group.new("Title", c.cyan, c.none, s.none)
    Group.new("Todo", c.fruit, c.none, s.none)
    Group.new("Warning", c.orange, c.none, s.none)

    -- https://neovim.io/doc/user/syntax.html#hl-User1
    Group.new("User1", c.brown, c.none, s.none)
    Group.new("User2", c.blue, c.none, s.none)
    Group.new("User3", c.brick, c.none, s.none)

    -- diff
    Group.new("Added", c.cactus, c.none, s.none)
    Group.new("Changed", c.brown, c.none, s.none)
    Group.new("Removed", c.brick, c.none, s.none)
    Group.new("DiffAdd", c.cactus, c.none, s.none)
    Group.new("DiffChange", c.brown, c.none, s.none)
    Group.new("DiffDelete", c.brick, c.none, s.none)
    Group.new("DiffLine", c.darker, c.none, s.underline)
    Group.new("DiffText", c.brown, c.none, s.none)

    -- search and highlight stuff
    Group.new("CurSearch", c.fruit, c.none, s.underline)
    Group.new("IncSearch", c.fruit, c.none, s.underline)
    Group.new("MatchParen", c.cyan, c.none, s.none)
    Group.new("Pmenu", c.darker, c.black, s.none)
    Group.new("PmenuSel", c.grey, c.black, s.none)
    Group.new("PmenuThumb", c.brown, c.black, s.none) -- not sure what this is
    Group.new("Search", c.fruit, c.none, s.underline)
    Group.new("StatusLine", c.none, c.black, s.none)
    Group.new("StatusLineNC", c.black, c.black, s.none)
    Group.new("Visual", c.blue, c.base, s.none)
    Group.new("VisualNOS", c.blue, c.base, s.none)
    Group.new("WildMenu", c.fruit, c.base, s.none)

    -- spelling problesm are shown!
    Group.new("SpellBad", c.red, c.none, s.undercurl)
    -- https://neovim.io/doc/user/syntax.html#hl-SpellCap
    Group.new("SpellCap", c.orange, c.none, s.undercurl)
    -- https://neovim.io/doc/user/syntax.html#hl-SpellLocal
    Group.new("SpellLocal", c.brown, c.none, s.undercurl)
    -- https://neovim.io/doc/user/syntax.html#hl-SpellRare
    Group.new("SpellRare", c.blue, c.none, s.undercurl)

    -- LINKS
    Group.new("Constant", g.Normal, g.Normal, g.Normal + s.italic)
    Group.link("Boolean", g.Number)
    Group.link("Character", g.Number)
    Group.link("Conditional", g.Normal)
    Group.link("Debug", g.Todo)
    Group.link("Delimiter", g.Normal)
    Group.link("Directory", g.String)
    Group.link("Exception", g.Normal)
    Group.link("Function", g.Special)
    Group.link("Identifier", g.Normal)
    Group.link("Include", g.Normal)
    Group.link("Keyword", g.Noise)
    Group.link("Label", g.Normal)
    Group.link("Macro", g.User2)
    Group.link("Operator", g.Noise)
    Group.link("PreProc", g.Normal)
    Group.link("Repeat", g.Normal)
    Group.link("SpecialChar", g.Special)
    Group.link("SpecialKey", g.Special)
    Group.link("Statement", g.Normal)
    Group.link("StorageClass", g.Normal)
    Group.link("Structure", g.Normal)
    Group.link("Tag", g.Normal)
    Group.link("Type", g.User3)
    Group.link("TypeDef", g.User3)

    -- treesitter stuff
    Group.link("@type.builtin", g.User3)
    Group.link("@constant.builtin", g.User1)
    Group.link("@constructor", g.Normal)
    Group.link("@exception.operator", g.Special)
    Group.link("@function.macro", g.Normal)
    Group.link("@namespace", g.Normal)
    Group.link("@punctuation.special", g.Normal)
    Group.link("@keyword.storage", g.User2)
    Group.link("@type.qualifier", g.Normal)
    Group.link("@variable", g.Normal)
    Group.link("@variable.builtin", g.String)

    -- USER INTERFACE
    Group.link("ErrorMsg", g.Error)
    Group.link("ModeMsg", g.Normal)
    Group.link("MoreMsg", g.Normal)
    Group.link("Question", g.Warning)
    Group.link("WarningMsg", g.Warning)

    Group.link("Conceal", g.Comment)
    Group.link("CursorLine", g.StatusLine)
    Group.link("ColorColumn", g.CursorLine)
    Group.link("CursorLineNr", g.Normal)
    Group.link("EndOfBuffer", g.NonText)
    Group.link("Folded", g.NonText)
    Group.link("LineNr", g.NonText)
    Group.link("FoldColumn", g.LineNr)
    Group.link("SignColumn", g.LineNr)
    Group.link("VertSplit", g.NonText)
    Group.link("Whitespace", g.NonText)
    Group.link("WinSeparator", g.NonText)

    Group.link("NormalFloat", g.Normal)
    Group.link("TabLine", g.Normal)
    Group.link("TabLineFill", g.Normal)
    Group.link("TabLineSel", g.Special)

    Group.link("NvimInternalError", g.Error)
    Group.link("FloatBorder", g.NonText)

    -- PLUGIN SPECIFIC
    Group.new("DiagnosticUnderlineError", c.none, c.none, s.underline, c.red)
    Group.new("DiagnosticUnderlineWarn", c.none, c.none, s.underline, c.orange)
    Group.new("DiagnosticUnderlineHint", c.none, c.none, s.underline)
    Group.new("DiagnosticUnderlineInfo", c.none, c.none, s.underline)

    Group.link("DiagnosticError", g.Error)
    Group.link("DiagnosticWarn", g.Warning)
    Group.link("DiagnosticHint", g.Comment)
    Group.link("DiagnosticInfo", g.Comment)
    Group.link("DiagnosticOk", g.String)

    Group.link("GitSignsAdd", g.NonText)
    Group.link("GitSignsChange", g.NonText)
    Group.link("GitSignsDelete", g.NonText)

    Group.link("TelescopeBorder", g.Noise)
    Group.link("TelescopeMatching", g.User1)
    Group.link("TelescopePromptCounter", g.Noise)

    -- custom markdown
    Group.link("@markup.list.unchecked.markdown", g.Error)
    Group.link("@markup.list.checked.markdown", g.Number)
    Group.link("@markup.link.label.markdown_inline", g.Special)
    Group.link("@markup.link.url.markdown_inline", g.Noise)
end

return {
    {
        "tjdevries/colorbuddy.nvim",
        config = function()
            local colorbuddy = require "colorbuddy"

            setup_colors()
        end,
    },
}

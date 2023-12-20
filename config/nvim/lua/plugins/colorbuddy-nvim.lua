local function init_colors(color)
    local palette = {
        white = { gui = "#eaeaea", cterm = 250 },
        lighgray = { gui = "#919191", cterm = 246 },
        lightergray = { gui = "#717171", cterm = 246 },
        gray = { gui = "#4c5356", cterm = 238 },
        darkgray = { gui = "#34373a", cterm = 095 },
        dark = { gui = "#1c1c1c", cterm = 243 },
        black = { gui = "#131515", cterm = 234 },
        backgnd = { gui = "#181a1b", cterm = 233 },
        backgnd_alt = { gui = "#2f3132", cterm = 233 },

        darkgreen = { gui = "#37ad82", cterm = 065 },
        limegreen = { gui = "#a3db81", cterm = 108 },
        pink = { gui = "#ca70d6", cterm = 175 },
        purple = { gui = "#a29bfe", cterm = 103 },
        red = { gui = "#d75f5f", cterm = 167 },
        orange = { gui = "#fe8019", cterm = 173 },
        yellow = { gui = "#FAC03B", cterm = 173 },
        brown = { gui = "#af875f", cterm = 137 },
        blue = { gui = "#7398dd", cterm = 067 },
    }

    -- initialize all colors from palette
    for key, value in pairs(palette) do
        color.new(key, value.gui)
    end
end

local function init_groups(Group, colors, styles)
    Group.new("None", colors.none, colors.none, styles.none)
    Group.new("Header", colors.white, colors.none, styles.none)
    Group.new("Normal", colors.white, colors.backgnd, styles.none)
    Group.new("Noise", colors.lighgray, colors.none, styles.none)
    Group.new("Comment", colors.lightergray, colors.none, styles.none)
    Group.new("NonText", colors.dark, colors.none, styles.none)

    Group.new("Error", colors.red, colors.none, styles.none)
    Group.new("Number", colors.purple, colors.none, styles.none)
    Group.new("Special", colors.yellow, colors.none, styles.none)
    Group.new("String", colors.darkgreen, colors.none, styles.none)
    Group.new("Title", colors.blue, colors.none, styles.none)
    Group.new("Todo", colors.pink, colors.none, styles.none)
    Group.new("Warning", colors.orange, colors.none, styles.none)
    Group.new("Hint", colors.blue, colors.none, styles.none)

    Group.new("SitrusPurple", colors.purple, colors.none, styles.none)
    Group.new("SitrusBlue", colors.blue, colors.none, styles.none)
    Group.new("SitrusRed", colors.red, colors.none, styles.none)
    Group.new("SitrusOrange", colors.orange, colors.none, styles.none)
    Group.new("SitrusYellow", colors.yellow, colors.none, styles.none)
    Group.new("SitrusGray", colors.gray, colors.none, styles.none)
    Group.new("SitrusDark", colors.dark, colors.none, styles.none)
    Group.new("SitrusBlack", colors.black, colors.none, styles.none)
    Group.new("SitrusLimegreen", colors.limegreen, colors.none, styles.none)
    Group.new("SitrusGreen", colors.green, colors.none, styles.none)

    Group.new("SitrusBlueReverse", colors.blue, colors.none, styles.reverse)
    Group.new("SitrusOrangeReverse", colors.orange, colors.none, styles.reverse)

    Group.new("DiffAdd", colors.limegreen, colors.none, styles.none)
    Group.new("DiffAdded", colors.limegreen, colors.none, styles.none)
    Group.new("DiffChange", colors.blue, colors.none, styles.none)
    Group.new("DiffDelete", colors.red, colors.none, styles.none)
    Group.new("DiffLine", colors.black, colors.backgnd_alt, styles.underline)
    Group.new("DiffRemoved", colors.red, colors.backgnd_alt, styles.none)
    Group.new("DiffText", colors.brown, colors.backgnd_alt, styles.none)

    Group.new("SpellBad", colors.red, colors.none, styles.undercurl)
    Group.new("SpellCap", colors.orange, colors.none, styles.undercurl)
    Group.new("SpellLocal", colors.brown, colors.none, styles.undercurl)
    Group.new("SpellRare", colors.blue, colors.none, styles.undercurl)

    Group.new("IncSearch", colors.orange, colors.none, styles.reverse)
    Group.new("CurSearch", colors.orange, colors.none, styles.reverse)
    Group.new("Search", colors.yellow, colors.none, styles.reverse)
    Group.new("MatchParen", colors.yellow, colors.none, styles.none)
    Group.new("Pmenu", colors.none, colors.backgnd_alt, styles.none)
    Group.new("PmenuSel", colors.yellow, colors.dark, styles.none)
    Group.new("StatusLine", colors.none, colors.black, styles.none)
    Group.new("StatusLineNC", colors.black, colors.black, styles.none)
    Group.new("URI", colors.darkgreen, colors.none, styles.underline)
    Group.new("Visual", colors.none, colors.darkgray, styles.none)
    Group.new("VisualNOS", colors.none, colors.darkgray, styles.none)
    Group.new("WildMenu", colors.pink, colors.darkgray, styles.none)

    Group.new("TSDefine", colors.darkgreen, colors.none, styles.none)

    Group.new("NormalFloat", colors.white, colors.backgnd_alt, styles.none)
    Group.new(
        "DiagnosticUnderlineError",
        colors.none,
        colors.none,
        styles.underline,
        colors.red
    )
    Group.new(
        "DiagnosticUnderlineWarn",
        colors.none,
        colors.none,
        styles.underline,
        colors.orange
    )
    Group.new(
        "DiagnosticUnderlineHint",
        colors.none,
        colors.none,
        styles.underline,
        colors.blue
    )
    Group.new(
        "DiagnosticUnderlineInfo",
        colors.none,
        colors.none,
        styles.underline,
        colors.gray
    )
end

local function treesitter(group, groups)
    group.link("@text.todo.unchecked", groups.ErrorMsg)
    group.link("@text.todo.checked", groups.Hint)

    group.link("@comment", groups.Comment)
    group.link("@none", groups.None)
    group.link("@preproc", groups.PreProc)
    group.link("@define", groups.TSDefine)
    group.link("@operator", groups.Operator)

    group.link("@punctuation.delimiter", groups.Delimiter)
    group.link("@punctuation.bracket", groups.Delimiter)
    group.link("@punctuation.special", groups.Delimiter)

    group.link("@string", groups.String)
    group.link("@string.regex", groups.String)
    group.link("@string.escape", groups.SpecialChar)
    group.link("@string.special", groups.SpecialChar)
    group.link("@character", groups.Character)
    group.link("@character.special", groups.SpecialChar)
    group.link("@boolean", groups.Boolean)
    group.link("@number", groups.Number)

    group.link("@function", groups.Function)
    group.link("@function.builtin", groups.Special)
    group.link("@function.call", groups.Function)
    group.link("@function.macro", groups.Macro)

    group.link("@method", groups.Function)
    group.link("@method.call", groups.Function)

    group.link("@constructor", groups.Normal)
    group.link("@parameter", groups.Identifier)

    group.link("@keyword", groups.Keyword)
    group.link("@keyword.function", groups.Keyword)
    group.link("@keyword.operator", groups.SitrusRed)
    group.link("@keyword.return", groups.Keyword)

    group.link("@conditional", groups.Conditional)

    group.link("@repeat", groups.Repeat)
    group.link("@debug", groups.Debug)
    group.link("@label", groups.Label)
    group.link("@include", groups.Include)
    group.link("@exception", groups.Exception)

    group.link("@type", groups.Type)
    group.link("@type.builtin", groups.Type)
    group.link("@type.definition", groups.Typedef)
    group.link("@type.qualifier", groups.Type)

    group.link("@storageclass", groups.StorageClass)
    group.link("@attribute", groups.PreProc)
    group.link("@field", groups.Identifier)
    group.link("@property", groups.Identifier)

    group.link("@variable", groups.Normal)
    group.link("@variable.builtin", groups.Normal)

    group.link("@constant", groups.Constant)
    group.link("@constant.builtin", groups.Normal)
    group.link("@constant.macro", groups.TSDefine)

    group.link("@namespace", groups.Normal)
    group.link("@symbol", groups.Boolean)

    group.link("@text", groups.Normal)
    group.link("@text.title", groups.Title)
    group.link("@text.literal", groups.String)
    group.link("@text.uri", groups.URI)
    group.link("@text.math", groups.Special)
    group.link("@text.environment", groups.Macro)
    group.link("@text.environment.name", groups.Type)
    group.link("@text.reference", groups.Constant)
    group.link("@text.todo", groups.Todo)
    group.link("@text.note", groups.Comment)
    group.link("@text.warning", groups.Warning)
    group.link("@text.danger", groups.ErrorMsg)

    group.link("@text.diff.add", groups.DiffAdded)
    group.link("@text.diff.delete", groups.DiffRemoved)

    group.link("@tag", groups.Tag)
    group.link("@tag.attribute", groups.Identifier)
    group.link("@tag.delimiter", groups.Delimiter)

    group.link("@punctuation", groups.Delimiter)
    group.link("@macro", groups.Macro)
    group.link("@structure", groups.Structure)

    group.link("@lsp.type.class", groups.Noise)
    group.link("@lsp.type.decorator", groups.Identifier)
    group.link("@lsp.type.enum", groups.Type)
    group.link("@lsp.type.enumMember", groups.Constant)
    group.link("@lsp.type.function", groups.Noise)
    group.link("@lsp.type.interface", groups.Keyword)
    group.link("@lsp.type.macro", groups.Macro)
    group.link("@lsp.type.method", groups.Function)
    group.link("@lsp.type.namespace", groups.Noise)
    group.link("@lsp.type.parameter", groups.Normal)
    group.link("@lsp.type.property", groups.Identifier)
    group.link("@lsp.type.struct", groups.Noise)
    group.link("@lsp.type.type", groups.Type)
    group.link("@lsp.type.typeParameter", groups.Typedef)
    group.link("@lsp.type.variable", groups.Normal)
end

local function basic_editor(Group, groups)
    Group.link("Constant", groups.Normal)
    Group.link("Delimiter", groups.Normal)
    Group.link("Function", groups.Normal)
    Group.link("Identifier", groups.Normal)
    Group.link("Statement", groups.Normal)
    Group.link("Type", groups.Noise)
    Group.link("Structure", groups.Noise)
    Group.link("TypeDef", groups.Noise)

    Group.link("Conditional", groups.SitrusYellow)
    Group.link("Exception", groups.Noise)
    Group.link("Include", groups.Noise)
    Group.link("Keyword", groups.SitrusYellow)
    Group.link("Macro", groups.Noise)
    Group.link("Operator", groups.Noise)
    Group.link("PreProc", groups.Noise)
    Group.link("Repeat", groups.Noise)
    Group.link("StorageClass", groups.Noise)

    Group.link("Boolean", groups.Number)
    Group.link("Character", groups.Number)
    Group.link("Debug", groups.Todo)
    Group.link("Directory", groups.String)
    Group.link("Label", groups.SitrusBlue)
    Group.link("SpecialChar", groups.Special)
    Group.link("SpecialKey", groups.Special)
    Group.link("Tag", groups.SitrusBlue)
end

local function basic_ui(Group, groups)
    Group.link("ErrorMsg", groups.Error)
    Group.link("ModeMsg", groups.Normal)
    Group.link("MoreMsg", groups.Normal)
    Group.link("Question", groups.Warning)
    Group.link("WarningMsg", groups.Warning)
    Group.link("HealthSuccess", groups.String)

    Group.link("CursorLine", groups.StatusLine)
    Group.link("ColorColumn", groups.CursorLine)
    Group.link("LineNr", groups.SitrusGray)
    Group.link("CursorLineNr", groups.SitrusYellow)
    Group.link("EndOfBuffer", groups.NonText)
    Group.link("FoldColumn", groups.LineNr)
    Group.link("Folded", groups.NonText)
    Group.link("SignColumn", groups.SitrusGray)
    Group.link("VertSplit", groups.LineNr)
    Group.link("Whitespace", groups.NonText)

    Group.link("TabLine", groups.Normal)
    Group.link("TabLineFill", groups.Normal)
    Group.link("TabLineSel", groups.Special)

    Group.link("NvimInternalError", groups.Error)
    Group.link("FloatBorder", groups.Noise)
end

local function diagnostics(Group, groups)
    Group.link("DiagnosticError", groups.Error)
    Group.link("DiagnosticWarn", groups.Warning)
    Group.link("DiagnosticHint", groups.Hint)
    Group.link("DiagnosticInfo", groups.Comment)
end

local function gitsigns(Group, groups)
    Group.link("GitSignsAdd", groups.DiffAdd)
    Group.link("GitSignsChange", groups.DiffChange)
    Group.link("GitSignsDelete", groups.DiffDelete)
end

local function telescope(Group, groups)
    Group.link("TelescopeBorder", groups.Normal)
    Group.link("TelescopeMatching", groups.SitrusBlue)
    Group.link("TelescopeSelection", groups.SitrusOrange)
end

local function lsp(Group, groups)
    Group.link("LspInlayHint", groups.NonText)
end

local function cmp(Group, groups)
    Group.link("CmpItemAbbr", groups.NormalFloat)
    Group.link("CmpItemAbbrMatch", groups.SitrusYellow)
    Group.link("CmpItemAbbrMatchFuzzy", groups.SitrusYellow)
    Group.link("CmpItemKind", groups.SitrusBlue)
    Group.link("CmpItemKindText", groups.SitrusOrange)
    Group.link("CmpItemMenu", groups.SitrusPurple)
end

local function help(Group, groups)
    Group.link("helpHeader", groups.Header)
    Group.link("helpHeadline", groups.Title)
    Group.link("helpHyperTextEntry", groups.Number)
    Group.link("helpIgnore", groups.NonText)
    Group.link("helpOption", groups.String)
    Group.link("helpSectionDelim", groups.Noise)
end

return {
    {
        "tjdevries/colorbuddy.nvim",
        config = function()
            local Color, colors, Group, groups, styles =
                require("colorbuddy").setup()

            init_colors(Color)
            init_groups(Group, colors, styles)

            basic_editor(Group, groups)
            basic_ui(Group, groups)
            diagnostics(Group, groups)
            gitsigns(Group, groups)
            telescope(Group, groups)
            lsp(Group, groups)
            cmp(Group, groups)
            help(Group, groups)
            treesitter(Group, groups)
        end,
    },
}

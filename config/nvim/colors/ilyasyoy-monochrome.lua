local function hi(group, opts)
    opts = opts or {}
    local guifg = opts.guifg or "NONE"
    local guibg = opts.guibg or "NONE"
    local guisp = opts.guisp or "NONE"
    local gui = opts.gui or "NONE"
    local ctermfg = opts.ctermfg or "NONE"
    local ctermbg = opts.ctermbg or "NONE"
    local cterm = opts.cterm or "NONE"

    local cmd = string.format(
        "hi %s guifg=%s guibg=%s guisp=%s gui=%s ctermfg=%s ctermbg=%s cterm=%s",
        group,
        guifg,
        guibg,
        guisp,
        gui,
        ctermfg,
        ctermbg,
        cterm
    )
    vim.cmd(cmd)
end

local function link(from, to)
    vim.cmd(string.format("hi! link %s %s", from, to))
end

-- =============================================================================
-- PALETTE
-- =============================================================================
local palette = {
    bg = "#000000",
    fg = "#dadada",
    elevated = "#1c1c1c",
    subtle = "#303030",
    muted = "#707070",
    noise = "#191919",

    search = "#00afff",
    visual = "#ffaf00",
    add = "#416241",
    remove = "#722529",
    error = "#ff005f",
    cursor = "#8787af",
}

local bg = vim.o.background

if bg == "light" then
    palette.bg = "#eeeeee"
    palette.fg = "#000000"
    palette.elevated = "#d7d7d7"
    palette.subtle = "#e4e4e4"
    palette.muted = "#626262"
    palette.add = "#8dda9e"
    palette.remove = "#da8d8d"
    palette.noise = "#cccccc"
end

-- Set up colorscheme
vim.cmd "set termguicolors"
vim.cmd 'let g:colors_name = "ilyasyoy-monochrome"'
vim.cmd("set background=" .. bg)

-- =============================================================================
-- BASE GROUPS
-- =============================================================================
hi("Normal", { guifg = palette.fg, guibg = palette.bg })
hi("CursorLine", { guibg = palette.subtle })
hi("CursorLineNr", { guifg = palette.fg, guibg = palette.subtle })
hi("ColorColumn", { guibg = palette.subtle })
hi("LineNr", { guifg = palette.muted })
hi("FoldColumn", { guifg = palette.muted })
hi("Folded", { guifg = palette.muted, guibg = palette.bg })
hi("EndOfBuffer", { guifg = palette.muted })
hi("Conceal", { guifg = palette.muted })
hi("NonText", { guifg = palette.noise })
hi("SpecialKey", { guifg = palette.noise, gui = "bold" })

-- =============================================================================
-- SYNTAX ELEMENTS
-- =============================================================================
hi("Comment", { guifg = palette.muted })
hi("Keyword", { guifg = palette.muted })
hi("Statement", { guifg = palette.fg })
hi("Function", { guifg = palette.fg, gui = "bold" })
hi("Identifier", { guifg = palette.fg })
hi("Type", { guifg = palette.fg, gui = "underline" })
hi("Typedef", { guifg = palette.fg, gui = "underline" })
hi("StorageClass", { guifg = palette.fg })
hi("Structure", { guifg = palette.fg })

hi("Constant", { guifg = palette.fg, gui = "italic" })
hi("String", { guifg = palette.fg, gui = "italic" })
hi("Number", { guifg = palette.fg, gui = "italic" })
hi("Boolean", { guifg = palette.fg, gui = "italic" })
hi("Float", { guifg = palette.fg, gui = "italic" })
hi("Character", { guifg = palette.fg, gui = "italic" })

hi("PreProc", { guifg = palette.fg })
hi("Include", { guifg = palette.fg })
hi("Define", { guifg = palette.fg })
hi("Macro", { guifg = palette.fg })
hi("PreCondit", { guifg = palette.fg })

hi("Special", { guifg = palette.fg })
hi("SpecialChar", { guifg = palette.fg })
hi("Tag", { guifg = palette.fg })
hi("Delimiter", { guifg = palette.fg })
hi("SpecialComment", { guifg = palette.fg })

hi("Underlined", { guifg = palette.fg, gui = "underline" })
hi("Ignore", { guifg = palette.fg })

-- =============================================================================
-- TREESITTER LINKS
-- =============================================================================
link("@function", "Function")
link("@function.call", "Function")
link("@function.builtin", "Function")
link("@function.method", "Function")
link("@function.method.call", "Function")

link("@type", "Type")
link("@type.builtin", "Type")
link("@type.definition", "Type")

link("@keyword", "Keyword")
link("@keyword.return", "Keyword")
link("@keyword.function", "Keyword")
link("@keyword.operator", "Keyword")
link("@keyword.import", "Keyword")
link("@keyword.type", "Keyword")
link("@keyword.modifier", "Keyword")
link("@keyword.repeat", "Keyword")
link("@keyword.conditional", "Keyword")
link("@keyword.exception", "Keyword")

link("@comment", "Comment")
link("@comment.documentation", "Comment")

link("@variable", "Identifier")
link("@variable.parameter", "Identifier")
link("@variable.member", "Identifier")
link("@constant", "Constant")
link("@constant.builtin", "Constant")
link("@string", "String")
link("@string.documentation", "String")
link("@string.regexp", "String")
link("@string.escape", "String")
link("@string.special", "String")
link("@string.special.symbol", "String")
link("@string.special.url", "String")
link("@string.special.path", "String")

link("@character", "Character")
link("@character.special", "Character")

link("@number", "Number")
link("@number.float", "Number")

link("@boolean", "Boolean")

link("@number", "Number")

link("@operator", "Operator")

link("@punctuation.delimiter", "Delimiter")
link("@punctuation.bracket", "Delimiter")

link("@tag", "Tag")
link("@tag.attribute", "Type")

-- =============================================================================
-- SEARCH AND VISUAL
-- =============================================================================
hi(
    "Search",
    { guifg = palette.search, guibg = palette.bg, gui = "reverse" }
)
hi(
    "IncSearch",
    { guifg = palette.visual, guibg = palette.bg, gui = "reverse" }
)
hi(
    "CurSearch",
    { guifg = palette.visual, guibg = palette.bg, gui = "reverse" }
)
hi(
    "Visual",
    { guifg = palette.visual, guibg = palette.elevated }
)
hi("VisualNOS", { guibg = palette.subtle })

-- =============================================================================
-- DIFF
-- =============================================================================
hi("DiffAdd", { guibg = palette.add })
hi("DiffDelete", { guibg = palette.remove })
hi("DiffChange", { guibg = "#87afd7" })
hi("DiffText", { guibg = "#d787d7" })

link("@diff.plus", "DiffAdd")
link("@diff.minus", "DiffDelete")
link("@diff.delta", "DiffChange")

link("diffAdded", "DiffAdd")
link("diffRemoved", "DiffDelete")

-- =============================================================================
-- UI ELEMENTS
-- =============================================================================
hi("StatusLine", { guifg = palette.bg, guibg = palette.elevated, gui = "bold" })
hi("StatusLineNC", { guifg = palette.muted, guibg = palette.elevated })
hi("WinSeparator", { guifg = palette.muted, guibg = palette.bg })
hi("TabLine", { guifg = palette.muted, guibg = palette.bg })
hi("TabLineFill", { guifg = palette.muted, guibg = palette.bg })
hi("TabLineSel", { guibg = palette.elevated, gui = "bold,reverse" })

hi("NormalFloat", { guifg = palette.fg, guibg = palette.elevated })

hi("Pmenu", { guifg = palette.fg, guibg = palette.elevated })
hi("PmenuSel", { guifg = palette.bg, guibg = palette.fg })
hi("PmenuExtra", { guifg = palette.fg, guibg = palette.elevated })
hi("PmenuExtraSel", { guifg = palette.bg, guibg = palette.fg })
hi("PmenuKind", { guifg = palette.fg, guibg = palette.elevated, gui = "bold" })
hi("PmenuKindSel", { guifg = palette.bg, guibg = palette.fg, gui = "bold" })
hi("PmenuSbar", { guibg = palette.subtle })
hi("PmenuThumb", { guibg = palette.muted })

hi(
    "WildMenu",
    { guifg = palette.search, guibg = palette.bg, gui = "bold" }
)
hi("Directory", { guifg = palette.fg })
hi("Title", { guifg = palette.fg })
hi("Question", { guifg = palette.fg })
hi("MoreMsg", { guifg = palette.fg })
hi("ModeMsg", { guifg = palette.fg, gui = "bold" })

-- =============================================================================
-- MATCH AND SPELL
-- =============================================================================
hi("MatchParen", { guifg = palette.visual, gui = "bold,underline" })
hi("SpellBad", {
    guifg = palette.error,
    guisp = palette.error,
    gui = "undercurl",
})
hi("SpellCap", { guifg = "#0087d7", guisp = "#0087d7", gui = "undercurl" })
hi("SpellLocal", { guifg = "#d787d7", guisp = "#d787d7", gui = "undercurl" })
hi("SpellRare", { guifg = "#00afaf", guisp = "#00afaf", gui = "undercurl" })

-- =============================================================================
-- ERROR AND TODO
-- =============================================================================
hi(
    "Error",
    { guifg = palette.error, guibg = palette.bg, gui = "bold,reverse" }
)
hi("ErrorMsg", { guibg = palette.error })
hi("WarningMsg", { guifg = palette.fg })
hi("Todo", { guifg = palette.search, gui = "bold,reverse" })

-- =============================================================================
-- DIAGNOSTICS
-- =============================================================================
hi("DiagnosticError", { guifg = palette.error, gui = "bold" })
hi("DiagnosticUnderlineError", { guisp = palette.error, gui = "undercurl" })
hi("DiagnosticVirtualTextError", { guifg = palette.error })
hi("DiagnosticFloatingError", { guifg = palette.error })
link("DiagnosticSignError", "DiagnosticError")

hi("DiagnosticWarn", { guisp = palette.noise })
hi("DiagnosticInfo", { guisp = palette.noise })
hi("DiagnosticHint", { guisp = palette.noise })
hi("DiagnosticOk", { guisp = palette.noise })

hi("DiagnosticVirtualTextWarn", { guisp = palette.noise })
hi("DiagnosticVirtualTextInfo", { guisp = palette.noise })
hi("DiagnosticVirtualTextHint", { guisp = palette.noise })
hi("DiagnosticVirtualTextOk", { guisp = palette.noise })

hi("DiagnosticUnderlineWarn", { guisp = palette.noise, gui = "undercurl" })
hi("DiagnosticUnderlineInfo", { guisp = palette.noise, gui = "undercurl" })
hi("DiagnosticUnderlineHint", { guisp = palette.noise, gui = "undercurl" })
hi("DiagnosticUnderlineOk", { guisp = palette.noise, gui = "undercurl" })

link("DiagnosticSignWarn", "DiagnosticWarn")
link("DiagnosticSignInfo", "DiagnosticInfo")
link("DiagnosticSignHint", "DiagnosticHint")
link("DiagnosticSignOk", "DiagnosticOk")

-- =============================================================================
-- CURSOR
-- =============================================================================
hi("Cursor", { guibg = palette.cursor })

-- =============================================================================
-- SIGN COLUMN
-- =============================================================================
hi("SignColumn", { guifg = palette.fg })
hi("LineNr", { guifg = palette.muted })

-- =============================================================================
-- QUICKFIX
-- =============================================================================
hi("QuickFixLine", { guifg = palette.search, gui = "reverse" })
hi("qfFileName", { gui = "bold" })

-- =============================================================================
-- FUGITIVE
-- =============================================================================
link("fugitiveStagedHeading", "Include")
link("fugitiveUnstagedHeading", "Macro")
link("fugitiveUntrackedHeading", "PreCondit")
link("fugitiveStagedModifier", "Typedef")
link("fugitiveUnstagedModifier", "Structure")
link("fugitiveUntrackedModifier", "StorageClass")
link("fugitiveHeader", "Label")
link("fugitiveHelpHeader", "fugitiveHeader")
link("fugitiveHelpTag", "Tag")
link("fugitiveHash", "Identifier")
link("fugitiveSymbolicRef", "Function")
link("fugitiveCount", "Number")
link("fugitiveInstruction", "Type")
link("fugitiveStop", "Function")

-- =============================================================================
-- MISC LINKS
-- =============================================================================
link("Added", "Normal")
link("Changed", "Normal")
link("Removed", "Normal")
link("Boolean", "Constant")
link("Character", "Constant")
link("Float", "Constant")
link("Number", "Constant")
link("String", "Constant")
link("Conditional", "Statement")
link("Repeat", "Statement")
link("Label", "Statement")
link("Operator", "Statement")
link("Exception", "Statement")
link("Debug", "Special")
link("define", "PreProc")
link("include", "PreProc")

-- =============================================================================
-- FZF-LUA
-- =============================================================================
hi("FzfLuaNormal", { guifg = palette.fg, guibg = palette.bg })
hi("FzfLuaBorder", { guifg = palette.muted, guibg = palette.bg })
hi("FzfLuaTitle", { guifg = palette.fg, guibg = palette.elevated })
hi("FzfLuaTitleFlags", { guifg = palette.fg, guibg = palette.subtle })
hi("FzfLuaBackdrop", { guifg = palette.muted, guibg = palette.bg })
hi("FzfLuaPreviewNormal", { guifg = palette.fg, guibg = palette.elevated })
hi("FzfLuaPreviewBorder", { guifg = palette.muted, guibg = palette.elevated })
hi("FzfLuaPreviewTitle", { guifg = palette.fg, guibg = palette.elevated })
hi("FzfLuaCursor", { guibg = palette.cursor })
hi("FzfLuaCursorLine", { guibg = palette.subtle })
hi("FzfLuaCursorLineNr", { guifg = palette.fg, guibg = palette.subtle })
hi("FzfLuaSearch", { guifg = palette.visual, guibg = palette.bg, gui = "reverse" })
hi("FzfLuaScrollBorderEmpty", { guifg = palette.muted, guibg = palette.bg })
hi("FzfLuaScrollBorderFull", { guifg = palette.muted, guibg = palette.bg })
hi("FzfLuaScrollFloatEmpty", { guibg = palette.subtle })
hi("FzfLuaScrollFloatFull", { guibg = palette.muted })
hi("FzfLuaHelpNormal", { guifg = palette.fg, guibg = palette.bg })
hi("FzfLuaHelpBorder", { guifg = palette.muted, guibg = palette.bg })
hi("FzfLuaHeaderBind", { guifg = palette.fg })
hi("FzfLuaHeaderText", { guifg = palette.fg })
hi("FzfLuaPathColNr", { guifg = palette.search })
hi("FzfLuaPathLineNr", { guifg = palette.add })
hi("FzfLuaBufName", { guifg = palette.fg })
hi("FzfLuaBufId", { guifg = palette.muted })
hi("FzfLuaBufNr", { guifg = palette.fg })
hi("FzfLuaBufLineNr", { guifg = palette.muted })
hi("FzfLuaBufFlagCur", { guifg = palette.fg })
hi("FzfLuaBufFlagAlt", { guifg = palette.search })
hi("FzfLuaTabTitle", { guifg = palette.search })
hi("FzfLuaTabMarker", { guifg = palette.fg })
hi("FzfLuaDirIcon", { guifg = palette.fg })
hi("FzfLuaDirPart", { guifg = palette.muted })
hi("FzfLuaFilePart", { guifg = palette.fg })
hi("FzfLuaLivePrompt", { guifg = palette.fg })
hi("FzfLuaLiveSym", { guifg = palette.search })
hi("FzfLuaCmdEx", { guifg = palette.fg })
hi("FzfLuaCmdBuf", { guifg = palette.add })
hi("FzfLuaCmdGlobal", { guifg = palette.fg })
hi("FzfLuaFzfNormal", { guifg = palette.fg, guibg = palette.bg })
hi("FzfLuaFzfCursorLine", { guifg = palette.fg, guibg = palette.subtle })
hi("FzfLuaFzfMatch", { guifg = palette.search, gui = "bold" })
hi("FzfLuaFzfBorder", { guifg = palette.muted, guibg = palette.bg })
hi("FzfLuaFzfScrollbar", { guifg = palette.muted, guibg = palette.bg })

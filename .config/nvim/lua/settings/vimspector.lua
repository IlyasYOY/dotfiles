local mapping = require("functions.map")

local map_normal = mapping.map_normal

map_normal("<leader><F1>", "<Plug>VimspectorReset")
map_normal("<F2>", "<Plug>VimspectorStop")
map_normal("<F5>", "<Plug>VimspectorContinue")
map_normal("<leader><F5>", "<Plug>VimspectorRunToCursor")
map_normal("<F6>", "<Plug>VimspectorPause")
map_normal("<F9>", "<Plug>VimspectorToggleBreakpoint")
map_normal("<leader><F9>", "<Plug>VimspectorToggleConditionalBreakpoint")
map_normal("<F10>", "<Plug>VimspectorStepOver")
map_normal("<leader><F10>", "<Plug>VimspectorStepInto")
map_normal("<F12>", "<Plug>VimspectorStepOut")

std = luajit
codes = true

self = false

-- Glorious list of warnings: https://luacheck.readthedocs.io/en/stable/warnings.html
ignore = {
    "212", -- Unused argument, In the case of callback function, _arg_name is easier to understand than _, so this option is set to off.
    "122", -- Indirectly setting a readonly global
}

globals = {
    "_",
    "G_P",
    "G_R",
    "TelescopeGlobalState",
    "_TelescopeConfigurationValues",
    "_TelescopeConfigurationPickers",
    "__TelescopeKeymapStore",
}

-- Global objects defined by the C code
read_globals = {
    "vim",
    "assert",
    "describe",
    "it",
    "before_each",
    "after_each",
    "pending",
    "clear",
    -- for hammerspoon
    "hs",
}

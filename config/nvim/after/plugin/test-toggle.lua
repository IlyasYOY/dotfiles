require("test-toggle").setup {
    keymap = "<localleader>ot",
    filetypes = {
        go = { preset = "go", command = "GoToggleTest" },
        java = { preset = "java", command = "JavaToggleTest" },
        python = { preset = "python", command = "PythonToggleTest" },
        javascript = { preset = "javascript", command = "JSToggleTest" },
        typescript = { preset = "typescript", command = "TSToggleTest" },
        typescriptreact = { preset = "tsx", command = "TSXToggleTest" },
        lua = { preset = "lua", command = "LuaToggleTest" },
    },
}

vim.opt_local.spell = true
vim.opt_local.wrap = true

vim.keymap.set("n", "<localleader>fs", function()
    require("codecompanion").prompt "text-fix-spelling-inline"
end, {
    buffer = true,
})

vim.keymap.set(
    { "v", "s" },
    "<localleader>acc",
    "!aichat --role \\%conventional-comment\\%<CR>",
    {
        buffer = true,
    }
)

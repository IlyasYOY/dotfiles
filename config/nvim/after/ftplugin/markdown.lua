vim.opt_local.spell = true
vim.opt_local.wrap = true

vim.keymap.set("n", "<localleader>fs", function()
    require("codecompanion").prompt "text-fix-spelling-inline"
end, {
    buffer = true,
})

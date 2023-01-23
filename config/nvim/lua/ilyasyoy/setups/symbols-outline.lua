local outline = require "symbols-outline"

outline.setup()

vim.keymap.set("n", "<leader>O", function()
    outline.toggle_outline()
end, { desc = "Opens [O]utline", silent = true })

local obsidian = require "functions.obsidian"

obsidian.setup {
    journal = {
        template_name = "daily",
    },
}

vim.keymap.set("n", "<leader>nT", function()
    obsidian.vault:find_and_insert_template()
end, { desc = "Inserts [n]otes [T]emplate" })

vim.keymap.set("n", "<leader>nfj", function()
    obsidian.vault:find_journal()
end, { desc = "[n]otes [f]ind [j]ournal" })

vim.keymap.set("n", "<leader>nd", function()
    obsidian.vault:open_daily()
end, { desc = "[n]otes [d]aily" })

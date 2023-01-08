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

vim.keymap.set("n", "<leader>nff", function()
    obsidian.vault:find_note()
end, { desc = "[n]otes [f]iles [f]ind" })

vim.keymap.set("n", "<leader>nfg", function()
    obsidian.vault:grep_note()
end, { desc = "[n]otes [f]iles [g]rep" })

local group = vim.api.nvim_create_augroup("IlyasyoyObsidian", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = group,
    pattern = "*.md",
    desc = "Setup notes nvim-cmp source",
    callback = function()
        require("cmp").setup.buffer {
            sources = {
                { name = "obsidian" },
            },
        }
    end,
})
